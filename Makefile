# RISC-V Audiomark: Q15 AXPY (RVV)
# Usage:
#   make            # build
#   make run        # run on Spike
#   make disasm     # disassemble q15_axpy_rvv
#   make log        # run Spike with instruction log
#   make clean

RISCV_PREFIX ?= riscv64-unknown-elf-
CC           := $(RISCV_PREFIX)gcc
OBJDUMP      := $(RISCV_PREFIX)objdump

SPIKE ?= spike
PK    ?= pk

SRC  := src/q15_axpy_challenge.c
ELF  := q15_axpy.elf

# Target ISA: RV64 + GCV + Zicntr (needed for rdcycle)
ARCH ?= rv64gcv_zicntr
ABI  ?= lp64

CFLAGS  := -O2 -march=$(ARCH) -mabi=$(ABI) -Wall -Wextra

# Spike ISA must include 'v' and zicntr for rdcycle
SPIKE_ISA ?= $(ARCH)

.PHONY: all clean run disasm log

all: $(ELF)

$(ELF): $(SRC)
	$(CC) $(CFLAGS) $< -o $@

run: $(ELF)
	$(SPIKE) --isa=$(SPIKE_ISA) $(PK) ./$(ELF)

disasm: $(ELF)
	$(OBJDUMP) -d ./$(ELF) | sed -n '/<q15_axpy_rvv>:/,/^$$/p' | head -160

log: $(ELF)
	$(SPIKE) --isa=$(SPIKE_ISA) -l --log=run.log $(PK) ./$(ELF)
	@echo "Wrote run.log"
	@grep -n -E "vsetvli|vle|vse|vwmacc|vwmul|vnclip|vadd" run.log | head -40 || true

clean:
	rm -f $(ELF) run.log

