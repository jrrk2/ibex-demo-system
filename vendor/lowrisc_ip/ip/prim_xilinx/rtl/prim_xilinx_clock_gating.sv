// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// VC707 open-flow variant: HARD PASS-THROUGH (no clock gating at all).
// Ibex uses this only for power-saving sleep gating; passing the clock
// through ungated keeps function identical (the core simply never stops
// its clock during WFI) while guaranteeing a single, ungated clock tree
// -- the only shape the open flow (nextpnr + prjxray) drives reliably.
// Relying on Vivado's -gated_clock_conversion was insufficient: a
// dont_touch on prim_xilinx_flop made it silently convert 0 gates,
// leaving 66 FFs on a LUT-gated fabric clock.  en_i/test_en_i ignored.
module prim_xilinx_clock_gating #(
  parameter bit NoFpgaGate    = 1'b0,
  parameter bit FpgaBufGlobal = 1'b1
) (
  input        clk_i,
  input        en_i,
  input        test_en_i,
  output logic clk_o
);
  assign clk_o = clk_i;
endmodule
