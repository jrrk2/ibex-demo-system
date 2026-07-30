#!/bin/bash
# Phase 3: closed slack-driven hold-fix loop, fully in-process per iteration.
#
#   place_lef (targeted hold buffers) -> carry_stamp -> nextpnr route
#   -> nextpnr's IN-PROCESS hold analysis exports the sub-margin hold endpoints
#   -> next iteration's place_lef buffers exactly those -> re-route -> re-check
#   ... until nextpnr exports ZERO targets (hold clean) or MAX_ITER.
#
# The rolling target file NEXTPNR_HOLD_TARGETS is READ by place_lef (Phase 2c,
# place_lef_core insert_hold_buffers) at step 2 and OVERWRITTEN by nextpnr
# (Phase 2b, timing.cc) at step 4 -- so each pass buffers the previous pass's
# marginal FFs and re-measures.  OpenSTA (run_sta_rc.sh) is the periodic signoff.
#
# Requires a VALID place_lef input netlist (regenerate ibex_fpga_yosys.json if
# stale).  Each iteration ~= place_lef 15 min + route 10 min.
set -eu
# env-overridable so the top-level Makefile can drive it (passes ROOT/W/SVS/
# NEXTPNR/CHIPDB, all forwarded to place_route_yosys.sh via the environment).
ROOT=${ROOT:-/home/jonathan/v7-johnson-demo}
W=${W:-$ROOT/build/ibex_yosys}
FLOW=${FLOW:-$ROOT/ibexsoc/openflow/svs/yosys/place_route_yosys.sh}
TGT=$W/hold_targets.txt
MARGIN=${HOLD_MARGIN_NS:-0.05}   # only buffer endpoints with hold slack < this
MAX_ITER=${MAX_ITER:-6}

rm -f "$TGT"
for it in $(seq 0 $MAX_ITER); do
  echo "############ hold-loop iteration $it ############"
  if [ "$it" -eq 0 ]; then
    unset FPGA_HOLD_LUT1 || true                 # baseline: measure, don't buffer
  else
    export FPGA_HOLD_LUT1=1                       # buffer last pass's targets
  fi
  # nextpnr exports the NEW sub-margin targets to the same file (overwrites).
  export NEXTPNR_HOLD_TARGETS=$TGT NEXTPNR_HOLD_MARGIN_NS=$MARGIN
  bash "$FLOW" 2>&1 | grep -E "hold_lut1|Estimated worst hold slack|Wrote .* hold target|Max frequency" || true

  whs=$(grep -a "Estimated worst hold slack" "$W/route.log" | tail -1 | grep -oE '[-0-9.]+ ns' | head -1)
  n=$([ -f "$TGT" ] && wc -l < "$TGT" || echo 0)
  echo ">>> iter $it: worst hold slack = ${whs:-?}, remaining sub-margin targets = $n"
  if [ "$n" -eq 0 ]; then echo ">>> HOLD CLEAN (no sub-$MARGIN ns endpoints) -- converged in $it iteration(s)"; break; fi
done

echo "############ OpenSTA signoff ############"
bash "$ROOT/ethsoc/openflow/opentimer/run_sta_rc.sh" ibex_idx 2>&1 | grep -E "SETUP|HOLD|worst slack" || true
