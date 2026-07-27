// Custom riscv-tests environment for the ibex-mini SoC (M-only, RV32IMC, U).
// The stock env/p does S-mode/PMP setup (sptbr, medeleg, pmpcfg0) that the
// minimal ibex-mini does not implement and would trap on.  This env runs every
// test in M-mode, needs no HTIF: PASS/FAIL is signalled by writing gp to a
// `tohost` word in RAM and spinning, so the debugger can halt and read either
// gp (x3) or the tohost word.  gp==1 => PASS; otherwise gp==2*failtestnum+1.
#ifndef _ENV_IBEX_MINI_H
#define _ENV_IBEX_MINI_H

#include "encoding.h"

#define TESTNUM gp

// The rv32 tests redefine RVTEST_RV64* -> RVTEST_RV32*, so define both.
#define RVTEST_RV32U  .macro init; .endm
#define RVTEST_RV32UF .macro init; .endm
#define RVTEST_RV32M  .macro init; .endm
#define RVTEST_RV32S  .macro init; .endm
#define RVTEST_RV64U  .macro init; .endm
#define RVTEST_RV64UF .macro init; .endm
#define RVTEST_RV64M  .macro init; .endm
#define RVTEST_RV64S  .macro init; .endm

#define INTERRUPT_HANDLER j other_exception

/* ibex trap vector = boot_addr (0x00100000, 256-aligned), VECTORED
   (mtvec[1:0]=01): interrupts jump to base+4*cause, synchronous exceptions
   (incl. ecall) to base+0.  The vector table therefore holds JUMPS ONLY — one
   4-byte `j trap_entry` per cause slot — and the handler proper lives outside
   it.  ibex's RESET PC is boot_addr + 0x80, so _start sits at base+0x80 (right
   above the 0x80-byte vector table) and the CPU boots straight into it — no
   debugger needed to set pc in simulation. */
#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                           \
        .option push;                                                  \
        .option norvc;   /* vector slots must be 4-byte jumps */        \
        .weak mtvec_handler;                                           \
        .globl mtvec_base;                                             \
        .globl _start;                                                 \
mtvec_base:                                                            \
        /* ibex trap vector base = boot_addr (0x00100000), VECTORED.    \
           JUMPS ONLY: one 4-byte slot per cause (exceptions -> slot 0, \
           interrupts -> base + 4*cause).  _start is NOT in the table. */ \
        .rept 32;                                                      \
        j trap_entry;                                                  \
        .endr;                                                         \
        . = mtvec_base + 0x80;                                         \
_start:                  /* ibex reset PC = boot_addr + 0x80 */         \
        j reset_vector;                                                \
        .option pop;                                                   \
trap_entry:              /* handler lives OUTSIDE the vector table */   \
        csrr t5, mcause;                                               \
        li t6, CAUSE_MACHINE_ECALL;                                    \
        beq t5, t6, write_tohost;                                      \
        li t6, CAUSE_USER_ECALL;                                       \
        beq t5, t6, write_tohost;                                      \
        la t5, mtvec_handler;                                          \
        beqz t5, 1f;                                                   \
        jr t5;                                                         \
  1:    csrr t5, mcause;                                               \
        bgez t5, handle_exception;                                     \
        INTERRUPT_HANDLER;                                             \
handle_exception:                                                      \
  other_exception:                                                     \
        ori TESTNUM, TESTNUM, 1337;                                    \
write_tohost:                                                          \
        sw TESTNUM, tohost, t5;                                        \
        j write_tohost;                                                \
reset_vector:                                                          \
        li TESTNUM, 0;                                                 \
        la t0, mtvec_base;                                             \
        ori t0, t0, 1;   /* vectored mode */                           \
        csrw mtvec, t0;                                                \
        csrwi mstatus, 0;                                              \
        init;                                                          \
        /* fall through into the test body, running in M-mode */       \
1:

#define RVTEST_CODE_END unimp

#define RVTEST_PASS                                                    \
        fence;                                                         \
        li TESTNUM, 1;                                                 \
        ecall

#define RVTEST_FAIL                                                    \
        fence;                                                         \
  1:    beqz TESTNUM, 1b;                                              \
        sll TESTNUM, TESTNUM, 1;                                       \
        or TESTNUM, TESTNUM, 1;                                        \
        ecall

#define RVTEST_DATA_BEGIN                                              \
        .pushsection .tohost,"aw",@progbits;                          \
        .align 6; .global tohost; tohost: .dword 0;                    \
        .align 6; .global fromhost; fromhost: .dword 0;                \
        .popsection;                                                   \
        .align 4; .global begin_signature; begin_signature:

#define RVTEST_DATA_END .align 4; .global end_signature; end_signature:

#endif
