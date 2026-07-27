set(LINKER_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../common/link.ld")
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER riscv32-unknown-elf-gcc)
set(CMAKE_OBJCOPY riscv32-unknown-elf-objcopy)
set(CMAKE_C_FLAGS_INIT
    "-march=rv32imc_zicsr_zifencei -mabi=ilp32 -mcmodel=medany -Wall -fvisibility=hidden -ffreestanding")
set(CMAKE_ASM_FLAGS_INIT "-march=rv32imc_zicsr_zifencei -mabi=ilp32")
# Distro riscv64-unknown-elf gcc ships no newlib; the demo is freestanding.
set(CMAKE_EXE_LINKER_FLAGS_INIT "-nostartfiles -nostdlib -T \"${LINKER_SCRIPT}\"")
set(CMAKE_C_STANDARD_LIBRARIES "-lgcc")
