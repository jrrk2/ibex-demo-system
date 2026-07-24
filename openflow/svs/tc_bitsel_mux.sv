// Isolates the ibex_alu `shift_amt` multi-driver bug: a signal whose bits are
// driven by TWO separate processes — a CONTINUOUS bit-select assign on the top
// bit, and a PROCEDURAL always_comb on the lower bits.  The frontend must keep
// these as two partial drivers (`amt[5]` and `amt[4:0]`), NOT widen the
// continuous bit-select into a whole-signal `amt = {bit5, 0,0,0,0,0}` that
// zero-fills — and collides with — the [4:0] driver (Vivado multi-driven net,
// GND wins, the low bits read 0).
module tc_bitsel_mux (
  input  logic       funnel,
  input  logic       first,
  input  logic [5:0] b,
  input  logic [4:0] compl,
  output logic [5:0] amt
);
  // top bit: continuous bit-select assign
  assign amt[5] = b[5] & funnel;

  // low bits: procedural, separate process
  always_comb begin
    amt[4:0] = first ? b[4:0] : compl;
  end
endmodule
