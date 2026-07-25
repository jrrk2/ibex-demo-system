#!/usr/bin/env bash
# Dual-VCD xsim build: compile a netlist (behavioral OR gate-mapped) + the
# ibex_mini_system wrapper + tb_mini_vcd + glbl + UNISIMs, run, dump <tag>.vcd.
#   usage: build_xsim.sh <netlist.v> <tag>
#   e.g.:  build_xsim.sh /tmp/svs_ibex_mini/ibex_mini_behav.v        beh
#          build_xsim.sh /tmp/svs_ibex_mini/ibex_mini_hier_novstub.v gate
set -uo pipefail
NETLIST="${1:?need netlist}"; TAG="${2:?need tag}"
W="${W:-/tmp/svs_ibex_mini}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VH="${XILINX_VIVADO:-/home/Xilinx/Vivado/2020.1}"
export PATH="$VH/bin:$PATH"
RUN="$W/xsim_$TAG"; rm -rf "$RUN"; mkdir -p "$RUN"; cd "$RUN"

# name-stable ibex_mini_system alias for this netlist
W="$W" bash "$HERE/gen_wrappers.sh" >/dev/null 2>&1 || true

echo "[xsim:$TAG] xvlog ..."
xvlog -sv "$VH/data/verilog/src/glbl.v" "$NETLIST" "$W/mini_wrap.sv" "$HERE/tb_mini_vcd.sv" \
  > xvlog.log 2>&1
rc=$?; if [ $rc -ne 0 ]; then echo "[xsim:$TAG] xvlog FAILED"; tail -20 xvlog.log; exit $rc; fi

echo "[xsim:$TAG] xelab ..."
xelab -L unisims_ver -L secureip -timescale 1ns/1ps \
  tb_ibex_mini glbl -s ${TAG}_snap > xelab.log 2>&1
rc=$?; if [ $rc -ne 0 ]; then echo "[xsim:$TAG] xelab FAILED"; grep -iE "error|ERROR" xelab.log | head; exit $rc; fi

echo "[xsim:$TAG] xsim run ..."
xsim ${TAG}_snap -runall -testplusarg "VCD=$W/mini_$TAG.vcd" > xsim.log 2>&1
rc=$?
echo "[xsim:$TAG] LED ticks / result:"; grep -iE "\[tb\]|LED=|PASS|TIMEOUT|Error" xsim.log | head -20
ls -la "$W/mini_$TAG.vcd" 2>/dev/null
exit $rc
