package fr.shoploc.fidelity.web.mapper;

import fr.shoploc.fidelity.domain.model.FidelityAccount;
import fr.shoploc.fidelity.web.payload.FidelityAccountPayload;
import java.util.UUID;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2026-09-28T00:02:28+0200",
    comments = "version: 1.6.3, compiler: javac, environment: Java 21.0.12.1 (Microsoft)"
)
@Component
public class FidelityWebMapperImpl extends FidelityWebMapper {

    @Override
    public FidelityAccountPayload toFidelityPayload(FidelityAccount accountEntity) {
        if ( accountEntity == null ) {
            return null;
        }

        FidelityAccountPayload fidelityAccountPayload = new FidelityAccountPayload();

        if ( accountEntity.cardNumber() != null ) {
            fidelityAccountPayload.setCardId( accountEntity.cardNumber().toString() );
        }
        if ( accountEntity.coinAmount() != null ) {
            fidelityAccountPayload.setCoinAmount( accountEntity.coinAmount() );
        }
        if ( accountEntity.moneyAmount() != null ) {
            fidelityAccountPayload.setMoneyAmount( accountEntity.moneyAmount() );
        }

        return fidelityAccountPayload;
    }

    @Override
    public FidelityAccount toFidelityAccount(FidelityAccountPayload accountEntity) {
        if ( accountEntity == null ) {
            return null;
        }

        UUID cardNumber = null;
        Double coinAmount = null;
        Double moneyAmount = null;

        if ( accountEntity.getCardId() != null ) {
            cardNumber = UUID.fromString( accountEntity.getCardId() );
        }
        coinAmount = accountEntity.getCoinAmount();
        moneyAmount = accountEntity.getMoneyAmount();

        FidelityAccount fidelityAccount = new FidelityAccount( cardNumber, coinAmount, moneyAmount );

        return fidelityAccount;
    }
}
