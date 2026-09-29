package com.example.orders;

import com.example.common.Money;
import java.math.BigDecimal;
import java.util.List;

public class OrderService {
  public Money total(List<Money> lines) {
    return lines.stream().reduce(new Money(BigDecimal.ZERO, "EUR"), Money::add);
  }
}
