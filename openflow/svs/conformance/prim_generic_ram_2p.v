// Conformance-sim replacement for vendor prim_generic_ram_2p: identical
// interface (imports prim_ram_2p_pkg for ram_2p_cfg_t) but loads the program
// per-test from the +VMEM plusarg instead of the compile-time MemInitFile
// param, so the RTL sim is built ONCE and each test is loaded at run time.
module prim_generic_ram_2p import prim_ram_2p_pkg::*; #(
  parameter  int Width           = 32,
  parameter  int Depth           = 128,
  parameter  int DataBitsPerMask = 1,
  parameter      MemInitFile     = "",
  localparam int Aw              = $clog2(Depth)
) (
  input clk_a_i,
  input clk_b_i,
  input                    a_req_i,
  input                    a_write_i,
  input        [Aw-1:0]    a_addr_i,
  input        [Width-1:0] a_wdata_i,
  input  logic [Width-1:0] a_wmask_i,
  output logic [Width-1:0] a_rdata_o,
  input                    b_req_i,
  input                    b_write_i,
  input        [Aw-1:0]    b_addr_i,
  input        [Width-1:0] b_wdata_i,
  input  logic [Width-1:0] b_wmask_i,
  output logic [Width-1:0] b_rdata_o,
  input ram_2p_cfg_t       cfg_i
);
  logic [Width-1:0] mem [0:Depth-1];
  integer i; reg [8191:0] vmempath;
  reg [31:0] tohost = 32'h00100100;
  initial begin
    for (i = 0; i < Depth; i = i + 1) mem[i] = '0;
    if ($value$plusargs("VMEM=%s", vmempath)) $readmemh(vmempath, mem);
    void'($value$plusargs("TOHOST=%h", tohost));
  end
  always_ff @(posedge clk_a_i) if (a_req_i) begin
    if (a_write_i && a_addr_i == tohost[Aw+1:2]) begin
      $display("TOHOST %08x", a_wdata_i); $finish;
    end
    if (a_write_i) mem[a_addr_i] <= (mem[a_addr_i] & ~a_wmask_i) | (a_wdata_i & a_wmask_i);
    a_rdata_o <= mem[a_addr_i];
  end
  always_ff @(posedge clk_b_i) if (b_req_i) begin
    if (b_write_i) mem[b_addr_i] <= (mem[b_addr_i] & ~b_wmask_i) | (b_wdata_i & b_wmask_i);
    b_rdata_o <= mem[b_addr_i];
  end
endmodule
