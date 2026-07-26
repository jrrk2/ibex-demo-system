# Place & route the SVS-emitted hierarchical EDIF into a VC707 bitstream.
#
# Alternative front door to `bitstream`: instead of reading gate-mapped Verilog,
# Vivado imports the SVS netlist via read_edif (svd.write_hier_edif output) and
# drops it into the RTL board top as an out-of-context sub-block.  Same design &
# baked program; this exercises the bir_to_edif emitter as the Vivado input path.
#
# Env (set by the Makefile `edif` target):
#   REPO      ibexsoc repo root
#   EDIFDIR   dir holding ibex_mini_system.edf, soc_stub.v, wrap.v, top_mapped.v
#   TOPCELL   the name-mangled ibex_mini_system cell (EDIF top)
set part xc7vx485tffg1761-2
set repo  $env(REPO)
set build $env(EDIFDIR)
set cell  $env(TOPCELL)

# --- 1. EDIF block -> out-of-context synthesized checkpoint ------------------
# OOC link_design looks the netlist up by <top-module>.edf, so read the copy the
# Makefile named after the (mangled) top cell rather than ibex_mini_system.edf.
create_project -force -in_memory ibex_mini_edif_ooc -part $part
read_edif $build/$cell.edf
link_design -top $cell -part $part -mode out_of_context
write_checkpoint -force $build/soc_ooc.dcp
close_project

# --- 2. RTL board top (SoC as black box) then fill it with the EDIF block ----
create_project -force -in_memory ibex_mini_edif -part $part
read_verilog -sv $build/soc_stub.v
read_verilog -sv $build/wrap.v
read_verilog -sv $build/top_mapped.v
read_verilog -sv $repo/rtl/fpga/clkgen_vc707.sv
read_xdc         $repo/data/pins_vc707_mini.xdc
synth_design -top top_vc707_mini -part $part
# populate the black-box instance (u_soc/u = wrap alias -> mangled cell) with the
# SVS EDIF netlist synthesized above.
read_checkpoint -cell u_soc/u $build/soc_ooc.dcp

opt_design
place_design
route_design

write_checkpoint      -force $build/ibex_mini_edif.dcp
write_bitstream       -force $build/ibex_mini_edif.bit
report_utilization    -file  $build/ibex_mini_edif_util.rpt
report_timing_summary -file  $build/ibex_mini_edif_timing.rpt -max_paths 5
puts "IBEX_MINI_EDIF_BIT_DONE"
