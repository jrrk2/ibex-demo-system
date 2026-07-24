// Testcases isolating the unpacked-vs-packed array syntaxes the SVS emitter
// must choose between, to verify what Vivado's RTL front-end (xvlog / synth
// -rtl) actually accepts.  Compile each module alone to see which pass:
//   xvlog -sv tc_unpacked_array.sv
// A module that fails names the illegal construct; a module that passes is a
// legal emission form the SVS can target.

// ---- 1. unpacked decl + per-slot writes (the bus/device_rdata shape) ----
module tc_unpacked_perslot (input logic clk, input logic [31:0] d, output logic [31:0] o [0:2]);
  always_comb begin
    o[0] = d;
    o[1] = d;
    o[2] = d;
  end
endmodule

// ---- 2. unpacked reset via bare '0 (what the SVS reset path emits) ----
module tc_unpacked_reset_bare (input logic clk, input logic rst_n, input logic [31:0] d [0:1], output logic [31:0] q [0:1]);
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) q = '0;
    else        q = d;
endmodule

// ---- 3. unpacked reset via '{default:'0} ----
module tc_unpacked_reset_pattern (input logic clk, input logic rst_n, input logic [31:0] d [0:1], output logic [31:0] q [0:1]);
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) q = '{default: '0};
    else        q = d;
endmodule

// ---- 4. unpacked reset via sized packed constant (the failing form) ----
module tc_unpacked_reset_sized (input logic clk, input logic rst_n, output logic [31:0] q [0:1]);
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) q = 64'd0;
    else        q = q;
endmodule

// ---- 5. unpacked whole-array procedural copy ----
module tc_unpacked_copy_proc (input logic [31:0] a [0:1], output logic [31:0] o [0:1]);
  always_comb o = a;
endmodule

// ---- 6. unpacked whole-array CONTINUOUS copy (suspect illegal) ----
module tc_unpacked_copy_cont (input logic [31:0] a [0:1], output logic [31:0] o [0:1]);
  assign o = a;
endmodule

// ---- 7. unpacked array passed whole as a submodule port ----
module tc_unpacked_port_sink (input logic [31:0] a [0:2], output logic [31:0] o);
  assign o = a[0] ^ a[1] ^ a[2];
endmodule
module tc_unpacked_port_top (input logic [31:0] a [0:2], output logic [31:0] o);
  tc_unpacked_port_sink u (.a(a), .o(o));
endmodule

// ---- 8. packed 2-D reset via sized constant (dm_csrs data shape — should pass) ----
module tc_packed2d_reset (input logic clk, input logic rst_n, output logic [1:0][31:0] q);
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) q = 64'd0;
    else        q = q;
endmodule
