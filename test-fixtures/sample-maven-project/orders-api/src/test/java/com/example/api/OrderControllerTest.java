package com.example.api;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class OrderControllerTest {
  @Test
  void pings() {
    assertEquals("ok 0", new OrderController().ping());
  }
}
