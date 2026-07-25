// Dual-VCD testbench: drive ibex_mini_system (via mini_wrap.sv) with a plain
// 50 MHz clock + JTAG-to-TLR reset, dump the whole DUT to VCD.  Used to run the
// GATE-mapped netlist and the BEHAVIORAL netlist under identical stimulus and
// diff the two VCDs for the first divergence (localises gate_map lowering bugs
// without the Z3 miter's interface-vacuity).  VCD path via +VCD=<file>.
`timescale 1ns/1ps
module tb_ibex_mini;
  logic clk=0, rst_n=0, tck=0, trst_n=0, tms=1'b1;
  logic [7:0] gp_o, prev=8'hxx;
  integer ticks=0;
  string vcd;

  always #10 clk = ~clk;   // 50 MHz
  always #7  tck = ~tck;

  ibex_mini_system dut (
    .clk_sys_i(clk), .rst_sys_ni(rst_n), .gp_i(8'h00), .gp_o(gp_o),
    .tck_i(tck), .tms_i(tms), .trst_ni(trst_n), .td_i(1'b0), .td_o());

  initial begin
    if (!$value$plusargs("VCD=%s", vcd)) vcd = "mini.vcd";
    $dumpfile(vcd);
    $dumpvars(0, tb_ibex_mini.dut);
  end

  initial begin
    rst_n=0; trst_n=0; tms=1'b1;
    #203; trst_n=1'b1;            // release TAP reset (TLR), keep tms=1
    #100; tms=1'b0;              // to Run-Test-Idle
    rst_n=1'b1;                  // release core reset
    $display("[tb] reset released @ %0t", $time);
  end

  always @(gp_o) if (rst_n===1'b1 && gp_o!==prev) begin
    $display("[tb] t=%0t LED=0x%02x", $time, gp_o); prev=gp_o; ticks=ticks+1;
    if (ticks>=10) begin $display("[tb] PASS %0d LED-ticks", ticks); $finish; end
  end

  // run long enough for johnson's first LED transitions; the 1 Hz-ish divider
  // is small in the mini SoC, so a few hundred us shows several ticks.
  initial begin #2000000; $display("[tb] TIMEOUT ticks=%0d LED=0x%02x", ticks, gp_o); $finish; end
endmodule
