# P&R the k=6 mapped netlist AND emit a post-layout timing netlist + SDF for a
# gate-level timing (SDF back-annotated) simulation in xsim.  Same read/synth as
# build_mapped_bit.tcl, then write_verilog -mode timesim + write_sdf from the
# routed design.  This models real routing delays AND glbl/GSR power-up reset,
# which the zero-delay Verilator sim cannot — the faithful silicon reproduction.
set part xc7vx485tffg1761-2
set repo  $env(REPO)
set build $env(MAPPEDDIR)

create_project -force -in_memory ibex_mini_sdf -part $part
read_verilog -sv $build/dut.v
read_verilog -sv $build/wrap.v
read_verilog -sv $build/top_mapped.v
read_verilog -sv $repo/rtl/fpga/clkgen_vc707.sv
read_xdc         $repo/data/pins_vc707_mini.xdc

synth_design -top top_vc707_mini -part $part -flatten_hierarchy rebuilt
opt_design
place_design
route_design
write_checkpoint -force $build/ibex_mini_sdf.dcp

# Post-layout timing netlist + SDF for xsim.
write_verilog -force -mode timesim -sdf_anno true -nolib $build/timesim.v
write_sdf     -force -mode timesim  $build/timesim.sdf
puts "IBEX_MINI_SDF_DONE"
