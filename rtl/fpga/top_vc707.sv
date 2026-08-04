// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// VC707 top level for the Ibex Demo System.  RISC-V debug is reached
// through the FPGA's own JTAG chain (BSCANE2 via dmi_bscane_tap), so no
// extra pins are needed: the same Digilent USB-JTAG that configures the
// board talks to OpenOCD's riscv target.
module top_vc707 #(
  parameter SRAMInitFile = ""
) (
  // 200 MHz LVDS system clock
  input         IO_CLK_P,
  input         IO_CLK_N,
  // CPU_RESET push button, active high
  input         IO_RST,
  output [ 7:0] LED,
  input         UART_RX,
  output        UART_TX,

  // Ethernet: 1000BASE-X SGMII (GTX bank 117) + MDIO management
  input         sgmii_rxp,
  input         sgmii_rxn,
  output        sgmii_txp,
  output        sgmii_txn,
  input         sgmii_refclk_p,
  input         sgmii_refclk_n,
  output        eth_rst_n,
  output        eth_mdc,
  inout         eth_mdio
);

  logic clk_sys, rst_sys_n, locked;

  // MDIO bidirectional pad
  wire eth_mdio_i, eth_mdio_o, eth_mdio_oe;
  assign eth_mdio   = eth_mdio_oe ? eth_mdio_o : 1'bz;
  assign eth_mdio_i = eth_mdio;

  // -------------------------------------------------------------------
  // USER1 BSCAN observe-only (works on the open flow, unlike riscv-dbg).
  // Stop-on-load reverted: the CPU now runs from boot_addr at reset with no
  // cpu_go gating.  This probe is read-only telemetry -- shift out a 40-bit DR
  // over USER1 (IR 0x02) to sample {heartbeat, locked}; useful to confirm the
  // clock is live on silicon.
  //   capture DR: [7:0]=0xA5 [9:8]={0,locked} [39:16]=hb_clk
  // -------------------------------------------------------------------
  logic bs_sel, bs_capture, bs_shift, bs_update, bs_drck, bs_tdi;
  logic [39:0] bs_sr;
  BSCANE2 #(.JTAG_CHAIN(1)) u_probe_bscan (
    .CAPTURE(bs_capture), .DRCK(bs_drck), .RESET(), .RUNTEST(),
    .SEL(bs_sel), .SHIFT(bs_shift), .TCK(), .TDI(bs_tdi),
    .TDO(bs_sr[0]), .TMS(), .UPDATE(bs_update)
  );
  logic [24:0] hb_clk;
  always_ff @(posedge clk_sys) hb_clk <= hb_clk + 1'b1;
  logic [7:0] led_int;
  logic       uart_tx_int;
  // Stop-on-load reverted: no cpu_go gating -- the core runs unconditionally
  // from boot_addr at reset.  USER1 probe kept as observe-only (heartbeat +
  // locked) for silicon diagnostics.
  wire [7:0] probe_status = {7'b0, locked};
  always_ff @(posedge bs_drck) begin
    if (bs_sel && bs_capture)
      bs_sr <= {hb_clk[23:0], probe_status, 8'hA5};
    else if (bs_sel && bs_shift)
      bs_sr <= {bs_tdi, bs_sr[39:1]};
  end

  ibex_demo_system #(
    .GpiWidth     ( 8                     ),
    .GpoWidth     ( 8                     ),
    .PwmWidth     ( 1                     ),
    // Flip-flop register file instead of distributed-RAM (RegFileFPGA):
    // removes the RAMD32/DI1MUX mapping the open flow is least exercised on.
    .RegFile      ( ibex_pkg::RegFileFF   ),
    .SRAMInitFile ( SRAMInitFile          )
  ) u_ibex_demo_system (
    .clk_sys_i (clk_sys),
    // Core runs from boot_addr at reset (stop-on-load reverted); the whole SoC
    // incl. the debug module / JTAG DTM runs as soon as the clock locks.
    .rst_sys_ni(rst_sys_n),
    .gp_i      (8'h00),
    .uart_rx_i (UART_RX),

    .gp_o     (led_int),
    .pwm_o    (),
    .uart_tx_o(uart_tx_int),

    .spi_rx_i (1'b0),
    .spi_tx_o (),
    .spi_sck_o(),

    // Real TAP comes from BSCANE2 inside dmi_bscane_tap.
    // trst_ni MUST provide a real power-up reset to the tck/dmi_jtag domain:
    // tying it high left error_q/state_q/dr_q relying on GSR, which on silicon
    // did not reset them -> the DMI FSM never issued a request (data=0 blocker,
    // reproduced+fixed in the xsim baseline).  Drive it from the system reset.
    .trst_ni(rst_sys_n),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   (),

    // Ethernet peripheral.  clk_eth_int = clk_sys (free-running, GT-independent).
    .clk_eth_int_i  (clk_sys),
    .sgmii_rxp      (sgmii_rxp),
    .sgmii_rxn      (sgmii_rxn),
    .sgmii_txp      (sgmii_txp),
    .sgmii_txn      (sgmii_txn),
    .sgmii_refclk_p (sgmii_refclk_p),
    .sgmii_refclk_n (sgmii_refclk_n),
    .eth_phy_reset_n(eth_rst_n),
    .eth_mdio_i     (eth_mdio_i),
    .eth_mdio_o     (eth_mdio_o),
    .eth_mdio_oe    (eth_mdio_oe),
    .eth_mdc        (eth_mdc)
  );

  assign LED     = led_int;
  assign UART_TX = uart_tx_int;

  clkgen_vc707 clkgen (
    .IO_CLK_P,
    .IO_CLK_N,
    .IO_RST_N (~IO_RST),
    .clk_sys,
    .rst_sys_n,
    .locked
  );

endmodule
