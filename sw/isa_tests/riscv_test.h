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

/* ibex FORCES mtvec into VECTORED mode (mtvec[1:0]=01) with a 256-byte
   aligned base.  In vectored mode synchronous EXCEPTIONS (incl. ecall) jump
   to base+0, not base+4*cause.  So the trap handler MUST sit at the mtvec
   base.  We make the base = start of .text.init (0x00100000, already
   256-aligned), place the handler there, and put _start AFTER it — the
   debugger sets pc = ELF entry (_start) after load, so _start need not be at
   the image base. */
#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                           \
        .align 8;                                                      \
        .weak mtvec_handler;                                           \
        .globl mtvec_base;                                             \
        .globl _start;                                                 \
mtvec_base:                                                            \
        j trap_entry;                                                  \
        .align 2;                                                      \
trap_entry:                                                            \
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
_start:                                                                \
        j reset_vector;                                                \
reset_vector:                                                          \
        li TESTNUM, 0;                                                 \
        la t0, mtvec_base;                                             \
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
