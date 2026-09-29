package com.example.orders;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.example.common.Money;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

class OrderServiceTest {
  @Test
  void sumsLines() {
    Money total =
        new OrderService()
            .total(List.of(new Money(BigDecimal.ONE, "EUR"), new Money(BigDecimal.TEN, "EUR")));
    assertEquals(new BigDecimal("11"), total.amount());
  }
}
