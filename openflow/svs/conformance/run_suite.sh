#!/usr/bin/env bash
# Run the RISC-V conformance suite on one Verilator sim binary.
# usage: run_suite.sh <sim-binary> <vmem-dir> <elf-dir> <label>
set -uo pipefail
SIM="$1"; VMEMDIR="$2"; ELFDIR="$3"; LABEL="$4"
OBJDUMP="${OBJDUMP:-riscv32-unknown-elf-objdump}"
pass=0; fail=0; other=0; faillist=""
for vm in "$VMEMDIR"/*.vmem; do
  [ -e "$vm" ] || { echo "no vmems in $VMEMDIR"; exit 2; }
  nm=$(basename "$vm" .vmem)
  th=$("$OBJDUMP" -t "$ELFDIR/$nm.elf" 2>/dev/null | awk '$NF=="tohost"{print $1; exit}')
  res=$(timeout "${TEST_TIMEOUT:-20}" "$SIM" +VMEM="$vm" +TOHOST="$th" 2>/dev/null \
        | grep -oE 'TOHOST [0-9a-f]{8}|TIMEOUT' | head -1)
  val=${res#TOHOST }
  if   [ "$val" = "00000001" ]; then pass=$((pass+1))
  elif [ "$res" = "TIMEOUT" ] || [ -z "$res" ]; then other=$((other+1)); faillist="$faillist $nm(to)"
  else fail=$((fail+1)); faillist="$faillist $nm(gp=$val)"; fi
done
printf '%-10s  PASS=%-3d FAIL=%-3d TIMEOUT=%-3d  of %d\n' \
  "$LABEL" "$pass" "$fail" "$other" "$((pass+fail+other))"
[ -n "$faillist" ] && printf '   non-pass:%s\n' "$faillist"
# non-zero exit if not all passed (so `make` surfaces it)
[ "$fail" -eq 0 ] && [ "$other" -eq 0 ]
