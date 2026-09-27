package fr.shoploc.fidelity.jpa.mapper;

import fr.shoploc.fidelity.domain.model.FidelityAccount;
import fr.shoploc.fidelity.jpa.entity.FidelityAccountEntity;
import java.util.UUID;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2026-09-27T23:56:12+0200",
    comments = "version: 1.6.3, compiler: javac, environment: Java 21.0.12.1 (Microsoft)"
)
@Component
public class FidelityJpaMapperImpl extends FidelityJpaMapper {

    @Override
    public FidelityAccount toFidelityAccount(FidelityAccountEntity accountEntity) {
        if ( accountEntity == null ) {
            return null;
        }

        UUID cardNumber = null;
        Double coinAmount = null;
        Double moneyAmount = null;

        cardNumber = accountEntity.getId();
        coinAmount = accountEntity.getCoinAmount();
        moneyAmount = accountEntity.getMoneyAmount();

        FidelityAccount fidelityAccount = new FidelityAccount( cardNumber, coinAmount, moneyAmount );

        return fidelityAccount;
    }

    @Override
    public FidelityAccountEntity toFidelityEntity(FidelityAccount fidelityAccount) {
        if ( fidelityAccount == null ) {
            return null;
        }

        FidelityAccountEntity fidelityAccountEntity = new FidelityAccountEntity();

        fidelityAccountEntity.setId( fidelityAccount.cardNumber() );
        fidelityAccountEntity.setCoinAmount( fidelityAccount.coinAmount() );
        fidelityAccountEntity.setMoneyAmount( fidelityAccount.moneyAmount() );

        return fidelityAccountEntity;
    }
}
