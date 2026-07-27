#!/bin/bash
# ---------------------------------------------------------------------------
# Run the RISC-V ISA conformance suite (rv32ui + rv32um) on the VC707 via
# openocd JTAG, against the flashed open-flow (SVS/yosys+place_lef) ibex bit.
# Each test ELF is loaded into RAM over JTAG (progbuf), run, and its `gp`
# result read back (gp==1 => PASS, else 2*testnum+1).  Requires the board
# flashed with ibex_yosys.bit and the FTDI JTAG cable attached.
#
#   ELFDIR=/tmp/svs_conformance/elf ./run_conformance_openocd.sh
# ---------------------------------------------------------------------------
set -eu
# GNU coreutils: on macOS `dirname` is the g-prefixed brew tool.
command -v gdirname >/dev/null 2>&1 && DIRNAME=gdirname || DIRNAME=dirname
HERE=$(cd "$($DIRNAME "$0")" && pwd)
OPENOCD=${OPENOCD:-/home/jonathan/riscv-openocd/src/openocd}
ELFDIR=${ELFDIR:-/tmp/svs_conformance/elf}      # built by conformance/Makefile
ENTRY=0x00100080                                # ibex reset PC = boot_addr+0x80
CFG=$(mktemp /tmp/ocd_conf.XXXXXX.cfg)

# openocd connection header (BSCANE2 USER chains; progbuf mem access — sysbus
# is not implemented on this DM config).
sed -e 's/^init$//' -e '/^halt$/,$d' "$HERE/../ibex_diag.cfg" > "$CFG" 2>/dev/null || {
  cat > "$CFG" <<'HDR'
adapter driver ftdi
transport select jtag
ftdi vid_pid 0x0403 0x6010
ftdi channel 0
ftdi layout_init 0x0088 0x008b
ftdi tdo_sample_edge falling
reset_config none
jtag newtap riscv cpu -irlen 6 -expected-id 0x03687093 -ignore-version
target create riscv.cpu riscv -chain-position riscv.cpu
riscv set_ir idcode 0x09
riscv set_ir dtmcs 0x22
riscv set_ir dmi 0x23
gdb_port disabled
tcl_port disabled
telnet_port disabled
adapter speed 1000
riscv set_command_timeout_sec 20
HDR
}
cat >> "$CFG" <<HDR
riscv set_mem_access progbuf
init
proc run_test {name elf} {
  halt
  load_image \$elf
  reg pc $ENTRY
  resume
  after 300
  halt
  set gp [dict get [get_reg gp] gp]
  if {\$gp == 1} { echo "RESULT \$name PASS" } else { echo "RESULT \$name FAIL gp=\$gp" }
}
HDR
for e in $(ls "$ELFDIR"/*.elf | sort); do
  n=$(basename "$e" .elf); echo "run_test $n $e" >> "$CFG"
done
echo shutdown >> "$CFG"

LOG=$(mktemp /tmp/ocd_conf_run.XXXXXX.log)
"$OPENOCD" -f "$CFG" > "$LOG" 2>&1 || true
grep "RESULT" "$LOG" || { echo "no results — openocd tail:"; tail -20 "$LOG"; exit 1; }
P=$(grep -c 'RESULT.*PASS' "$LOG" || true); F=$(grep -c 'RESULT.*FAIL' "$LOG" || true)
echo "==== conformance (open-flow silicon): PASS=$P FAIL=$F of $((P+F)) ===="
grep 'RESULT.*FAIL' "$LOG" || true
