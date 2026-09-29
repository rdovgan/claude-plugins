package com.example.common;

import java.math.BigDecimal;

public record Money(BigDecimal amount, String currency) {
  public Money add(Money other) {
    if (!currency.equals(other.currency)) {
      throw new IllegalArgumentException("Currency mismatch");
    }
    return new Money(amount.add(other.amount), currency);
  }
}
