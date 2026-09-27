package fr.shoploc.fidelity.web.mapper;

import fr.shoploc.fidelity.domain.model.FidelityAccount;
import fr.shoploc.fidelity.web.payload.FidelityAccountPayload;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public abstract  class FidelityWebMapper {
    @Mapping(target="cardId",source = "cardNumber")
    @Mapping(target="coinAmount",source = "coinAmount")
    @Mapping(target="moneyAmount",source = "moneyAmount")
    public abstract FidelityAccountPayload toFidelityPayload(FidelityAccount accountEntity);

    @Mapping(target="cardNumber",source = "cardId")
    @Mapping(target="coinAmount",source = "coinAmount")
    @Mapping(target="moneyAmount",source = "moneyAmount")
    public abstract FidelityAccount toFidelityAccount(FidelityAccountPayload accountEntity);
}
