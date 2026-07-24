// Narrow the SVS param-override evaluation bug.
package idp;
  localparam logic [10:0] MFG = {4'd12, 7'b110_1111};               // 0x66F
  localparam logic [31:0] IDC = {4'h1, {12'h100, 4'h1}, MFG, 1'b1}; // 0x11001cdf
  localparam logic [31:0] FLAT = 32'h11001cdf;                      // plain literal in pkg
endpackage

module tc_pc_child #(
  parameter logic [31:0] P = 32'h00000001
) (
  output logic [31:0] o
);
  assign o = P;
endmodule

module tc_param_concat (
  output logic [31:0] o1, o2, o3, o4, o5
);
  tc_pc_child #(.P(32'h11001cdf))                       u1 (.o(o1)); // literal
  tc_pc_child #(.P(idp::FLAT))                          u2 (.o(o2)); // pkg literal
  tc_pc_child #(.P({4'h1, 28'h1001cdf}))                u3 (.o(o3)); // inline concat
  tc_pc_child #(.P(idp::MFG))                           u4 (.o(o4)); // pkg simple concat -> 0x66F
  tc_pc_child #(.P(idp::IDC))                           u5 (.o(o5)); // pkg NESTED concat (the bug)
endmodule
