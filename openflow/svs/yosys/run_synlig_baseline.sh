#!/bin/bash
# ---------------------------------------------------------------------------
# Independent baseline: ibex-mini RTL -> synlig (Surelog+yosys) -> synth_xilinx
# -> nextpnr JSON.  Bypasses SVS entirely, to compare netlist quality AND
# routability against the SVS-create_circuit yosys flow.  (RAM INIT is not
# loaded here — irrelevant to the routability question; patch later for a
# functional bit.)
# ---------------------------------------------------------------------------
set -eu
REPO=/home/jonathan/v7-johnson-demo/ibexsoc
LUA=$REPO/openflow/svs/ibex_mini_svs.lua
SYNLIG=/home/jonathan/synlig/build/release/synlig/synlig
# GNU coreutils: on macOS `readlink -f`/`dirname` are the g-prefixed brew tools.
command -v greadlink >/dev/null 2>&1 && READLINK=greadlink || READLINK=readlink
command -v gdirname  >/dev/null 2>&1 && DIRNAME=gdirname  || DIRNAME=dirname
YSHARE=$($DIRNAME $($DIRNAME $($READLINK -f /home/jonathan/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys)))/share/yosys
W=${W:-/tmp/svs_ibex_synlig}
mkdir -p "$W"

# file list from the SVS lua (drop the .vmem-only helper if any)
grep -oE '/home/jonathan/v7-johnson-demo/ibexsoc/[^"]*\.sv' "$LUA" > "$W/files.txt"
echo "  $(wc -l < "$W/files.txt") source files"

INC="-I$REPO/vendor/lowrisc_ip/ip/prim/rtl -I$REPO/vendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils"
DEFS="-DFPGA_XILINX=1 -DVC707=1 -DSYNTHESIS=1 -DPRIM_DEFAULT_IMPL=prim_pkg::ImplXilinx"

echo "=== synlig read_systemverilog + synth_xilinx ==="
"$SYNLIG" -ql "$W/synlig.log" -p "
  read_systemverilog -defer $DEFS $INC $(cat "$W/files.txt" | tr '\n' ' ')
  read_systemverilog -link
  read_verilog -lib $YSHARE/xilinx/cells_sim.v
  read_verilog -lib $YSHARE/xilinx/cells_xtra.v
  hierarchy -top top_vc707_mini
  synth_xilinx -family xc7 -flatten ${SYNTH_XILINX_OPTS:-}
  write_json $W/ibex_synlig.json
  stat
" 2>&1 | tail -6
echo "  wrote $W/ibex_synlig.json"
python3 - "$W/ibex_synlig.json" <<'PY'
import json,sys
from collections import Counter
d=json.load(open(sys.argv[1])); c=Counter()
for m in d['modules'].values():
    for cell in m.get('cells',{}).values(): c[cell['type']]+=1
lut=sum(v for k,v in c.items() if k.startswith('LUT'))
def g(*t): return sum(c.get(x,0) for x in t)
print(f"  LUT={lut} CARRY4={c.get('CARRY4',0)} DSP={g('DSP48E1','DSP48E2')} "
      f"FF={g('FDRE','FDCE','FDSE','FDPE')} RAMB36={c.get('RAMB36E1',0)} "
      f"BSCANE2={c.get('BSCANE2',0)} MMCM={c.get('MMCME2_ADV',0)}")
PY
