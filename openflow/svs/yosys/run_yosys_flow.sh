#!/bin/bash
# ---------------------------------------------------------------------------
# yosys optimisation stage for the SVS open flow (temporary, until the SVS
# built-in gate_map/optimise reaches Vivado quality).
#
# SVS emits the create_circuit netlist (arithmetic operators + hard-macro
# instances intact, passes 47/47 conformance).  yosys `synth_xilinx` maps it to
# LUT/CARRY4/DSP48/RAMB — near-Vivado quality (75 CARRY4 / ~5.9k LUT / 1 DSP vs
# Vivado 76 / 4296) — AND bypasses SVS's own LUT-cover (whose signed-mul bug
# fails the `mapped` conformance path).  Output JSON feeds nextpnr-xilinx.
#
#   ./run_yosys_flow.sh [emit|synth|all]
# ---------------------------------------------------------------------------
set -e
STAGE="${1:-all}"

# Paths are overridable so the top-level Makefile can drive this (ROOT/SVSROOT/
# YOSYS); the defaults match a standard checkout on this machine.
ROOT=${ROOT:-/home/jonathan/v7-johnson-demo}
REPO=$ROOT/ibexsoc
SVSROOT=${SVSROOT:-$ROOT/deps/System-Verilog-suite}
SVS=$SVSROOT/_build/default/sv_suite.exe
LUA=$REPO/openflow/svs/ibex_mini_svs.lua
YOSYS=${YOSYS:-/home/jonathan/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys}
# GNU coreutils: on macOS `readlink -f`/`dirname` are the g-prefixed brew tools.
command -v greadlink >/dev/null 2>&1 && READLINK=greadlink || READLINK=readlink
command -v gdirname  >/dev/null 2>&1 && DIRNAME=gdirname  || DIRNAME=dirname
# yosys' data dir (cells_sim.v etc.).  For an in-tree, non-installed build --
# like the pinned deps/yosys -- the share sits NEXT TO the binary and
# `yosys-config --datdir` wrongly returns the compiled-in /usr/local prefix.
# So: prefer the build-tree share, then a yosys-config that actually resolves,
# then a derived path.  ($YOSYS may be a bare PATH name like "yosys".)
YOSYS_RESOLVED=$(command -v "$YOSYS" 2>/dev/null || echo "$YOSYS")
YDIR=$($DIRNAME "$($READLINK -f "$YOSYS_RESOLVED")")
if   [ -f "$YDIR/share/xilinx/cells_sim.v" ];       then YSHARE="$YDIR/share"
elif [ -f "$YDIR/share/yosys/xilinx/cells_sim.v" ]; then YSHARE="$YDIR/share/yosys"
elif command -v "${YOSYS}-config" >/dev/null 2>&1 && \
     [ -f "$("${YOSYS}-config" --datdir)/xilinx/cells_sim.v" ]; then
  YSHARE=$("${YOSYS}-config" --datdir)
elif command -v yosys-config >/dev/null 2>&1 && \
     [ -f "$(yosys-config --datdir)/xilinx/cells_sim.v" ]; then
  YSHARE=$(yosys-config --datdir)
else
  YSHARE="$($DIRNAME "$YDIR")/share/yosys"
fi

W=${W:-/tmp/svs_ibex_yosys}
CC=$W/cc
mkdir -p "$W"

if [ "$STAGE" = "emit" ] || [ "$STAGE" = "all" ]; then
  echo "=== [1/2] emit FPGA-variant create_circuit netlist ==="
  eval "$(opam env --switch=${OPAM_SWITCH:-5.3.0} 2>/dev/null || opam env)"
  export SVS_DEFINE='FPGA_XILINX=1;PRIM_DEFAULT_IMPL=prim_pkg::ImplXilinx;VC707=1;SYNTHESIS=1'
  export MEMLOWER_FPGA=1 MEMLOWER_NO_LUTRAM=1
  export SVS_INCDIR="$REPO/vendor/lowrisc_ip/ip/prim/rtl:$REPO/vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils"
  export SVS_REPO="$REPO"        # roots the source paths in ibex_mini_svs.lua
  # Vivado-free primitive port directions (BUFG/IBUFDS/MMCME2_ADV/...): read the
  # committed cache instead of Vivado's unisim .vhd (absent on non-Vivado hosts).
  export XIL_PRIM_PORTS_JSON="${XIL_PRIM_PORTS_JSON:-$SVSROOT/xilinx_lef/xil_primitive_ports.json}"
  # Build the RAM image from source (needs an rv32 bare-metal gcc); baking it
  # into RAMB36 is what keeps the CPU from being optimised away.  Idempotent.
  export SRAM_INIT="$REPO/sw/mini/johnson.vmem"
  if ! make -s -C "$REPO/sw/mini" johnson.vmem; then
    echo "failed to build $SRAM_INIT -- need an rv32 bare-metal gcc (set CROSS=)" >&2
    exit 1
  fi
  # keep primitive #(...) params (RAMB36 INIT, MMCM config, BSCANE2 JTAG_CHAIN)
  export SVS_CIRC_KEEP_PARAMS=1
  export EMIT_CREATE_CIRCUIT="$CC"
  rm -rf "$CC"; mkdir -p "$CC"
  if ! "$SVS" script "$LUA" >"$W/emit.stdout" 2>"$W/emit.err"; then
    echo "SVS emit failed -- tail of $W/emit.err:" >&2
    tail -25 "$W/emit.err" >&2
    exit 1
  fi
  echo "  emitted $(ls "$CC"/*.v | wc -l) modules to $CC"
fi

if [ "$STAGE" = "synth" ] || [ "$STAGE" = "all" ]; then
  echo "=== [2/2] yosys synth_xilinx -> nextpnr JSON ==="
  # concat all create_circuit modules into one source
  SOC=$W/soc_fpga.v
  : > "$SOC"
  for f in "$CC"/*.v; do echo "// ==== $(basename "$f") ====" >> "$SOC"; cat "$f" >> "$SOC"; done
  TOP=$(grep -hoE "top_vc707_mini__[A-Za-z0-9]+" "$SOC" | head -1)
  echo "  top module: $TOP"
  "$YOSYS" -q -l "$W/yosys.log" -p "
    read_verilog -lib $YSHARE/xilinx/cells_sim.v
    read_verilog -lib $YSHARE/xilinx/cells_xtra.v
    read_verilog -sv $SOC
    hierarchy -top $TOP
    synth_xilinx -family xc7 -flatten ${SYNTH_XILINX_OPTS:-}
    write_json $W/ibex_fpga_yosys.json
    stat
  "
  echo "  wrote $W/ibex_fpga_yosys.json"
  # quick cell summary
  python3 - "$W/ibex_fpga_yosys.json" <<'PY'
import json,sys
from collections import Counter
d=json.load(open(sys.argv[1])); c=Counter()
for m in d['modules'].values():
    for cell in m.get('cells',{}).values(): c[cell['type']]+=1
lut=sum(v for k,v in c.items() if k.startswith('LUT'))
def g(*t): return sum(c.get(x,0) for x in t)
print(f"  LUT={lut} CARRY4={c.get('CARRY4',0)} DSP={g('DSP48E1','DSP48E2')} "
      f"FF={g('FDRE','FDCE','FDSE','FDPE')} RAMB36={c.get('RAMB36E1',0)} "
      f"BSCANE2={c.get('BSCANE2',0)} MMCM={c.get('MMCME2_ADV',0)} "
      f"IBUFDS={c.get('IBUFDS',0)} BUFG={c.get('BUFG',0)}")
PY
fi
echo "=== done ($STAGE) ==="
