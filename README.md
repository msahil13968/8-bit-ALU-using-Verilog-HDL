# 8-bit ALU in Verilog HDL

A purely combinational 8-bit Arithmetic Logic Unit with arithmetic and logical
operations, status flags (zero, negative, carry, overflow) and a
**signed / unsigned mode** select. Verified with a self-checking testbench
that includes an **exhaustive** test over all 65,536 input pairs.

## Features
- 13 operations: ADD, SUB, AND, OR, XOR, NOT, INC, DEC, SLL, SRL/SRA, NAND, NOR, XNOR
- Overflow detection (mode dependent)
- Zero, negative and carry/borrow flags
- Signed (two's complement) and unsigned modes
- Latch-free combinational design (defaults assigned for every output)
- Directed + exhaustive self-checking testbench against an independent
  integer-arithmetic reference model

## Interface
| Port | Dir | Width | Description |
|------|-----|:-----:|-------------|
| `a`, `b` | in | 8 | Operands |
| `op` | in | 4 | Operation select |
| `signed_mode` | in | 1 | 0 = unsigned, 1 = signed (two's complement) |
| `result` | out | 8 | ALU result |
| `zero` | out | 1 | `result == 0` |
| `negative` | out | 1 | `result[7]` (sign bit, meaningful in signed mode) |
| `carry` | out | 1 | Carry-out (ADD/INC), borrow (SUB/DEC), bit shifted out (shifts) |
| `overflow` | out | 1 | Unsigned mode: result does not fit in 8 bits. Signed mode: two's-complement overflow |

## Operation table
| `op` | Mnemonic | Result |
|:----:|----------|--------|
| 0000 | ADD | `a + b` |
| 0001 | SUB | `a - b` |
| 0010 | AND | `a & b` |
| 0011 | OR | `a \| b` |
| 0100 | XOR | `a ^ b` |
| 0101 | NOT | `~a` |
| 0110 | INC | `a + 1` |
| 0111 | DEC | `a - 1` |
| 1000 | SLL | `a << 1` |
| 1001 | SRL / SRA | `a >> 1` (logical in unsigned mode, arithmetic in signed mode) |
| 1010 | NAND | `~(a & b)` |
| 1011 | NOR | `~(a \| b)` |
| 1100 | XNOR | `~(a ^ b)` |
| others | - | `0` |

## Overflow logic
| Operation | Unsigned mode | Signed mode |
|-----------|---------------|-------------|
| ADD | carry-out | `(a[7] == b[7]) && (sum[7] != a[7])` |
| SUB | borrow | `(a[7] != b[7]) && (diff[7] != a[7])` |
| INC | carry-out | `~a[7] & result[7]` |
| DEC | borrow | `a[7] & ~result[7]` |
| SLL | `a[7]` | `a[7] ^ result[7]` |

Examples:
- `100 + 28` → `0x80`: unsigned `overflow=0`, signed `overflow=1` (128 does not fit in int8)
- `255 + 1` → `0x00`: unsigned `carry=1, overflow=1, zero=1`; signed (`-1 + 1`) `overflow=0`

## Repository structure
```
.
├── rtl/alu_8bit.v          # design
├── tb/tb_alu_8bit.v        # self-checking testbench
├── Makefile
├── LICENSE
└── README.md
```

## How to run
Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/) and
(optionally) GTKWave.

```bash
make sim     # compile + run; prints [ OK ] / [FAIL] lines and a final RESULT
make wave    # open sim/alu.vcd in GTKWave
make clean
```

Vivado: add `rtl/alu_8bit.v` as a design source and `tb/tb_alu_8bit.v` as a
simulation source (create a `sim/` folder or edit the `$dumpfile` path).

## Tools
Verilog HDL · Icarus Verilog · GTKWave · Xilinx Vivado

## Author
**Muhammad Sahil** — M.Tech (Signal Processing & ML), NIT Jalandhar
