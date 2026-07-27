// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// VC707 top level for the cut-down Ibex mini system: 200 MHz LVDS -> 50 MHz,
// 8 LEDs, and RISC-V debug over the FPGA's own JTAG chain (BSCANE2 inside the
// pulp dmi_jtag, same as top_vc707), so no extra pins are needed.  This is the
// minimal design used to isolate residual SVS frontend bugs -- see
// ibex_mini_system.  Same physical pins as data/pins_vc707.xdc (clock/reset/LED
// only); UART, SPI and Ethernet are gone.
module top_vc707_mini #(
  parameter SRAMInitFile = ""
) (
  input         IO_CLK_P,   // 200 MHz LVDS system clock
  input         IO_CLK_N,
  input         IO_RST,     // CPU_RESET push button, active high
  output [ 7:0] LED
);

  logic clk_sys, rst_sys_n, locked;
  logic [7:0] led_int;

  ibex_mini_system #(
    .GpiWidth     ( 8                   ),
    .GpoWidth     ( 8                   ),
    // Flip-flop register file (RegFileFF) rather than distributed-RAM: keeps the
    // mapping in the well-exercised FF path for this bug-isolation vehicle.
    .RegFile      ( ibex_pkg::RegFileFF ),
    .SRAMInitFile ( SRAMInitFile        )
  ) u_ibex_mini_system (
    .clk_sys_i (clk_sys),
    .rst_sys_ni(rst_sys_n),

    .gp_i      (8'h00),
    .gp_o      (led_int),

    // Real TAP is the BSCANE2 chain inside pulp dmi_jtag.  trst_ni must carry a
    // real power-up reset to the tck/dmi domain (tying it high left the DMI FSM
    // relying on GSR, which did not reset on silicon -> data=0), so drive it
    // from the system reset.
    .trst_ni(rst_sys_n),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   ()
  );

  assign LED = led_int;

  clkgen_vc707 clkgen (
    .IO_CLK_P,
    .IO_CLK_N,
    .IO_RST_N (~IO_RST),
    .clk_sys,
    .rst_sys_n,
    .locked
  );

endmodule
