# Single-source ibex+eth VC707 build: canonical in-place sources only
# (official ibex checkout + our git-tracked edits). No fusesoc/build-src dup.
set part xc7vx485tffg1761-2
create_project -force -in_memory ibex_eth -part $part
set_property verilog_define {FPGA_XILINX=1 PRIM_DEFAULT_IMPL=prim_pkg::ImplXilinx VC707=1} [current_fileset]
set_property include_dirs [list \
  /home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl \
  /home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils] [current_fileset]

# ---- canonical ibex/prim/dbg sources (incl clkgen; content-verified) ----
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_cipher_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_and2.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_buf.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_gating.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_flop.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_ram_2p_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_22_16_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_22_16_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_28_22_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_28_22_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_39_32_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_39_32_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_64_57_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_64_57_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_72_64_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_72_64_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_22_16_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_22_16_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_39_32_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_39_32_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_72_64_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_72_64_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_76_68_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_hamming_76_68_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_22_16_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_22_16_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_28_22_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_28_22_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_39_32_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_39_32_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_64_57_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_64_57_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_72_64_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_72_64_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_22_16_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_22_16_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_39_32_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_39_32_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_72_64_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_72_64_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_76_68_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_inv_hamming_76_68_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_and2.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_buf.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_clock_gating.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_clock_mux2.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_xilinx/rtl/prim_xilinx_flop.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_icache.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/timer.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_cdc_rand_delay.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_subst_perm.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_present.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_prince.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_count_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_count.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_mux2.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_ram_1p.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_ram_2p.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_lfsr.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_util_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/dv/uvm/icache/dv/prim_badbit/prim_badbit_ram_1p.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_onehot_enc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_onehot_mux.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_onehot_check.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_flop_2sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_inv.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi4_sender.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi4_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi4_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi8_sender.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi8_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi8_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi12_sender.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi12_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi12_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi16_sender.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi16_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi16_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi20_sender.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi20_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi20_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi24_sender.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi24_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi24_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi28_sender.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi28_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi28_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi32_sender.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi32_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi32_dec.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/fpga/xilinx/clkgen_xil7series.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/ram_1p.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/ram_2p.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_alu.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_branch_predict.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_compressed_decoder.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_controller.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_cs_registers.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_csr.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_counter.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_decoder.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_ex_block.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_fetch_fifo.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_id_stage.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_if_stage.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_load_store_unit.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_multdiv_fast.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_multdiv_slow.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_prefetch_buffer.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_pmp.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_wb_stage.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_dummy_instr.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_core.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_async_sram_adapter.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_async_simple.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_async.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync_cnt.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_adv.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_scr.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_register_file_ff.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_register_file_fpga.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_register_file_latch.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_lockstep.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/rtl/ibex_top.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/debug_rom/debug_rom.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/debug_rom/debug_rom_one_scratch.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dm_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dm_sba.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dm_csrs.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dm_mem.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dmi_cdc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dmi_jtag.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ip/ip/prim/rtl/prim_sync_reqack.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/pulp_riscv_dbg/src/dmi_bscane_tap.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/jtag_id_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/dm_top.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/debounce.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/gpio.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/pwm.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/pwm_wrapper.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/uart.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/spi_host.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/spi_top.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/fpga/clkgen_vc707.sv}

# ---- fusesoc-generated prim wrappers (captured once) ----
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_pkg.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_and2.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_buf.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_flop.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_clock_gating.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_clock_mux2.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_clock_inv.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_ram_1p.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/prim_gen/prim_ram_2p.sv}

# ---- our edited/new files (git-tracked, in place; NOT clkgen which is canonical) ----
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/vendor/lowrisc_ibex/shared/rtl/bus.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/ibex_demo_system.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/system/eth_dev.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ibexsoc/rtl/fpga/top_vc707.sv}

# ---- ethsoc ethernet stack ----
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/framing_top_sgmii.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/sgmii_soc.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/eth_mac_1g.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/axis_gmii_rx.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/axis_gmii_tx.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/rgmii_lfsr.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/dualmem_widen.sv}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/dualmem_widen8.sv}
read_verilog {/home/jonathan/v7-johnson-demo/ethsoc/pcs_pma_flat.v}
# eth support modules instantiated by framing_top_sgmii/eth_dev (omitted before;
# same set the SVS flow adds) — needed for the golden build to synthesize.
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/eth_macro.sv}
read_verilog {/home/jonathan/v7-johnson-demo/ethsoc/async_fifo.v}
read_verilog -sv {/home/jonathan/v7-johnson-demo/ethsoc/dualmem64.sv}
read_verilog {/home/jonathan/v7-johnson-demo/ethsoc/ramb16_compat.v}
read_verilog {/home/jonathan/v7-johnson-demo/ethsoc/eth_stream_conv.v}

read_xdc {/home/jonathan/v7-johnson-demo/ibexsoc/data/pins_vc707.xdc}
read_xdc {/home/jonathan/v7-johnson-demo/ibexsoc/data/eth_vc707.xdc}

synth_design -top top_vc707 -part $part -flatten_hierarchy rebuilt
opt_design
place_design
route_design
write_checkpoint -force /tmp/ibex_eth.dcp
write_bitstream -force /tmp/ibex_eth.bit
write_verilog -force -mode design /tmp/ibex_eth_netlist.v
report_timing_summary -file /tmp/ibex_eth_timing.rpt -max_paths 5
puts "IBEX_ETH_BUILD_DONE"
