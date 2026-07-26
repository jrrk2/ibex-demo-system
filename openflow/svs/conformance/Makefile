# RISC-V conformance of the ibex-mini SoC across FOUR representations:
#   rtl       — vendor ibex source RTL (golden)
#   behav     — SVS behavioural netlist   (BEHAV_VERILOG: post-passes BIR)
#   hardcaml  — SVS "after-Hardcaml" netlist (create_circuit, pre LUT-cover)
#   mapped    — SVS gate-mapped netlist   (create_circuit -> AIG -> LUT cover)
#
# Each variant is Verilated ONCE (its RAM replaced by a +VMEM behavioural leaf),
# then the whole rv32ui+rv32um suite is run by loading each test's .vmem at run
# time.  Program pass/fail is the `tohost` word (gp==1 => PASS).
#
#   make            # build vmems + all four, print a summary table
#   make rtl        # just the RTL variant
#   make hardcaml   # just the create_circuit variant
#   make vmem       # just (re)build the conformance programs
#   make clean
# ---------------------------------------------------------------------------

HERE      := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO      := $(abspath $(HERE)/../../..)
SUITEROOT := $(abspath $(REPO)/../deps/System-Verilog-suite)
SUITE     ?= $(SUITEROOT)/_build/default/sv_suite.exe
LUA       ?= $(REPO)/openflow/svs/ibex_mini_sim.lua
VERILATOR ?= $(HOME)/verilator/bin/verilator
# Xilinx UNISIM simulation models (FDRE/FDCE/FDPE/LUTn/CARRY4 …) for the
# gate-mapped netlist, taken from the yosys techlib.
UNISIM    ?= $(abspath $(REPO)/../deps/prjxray/third_party/yosys/techlibs/xilinx/cells_sim.v)
XPFX      ?= riscv32-unknown-elf-
BUILD     ?= /tmp/svs_conformance
# Vivado (for the `bitstream` target: places & routes the mapped netlist)
VIVADO    ?= $(firstword $(wildcard /opt/Xilinx/Vivado/*/bin/vivado) vivado)

# --- SVS emit environment (matches the SVS FPGA flow) ---
export SVS_DEFINE  := FPGA_XILINX=1;PRIM_DEFAULT_IMPL=prim_pkg::ImplXilinx;VC707=1;SYNTHESIS=1
export SVS_INCDIR  := $(REPO)/vendor/lowrisc_ip/ip/prim/rtl:$(REPO)/vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils
SRAM               := $(REPO)/sw/mini/johnson.vmem

VFLAGS := --binary -j $$(nproc) -Wno-lint -Wno-fatal -Wno-WIDTH \
          -Wno-CASEINCOMPLETE -Wno-UNOPTFLAT -Wno-MULTIDRIVEN -fno-gate --timing
TB     := $(HERE)/tb_conf.sv

# --- conformance programs (riscv-tests ISA suite, custom ibex-mini env) ---
ISADIR  := $(REPO)/vendor/lowrisc_ibex/vendor/riscv-tests/isa
ENVDIR  := $(REPO)/sw/isa_tests
TESTENV := $(REPO)/vendor/lowrisc_ibex/vendor/riscv-test-env
MACROS  := $(ISADIR)/macros/scalar
GCCOPTS := -march=rv32im_zicsr_zifencei -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden \
           -nostdlib -nostartfiles -I$(ENVDIR) -I$(TESTENV) -I$(MACROS) -T$(ENVDIR)/link_isa.ld
TESTS   := $(patsubst $(ISADIR)/rv32ui/%.S,rv32ui-%,$(wildcard $(ISADIR)/rv32ui/*.S)) \
           $(patsubst $(ISADIR)/rv32um/%.S,rv32um-%,$(wildcard $(ISADIR)/rv32um/*.S))
VMEMS   := $(addprefix $(BUILD)/vmem/,$(addsuffix .vmem,$(TESTS)))
export OBJDUMP := $(XPFX)objdump

.PHONY: all conformance rtl behav hardcaml mapped vmem bitstream edif clean
all: conformance
conformance: rtl behav hardcaml mapped
	@echo "==== conformance complete ===="

# ===========================================================================
# 1. conformance programs
# ===========================================================================
vmem: $(VMEMS)
$(BUILD)/vmem/rv32ui-%.vmem: $(ISADIR)/rv32ui/%.S
	@mkdir -p $(BUILD)/vmem $(BUILD)/elf
	@$(XPFX)gcc $(GCCOPTS) $< -o $(BUILD)/elf/rv32ui-$*.elf
	@$(XPFX)objcopy -O binary $(BUILD)/elf/rv32ui-$*.elf $(BUILD)/vmem/rv32ui-$*.bin
	@od -An -tx4 -v $(BUILD)/vmem/rv32ui-$*.bin | tr -s ' ' '\n' | grep . > $@
$(BUILD)/vmem/rv32um-%.vmem: $(ISADIR)/rv32um/%.S
	@mkdir -p $(BUILD)/vmem $(BUILD)/elf
	@$(XPFX)gcc $(GCCOPTS) $< -o $(BUILD)/elf/rv32um-$*.elf
	@$(XPFX)objcopy -O binary $(BUILD)/elf/rv32um-$*.elf $(BUILD)/vmem/rv32um-$*.bin
	@od -An -tx4 -v $(BUILD)/vmem/rv32um-$*.bin | tr -s ' ' '\n' | grep . > $@

# extract the SVS-emitted RAM leaf module name from a netlist, and generate a
# matching +VMEM behavioural leaf from ram_leaf.v.in
define GEN_LEAF   # $(1) = netlist file, $(2) = output leaf .v
	m=$$(grep -oE 'prim_generic_ram_2p__[A-Za-z0-9_]+_W32' $(1) | head -1); \
	test -n "$$m" || { echo "no RAM leaf module in $(1)"; exit 1; }; \
	sed "s/@@MOD@@/$$m/" $(HERE)/ram_leaf.v.in > $(2)
endef
# strip a module (name = $(2)) from a one-file netlist $(1) -> $(3)
define STRIP_MOD  # $(1)=in, $(2)=modname, $(3)=out
	awk -v m="$(2)" 'BEGIN{s=0} $$0 ~ ("^module "m"( |\\()") {s=1} s&&/^endmodule/{s=0;next} !s' $(1) > $(3)
endef
# generate the ibex_mini_system wrapper for an SVS netlist $(1) -> $(2)
define GEN_WRAP   # $(1)=netlist, $(2)=out wrapper .v
	t=$$(grep -oE '^module ibex_mini_system__[A-Za-z0-9_]+' $(1) | head -1 | sed 's/^module //'); \
	test -n "$$t" || { echo "no ibex_mini_system__ top in $(1)"; exit 1; }; \
	sed "s/@@TOP@@/$$t/" $(HERE)/mini_wrap.v.in > $(2)
endef

# ===========================================================================
# 2. RTL (golden) — vendor RTL, vendor RAM swapped for the +VMEM model
# ===========================================================================
rtl: $(BUILD)/rtl/Vsim vmem
	@$(HERE)/run_suite.sh $(BUILD)/rtl/Vsim $(BUILD)/vmem $(BUILD)/elf rtl || true
$(BUILD)/rtl/Vsim: $(HERE)/rtl_files.f $(HERE)/prim_generic_ram_2p.v $(TB)
	@mkdir -p $(BUILD)/rtl
	@sed 's#__REPO__#$(REPO)#g' $(HERE)/rtl_files.f > $(BUILD)/rtl/files.f
	VM_PARALLEL_BUILDS=1 $(VERILATOR) $(VFLAGS) -Wno-PINNOTFOUND \
	  +define+FPGA_XILINX=1 +define+VC707=1 +define+SYNTHESIS=1 \
	  +incdir+$(REPO)/vendor/lowrisc_ip/ip/prim/rtl \
	  +incdir+$(REPO)/vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils \
	  --top-module tb_ibex_mini --Mdir $(BUILD)/rtl/obj -o Vsim -o $(BUILD)/rtl/Vsim \
	  $(TB) -f $(BUILD)/rtl/files.f $(HERE)/prim_generic_ram_2p.v

# ===========================================================================
# 3. behavioural netlist (BEHAV_VERILOG)
# ===========================================================================
behav: $(BUILD)/behav/Vsim vmem
	@$(HERE)/run_suite.sh $(BUILD)/behav/Vsim $(BUILD)/vmem $(BUILD)/elf behav || true
$(BUILD)/behav/dut.v:
	@mkdir -p $(BUILD)/behav
	BEHAV_VERILOG=1 SRAM_INIT=$(SRAM) W=$(BUILD)/behav $(SUITE) script $(LUA)
	@mv $(BUILD)/behav/ibex_mini_sim_dut.v $@
$(BUILD)/behav/Vsim: $(BUILD)/behav/dut.v $(TB) $(HERE)/ram_leaf.v.in $(HERE)/mini_wrap.v.in
	@m=$$(grep -oE 'prim_generic_ram_2p__[A-Za-z0-9_]+_W32' $(BUILD)/behav/dut.v | head -1); \
	  sed "s/@@MOD@@/$$m/" $(HERE)/ram_leaf.v.in > $(BUILD)/behav/ram.v; \
	  $(call STRIP_MOD,$(BUILD)/behav/dut.v,$$m,$(BUILD)/behav/dut_noram.v)
	@$(call GEN_WRAP,$(BUILD)/behav/dut.v,$(BUILD)/behav/wrap.v)
	VM_PARALLEL_BUILDS=1 $(VERILATOR) $(VFLAGS) -Wno-PINNOTFOUND \
	  --top-module tb_ibex_mini --Mdir $(BUILD)/behav/obj -o $(BUILD)/behav/Vsim \
	  $(TB) $(BUILD)/behav/wrap.v $(BUILD)/behav/dut_noram.v $(BUILD)/behav/ram.v

# ===========================================================================
# 4. hardcaml netlist (create_circuit, per-module; leaf is a separate file)
# ===========================================================================
hardcaml: $(BUILD)/hardcaml/Vsim vmem
	@$(HERE)/run_suite.sh $(BUILD)/hardcaml/Vsim $(BUILD)/vmem $(BUILD)/elf hardcaml || true
$(BUILD)/hardcaml/soc.v:
	@mkdir -p $(BUILD)/hardcaml/cc
	MEMLOWER_FPGA=1 MEMLOWER_NO_LUTRAM=1 SRAM_INIT=$(SRAM) \
	  EMIT_CREATE_CIRCUIT=$(BUILD)/hardcaml/cc $(SUITE) script $(LUA)
	@leaf=$$(ls $(BUILD)/hardcaml/cc/prim_generic_ram_2p__*_W32.v | head -1); \
	  : > $@; for f in $(BUILD)/hardcaml/cc/*.v; do [ "$$f" = "$$leaf" ] && continue; \
	    echo "// ==== $$(basename $$f) ====" >> $@; cat "$$f" >> $@; done
$(BUILD)/hardcaml/Vsim: $(BUILD)/hardcaml/soc.v $(TB) $(HERE)/ram_leaf.v.in $(HERE)/mini_wrap.v.in
	@$(call GEN_LEAF,$(BUILD)/hardcaml/cc/prim_generic_ram_2p__*_W32.v,$(BUILD)/hardcaml/ram.v)
	@$(call GEN_WRAP,$(BUILD)/hardcaml/soc.v,$(BUILD)/hardcaml/wrap.v)
	VM_PARALLEL_BUILDS=1 $(VERILATOR) $(VFLAGS) -Wno-PINNOTFOUND \
	  --top-module tb_ibex_mini --Mdir $(BUILD)/hardcaml/obj -o $(BUILD)/hardcaml/Vsim \
	  $(TB) $(BUILD)/hardcaml/wrap.v $(BUILD)/hardcaml/soc.v $(BUILD)/hardcaml/ram.v

# ===========================================================================
# 5. mapped netlist (gate_map -> LUT cover, one hier file)
# ===========================================================================
mapped: $(BUILD)/mapped/Vsim vmem
	@$(HERE)/run_suite.sh $(BUILD)/mapped/Vsim $(BUILD)/vmem $(BUILD)/elf mapped || true
$(BUILD)/mapped/dut.v:
	@mkdir -p $(BUILD)/mapped
	HIER_VERILOG=1 MEMLOWER_FPGA=1 MEMLOWER_NO_LUTRAM=1 SRAM_INIT=$(SRAM) \
	  W=$(BUILD)/mapped $(SUITE) script $(LUA)
	@mv $(BUILD)/mapped/ibex_mini_hier.v $@
$(BUILD)/mapped/Vsim: $(BUILD)/mapped/dut.v $(TB) $(HERE)/ram_leaf.v.in $(HERE)/mini_wrap.v.in $(UNISIM)
	@m=$$(grep -oE 'prim_generic_ram_2p__[A-Za-z0-9_]+_W32' $(BUILD)/mapped/dut.v | head -1); \
	  sed "s/@@MOD@@/$$m/" $(HERE)/ram_leaf.v.in > $(BUILD)/mapped/ram.v; \
	  $(call STRIP_MOD,$(BUILD)/mapped/dut.v,$$m,$(BUILD)/mapped/dut_noram.v)
	@$(call GEN_WRAP,$(BUILD)/mapped/dut.v,$(BUILD)/mapped/wrap.v)
	VM_PARALLEL_BUILDS=1 $(VERILATOR) $(VFLAGS) -Wno-PINNOTFOUND -Wno-TIMESCALEMOD \
	  --top-module tb_ibex_mini --Mdir $(BUILD)/mapped/obj -o $(BUILD)/mapped/Vsim \
	  $(TB) $(BUILD)/mapped/wrap.v $(BUILD)/mapped/dut_noram.v $(BUILD)/mapped/ram.v $(UNISIM)

# ===========================================================================
# 6. bitstream — place & route the MAPPED netlist onto the VC707 (Vivado)
# ===========================================================================
# Takes the exact gate-mapped netlist from `make mapped` (LUTn/FDRE/CARRY4 +
# RAMB36E1 with the program baked into the BRAM INIT), wraps it in the board
# clock generator + pins, and P&Rs it to $(BUILD)/mapped/ibex_mini_mapped.bit.
# The baked program is $(SRAM) (johnson LED demo by default).  Vivado only
# routes the instantiated primitives; it does NOT re-synthesise the mapped core.
bitstream: $(BUILD)/mapped/ibex_mini_mapped.bit
$(BUILD)/mapped/ibex_mini_mapped.bit: $(BUILD)/mapped/dut.v \
    $(HERE)/mini_wrap.v.in $(HERE)/top_mapped.v.in $(HERE)/build_mapped_bit.tcl
	@$(call GEN_WRAP,$(BUILD)/mapped/dut.v,$(BUILD)/mapped/wrap.v)
	@cp $(HERE)/top_mapped.v.in $(BUILD)/mapped/top_mapped.v
	REPO=$(REPO) MAPPEDDIR=$(BUILD)/mapped \
	  $(VIVADO) -mode batch -nojournal -log $(BUILD)/mapped/vivado.log \
	  -source $(HERE)/build_mapped_bit.tcl
	@test -f $@ && echo "BITSTREAM $@" || { echo "bitstream FAILED (see $(BUILD)/mapped/vivado.log)"; exit 1; }

# ===========================================================================
# 7. edif — hierarchical-EDIF variant of the bitstream flow (Vivado read_edif)
# ===========================================================================
# Same design & baked program as `bitstream`, but delivered as a hierarchical
# EDIF (svd.write_hier_edif) that Vivado links via read_edif instead of reading
# gate-mapped Verilog.  This exercises the bir_to_edif emitter end-to-end.
edif: $(BUILD)/edif/ibex_mini_edif.bit
# write_hier_edif renames its output to match the top cell -> ibex_mini_system.edf
$(BUILD)/edif/ibex_mini_system.edf:
	@mkdir -p $(BUILD)/edif
	HIER_EDIF=1 MEMLOWER_FPGA=1 MEMLOWER_NO_LUTRAM=1 SRAM_INIT=$(SRAM) \
	  W=$(BUILD)/edif $(SUITE) script $(LUA)
$(BUILD)/edif/ibex_mini_edif.bit: $(BUILD)/edif/ibex_mini_system.edf \
    $(HERE)/mini_wrap.v.in $(HERE)/soc_stub.v.in $(HERE)/top_mapped.v.in $(HERE)/build_edif_bit.tcl
	@t=$$(grep -aoE 'ibex_mini_system__[A-Za-z0-9_]+' $(BUILD)/edif/ibex_mini_system.edf | head -1); \
	  test -n "$$t" || { echo "no mangled ibex_mini_system top in EDIF"; exit 1; }; \
	  sed "s/@@TOP@@/$$t/" $(HERE)/mini_wrap.v.in > $(BUILD)/edif/wrap.v; \
	  sed "s/@@TOP@@/$$t/" $(HERE)/soc_stub.v.in > $(BUILD)/edif/soc_stub.v; \
	  cp -f $(BUILD)/edif/ibex_mini_system.edf $(BUILD)/edif/$$t.edf; \
	  echo "$$t" > $(BUILD)/edif/topcell.txt
	@cp $(HERE)/top_mapped.v.in $(BUILD)/edif/top_mapped.v
	REPO=$(REPO) EDIFDIR=$(BUILD)/edif TOPCELL=$$(cat $(BUILD)/edif/topcell.txt) \
	  $(VIVADO) -mode batch -nojournal -log $(BUILD)/edif/vivado.log \
	  -source $(HERE)/build_edif_bit.tcl
	@test -f $@ && echo "BITSTREAM $@" || { echo "edif bitstream FAILED (see $(BUILD)/edif/vivado.log)"; exit 1; }

clean:
	rm -rf $(BUILD)
