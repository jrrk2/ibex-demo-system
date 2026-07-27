// Cut-down ibex mini system firmware: count an 8-bit value on the 8 LEDs at
// 1 Hz.  Timebase is the RISC-V mcycle CSR (enabled by crt0 clearing
// mcountinhibit), so the period is exact for the 50 MHz system clock.
#include <stdint.h>

#define GPIO_OUT (*(volatile uint32_t *)0x80000000u)

// 1 second at 50 MHz.  Fits in 32 bits (< 2^32), so a single-word mcycle
// delta with unsigned wraparound is sufficient.
#define CLK_HZ    50000000u
#define TICK_HZ   1u

static inline uint32_t rd_mcycle(void) {
  uint32_t v;
  __asm__ volatile("csrr %0, mcycle" : "=r"(v));
  return v;
}

int main(void) {
  // PERIOD_CYCLES lets a simulation build shrink the 1 Hz tick (50 M cycles) to
  // something observable in xsim (e.g. -DPERIOD_CYCLES=200).
#ifndef PERIOD_CYCLES
#define PERIOD_CYCLES (CLK_HZ / TICK_HZ)
#endif
  const uint32_t period = PERIOD_CYCLES;
  uint32_t count = 0;
  uint32_t last  = rd_mcycle();

  for (;;) {
    GPIO_OUT = count & 0xFFu;                 // drive the 8 LEDs
    while ((uint32_t)(rd_mcycle() - last) < period) {
      // busy-wait one 1 Hz tick
    }
    last += period;
    count++;
  }
  return 0;
}
