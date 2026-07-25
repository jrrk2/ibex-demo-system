/* riscv-tests ISA test link map for the ibex-mini SoC.
   RAM 16 KiB at 0x0010_0000.  _start (in .text.init) is placed at the base;
   the debugger sets pc = ELF entry (_start) after load_image, so the natural
   boot vector offset is irrelevant.  tohost lands in RAM and is read back. */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  ram (rwx) : ORIGIN = 0x00100000, LENGTH = 0x4000
}

SECTIONS {
  .text.init : { KEEP(*(.text.init)) } > ram
  .text      : { *(.text*) } > ram
  .rodata    : { . = ALIGN(4); *(.rodata*) *(.srodata*) } > ram
  .data      : { . = ALIGN(4); *(.data*) *(.sdata*) } > ram
  .tohost    : { . = ALIGN(64); *(.tohost) } > ram
  .bss       : { . = ALIGN(4); *(.bss*) *(.sbss*) *(COMMON) } > ram
  _end = .;
}
