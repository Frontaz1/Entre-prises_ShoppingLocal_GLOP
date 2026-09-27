package fr.shoploc.fidelity.domain.service;

import fr.shoploc.fidelity.domain.model.FidelityAccount;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.UUID;
@Service
public class FidelityService implements IFidelityService{
    @Autowired
    IFidelityRepository fidelityRepository;

    public FidelityAccount getFidelityAccount(UUID accountId) {
        return fidelityRepository.getFidelityAccount(accountId).orElseThrow(()->new RuntimeException());
    }

    @Override
    public FidelityAccount createFidelityAccount(FidelityAccount fidelityAccount) {
        return fidelityRepository.createFidelityAccount(fidelityAccount);
    }
}
