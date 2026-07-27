// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Simplistic Ibex bus implementation
 *
 * This module is designed for demo and simulation purposes, do not use it in
 * a real-world system.
 *
 * This implementation doesn't handle the full bus protocol, but makes the
 * following simplifying assumptions.
 *
 * - A single outstanding transaction at a time (new requests are held off,
 *   via gnt, until the current one responds).
 * - Devices (slaves) may take an arbitrary number of cycles to respond: the
 *   bus holds the response steering until device_rvalid_i is seen.  A device
 *   that responds in the cycle after its request (the classic case) behaves
 *   exactly as before, with no throughput penalty.
 * - Host (master) arbitration is strictly priority based.
 */
module bus #(
  parameter int NrDevices    = 1,
  parameter int NrHosts      = 1,
  parameter int DataWidth    = 32,
  parameter int AddressWidth = 32
) (
  input                           clk_i,
  input                           rst_ni,

  // Hosts (masters)
  input                           host_req_i    [NrHosts],
  output logic                    host_gnt_o    [NrHosts],

  input        [AddressWidth-1:0] host_addr_i   [NrHosts],
  input                           host_we_i     [NrHosts],
  input        [ DataWidth/8-1:0] host_be_i     [NrHosts],
  input        [   DataWidth-1:0] host_wdata_i  [NrHosts],
  output logic                    host_rvalid_o [NrHosts],
  output logic [   DataWidth-1:0] host_rdata_o  [NrHosts],
  output logic                    host_err_o    [NrHosts],

  // Devices (slaves)
  output logic                    device_req_o    [NrDevices],

  output logic [AddressWidth-1:0] device_addr_o   [NrDevices],
  output logic                    device_we_o     [NrDevices],
  output logic [ DataWidth/8-1:0] device_be_o     [NrDevices],
  output logic [   DataWidth-1:0] device_wdata_o  [NrDevices],
  input                           device_rvalid_i [NrDevices],
  input        [   DataWidth-1:0] device_rdata_i  [NrDevices],
  input                           device_err_i    [NrDevices],

  // Device address map
  input        [AddressWidth-1:0] cfg_device_addr_base [NrDevices],
  input        [AddressWidth-1:0] cfg_device_addr_mask [NrDevices]
);

  localparam int unsigned NumBitsHostSel = NrHosts > 1 ? $clog2(NrHosts) : 1;
  localparam int unsigned NumBitsDeviceSel = NrDevices > 1 ? $clog2(NrDevices) : 1;

  logic host_sel_valid;
  logic device_sel_valid;

  logic [NumBitsHostSel-1:0]   host_sel_req;
  logic [NumBitsDeviceSel-1:0] device_sel_req;

  // In-flight (outstanding) transaction bookkeeping.  Unlike the original
  // fixed-1-cycle bus, the response steering is latched and held until the
  // selected device actually responds, so slow devices are supported.
  logic                        outstanding_q;
  logic [NumBitsHostSel-1:0]   resp_host_q;
  logic [NumBitsDeviceSel-1:0] resp_dev_q;
  logic                        resp_err_q;   // decode miss: respond err, no device

  logic accept;      // a new request is captured this cycle
  logic resp_valid;  // the in-flight transaction responds this cycle

  // Master select prio arbiter (host 0 = highest priority)
  always_comb begin
    host_sel_valid = 1'b0;
    host_sel_req = '0;
    for (integer host = NrHosts - 1; host >= 0; host = host - 1) begin
      if (host_req_i[host]) begin
        host_sel_valid = 1'b1;
        host_sel_req = NumBitsHostSel'(host);
      end
    end
  end

  // Device select for the currently selected host's address
  always_comb begin
    device_sel_valid = 1'b0;
    device_sel_req = '0;
    for (integer device = 0; device < NrDevices; device = device + 1) begin
      if ((host_addr_i[host_sel_req] & cfg_device_addr_mask[device])
          == cfg_device_addr_base[device]) begin
        device_sel_valid = 1'b1;
        device_sel_req = NumBitsDeviceSel'(device);
      end
    end
  end

  // The in-flight transaction responds when its device raises rvalid, or
  // immediately (next cycle) for a decode miss.
  assign resp_valid = outstanding_q &
                      (resp_err_q | device_rvalid_i[resp_dev_q]);

  // Accept a new request when the bus is idle, or in the same cycle the
  // current one completes (keeps back-to-back 1-cycle devices at full rate).
  assign accept = host_sel_valid & (~outstanding_q | resp_valid);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      outstanding_q <= 1'b0;
      resp_host_q   <= '0;
      resp_dev_q    <= '0;
      resp_err_q    <= 1'b0;
    end else if (accept) begin
      outstanding_q <= 1'b1;
      resp_host_q   <= host_sel_req;
      resp_dev_q    <= device_sel_req;
      resp_err_q    <= ~device_sel_valid;
    end else if (resp_valid) begin
      outstanding_q <= 1'b0;
    end
  end

  // Drive the selected device for exactly one cycle (the accept cycle).  The
  // device must capture address/wdata with its request, as before.
  always_comb begin
    for (integer device = 0; device < NrDevices; device = device + 1) begin
      if (accept && device_sel_valid && NumBitsDeviceSel'(device) == device_sel_req) begin
        device_req_o[device]   = 1'b1;
        device_we_o[device]    = host_we_i[host_sel_req];
        device_addr_o[device]  = host_addr_i[host_sel_req];
        device_wdata_o[device] = host_wdata_i[host_sel_req];
        device_be_o[device]    = host_be_i[host_sel_req];
      end else begin
        device_req_o[device]   = 1'b0;
        device_we_o[device]    = 1'b0;
        device_addr_o[device]  = 'b0;
        device_wdata_o[device] = 'b0;
        device_be_o[device]    = 'b0;
      end
    end
  end

  // Grant the accepted host; route the response to the in-flight host.
  always_comb begin
    for (integer host = 0; host < NrHosts; host = host + 1) begin
      host_gnt_o[host]    = 1'b0;
      host_rvalid_o[host] = 1'b0;
      host_err_o[host]    = 1'b0;
      host_rdata_o[host]  = 'b0;
    end

    if (accept) begin
      host_gnt_o[host_sel_req] = 1'b1;
    end

    if (outstanding_q) begin
      if (resp_err_q) begin
        host_rvalid_o[resp_host_q] = 1'b1;
        host_err_o[resp_host_q]    = 1'b1;
        host_rdata_o[resp_host_q]  = 'b0;
      end else begin
        host_rvalid_o[resp_host_q] = device_rvalid_i[resp_dev_q];
        host_err_o[resp_host_q]    = device_err_i[resp_dev_q];
        host_rdata_o[resp_host_q]  = device_rdata_i[resp_dev_q];
      end
    end
  end
endmodule
