package fr.shoploc.fidelity.jpa.mapper;

import fr.shoploc.fidelity.domain.model.FidelityAccount;
import fr.shoploc.fidelity.jpa.entity.FidelityAccountEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public abstract class FidelityJpaMapper {
    @Mapping(target="cardNumber",source = "id")
    @Mapping(target="coinAmount",source = "coinAmount")
    @Mapping(target="moneyAmount",source = "moneyAmount")
    public abstract FidelityAccount toFidelityAccount(FidelityAccountEntity accountEntity);
    @Mapping(target="id",source = "cardNumber")
    @Mapping(target="coinAmount",source = "coinAmount")
    @Mapping(target="moneyAmount",source = "moneyAmount")
    public abstract FidelityAccountEntity toFidelityEntity(FidelityAccount fidelityAccount);
}
