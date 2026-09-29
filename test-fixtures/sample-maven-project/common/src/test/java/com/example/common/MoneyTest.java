package com.example.common;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class MoneyTest {
  @Test
  void addsSameCurrency() {
    Money sum =
        new Money(new BigDecimal("1.50"), "EUR").add(new Money(new BigDecimal("2.00"), "EUR"));
    assertEquals(new BigDecimal("3.50"), sum.amount());
  }

  @Test
  void rejectsCurrencyMismatch() {
    assertThrows(
        IllegalArgumentException.class,
        () -> new Money(BigDecimal.ONE, "EUR").add(new Money(BigDecimal.ONE, "USD")));
  }
}
