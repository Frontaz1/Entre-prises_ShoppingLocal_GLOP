package fr.shoploc.fidelity.domain.service;

import fr.shoploc.fidelity.domain.model.FidelityAccount;

import java.util.UUID;

public interface IFidelityService {
    FidelityAccount getFidelityAccount(UUID accountId);
    FidelityAccount createFidelityAccount(FidelityAccount fidelityAccount);
}
