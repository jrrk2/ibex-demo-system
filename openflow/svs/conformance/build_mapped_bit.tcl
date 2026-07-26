# Place & route the SVS gate-MAPPED ibex-mini netlist into a VC707 bitstream.
#
# Reads the same gate-mapped Verilog we simulate in `make mapped` (real UNISIM
# cells: LUTn / FDRE / CARRY4 / RAMB36E1 with the program baked into the BRAM
# INIT), wraps it in the board clock generator + pins, and lets Vivado only
# place & route the instantiated primitives (synth just builds the RTL glue in
# clkgen/top — -flatten_hierarchy rebuilt keeps the mapped cells as-is).
#
# Paths come from the environment (set by the Makefile `bitstream` target):
#   REPO        ibexsoc repo root
#   MAPPEDDIR   dir holding dut.v (mapped netlist), wrap.v, top_mapped.v
set part xc7vx485tffg1761-2
set repo  $env(REPO)
set build $env(MAPPEDDIR)

create_project -force -in_memory ibex_mini_mapped -part $part
# Order matters: the gate-mapped SoC + its RAMB leaf, then the name alias, then
# the board top and clock generator.
read_verilog -sv $build/dut.v
read_verilog -sv $build/wrap.v
read_verilog -sv $build/top_mapped.v
read_verilog -sv $repo/rtl/fpga/clkgen_vc707.sv
read_xdc         $repo/data/pins_vc707_mini.xdc

synth_design -top top_vc707_mini -part $part -flatten_hierarchy rebuilt
opt_design
place_design
route_design

write_checkpoint     -force $build/ibex_mini_mapped.dcp
write_bitstream      -force $build/ibex_mini_mapped.bit
report_utilization   -file  $build/ibex_mini_mapped_util.rpt
report_timing_summary -file $build/ibex_mini_mapped_timing.rpt -max_paths 5
puts "IBEX_MINI_MAPPED_BIT_DONE"
