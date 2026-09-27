package fr.shoploc.fidelity.domain.model;

import java.util.UUID;

public record FidelityAccount(UUID cardNumber, Double coinAmount, Double moneyAmount) {
}
