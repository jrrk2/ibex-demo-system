// Netlist-agnostic conformance harness: drives clock + reset + JTAG-idle, and
// times out.  The PASS/FAIL `tohost` store is detected INSIDE the RAM leaf
// (which is our own module, present in every netlist regardless of how the
// tool renames internal instances) — see ram_leaf.v.in / prim_generic_ram_2p.v.
`timescale 1ns/1ps
module tb_ibex_mini;
  logic clk=0, rst_n=0, trst_n=0, tms=1'b1; logic [7:0] gp_o;
  always #10 clk=~clk;
  ibex_mini_system dut (.clk_sys_i(clk), .rst_sys_ni(rst_n), .gp_i(8'h00), .gp_o(gp_o),
    .tck_i(1'b0), .tms_i(tms), .trst_ni(trst_n), .td_i(1'b0), .td_o());
  // Start reset DEASSERTED, then pulse it low: the vendor RTL uses async
  // (negedge rst_ni) resets, so a falling edge is required for Verilator to fire
  // the reset branch — starting at 0 (no edge) leaves async-reset FFs (e.g.
  // priv_lvl_q) at Verilator's 0 init => U-mode => csrw mtvec traps.  The SVS
  // netlists (behav/hardcaml/mapped) use sync reset so they don't need this.
  initial begin
    rst_n=1'b1; trst_n=1'b1; tms=1'b1;
    #5  rst_n=1'b0; trst_n=1'b0;          // falling edge -> assert async resets
    #203 trst_n=1'b1;
    #100 tms=1'b0; rst_n=1'b1;            // release
  end
  initial begin #60000000; $display("TIMEOUT"); $finish; end
endmodule
