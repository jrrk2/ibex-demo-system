# Cut-down ibex mini-system GATE-MAP-VERILOG build: Vivado reads the SVS
# gate-mapped HIERARCHICAL Verilog (ibex_mini_hier.v — real UNISIM cells,
# post gate_map) and only places & routes it.  This is the full open-synthesis
# flow (SVS does the gate mapping) but delivered as instantiated primitives in
# Verilog instead of EDIF, to BYPASS the bir_to_edif/link_design connectivity
# bug that collapsed the EDIF netlist to ~450 LUTs.
#
#   verilog in : /tmp/svs_ibex_mini/ibex_mini_hier.v   (HIER_VERILOG=1 emit)
#   top wrapper: /tmp/svs_ibex_mini/top_behav_wrap.sv  (top_vc707_mini alias)
#   program    : baked into the gate-mapped RAMB INIT (johnson)
set part xc7vx485tffg1761-2
create_project -force -in_memory ibex_mini_hierv -part $part
read_verilog -sv /tmp/svs_ibex_mini/ibex_mini_hier.v
read_verilog -sv /tmp/svs_ibex_mini/top_behav_wrap.sv
read_xdc {/home/jonathan/v7-johnson-demo/ibexsoc/data/pins_vc707_mini.xdc}
# -flatten_hierarchy none keeps the gate-mapped cells as-is (no re-synthesis of
# the instantiated primitives); Vivado just binds UNISIMs and P&Rs them.
synth_design -top top_vc707_mini -part $part -flatten_hierarchy rebuilt
opt_design
place_design
route_design
write_checkpoint -force /tmp/ibex_mini_hierv.dcp
write_bitstream -force /tmp/ibex_mini_hierv.bit
report_utilization -file /tmp/ibex_mini_hierv_util.rpt
report_timing_summary -file /tmp/ibex_mini_hierv_timing.rpt -max_paths 5
puts "IBEX_MINI_HIERV_DONE"
