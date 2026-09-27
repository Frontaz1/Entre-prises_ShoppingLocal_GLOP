package fr.shoploc.fidelity.jpa.repository;

import fr.shoploc.fidelity.domain.model.FidelityAccount;
import fr.shoploc.fidelity.domain.service.IFidelityRepository;
import fr.shoploc.fidelity.jpa.mapper.FidelityJpaMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public class FidelityRepository implements IFidelityRepository {
    @Autowired
    FidelityCrudRepository fidelityCrudRepository;

    @Autowired
    FidelityJpaMapper fidelityMapper;

    @Override
    public Optional<FidelityAccount> getFidelityAccount(UUID accountId) {
        return fidelityCrudRepository.findById(accountId)
                .map(fidelityMapper::toFidelityAccount);
    }

    @Override
    public FidelityAccount createFidelityAccount(FidelityAccount fidelityAccount) {
        return fidelityMapper.toFidelityAccount(fidelityCrudRepository.save(fidelityMapper.toFidelityEntity(fidelityAccount)));
    }
}
