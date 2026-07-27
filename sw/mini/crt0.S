# Minimal crt0 for the cut-down ibex mini system.
# Ibex takes its reset vector at boot_addr_i + 0x80; the mini SoC sets
# boot_addr_i = 0x0010_0000, so _start must land at 0x0010_0080.
    .section .vectors, "ax"
    .option norvc
    .org 0x00
    j    _start            # exception/reset base lands here too (mtvec = base)
    .org 0x80
    .globl _start
_start:
    la   sp, _stack_top
    csrw mie, zero         # no interrupts
    csrw mip, zero
    csrwi 0x320, 0         # mcountinhibit = 0 -> mcycle counts (1 Hz timebase)

    # zero .bss
    la   t0, _bss_start
    la   t1, _bss_end
1:  bge  t0, t1, 2f
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    1b
2:
    call main
hang:
    j    hang
