// Ethernet peripheral adapter: presents the lowRISC demo-bus device slave
// interface and wraps ethsoc's framing_top_sgmii (eth MAC + gig PCS/PMA SGMII).
//
// framing_top_sgmii is a 64-bit, single-cycle-latency register/buffer block on
// its `msoc_clk` side (ce_d asserted in cycle N with core_lsu_addr -> the
// combinational read decode, keyed on the registered ce_d_dly/addr_dly, has
// framing_rdata valid in cycle N+1).  The CPU<->MAC clock-domain crossing is
// internal to framing_top (dual-clock packet BRAMs), so `msoc_clk` here is just
// the 50 MHz ibex clk_sys.
//
// The demo bus is 32-bit; framing_top is 64-bit with addr[2] selecting the
// word half.  We reproduce the ethsoc 64<->32 shim byte-lane mapping.  Reads
// return one cycle after the request, which the (wait-state) bus tolerates.
//
// Offset 0x00000 is intercepted here as a read-only pcspma_status register
// (link/AN state), double-flopped into clk_sys.  Everything else passes to
// framing_top (registers at 0x0800, RPLR 0x0C00, TX buffer 0x1000, RX buffers
// 0x1_0000).

module eth_dev (
  input  logic        clk_i,          // 50 MHz ibex clk_sys (framing_top msoc_clk)
  input  logic        rst_ni,         // active-low system reset

  input  logic        clk_int_i,      // free-running fabric clock (IP independent_clock)
  input  logic        rst_int_i,      // active-high eth reset (into framing_top)

  // demo-bus device slave
  input  logic        device_req_i,
  input  logic [31:0] device_addr_i,
  input  logic        device_we_i,
  input  logic [ 3:0] device_be_i,
  input  logic [31:0] device_wdata_i,
  output logic        device_rvalid_o,
  output logic [31:0] device_rdata_o,

  output logic        eth_irq_o,

  // SGMII / GT / MDIO physical
  input  wire         sgmii_rxp,
  input  wire         sgmii_rxn,
  output wire         sgmii_txp,
  output wire         sgmii_txn,
  input  wire         sgmii_refclk_p,
  input  wire         sgmii_refclk_n,
  output wire         phy_reset_n,
  input  wire         phy_mdio_i,
  output wire         phy_mdio_o,
  output wire         phy_mdio_oe,
  output wire         phy_mdc
);

  localparam logic [16:0] STATUS_OFF = 17'h0_0000;  // pcspma status read

  // ---- request-phase decode ------------------------------------------------
  logic [16:0] addr17;
  assign addr17 = device_addr_i[16:0];

  logic status_sel;
  assign status_sel = device_req_i & (addr17 == STATUS_OFF) & ~device_we_i;

  logic eth_ce;                       // framing_top chip-enable (pass-through reqs)
  assign eth_ce = device_req_i & ~status_sel;

  // 64<->32: replicate the ethsoc shim byte-lane mapping (addr[2] = word half)
  logic [7:0]  eth_be;
  assign eth_be = device_we_i ? (device_addr_i[2] ? {device_be_i, 4'b0000}
                                                   : {4'b0000, device_be_i})
                              : 8'b0;

  wire [63:0] framing_rdata;

  // pcspma status CDC (eth domain -> clk_sys), declared before use
  wire  [15:0] pcspma_status_raw;
  logic [15:0] pcspma_status_s1, pcspma_status_sync;
  always_ff @(posedge clk_i) begin
    pcspma_status_s1   <= pcspma_status_raw;
    pcspma_status_sync <= pcspma_status_s1;
  end

  // ---- response phase (one cycle after req) --------------------------------
  logic        resp_valid_q;
  logic        resp_status_q;
  logic        resp_half_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      resp_valid_q  <= 1'b0;
      resp_status_q <= 1'b0;
      resp_half_q   <= 1'b0;
    end else begin
      resp_valid_q  <= device_req_i;
      resp_status_q <= status_sel;
      resp_half_q   <= device_addr_i[2];
    end
  end

  assign device_rvalid_o = resp_valid_q;
  assign device_rdata_o  = resp_status_q ? {16'b0, pcspma_status_sync}
                          : resp_half_q  ? framing_rdata[63:32]
                                         : framing_rdata[31:0];

  // ---- the ethsoc eth peripheral -------------------------------------------
  framing_top_sgmii eth (
    .msoc_clk       (clk_i),
    .core_lsu_addr  (addr17),
    .core_lsu_wdata ({device_wdata_i, device_wdata_i}),
    .core_lsu_be    (eth_be),
    .ce_d           (eth_ce),
    .we_d           (eth_ce & device_we_i),
    .framing_sel    (eth_ce),
    .framing_rdata  (framing_rdata),

    .clk_int        (clk_int_i),
    .rst_int        (rst_int_i),

    .sgmii_rxp      (sgmii_rxp),
    .sgmii_rxn      (sgmii_rxn),
    .sgmii_txp      (sgmii_txp),
    .sgmii_txn      (sgmii_txn),
    .sgmii_refclk_p (sgmii_refclk_p),
    .sgmii_refclk_n (sgmii_refclk_n),
    .phy_reset_n    (phy_reset_n),
    .phy_mdio_i     (phy_mdio_i),
    .phy_mdio_o     (phy_mdio_o),
    .phy_mdio_oe    (phy_mdio_oe),
    .phy_mdc        (phy_mdc),

    .eth_irq        (eth_irq_o),
    .pcspma_status_o(pcspma_status_raw),
    .eth_clk_o      (),
    .gtrefclk_bufg_o()
  );

endmodule
