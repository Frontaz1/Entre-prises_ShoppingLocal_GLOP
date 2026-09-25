<#
.SYNOPSIS
    Vérifie et installe les outils de dev du projet GLOP (Windows).

.DESCRIPTION
    1. Diagnostic : compare ce qui est installé avec tools/versions.json. Rien n'est modifié.
    2. S'il y a des actions : UNE confirmation globale, puis installation / mise à jour via winget.
    3. Diagnostic final pour vérifier le résultat.
    Relançable sans risque : un poste déjà conforme n'est jamais modifié.

.PARAMETER CheckOnly
    Fait uniquement le diagnostic, n'installe rien (pas besoin d'être admin).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\setup\setup-windows.ps1 -CheckOnly

.EXAMPLE
    # Dans un PowerShell lancé "en tant qu'administrateur" :
    powershell -ExecutionPolicy Bypass -File tools\setup\setup-windows.ps1
#>
[CmdletBinding()]
param([switch]$CheckOnly)

$ErrorActionPreference = 'Stop'
$cfg = Get-Content (Join-Path $PSScriptRoot '..\versions.json') -Raw -Encoding UTF8 | ConvertFrom-Json

# Codes de retour winget qui ne sont pas des échecs
$WINGET_OK             = 0
$WINGET_NO_UPGRADE     = -1978335189   # 0x8A15002B : déjà à jour
$WINGET_ALREADY        = -1978335135   # 0x8A150061 : déjà installé
$WINGET_REBOOT_TO_END  = -1978334967   # 0x8A150109 : installé, redémarrage requis

$script:RebootNeeded = $false

# ---------------------------------------------------------------- utilitaires

# Lance un exécutable et renvoie sa sortie (stdout + stderr) en texte, ou $null s'il est absent / en erreur.
function Invoke-Capture([string]$exe, [string[]]$arguments) {
    if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) { return $null }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'   # java -version écrit sur stderr : ce n'est pas une erreur
    try {
        $out = & $exe @arguments 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } catch {
        return $null
    } finally {
        $ErrorActionPreference = $prev
    }
    if ($code -ne 0) { return $null }
    return ($out -join "`n").Trim()
}

# "git version 2.51.0.windows.1" -> [version]2.51.0
function ConvertTo-Version([string]$text) {
    if (-not $text) { return $null }
    if ($text -match '(\d+)\.(\d+)\.(\d+)') { return [version]"$($Matches[1]).$($Matches[2]).$($Matches[3])" }
    if ($text -match '(\d+)\.(\d+)')        { return [version]"$($Matches[1]).$($Matches[2]).0" }
    if ($text -match '(\d+)')               { return [version]"$($Matches[1]).0.0" }
    return $null
}

function Get-JavaInfo([string]$javaExe) {
    $raw = Invoke-Capture $javaExe @('-version')
    if (-not $raw -or $raw -notmatch 'version "([^"]+)"') { return $null }
    $v = $Matches[1]
    if ($v -like '1.*') { $v = $v.Substring(2) }   # Java 8 : "1.8.0_392" -> "8.0_392"
    $vendor = 'autre'
    if ($raw -match 'Temurin')      { $vendor = 'Temurin' }
    elseif ($raw -match 'Java\(TM\)') { $vendor = 'Oracle' }
    $version = ConvertTo-Version $v
    return [pscustomobject]@{ Version = $version; Major = $version.Major; Vendor = $vendor }
}

# Le JAVA_HOME "utilisateur" l'emporte sur le JAVA_HOME "machine"
function Get-EffectiveJavaHome {
    $jh = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'User')
    if (-not $jh) { $jh = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine') }
    return $jh
}

# Recharge PATH et JAVA_HOME depuis le registre (sinon la session ne voit pas ce qu'on vient d'installer)
function Update-SessionEnv {
    $env:Path = @([Environment]::GetEnvironmentVariable('Path', 'Machine'),
                  [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';'
    $env:JAVA_HOME = Get-EffectiveJavaHome
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-Row($outil, $trouve, $attendu, $action, $detail = '') {
    if (-not $trouve) { $trouve = 'absent' }
    [pscustomobject]@{ Outil = $outil; Trouve = "$trouve"; Attendu = $attendu; Action = $action; Detail = $detail }
}

# ---------------------------------------------------------------- diagnostic

function Get-Diagnostic {
    $rows = @()

    # winget : prérequis de toutes les installations
    $w = ConvertTo-Version (Invoke-Capture 'winget' @('--version'))
    if ($w) { $rows += New-Row 'winget' $w 'présent' 'OK' }
    else    { $rows += New-Row 'winget' $null 'présent' 'MANUEL' 'Installe "App Installer" depuis le Microsoft Store (https://aka.ms/getwinget)' }

    # Git
    $min = [version]$cfg.git.min
    $v = ConvertTo-Version (Invoke-Capture 'git' @('--version'))
    if (-not $v)        { $rows += New-Row 'Git' $null ">= $min" 'INSTALLER' }
    elseif ($v -lt $min) { $rows += New-Row 'Git' $v ">= $min" 'METTRE A JOUR' }
    else                 { $rows += New-Row 'Git' $v ">= $min" 'OK' }

    # Java (celui que trouve le PATH = celui qu'utilisent le terminal et l'IDE par défaut)
    $major = [int]$cfg.java.major; $min = [version]$cfg.java.min
    $expected = "JDK $major (>= $min)"
    $j = Get-JavaInfo 'java'
    if (-not $j) {
        $rows += New-Row 'Java' $null $expected 'INSTALLER'
    } else {
        # Tout JDK de la bonne majeure est accepté (même code OpenJDK) : le script ne désinstalle jamais rien.
        $found = "$($j.Vendor) $($j.Version)"
        if ($j.Major -ne $major) {
            $rows += New-Row 'Java' $found $expected 'INSTALLER' "Temurin $major sera installé à côté de ton Java actuel"
        } elseif ($j.Version -lt $min -and $j.Vendor -eq 'Temurin') {
            $rows += New-Row 'Java' $found $expected 'METTRE A JOUR'
        } elseif ($j.Version -lt $min) {
            $rows += New-Row 'Java' $found $expected 'MANUEL' "JDK $($j.Vendor) trop ancien : mets-le à jour ou désinstalle-le, puis relance"
        } elseif ($j.Vendor -eq 'Oracle') {
            $rows += New-Row 'Java' $found $expected 'OK' 'Accepté (MAJ gratuites Oracle terminées : Temurin conseillé à terme)'
        } else {
            $rows += New-Row 'Java' $found $expected 'OK'
        }
    }

    # JAVA_HOME (utilisé par Maven / mvnw, pas par le PATH)
    $jh = Get-EffectiveJavaHome
    $jhInfo = $null
    if ($jh) { $jhInfo = Get-JavaInfo (Join-Path $jh 'bin\java.exe') }
    if (-not $jh) {
        $rows += New-Row 'JAVA_HOME' 'non défini' "JDK $major" 'CORRIGER'
    } elseif (-not $jhInfo -or $jhInfo.Major -ne $major) {
        $rows += New-Row 'JAVA_HOME' (Split-Path $jh -Leaf) "JDK $major" 'CORRIGER' "$jh sera repointé vers un JDK $major"
    } else {
        $rows += New-Row 'JAVA_HOME' "$($jhInfo.Vendor) $($jhInfo.Version)" "JDK $major" 'OK'
    }

    # Node.js : majeure figée (le paquet "LTS" de winget changera de majeure un jour, on ne le suit pas aveuglément)
    $major = [int]$cfg.node.major; $min = [version]$cfg.node.min
    $v = ConvertTo-Version (Invoke-Capture 'node' @('-v'))
    if (-not $v)                 { $rows += New-Row 'Node.js' $null "$major.x (>= $min)" 'INSTALLER' }
    elseif ($v.Major -gt $major) { $rows += New-Row 'Node.js' $v "$major.x (>= $min)" 'MANUEL' "Majeure trop récente : désinstalle Node $($v.Major) puis relance le script" }
    elseif ($v -lt $min)         { $rows += New-Row 'Node.js' $v "$major.x (>= $min)" 'METTRE A JOUR' }
    else                         { $rows += New-Row 'Node.js' $v "$major.x (>= $min)" 'OK' }

    # WSL 2 : prérequis de Docker Desktop
    if ($null -ne (Invoke-Capture 'wsl' @('--status'))) { $rows += New-Row 'WSL' 'actif' 'actif' 'OK' }
    else                                                 { $rows += New-Row 'WSL' $null 'actif' 'INSTALLER' 'Redémarrage requis ensuite' }

    # Docker (+ plugin compose)
    $min = [version]$cfg.docker.min
    $v = ConvertTo-Version (Invoke-Capture 'docker' @('--version'))
    $compose = Invoke-Capture 'docker' @('compose', 'version')
    if (-not $v)          { $rows += New-Row 'Docker' $null ">= $min + compose" 'INSTALLER' }
    elseif ($v -lt $min)  { $rows += New-Row 'Docker' $v ">= $min + compose" 'METTRE A JOUR' }
    elseif (-not $compose) { $rows += New-Row 'Docker' $v ">= $min + compose" 'METTRE A JOUR' 'Plugin "docker compose" absent' }
    else                  { $rows += New-Row 'Docker' $v ">= $min + compose" 'OK' }

    return $rows
}

function Show-Diagnostic($rows) {
    $colors = @{ 'OK' = 'Green'; 'MANUEL' = 'Red' }
    $fmt = '{0,-10} {1,-22} {2,-26} {3,-14} {4}'
    Write-Host ($fmt -f 'OUTIL', 'TROUVÉ', 'ATTENDU', 'ACTION', '') -ForegroundColor Cyan
    foreach ($r in $rows) {
        $color = $colors[$r.Action]; if (-not $color) { $color = 'Yellow' }
        Write-Host ($fmt -f $r.Outil, $r.Trouve, $r.Attendu, $r.Action, $r.Detail) -ForegroundColor $color
    }
    Write-Host ''
}

# ---------------------------------------------------------------- actions

function Invoke-Winget([string]$verb, [string]$id, [string[]]$extra = @()) {
    $wingetArgs = @($verb, '--id', $id, '--exact', '--silent', '--disable-interactivity', '--accept-source-agreements')
    if ($verb -eq 'install') { $wingetArgs += '--accept-package-agreements' }
    & winget @($wingetArgs + $extra)
    $code = $LASTEXITCODE
    if ($code -eq $WINGET_REBOOT_TO_END) { $script:RebootNeeded = $true; return }
    if ($code -notin @($WINGET_OK, $WINGET_NO_UPGRADE, $WINGET_ALREADY)) {
        throw "winget $verb $id a échoué (code $code)"
    }
}

# Dernière version publiée de la majeure voulue (ex : 24.19.0 pour la majeure 24)
function Get-LatestWingetVersion([string]$id, [int]$major) {
    $lines = & winget show --id $id --exact --versions --disable-interactivity --accept-source-agreements
    $versions = $lines | Where-Object { $_ -match "^\s*$major\.\d+\.\d+\s*$" } | ForEach-Object { [version]$_.Trim() }
    $latest = $versions | Sort-Object -Descending | Select-Object -First 1
    if (-not $latest) { throw "Aucune version $major.x trouvée pour $id" }
    return "$latest"
}

# Cherche un JDK de la bonne majeure : JAVA_HOME machine, puis Temurin, puis Oracle (emplacements par défaut)
function Find-JdkHome {
    $major = [int]$cfg.java.major
    $candidates = @()
    $machine = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine')
    if ($machine) { $candidates += $machine }
    foreach ($dir in @("$env:ProgramFiles\Eclipse Adoptium", "$env:ProgramFiles\Java")) {
        $candidates += Get-ChildItem $dir -Directory -Filter "jdk-$major*" -ErrorAction SilentlyContinue |
            Sort-Object { ConvertTo-Version $_.Name } -Descending | ForEach-Object { $_.FullName }
    }
    foreach ($c in $candidates) {
        $info = Get-JavaInfo (Join-Path $c 'bin\java.exe')
        if ($info -and $info.Major -eq $major) { return $c }
    }
    return $null
}

function Install-Temurin {
    # FeatureJavaHome = le MSI Temurin définit JAVA_HOME ; FeatureEnvironment = ajoute java au PATH
    Invoke-Winget 'install' $cfg.java.winget @('--custom', 'ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome')
}

function Repair-JavaHome {
    $h = Find-JdkHome
    if (-not $h) { throw "Aucun JDK $($cfg.java.major) trouvé : impossible de corriger JAVA_HOME" }
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $h, 'User')
    $env:JAVA_HOME = $h
}

function Invoke-Fix($row) {
    switch ($row.Outil) {
        'Git'       { Invoke-Winget 'install' $cfg.git.winget }
        'Java'      { Install-Temurin }
        'JAVA_HOME' { Repair-JavaHome }
        'Node.js'   {
            $version = Get-LatestWingetVersion $cfg.node.winget ([int]$cfg.node.major)
            Invoke-Winget 'install' $cfg.node.winget @('--version', $version)
        }
        'WSL'       {
            & wsl --install --no-distribution
            if ($LASTEXITCODE -ne 0) { throw "wsl --install a échoué (code $LASTEXITCODE)" }
            $script:RebootNeeded = $true
        }
        'Docker'    { Invoke-Winget 'install' $cfg.docker.winget }
    }
}

# ---------------------------------------------------------------- programme principal

Write-Host "`n=== GLOP : vérification de l'environnement de dev ===`n" -ForegroundColor Cyan
$rows = Get-Diagnostic
Show-Diagnostic $rows

$todo   = @($rows | Where-Object { $_.Action -notin @('OK', 'MANUEL') })
$manual = @($rows | Where-Object { $_.Action -eq 'MANUEL' })

if ($todo.Count -eq 0) {
    if ($manual.Count -gt 0) { Write-Host 'Il reste des points à régler à la main (en rouge).' -ForegroundColor Red; exit 1 }
    Write-Host 'Tout est conforme, rien à faire.' -ForegroundColor Green
    exit 0
}

if ($CheckOnly) {
    Write-Host "$($todo.Count) action(s) nécessaire(s). Relance sans -CheckOnly (en admin) pour les appliquer." -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'winget est absent : installe-le d''abord (voir ligne winget ci-dessus), puis relance.' -ForegroundColor Red
    exit 1
}
if (-not (Test-IsAdmin)) {
    Write-Host 'Les installations demandent les droits admin : relance PowerShell "en tant qu''administrateur".' -ForegroundColor Red
    exit 1
}

$answer = Read-Host "Appliquer ces $($todo.Count) action(s) ? [O/n]"
if ($answer -and $answer -notmatch '^(o|oui|y|yes)$') {
    Write-Host 'Annulé : rien n''a été modifié.'
    exit 0
}

$failed = @()
foreach ($row in $todo) {
    Write-Host "`n--> $($row.Outil) : $($row.Action)" -ForegroundColor Cyan
    try   { Invoke-Fix $row }
    catch { Write-Host "ÉCHEC : $_" -ForegroundColor Red; $failed += $row.Outil }
}

Update-SessionEnv
Write-Host "`n=== Diagnostic final ===`n" -ForegroundColor Cyan
Show-Diagnostic (Get-Diagnostic)

if ($failed.Count -gt 0) { Write-Host "Échecs : $($failed -join ', '). Corrige puis relance le script." -ForegroundColor Red }
if ($script:RebootNeeded) { Write-Host 'Redémarre le PC, puis relance ce script pour terminer.' -ForegroundColor Yellow }
Write-Host 'Pense à fermer / rouvrir tes terminaux et ton IDE pour qu''ils voient les nouveaux PATH / JAVA_HOME.'
Write-Host 'Docker Desktop : lance-le une fois à la main pour finir sa configuration.'
if ($failed.Count -gt 0) { exit 1 }
exit 0
