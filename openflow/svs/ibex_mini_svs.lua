-- IBEX MINI SoC (top_vc707_mini): SVS/verible SYNTHESIS -> EDIF for the
-- Vivado-P&R hybrid.  Cut down from ibex_svs.lua (no eth/uart/spi/pwm/timer)
-- so any residual verible-frontend bug is isolated to core+debug+gpio+ram.
--
-- REQUIRED ENV (matching what Vivado's synth_design does for the golden build):
--   SVS_DEFINE='FPGA_XILINX=1;PRIM_DEFAULT_IMPL=prim_pkg::ImplXilinx;VC707=1;SYNTHESIS=1'
--     SYNTHESIS=1 makes prim_assert.sv emit the DUMMY assertion macros; without
--     it lowRISC emits full SVA `assert property(...) else <action>`, which the
--     SVS verible grammar cannot yet parse -> ibex_core.sv is dropped and
--     ibex_top gate_map fails on unresolved ibex_core.* ports.  (Vivado defines
--     SYNTHESIS automatically, which is why the golden build is unaffected.)
--   MEMLOWER_FPGA=1   map the 16 KiB RAM to RAMB36 (else 32-bit bit-blast blows up).
--   SVS_INCDIR='.../ip/prim/rtl:.../dv/sv/dv_utils'   (prim_assert.sv include path)
--   W=<build dir>     output dir for ibex_mini.edf
local FILES = {
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_cipher_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_and2.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_buf.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_gating.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_flop.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_ram_2p_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_22_16_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_22_16_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_28_22_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_28_22_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_39_32_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_39_32_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_64_57_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_64_57_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_72_64_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_72_64_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_22_16_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_22_16_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_39_32_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_39_32_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_72_64_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_72_64_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_76_68_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_76_68_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_22_16_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_22_16_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_28_22_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_28_22_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_39_32_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_39_32_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_64_57_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_64_57_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_72_64_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_72_64_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_22_16_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_22_16_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_39_32_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_39_32_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_72_64_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_72_64_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_76_68_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_76_68_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_and2.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_buf.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_clock_gating.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_clock_mux2.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_flop.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_cdc_rand_delay.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_subst_perm.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_present.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_prince.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_count_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_count.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_mux2.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_ram_1p.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_ram_2p.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_lfsr.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_util_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/dv/uvm/icache/dv/prim_badbit/prim_badbit_ram_1p.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_onehot_enc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_onehot_mux.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_onehot_check.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_flop_2sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_inv.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi4_sender.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi4_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi4_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi8_sender.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi8_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi8_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi12_sender.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi12_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi12_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi16_sender.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi16_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi16_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi20_sender.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi20_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi20_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi24_sender.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi24_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi24_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi28_sender.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi28_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi28_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi32_sender.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi32_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi32_dec.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/fpga/xilinx/clkgen_xil7series.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/ram_1p.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/ram_2p.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_alu.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_branch_predict.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_compressed_decoder.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_controller.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_cs_registers.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_csr.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_counter.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_decoder.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_ex_block.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_fetch_fifo.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_id_stage.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_if_stage.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_load_store_unit.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_multdiv_fast.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_multdiv_slow.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_prefetch_buffer.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_pmp.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_wb_stage.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_dummy_instr.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_core.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_async_sram_adapter.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_async_simple.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_async.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync_cnt.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_adv.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_scr.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_register_file_ff.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_register_file_fpga.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_register_file_latch.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_lockstep.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_top.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/debug_rom/debug_rom.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/debug_rom/debug_rom_one_scratch.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dm_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dm_sba.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dm_csrs.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dm_mem.sv",  -- REAL dm_mem (comb-loop fixed by const-index array-flatten of abstract_cmd)
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dmi_cdc.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dmi_jtag.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_sync_reqack.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dmi_bscane_tap.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/jtag_id_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/dm_top.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/debounce.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/gpio.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/fpga/clkgen_vc707.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_pkg.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_and2.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_buf.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_flop.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_clock_gating.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_clock_mux2.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_clock_inv.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_ram_1p.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_ram_2p.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/bus.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/ibex_mini_system.sv",
  "/home/jonathan/v7-johnson-demo/ibexsoc/rtl/fpga/top_vc707_mini.sv",
}
-- SRAM_INIT=<vmem path>: bake the program into the RAM via $readmemh (SVS reads
-- the hex at convert time -> memlower emits RAMB INIT).  Override the top's
-- SRAMInitFile param (propagates to ram_2p.MemInitFile) with svd.parse_spec.
-- Without it the RAM is empty and Vivado opt_design prunes the whole CPU (LEDs
-- become constant): the hybrid MUST carry the program to be a real design.
local sram = os.getenv("SRAM_INIT")
local p
if sram and strlen(sram) > 0 then
  p = svd.parse_spec("verible", "top_vc707_mini", FILES, "SRAMInitFile=\""..sram.."\"")
else
  p = svd.parse("verible", "top_vc707_mini", FILES)
end
if os.getenv("RAW_DUMP") then print(svd.bir(svd.pick(p, os.getenv("RAW_DUMP")))); error("raw dump done") end
p = svd.unroll(p); p=svd.inline(p); p=svd.iflift(p)
p = svd.blocking_subst(p); p=svd.meminfer(p)
-- For behavioral simulation keep the inferred memory as a behavioral reg
-- array (clean synchronous timing).  memlower maps it to RAMB36 primitives
-- (unisim), which clock on their own edges and slip a cycle vs the fetch
-- logic in xsim -> the instr read returns stale/garbage words.  Only lower
-- for the FPGA/create_circuit flow.
if not os.getenv("BEHAV_VERILOG") then p=svd.memlower(p) end
p=svd.srl_infer(p)
-- BEHAV_VERILOG: emit the POST-PASSES behavioral BIR (before gate_map/create_circuit)
-- as Verilog, to bisect create_circuit vs the passes.
if os.getenv("BEHAV_VERILOG") then
  svd.write_verilog(p, (os.getenv("W") or "/tmp/svs_ibex_mini") .. "/ibex_mini_behav.v")
  print("WROTE behav verilog")
  return
end
local names = svd.module_names(p)
NT={}; local cnt=0; local i=1; local n=strlen(names)
while i<=n do local j=strfind(names,",",i,1); local nm
  if j then nm=strsub(names,i,j-1); i=j+1 else nm=strsub(names,i,n); i=n+1 end
  if strlen(nm)>0 then cnt=cnt+1; NT[cnt]=nm end
end
local result=p; local k=1
while k<=cnt do
  local M=NT[k]
  print("gate_map "..M)
  result = svd.splice(result, M, svd.mapped_to_prog(svd.gate_map(svd.pick(result,M),6,0)))
  k=k+1
end
-- HIER_VERILOG: emit HIERARCHICAL gate-mapped Verilog (per-module cells, NOT
-- flattened) for xsim — avoids the flatten_structural driverless-net bug that
-- the flat netlist hits.  xsim compiles the module hierarchy + UNISIMs directly.
if os.getenv("HIER_VERILOG") then
  local o2 = (os.getenv("W") or "/tmp/svs_ibex_mini") .. "/ibex_mini_hier.v"
  svd.write_verilog(result, o2)
  print("WROTE " .. o2)
  return
end
-- FLAT_TOP=<module>: emit a FLAT gate-level Verilog netlist (real UNISIM cells +
-- RAMB INIT) for that module, for xsim functional simulation.
if os.getenv("FLAT_TOP") then
  local t = os.getenv("FLAT_TOP")
  -- resolve to the SPECIALISED module name (t may be a base name; gate_map's
  -- module carries a __<params> suffix).
  local names = svd.module_names(result)
  local pick = nil
  local i=1; local n=strlen(names)
  while i<=n do local j=strfind(names,",",i,1); local nm
    if j then nm=strsub(names,i,j-1); i=j+1 else nm=strsub(names,i,n); i=n+1 end
    if nm==t then pick=nm end
    if not pick and strfind(nm, t.."__", 1, 1)==1 then pick=nm end
  end
  pick = pick or t
  local o2 = (os.getenv("W") or "/tmp/svs_ibex_mini") .. "/" .. t .. "_flat.v"
  local net = svd.flatten_struct(result, pick)
  svd.write_netlist_verilog(net, o2)
  print("WROTE " .. o2 .. " (module " .. pick .. ")")
  return
end
local out = (os.getenv("W") or "/tmp/svs_ibex_mini") .. "/ibex_mini.edf"
if os.getenv("HIER_EDIF") then
  svd.write_hier_edif(result, "top_vc707_mini", out)
else
  local net = svd.flatten_struct(result, "top_vc707_mini")
  svd.write_netlist_edif(net, out)
end
print("WROTE " .. out)
