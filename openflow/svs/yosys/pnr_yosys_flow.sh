#!/bin/bash
# ---------------------------------------------------------------------------
# Place & route the yosys-optimised ibex-mini netlist onto the VC707, producing
# a bitstream through the fully open flow (nextpnr-xilinx -> prjxray).
#
# Input : $W/ibex_fpga_yosys.json   (from run_yosys_flow.sh)
# Output: $W/ibex_yosys.bit
#
# Adapts the proven EDIF recipe (jtagtools/build_ibex_edif_r0.sh) — same VC707
# quirk handling — but nextpnr does its own placement (--placer sa) on the
# yosys netlist instead of importing a Vivado placement guide.
# ---------------------------------------------------------------------------
set -eu
ROOT=/home/jonathan/v7-johnson-demo
ETH=$ROOT/ethsoc
OF=$ROOT/ibexsoc/openflow
PXPY=$ROOT/deps/prjxray/env/bin/python
PXDB=$ROOT/deps/prjxray/database/virtex7
PART=xc7vx485tffg1761-2
NPNR=$ROOT/deps/nextpnr-xilinx/build/nextpnr-xilinx
CHIPDB=$ROOT/deps/nextpnr-xilinx/xilinx/xc7vx485t.bin
GOLDEN_BIT=${GOLDEN_BIT:-$ROOT/ibexsoc/build/lowrisc_ibex_demo_system_0/synth_vc707-vivado/lowrisc_ibex_demo_system_0.runs/impl_1/top_vc707.bit}

W=${W:-/tmp/svs_ibex_yosys}
JSON=$W/ibex_fpga_yosys.json
test -s "$JSON"

# Avoid the 6 mis-encoded INT_R bounce-pip encodings (prjxray DB subset-alias
# bug) that silently mis-route on silicon.
PIP_BLACKLIST=${PIP_BLACKLIST:-$OF/pip_blacklist_int_r_bounce.txt}

echo "=== [1/4] nextpnr-xilinx place & route (yosys netlist) ==="
flock /tmp/nextpnr.lock env NEXTPNR_ARC_MAX_VISIT=2000000 \
  NEXTPNR_PIP_BLACKLIST=$PIP_BLACKLIST \
  "$NPNR" --chipdb "$CHIPDB" \
    --xdc "$OF/ibex_pins.xdc" --json "$JSON" \
    --fasm "$W/ibex_yosys.fasm" --write "$W/ibex_yosys_routed.json" \
    --freq 50 --router router2 --placer "${PLACER:-heap}" 2>&1 | tee "$W/pnr.log" | tail -5
test -s "$W/ibex_yosys.fasm"

echo "=== [2/4] slow CPU MMCM output 50->25 MHz (open router misses 50 MHz) ==="
sed -i \
  -e "s/\(CMT_TOP_L_LOWER_B_X305Y269.MMCME2_ADV.CLKOUT0_CLKOUT1_HIGH_TIME\[5:0\] = \)6.b001010/\16'b010100/" \
  -e "s/\(CMT_TOP_L_LOWER_B_X305Y269.MMCME2_ADV.CLKOUT0_CLKOUT1_LOW_TIME\[5:0\] = \)6.b001010/\16'b010100/" \
  "$W/ibex_yosys.fasm"

echo "=== [3/4] fasm -> frames (+ BSCANE2 + golden output-IOB splice) ==="
XRAY_ALLOW_MISSING_FEATURES=1 $PXPY $ROOT/deps/prjxray/utils/fasm2frames.py \
  --db-root $PXDB --part $PART "$W/ibex_yosys.fasm" "$W/ibex_yosys.frames"
python3 $ETH/patch_bscan.py "$W/ibex_yosys.frames" "$W/ibex_yosys_bscan.frames" "$W/ibex_yosys.fasm"
python3 $OF/patch_output_iobs.py "$GOLDEN_BIT" "$W/ibex_yosys_bscan.frames" "$W/ibex_yosys_oiob.frames"

echo "=== [4/4] frames -> bitstream ==="
$ROOT/deps/prjxray/build/tools/xc7frames2bit --part_file $PXDB/$PART/part.yaml \
  --part_name $PART --frm_file "$W/ibex_yosys_oiob.frames" --output_file "$W/ibex_yosys.bit"
echo "IBEX YOSYS open-flow bit: $W/ibex_yosys.bit"
ls -la "$W/ibex_yosys.bit"
