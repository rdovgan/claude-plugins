package com.example.api;

import com.example.orders.OrderService;

public class OrderController {
  private final OrderService service = new OrderService();

  public String ping() {
    return "ok " + service.total(java.util.List.of()).amount();
  }
}
