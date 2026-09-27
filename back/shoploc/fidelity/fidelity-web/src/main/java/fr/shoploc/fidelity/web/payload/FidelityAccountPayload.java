package fr.shoploc.fidelity.web.payload;

import lombok.Data;
import tools.jackson.databind.annotation.JsonSerialize;

@JsonSerialize
@Data
public class FidelityAccountPayload {
    String cardId;
    double moneyAmount;
    double coinAmount;
}
