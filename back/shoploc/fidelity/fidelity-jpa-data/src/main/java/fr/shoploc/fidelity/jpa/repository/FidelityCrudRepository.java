package fr.shoploc.fidelity.jpa.repository;

import fr.shoploc.fidelity.jpa.entity.FidelityAccountEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;
@Repository
public interface FidelityCrudRepository extends JpaRepository<FidelityAccountEntity, UUID> {
}
