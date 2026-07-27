// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Cut-down Ibex "mini" system: the smallest SoC that still exercises the
// interesting SVS frontend paths (core + RISC-V debug module + a BRAM +
// GPIO/LEDs on the lowRISC bus).  Everything not needed to blink the LEDs
// from a program under debug control has been stripped relative to
// ibex_demo_system: no UART, SPI, PWM, timer, Ethernet or sim-ctrl.  Any
// residual verible-frontend bug is therefore isolated to a handful of
// modules and shows up directly as the 8 LEDs failing to count.
//
//   Hosts  : CoreD (core data), DbgHost (debug SBA)
//   Devices: Ram (code+data), Gpio (LEDs), DbgDev (debug ROM/CSR)
module ibex_mini_system #(
  parameter int                 GpiWidth       = 8,
  parameter int                 GpoWidth       = 8,
  parameter int unsigned        ClockFrequency = 50_000_000,
  parameter ibex_pkg::regfile_e RegFile        = ibex_pkg::RegFileFF,
  parameter                     SRAMInitFile   = ""
) (
  input  logic clk_sys_i,
  input  logic rst_sys_ni,

  input  logic [GpiWidth-1:0] gp_i,
  output logic [GpoWidth-1:0] gp_o,

  input  logic tck_i,    // JTAG test clock pad
  input  logic tms_i,    // JTAG test mode select pad
  input  logic trst_ni,  // JTAG test reset pad
  input  logic td_i,     // JTAG test data input pad
  output logic td_o      // JTAG test data output pad
);
  localparam logic [31:0] MEM_SIZE    = 16 * 1024; // 16 KiB
  localparam logic [31:0] MEM_START   = 32'h00100000;
  localparam logic [31:0] MEM_MASK    = ~(MEM_SIZE-1);

  localparam logic [31:0] GPIO_SIZE   =  4 * 1024; //  4 KiB
  localparam logic [31:0] GPIO_START  = 32'h80000000;
  localparam logic [31:0] GPIO_MASK   = ~(GPIO_SIZE-1);

  localparam logic [31:0] DEBUG_SIZE  = 64 * 1024; // 64 KiB
  localparam logic [31:0] DEBUG_START = 32'h1a110000;
  localparam logic [31:0] DEBUG_MASK  = ~(DEBUG_SIZE-1);

  typedef enum int {
    CoreD,
    DbgHost
  } bus_host_e;

  typedef enum int {
    Ram,
    Gpio,
    DbgDev
  } bus_device_e;

  localparam int NrDevices = 3;
  localparam int NrHosts   = 2;

  localparam int unsigned DbgHwBreakNum = 2;
  localparam bit          DbgTriggerEn  = 1'b1;

  // Host signals.
  logic        host_req      [NrHosts];
  logic        host_gnt      [NrHosts];
  logic [31:0] host_addr     [NrHosts];
  logic        host_we       [NrHosts];
  logic [ 3:0] host_be       [NrHosts];
  logic [31:0] host_wdata    [NrHosts];
  logic        host_rvalid   [NrHosts];
  logic [31:0] host_rdata    [NrHosts];
  logic        host_err      [NrHosts];

  // Device signals.
  logic        device_req    [NrDevices];
  logic [31:0] device_addr   [NrDevices];
  logic        device_we     [NrDevices];
  logic [ 3:0] device_be     [NrDevices];
  logic [31:0] device_wdata  [NrDevices];
  logic        device_rvalid [NrDevices];
  logic [31:0] device_rdata  [NrDevices];
  logic        device_err    [NrDevices];

  // Instruction fetch signals.
  logic        core_instr_req;
  logic        core_instr_gnt;
  logic        core_instr_rvalid;
  logic [31:0] core_instr_addr;
  logic [31:0] core_instr_rdata;
  logic        core_instr_sel_dbg;

  logic        mem_instr_req;
  logic [31:0] mem_instr_rdata;
  logic        dbg_instr_req;

  logic        dbg_device_req;
  logic [31:0] dbg_device_addr;
  logic        dbg_device_we;
  logic [ 3:0] dbg_device_be;
  logic [31:0] dbg_device_wdata;
  logic        dbg_device_rvalid;
  logic [31:0] dbg_device_rdata;

  /* verilator lint_off IMPERFECTSCH */
  logic rst_core_n;
  logic ndmreset_req;
  logic dm_debug_req;

  // Device address mapping.
  logic [31:0] cfg_device_addr_base [NrDevices];
  logic [31:0] cfg_device_addr_mask [NrDevices];

  assign cfg_device_addr_base[Ram]    = MEM_START;
  assign cfg_device_addr_mask[Ram]    = MEM_MASK;
  assign cfg_device_addr_base[Gpio]   = GPIO_START;
  assign cfg_device_addr_mask[Gpio]   = GPIO_MASK;
  assign cfg_device_addr_base[DbgDev] = DEBUG_START;
  assign cfg_device_addr_mask[DbgDev] = DEBUG_MASK;

  // Tie-off unused error signals.
  assign device_err[Ram]    = 1'b0;
  assign device_err[Gpio]   = 1'b0;
  assign device_err[DbgDev] = 1'b0;

  bus #(
    .NrDevices    ( NrDevices ),
    .NrHosts      ( NrHosts   ),
    .DataWidth    ( 32        ),
    .AddressWidth ( 32        )
  ) u_bus (
    .clk_i (clk_sys_i),
    .rst_ni(rst_sys_ni),

    .host_req_i   (host_req     ),
    .host_gnt_o   (host_gnt     ),
    .host_addr_i  (host_addr    ),
    .host_we_i    (host_we      ),
    .host_be_i    (host_be      ),
    .host_wdata_i (host_wdata   ),
    .host_rvalid_o(host_rvalid  ),
    .host_rdata_o (host_rdata   ),
    .host_err_o   (host_err     ),

    .device_req_o   (device_req   ),
    .device_addr_o  (device_addr  ),
    .device_we_o    (device_we    ),
    .device_be_o    (device_be    ),
    .device_wdata_o (device_wdata ),
    .device_rvalid_i(device_rvalid),
    .device_rdata_i (device_rdata ),
    .device_err_i   (device_err   ),

    .cfg_device_addr_base,
    .cfg_device_addr_mask
  );

  assign mem_instr_req =
      core_instr_req & ((core_instr_addr & cfg_device_addr_mask[Ram]) == cfg_device_addr_base[Ram]);

  assign dbg_instr_req =
      core_instr_req & ((core_instr_addr & cfg_device_addr_mask[DbgDev]) == cfg_device_addr_base[DbgDev]);

  assign core_instr_gnt = mem_instr_req | (dbg_instr_req & ~device_req[DbgDev]);

  always @(posedge clk_sys_i or negedge rst_sys_ni) begin
    if (!rst_sys_ni) begin
      core_instr_rvalid  <= 1'b0;
      core_instr_sel_dbg <= 1'b0;
    end else begin
      core_instr_rvalid  <= core_instr_gnt;
      core_instr_sel_dbg <= dbg_instr_req;
    end
  end

  assign core_instr_rdata = core_instr_sel_dbg ? dbg_device_rdata : mem_instr_rdata;

  assign rst_core_n = rst_sys_ni & ~ndmreset_req;

  ibex_top #(
    .RegFile         ( RegFile                                 ),
    .MHPMCounterNum  ( 0                                       ),
    .RV32M           ( ibex_pkg::RV32MFast                     ),
    .RV32B           ( ibex_pkg::RV32BNone                     ),
    .DbgTriggerEn    ( DbgTriggerEn                            ),
    .DbgHwBreakNum   ( DbgHwBreakNum                           ),
    .DmHaltAddr      ( DEBUG_START + dm::HaltAddress[31:0]     ),
    .DmExceptionAddr ( DEBUG_START + dm::ExceptionAddress[31:0])
  ) u_top (
    .clk_i (clk_sys_i),
    .rst_ni(rst_core_n),

    .test_en_i  ('b0),
    .scan_rst_ni(1'b1),
    .ram_cfg_i  ('b0),

    .hart_id_i  (32'b0),
    .boot_addr_i(MEM_START),  // reset vector = boot_addr + 0x80

    .instr_req_o       (core_instr_req),
    .instr_gnt_i       (core_instr_gnt),
    .instr_rvalid_i    (core_instr_rvalid),
    .instr_addr_o      (core_instr_addr),
    .instr_rdata_i     (core_instr_rdata),
    .instr_rdata_intg_i('0),
    .instr_err_i       ('0),

    .data_req_o       (host_req[CoreD]),
    .data_gnt_i       (host_gnt[CoreD]),
    .data_rvalid_i    (host_rvalid[CoreD]),
    .data_we_o        (host_we[CoreD]),
    .data_be_o        (host_be[CoreD]),
    .data_addr_o      (host_addr[CoreD]),
    .data_wdata_o     (host_wdata[CoreD]),
    .data_wdata_intg_o(),
    .data_rdata_i     (host_rdata[CoreD]),
    .data_rdata_intg_i('0),
    .data_err_i       (host_err[CoreD]),

    .irq_software_i(1'b0),
    .irq_timer_i   (1'b0),
    .irq_external_i(1'b0),
    .irq_fast_i    (15'b0),
    .irq_nm_i      (1'b0),

    .scramble_key_valid_i('0),
    .scramble_key_i      ('0),
    .scramble_nonce_i    ('0),
    .scramble_req_o      (),

    .debug_req_i        (dm_debug_req),
    .crash_dump_o       (),
    .double_fault_seen_o(),

    .fetch_enable_i        (ibex_pkg::IbexMuBiOn),
    .alert_minor_o         (),
    .alert_major_internal_o(),
    .alert_major_bus_o     (),
    .core_sleep_o          ()
  );

  ram_2p #(
      .Depth       ( MEM_SIZE / 4 ),
      .MemInitFile ( SRAMInitFile )
  ) u_ram (
    .clk_i (clk_sys_i),
    .rst_ni(rst_sys_ni),

    .a_req_i   (device_req[Ram]),
    .a_we_i    (device_we[Ram]),
    .a_be_i    (device_be[Ram]),
    .a_addr_i  (device_addr[Ram]),
    .a_wdata_i (device_wdata[Ram]),
    .a_rvalid_o(device_rvalid[Ram]),
    .a_rdata_o (device_rdata[Ram]),

    .b_req_i   (mem_instr_req),
    .b_we_i    (1'b0),
    .b_be_i    (4'b0),
    .b_addr_i  (core_instr_addr),
    .b_wdata_i (32'b0),
    .b_rvalid_o(),
    .b_rdata_o (mem_instr_rdata)
  );

  gpio #(
    .GpiWidth ( GpiWidth ),
    .GpoWidth ( GpoWidth )
  ) u_gpio (
    .clk_i (clk_sys_i),
    .rst_ni(rst_sys_ni),

    .device_req_i   (device_req[Gpio]),
    .device_addr_i  (device_addr[Gpio]),
    .device_we_i    (device_we[Gpio]),
    .device_be_i    (device_be[Gpio]),
    .device_wdata_i (device_wdata[Gpio]),
    .device_rvalid_o(device_rvalid[Gpio]),
    .device_rdata_o (device_rdata[Gpio]),

    .gp_i,
    .gp_o
  );

  assign dbg_device_req        = device_req[DbgDev] | dbg_instr_req;
  assign dbg_device_we         = device_req[DbgDev] & device_we[DbgDev];
  assign dbg_device_addr       = device_req[DbgDev] ? device_addr[DbgDev] : core_instr_addr;
  assign dbg_device_be         = device_be[DbgDev];
  assign dbg_device_wdata      = device_wdata[DbgDev];
  assign device_rvalid[DbgDev] = dbg_device_rvalid;
  assign device_rdata[DbgDev]  = dbg_device_rdata;

  always @(posedge clk_sys_i or negedge rst_sys_ni) begin
    if (!rst_sys_ni) begin
      dbg_device_rvalid <= 1'b0;
    end else begin
      dbg_device_rvalid <= device_req[DbgDev];
    end
  end

  dm_top #(
    .NrHarts      ( 1                              ),
    .IdcodeValue  ( jtag_id_pkg::RV_DM_JTAG_IDCODE )
  ) u_dm_top (
    .clk_i        (clk_sys_i),
    .rst_ni       (rst_sys_ni),
    .testmode_i   (1'b0),
    .ndmreset_o   (ndmreset_req),
    .dmactive_o   (),
    .debug_req_o  (dm_debug_req),
    .unavailable_i(1'b0),

    .device_req_i  (dbg_device_req),
    .device_we_i   (dbg_device_we),
    .device_addr_i (dbg_device_addr),
    .device_be_i   (dbg_device_be),
    .device_wdata_i(dbg_device_wdata),
    .device_rdata_o(dbg_device_rdata),

    .host_req_o    (host_req[DbgHost]),
    .host_add_o    (host_addr[DbgHost]),
    .host_we_o     (host_we[DbgHost]),
    .host_wdata_o  (host_wdata[DbgHost]),
    .host_be_o     (host_be[DbgHost]),
    .host_gnt_i    (host_gnt[DbgHost]),
    .host_r_valid_i(host_rvalid[DbgHost]),
    .host_r_rdata_i(host_rdata[DbgHost]),

    .tck_i,
    .tms_i,
    .trst_ni,
    .td_i,
    .td_o
  );

endmodule
