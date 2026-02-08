RISC-V Audiomark – Q15 AXPY RVV Implementation
Build

This project was built using the RISC-V GNU toolchain with RVV support.

Compile the program:

riscv64-unknown-elf-gcc -O2 \
  -march=rv64gcv_zicntr -mabi=lp64 \
  src/q15_axpy_challenge.c -o q15_axpy.elf


This enables:

rv64gcv → RV64 + vector extension

zicntr → cycle counter support for rdcycle

Run (Spike simulator)

Run the program using Spike with the vector extension enabled:

spike --isa=rv64gcv_zicntr pk ./q15_axpy.elf

## Makefile Usage (optional)

A simple Makefile is provided for convenience.

Build:
```bash
make

Run on Spike:
make run

Disassemble the RVV function:
make disasm

Run with instruction log:
make log


Results

Test configuration (from harness):

Input size: N = 4096

Alpha: 3

Simulator: Spike (rv64gcv_zicntr)

Cycle counter: rdcycle

Measured output:

Cycles ref: 53930
Verify RVV: OK (max diff = 0)
Cycles RVV: 10071

Speedup
Speedup = Cycles_ref / Cycles_RVV
        = 53930 / 10071
        ≈ 5.35×


Correctness: bit-for-bit identical to scalar reference

Maximum difference: 0

Design Choices
1. Vector-length agnostic loop

The implementation uses:

vsetvl_e16m1(n)


inside a while (n > 0) loop.
This ensures the function works correctly for any hardware vector length (VLEN).

2. Widened arithmetic for correctness

Scalar reference:

acc = (int32)a[i] + (int32)alpha * (int32)b[i]


To match this exactly:

a and b are widened to 32-bit

Computation is performed in 32-bit domain

Final result is saturated back to 16-bit

This guarantees bit-exact results.

3. Use of vwmacc (widening multiply-accumulate)

Instead of separate multiply and add:

vwmul + vadd


The implementation uses:

vwmacc


Advantages:

Fused multiply-add operation

Fewer vector instructions

Better mapping to real hardware execution units

4. Saturating narrow using vnclip

Final step:

vnclip (shift = 0)


This performs:

Saturation to int16 range

No rounding issues (shift = 0)

Single vector instruction instead of scalar clamps

5. Toolchain compatibility decision

Some toolchains report:

__riscv_v_intrinsic = 12000


instead of >=1000000 as assumed in some examples.
Therefore, the implementation:

Guards only on __riscv_vector

Avoids relying on specific intrinsic version values

This improves portability across different RVV toolchains.

6. Performance analysis:
The RVV implementation processes multiple Q15 elements per loop iteration by using vsetvli to select the maximum vector length supported by the target and operating on vl lanes at once. The computation is performed in widened 32-bit lanes to exactly match the scalar reference semantics (acc = (int32)a + (int32)alpha*(int32)b), then narrowed back to int16 with saturation using vnclip (shift=0). On Spike (--isa=rv64gcv_zicntr) with N=4096, the scalar reference measured 53,930 cycles and the RVV version measured 10,071 cycles, for a speedup of ~5.35×. This improvement comes from amortizing loop overhead (branches, pointer updates) and reducing per-element scalar operations by applying vector loads, widening multiply-accumulate, and saturating narrow over a whole vector of elements per iteration. Note that absolute cycle counts and speedup will vary across implementations depending on VLEN, memory bandwidth, and the microarchitecture’s vector pipelines.

Summary

Correctness: bit-exact match

Speedup (Spike): ~5.35×

VL-agnostic: yes

Works on: RV32 or RV64 with RVV
