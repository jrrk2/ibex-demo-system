// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Prevent Vivado from performing optimizations on/across this module.
// DONT_TOUCH removed for VC707 open-flow: lets flatten_hierarchy=full dissolve the wrapper (vector out port orphaned SVS flatten)
module prim_xilinx_buf #(
  parameter int Width = 1
) (
  input [Width-1:0] in_i,
  output logic [Width-1:0] out_o
);

  assign out_o = in_i;

endmodule
