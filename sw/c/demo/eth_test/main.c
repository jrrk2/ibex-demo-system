// Ethernet bring-up / wedge-repro test for the merged ibex+eth SoC.
// Ported from ethsoc/firmware.c onto the ibex demo-system drivers (real UART +
// LEDs available).  Purpose: exercise the eth peripheral over the ibex bus so
// the eth-TX wedge can be single-stepped over JTAG DMI.
//
// LED trace: LEDs = (pkts<<4)|stage, so a freeze shows exactly where.
// UART: human-readable progress on the demo console.

#include <stdbool.h>
#include <stdint.h>

#include "demo_system.h"
#include "gpio.h"
#include "eth.h"

static const uint8_t my_mac[6] = {0x02, 0x00, 0x00, 0x4d, 0x47, 0x31}; // "MG1"
static const uint8_t my_ip[4]  = {192, 168, 1, 42};

static uint32_t trace_pkts;
static void leds(uint32_t stage) { set_outputs(GPIO_OUT, (trace_pkts << 4) | stage); }

static void eth_init(void) {
  uint32_t lo = ((uint32_t)my_mac[2] << 24) | ((uint32_t)my_mac[3] << 16) |
                ((uint32_t)my_mac[4] << 8)  |  (uint32_t)my_mac[5];
  uint32_t hi = ((uint32_t)my_mac[0] << 8)  |  (uint32_t)my_mac[1];
  eth_write(MACLO_OFFSET, lo);
  eth_write(MACHI_OFFSET, hi);
  eth_write(RFCS_OFFSET, 31);      // use all 32 rx buffers
}

static int eth_tx_busy(void) { return eth_read(TPLR_OFFSET) & TPLR_BUSY_MASK; }

static void eth_send(const uint8_t *data, int len) {
  leds(3);                          // 3 = waiting for tx idle  (WEDGE POINT)
  while (eth_tx_busy()) ;
  leds(4);                          // 4 = copying to tx buffer
  int words = (len + 3) >> 2;
  for (int i = 0; i < words; i++) {
    uint32_t w = (uint32_t)data[(i << 2) + 0] |
                 ((uint32_t)data[(i << 2) + 1] << 8) |
                 ((uint32_t)data[(i << 2) + 2] << 16) |
                 ((uint32_t)data[(i << 2) + 3] << 24);
    eth_write(TXBUFF_OFFSET + (i << 2), w);
  }
  leds(5);                          // 5 = trigger send
  eth_write(TPLR_OFFSET, len);
  leds(6);
}

static uint8_t pkt[1536];
static uint8_t out[1536];

static int eth_recv(uint8_t *buf, int maxlen) {
  uint32_t rsr = eth_read(RSR_OFFSET);
  if (!(rsr & RSR_RECV_DONE_MASK)) return 0;
  uint32_t b = rsr & RSR_RECV_FIRST_MASK;
  int len = (int)eth_read(RPLR_OFFSET + (b << 3)) - 4;   // strip FCS
  if (len > 0) {
    int n = len < maxlen ? len : maxlen;
    uint32_t base = RXBUFF_OFFSET + (b << 11);
    for (int i = 0; i < n; i += 4) {
      uint32_t w = eth_read(base + i);
      buf[i] = w;
      if (i + 1 < n) buf[i + 1] = w >> 8;
      if (i + 2 < n) buf[i + 2] = w >> 16;
      if (i + 3 < n) buf[i + 3] = w >> 24;
    }
  }
  eth_write(RSR_OFFSET, b + 1);     // acknowledge
  return len;
}

static int ip_match(const uint8_t *p) {
  return p[0]==my_ip[0] && p[1]==my_ip[1] && p[2]==my_ip[2] && p[3]==my_ip[3];
}

static uint32_t csum_add(uint32_t s, const uint8_t *p, int n) {
  for (int i = 0; i + 1 < n; i += 2) s += ((uint32_t)p[i] << 8) | p[i + 1];
  if (n & 1) s += (uint32_t)p[n - 1] << 8;
  return s;
}
static uint16_t csum_fin(uint32_t s) {
  while (s >> 16) s = (s & 0xFFFF) + (s >> 16);
  return ~s & 0xFFFF;
}

static void handle_icmp(int len) {
  int ihl = (pkt[14] & 0xF) << 2;
  if (pkt[23] != 1) return;               // not ICMP
  if (!ip_match(pkt + 30)) return;        // not for us
  if (pkt[14 + ihl] != 8) return;         // not echo request
  int iplen = ((int)pkt[16] << 8) | pkt[17];
  int n = 14 + iplen;
  if (n > len) n = len;
  for (int i = 0; i < n; i++) out[i] = pkt[i];
  for (int i = 0; i < 6; i++) { out[i] = pkt[6 + i]; out[6 + i] = my_mac[i]; }
  for (int i = 0; i < 4; i++) { out[26 + i] = pkt[30 + i]; out[30 + i] = pkt[26 + i]; }
  out[14 + ihl] = 0;                      // echo reply type
  out[14 + ihl + 2] = 0; out[14 + ihl + 3] = 0;
  uint16_t c = csum_fin(csum_add(0, out + 14 + ihl, iplen - ihl));
  out[14 + ihl + 2] = c >> 8; out[14 + ihl + 3] = c;
  eth_send(out, n < 60 ? 60 : n);
  puts(" -> echo reply");
}

static void handle_arp(int len) {
  if (len < 42 || pkt[20] != 0 || pkt[21] != 1) return;
  if (!ip_match(pkt + 38)) return;
  for (int i = 0; i < 6; i++) { out[i] = pkt[6 + i]; out[6 + i] = my_mac[i]; }
  out[12] = 0x08; out[13] = 0x06;
  out[14] = 0; out[15] = 1; out[16] = 8; out[17] = 0;
  out[18] = 6; out[19] = 4; out[20] = 0; out[21] = 2;
  for (int i = 0; i < 6; i++) out[22 + i] = my_mac[i];
  for (int i = 0; i < 4; i++) out[28 + i] = my_ip[i];
  for (int i = 0; i < 10; i++) out[32 + i] = pkt[22 + i];
  eth_send(out, 42);
  puts(" -> arp reply");
}

int main(void) {
  leds(1);
  puts("ibex+eth bring-up");
  eth_init();
  leds(2);

  uint32_t last_link = 0xFFFFFFFFu;
  for (;;) {
    uint32_t link = eth_link_up();
    if (link != last_link) {
      puts(link ? "link up" : "link down");
      last_link = link;
    }
    int len = eth_recv(pkt, sizeof(pkt));
    if (len <= 0) continue;
    trace_pkts++;
    leds(2);
    if (pkt[12] == 0x08 && pkt[13] == 0x06) handle_arp(len);
    if (pkt[12] == 0x08 && pkt[13] == 0x00) handle_icmp(len);
  }
  return 0;
}
