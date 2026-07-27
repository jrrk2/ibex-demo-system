# Build the ibex mini-system firmware (RAM images for the SVS open flow).
# `make johnson.vmem` produces the SRAM_INIT image run_yosys_flow.sh bakes into
# RAMB36; `make` builds all PROGS.  Toolchain prefix is auto-detected (any
# rv32 bare-metal gcc); override with CROSS=.
CROSS   ?= $(or $(shell for p in riscv32-unknown-elf- riscv64-unknown-elf- riscv-none-elf- riscv64-elf-; do command -v $${p}gcc >/dev/null 2>&1 && echo $$p && break; done),riscv32-unknown-elf-)
CC       = $(CROSS)gcc
OBJCOPY  = $(CROSS)objcopy
OBJDUMP  = $(CROSS)objdump
ARCH    ?= rv32im_zicsr
ABI     ?= ilp32

CFLAGS   = -march=$(ARCH) -mabi=$(ABI) -Os -ffreestanding -nostdlib -Wall -Wextra \
           -fno-tree-loop-distribute-patterns
LDFLAGS  = -march=$(ARCH) -mabi=$(ABI) -nostdlib -T link.ld -Wl,--no-warn-rwx-segments

# Each program is <name>.c linked with crt0.o via link.ld.
PROGS   ?= johnson led_count

all: $(addsuffix .vmem,$(PROGS))

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.elf: %.o crt0.o link.ld
	$(CC) $(LDFLAGS) crt0.o $< -o $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

# 32-bit-word vmem for $readmemh (ram_2p MemInitFile), little-endian words.
%.vmem: %.bin
	od -An -tx4 -w4 -v $< | awk '{print $$1}' > $@

%.dis: %.elf
	$(OBJDUMP) -d $< > $@

clean:
	rm -f *.o *.elf *.bin *.vmem *.dis

# crt0.o and the *.elf/*.bin are reusable, not throwaway intermediates.
.PRECIOUS: crt0.o %.o %.elf %.bin
.PHONY: all clean
