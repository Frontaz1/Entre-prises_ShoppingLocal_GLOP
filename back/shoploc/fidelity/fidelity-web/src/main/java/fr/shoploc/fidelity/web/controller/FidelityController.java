package fr.shoploc.fidelity.web.controller;

import fr.shoploc.fidelity.domain.service.IFidelityService;
import fr.shoploc.fidelity.web.mapper.FidelityWebMapper;
import fr.shoploc.fidelity.web.payload.FidelityAccountPayload;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/fidelity")
public class FidelityController {
    @Autowired
    IFidelityService fidelityService;
    @Autowired
    FidelityWebMapper fidelityMapper;
    @GetMapping("/{accountId}")
    public ResponseEntity<FidelityAccountPayload> findFidelityAccount(@PathVariable UUID accountId){
        return ResponseEntity.ok(fidelityMapper.toFidelityPayload(fidelityService.getFidelityAccount(accountId)));
    }

    @PostMapping("/")
    public ResponseEntity<FidelityAccountPayload> createFidelityAccount(@RequestBody FidelityAccountPayload fidelityAccount){
        return ResponseEntity.ok(
                fidelityMapper.toFidelityPayload(
                    fidelityService.createFidelityAccount(
                            fidelityMapper.toFidelityAccount(fidelityAccount))
                )
        );
    }

}
