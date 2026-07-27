// ibex mini-system firmware: 8-LED JOHNSON (twisted-ring) counter at ~5 Hz.
// Each step shifts left and feeds in the inverted MSB, giving the 16-state
// 0x00,0x01,0x03,0x07,0x0F,0x1F,0x3F,0x7F,0xFF,0xFE,0xFC,0xF8,0xF0,0xE0,0xC0,0x80.
#include <stdint.h>

#define GPIO_OUT (*(volatile uint32_t *)0x80000000u)
#define CLK_HZ    50000000u
#define TICK_HZ   5u              // 5 steps/sec so the pattern is visible

static inline uint32_t rd_mcycle(void) {
  uint32_t v; __asm__ volatile("csrr %0, mcycle" : "=r"(v)); return v;
}

int main(void) {
#ifndef PERIOD_CYCLES
#define PERIOD_CYCLES (CLK_HZ / TICK_HZ)
#endif
  const uint32_t period = PERIOD_CYCLES;
  uint32_t johnson = 0;
  uint32_t last = rd_mcycle();

  for (;;) {
    GPIO_OUT = johnson & 0xFFu;
    while ((uint32_t)(rd_mcycle() - last) < period) { }
    last += period;
    uint32_t msb = (johnson >> 7) & 1u;               // current MSB
    johnson = ((johnson << 1) | (msb ^ 1u)) & 0xFFu;  // shift in inverted MSB
  }
  return 0;
}
