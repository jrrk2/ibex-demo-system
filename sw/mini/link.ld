/* Minimal linker script for the ibex mini system.
   RAM is 16 KiB at 0x0010_0000 (matches ibex_mini_system MEM_SIZE).  Reset
   vector is boot_addr + 0x80 = 0x0010_0080 (provided by crt0 .vectors). */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  ram (rwx) : ORIGIN = 0x00100000, LENGTH = 0x4000  /* 16 KiB */
}

SECTIONS {
  .text : {
    KEEP(*(.vectors))          /* 0x00..0x80: boot/exception base + _start */
    *(.text*)
  } > ram

  .rodata : {
    . = ALIGN(4);
    *(.rodata*)
    *(.srodata*)
  } > ram

  .data : {
    . = ALIGN(4);
    *(.data*)
    *(.sdata*)
  } > ram

  .bss : {
    . = ALIGN(4);
    _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > ram

  . = ALIGN(4);
  _stack_top = ORIGIN(ram) + LENGTH(ram);
}
