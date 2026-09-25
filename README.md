# Entre-prises_ShoppingLocal_GLOP

## Installer son environnement de dev (Windows)

Un script vérifie et installe les outils du projet : **Git, JDK 21, Node.js 24, WSL 2, Docker Desktop**.
Les versions attendues sont définies dans [`tools/versions.json`](tools/versions.json). Pour changer une version, on modifie ce fichier via une PR.

**1. Vérifier sans rien installer** (PowerShell normal, depuis la racine du repo) :

```powershell
powershell -ExecutionPolicy Bypass -File tools\setup\setup-windows.ps1 -CheckOnly
```

**2. Installer / mettre à jour ce qui manque** (PowerShell lancé **en tant qu'administrateur**) :

```powershell
powershell -ExecutionPolicy Bypass -File tools\setup\setup-windows.ps1
```

Le script affiche d'abord un diagnostic, puis demande **une seule confirmation** avant de toucher à quoi que ce soit. Il ne désinstalle jamais rien. On peut le relancer sans risque : un poste déjà conforme n'est pas modifié.

Pas besoin d'installer :
- **Maven** : le repo embarque le Maven Wrapper (`mvnw`).
- **PostgreSQL et SonarQube** : ils tournent dans Docker.
- **Les navigateurs Playwright** : `npx playwright install`.
