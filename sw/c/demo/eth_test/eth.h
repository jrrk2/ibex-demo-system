// Ethernet peripheral (ethsoc framing_top_sgmii) as mapped onto the ibex bus
// by eth_dev.sv.  Base 0x8010_0000 (see ibex_demo_system.sv ETH_START).
#ifndef ETH_H_
#define ETH_H_

#include <stdint.h>

#define ETH_BASE 0x80100000u

// register offsets (relative to ETH_BASE)
#define PCSPMA_OFFSET  0x0000   // read-only: [0]=link up (double-flopped)
#define MACLO_OFFSET   0x0800   // mac[31:0]
#define MACHI_OFFSET   0x0808   // {irq_en,promisc,...,mac[47:32]}
#define TPLR_OFFSET    0x0810   // write=tx length (+send); read [31]=tx_busy
#define TFCS_OFFSET    0x0818
#define MDIOCTRL_OFFSET 0x0820
#define RFCS_OFFSET    0x0828   // write=lastbuf (# rx buffers)
#define RSR_OFFSET     0x0830   // write=firstbuf ack; read status/ring
#define RPLR_OFFSET    0x0C00   // per-buffer rx length (32 entries, 8B stride)
#define TXBUFF_OFFSET  0x1000
#define RXBUFF_OFFSET  0x10000  // 32 x 2KB rx buffers

#define TPLR_BUSY_MASK      0x80000000u
#define RSR_RECV_DONE_MASK  0x00008000u
#define RSR_RECV_FIRST_MASK 0x0000001Fu

static inline uint32_t eth_read(uint32_t off) {
  return *(volatile uint32_t *)(ETH_BASE + off);
}
static inline void eth_write(uint32_t off, uint32_t val) {
  *(volatile uint32_t *)(ETH_BASE + off) = val;
}
static inline int eth_link_up(void) { return eth_read(PCSPMA_OFFSET) & 1u; }

#endif  // ETH_H_
