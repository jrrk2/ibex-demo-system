#!/bin/bash
# ---------------------------------------------------------------------------
# Place (place_lef topographical) + route (nextpnr) the yosys-optimised ibex
# netlist -> VC707 bitstream.  nextpnr's own HeAP placer scatters ibex's
# high-fanout clock-enable nets (if_stage _132, ~55 sinks) so router2 can't
# reach every CEUSEDMUX; place_lef allocates high-fanout nets to BUFG global
# routing (TOPO_BUFG_FANOUT) and is congestion/long-line aware, which the ARP
# open flow proved routable.  Recipe adapted from ethsoc/build_svs_arp.sh +
# the ibex fasm post-processing from pnr_yosys_flow.sh.
# ---------------------------------------------------------------------------
set -eu
# Paths overridable so the top-level Makefile can drive this.
ROOT=${ROOT:-/home/jonathan/v7-johnson-demo}
SVS=${SVS:-$ROOT/deps/System-Verilog-suite}
OF=$ROOT/ibexsoc/openflow
ETH=$ROOT/ethsoc
PXDB=${PXDB:-$ROOT/deps/prjxray/database/virtex7}
PXPY=${PXPY:-$ROOT/deps/prjxray/env/bin/python}
PART=xc7vx485tffg1761-2
NEXTPNR=${NEXTPNR:-$ROOT/deps/nextpnr-xilinx/build/nextpnr-xilinx}
CHIPDB=${CHIPDB:-$ROOT/deps/nextpnr-xilinx/xilinx/xc7vx485t.bin}
GOLDEN_BIT=${GOLDEN_BIT:-$ROOT/ibexsoc/build/lowrisc_ibex_demo_system_0/synth_vc707-vivado/lowrisc_ibex_demo_system_0.runs/impl_1/top_vc707.bit}
LOCK="flock /tmp/nextpnr.lock"

W=${W:-/tmp/svs_ibex_yosys}
JSON=$W/ibex_fpga_yosys.json
test -s "$JSON"

echo "=== 1. floorplan (prjxray tilegrid) ==="
if [ ! -s "$W/floorplan.json" ]; then
  python3 $SVS/xilinx_lef/gen_floorplan.py $W/floorplan.json > $W/floorplan.log 2>&1 \
    || { echo FLOORPLAN FAILED; tail -5 $W/floorplan.log; exit 1; }
fi

echo "=== 2. place_lef (topographical SA, high-fanout->BUFG) ~15 min ==="
SVS_SYNTH=1 \
TOPO_SITE_PHYSMAP=$SVS/xilinx_lef/xc7vx485t_bram_physmap.txt \
TOPO_COH_W=10 TOPO_SITE_W=300 TOPO_SITE_FRAC=0.55 TOPO_REGION_FILL=0.5 TOPO_SA_MOVES=900000 \
TOPO_CONG_W=6 TOPO_CONG_CAP=8 TOPO_CONG_BIN=5 TOPO_LL_W=8 TOPO_LL_HCAP=5 TOPO_LL_VCAP=5 \
TOPO_FEEDTHRU=18 TOPO_RELAY_MAXD=6 TOPO_BUF_TYPE=BUFR TOPO_BUFR_PER_REGION=0 \
TOPO_BUFG_FANOUT=24 TOPO_BUFG_MAX=40 \
TOPO_CARRY_SPREAD=1 TOPO_CARRY_MAX_PER_COL=32 \
TOPO_FIXNETS=$W/fixnets.txt TOPO_PLACE=sa TOPO_SEED=1 \
BELS_OUT=$W/bels.txt TOPO_FT_JSON=$W/ibex_ft.json \
TOPO_STAMPED_JSON=$W/ibex_stamped_ocaml.json PLACED_OUT=$W/placed.txt \
  $SVS/_build/default/place_lef.exe $W/floorplan.json $JSON > $W/place.log 2>&1 \
  || { echo PLACE FAILED; tail -15 $W/place.log; exit 1; }
echo "  placed: $(grep -c . $W/placed.txt 2>/dev/null) cells; $(grep -iE 'BUFG|fanout' $W/place.log | tail -2)"

echo "=== 3. carry_stamp ==="
CARRY_FLOORPLAN=$W/floorplan.json CARRY_STAMP_AVOID_CI=1 \
  python3 $SVS/carry_stamp.py $W/ibex_ft.json $W/bels.txt $W/ibex_stamped.json > $W/carry.log 2>&1 \
  || { echo CARRY_STAMP FAILED; tail -8 $W/carry.log; exit 1; }

echo "=== 4. route (nextpnr router2, placement locked) ==="
$LOCK env NEXTPNR_ALLOW_CO_5FF_CONTENTION=1 NEXTPNR_SKIP_FAILED_ARCS=1 NEXTPNR_ARC_MAX_VISIT=2000000 \
  NEXTPNR_PIP_BLACKLIST=$OF/pip_blacklist_int_r_bounce.txt \
  $NEXTPNR --router router2 --chipdb $CHIPDB --xdc $OF/ibex_pins.xdc --freq 50 \
  --json $W/ibex_stamped.json --fasm $W/ibex_yosys.fasm --write $W/ibex_yosys_routed.json 2>&1 \
  | tee $W/route.log | grep --line-buffered -E "Info: (Packing|Placing|Placed|Running|Routing global|Max freq)|ERROR|unbound|SKIP" | tail -20 || true
SK=$(grep -ac SKIP_FAILED_ARCS $W/route.log || true)
echo "SKIPS=$SK"
[ "$SK" = 0 ] || { echo "ROUTE INCOMPLETE ($SK skipped arcs)"; grep -a SKIP_FAILED_ARCS $W/route.log | head -5; exit 1; }
test -s "$W/ibex_yosys.fasm"

echo "=== 5. slow CPU MMCM 50->25 MHz ==="
sed -i \
  -e "s/\(CMT_TOP_L_LOWER_B_X305Y269.MMCME2_ADV.CLKOUT0_CLKOUT1_HIGH_TIME\[5:0\] = \)6.b001010/\16'b010100/" \
  -e "s/\(CMT_TOP_L_LOWER_B_X305Y269.MMCME2_ADV.CLKOUT0_CLKOUT1_LOW_TIME\[5:0\] = \)6.b001010/\16'b010100/" \
  "$W/ibex_yosys.fasm" || true

echo "=== 6. fasm -> frames (+BSCANE2 +golden output-IOB) -> bit ==="
XRAY_ALLOW_MISSING_FEATURES=1 $PXPY $ROOT/deps/prjxray/utils/fasm2frames.py \
  --db-root $PXDB --part $PART "$W/ibex_yosys.fasm" "$W/ibex_yosys.frames"
python3 $ETH/patch_bscan.py "$W/ibex_yosys.frames" "$W/ibex_yosys_bscan.frames" "$W/ibex_yosys.fasm"
python3 $OF/patch_output_iobs.py "$GOLDEN_BIT" "$W/ibex_yosys_bscan.frames" "$W/ibex_yosys_oiob.frames"
$ROOT/deps/prjxray/build/tools/xc7frames2bit --part_file $PXDB/$PART/part.yaml \
  --part_name $PART --frm_file "$W/ibex_yosys_oiob.frames" --output_file "$W/ibex_yosys.bit"
echo "IBEX YOSYS+place_lef open-flow bit: $W/ibex_yosys.bit"; ls -la "$W/ibex_yosys.bit"
