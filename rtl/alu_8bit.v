//==============================================================================
// Module  : alu_8bit
// Project : 8-bit ALU in Verilog HDL
// Author  : Muhammad Sahil
//
// Description
//   Purely combinational 8-bit ALU with arithmetic and logical operations,
//   status flags, and a signed / unsigned mode select.
//
//   op      Operation            Result
//   ----    -------------------  --------------------------------------------
//   0000    ADD                  a + b
//   0001    SUB                  a - b
//   0010    AND                  a & b
//   0011    OR                   a | b
//   0100    XOR                  a ^ b
//   0101    NOT                  ~a
//   0110    INC                  a + 1
//   0111    DEC                  a - 1
//   1000    SLL                  a << 1
//   1001    SRL / SRA            a >> 1  (logical if unsigned, arithmetic if signed)
//   1010    NAND                 ~(a & b)
//   1011    NOR                  ~(a | b)
//   1100    XNOR                 ~(a ^ b)
//   others  -                    0
//
//   Flags
//     zero      : result == 0
//     negative  : result[7]  (the sign bit; meaningful in signed mode)
//     carry     : bit 8 of the 9-bit arithmetic result.
//                 ADD/INC: carry-out.  SUB/DEC: borrow (a < b).
//                 SLL: bit shifted out (a[7]).  SRL/SRA: bit shifted out (a[0]).
//                 Logic ops: 0.
//     overflow  : mode dependent
//                 signed_mode = 0 (unsigned): result does not fit in 8 bits
//                                             (carry-out / borrow).
//                 signed_mode = 1 (signed)  : two's-complement overflow.
//==============================================================================
`timescale 1ns / 1ps

module alu_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [3:0] op,
    input  wire       signed_mode,   // 0 = unsigned, 1 = signed (two's complement)
    output reg  [7:0] result,
    output reg        zero,
    output reg        negative,
    output reg        carry,
    output reg        overflow
);

    // ---------------- opcodes ----------------
    localparam [3:0] OP_ADD  = 4'b0000;
    localparam [3:0] OP_SUB  = 4'b0001;
    localparam [3:0] OP_AND  = 4'b0010;
    localparam [3:0] OP_OR   = 4'b0011;
    localparam [3:0] OP_XOR  = 4'b0100;
    localparam [3:0] OP_NOT  = 4'b0101;
    localparam [3:0] OP_INC  = 4'b0110;
    localparam [3:0] OP_DEC  = 4'b0111;
    localparam [3:0] OP_SLL  = 4'b1000;
    localparam [3:0] OP_SHR  = 4'b1001;   // SRL (unsigned) / SRA (signed)
    localparam [3:0] OP_NAND = 4'b1010;
    localparam [3:0] OP_NOR  = 4'b1011;
    localparam [3:0] OP_XNOR = 4'b1100;

    reg [8:0] sum;   // 9-bit arithmetic result (bit 8 = carry / borrow)

    always @(*) begin
        // defaults (avoid latches)
        sum      = 9'd0;
        result   = 8'd0;
        carry    = 1'b0;
        overflow = 1'b0;

        case (op)
            OP_ADD: begin
                sum      = {1'b0, a} + {1'b0, b};
                result   = sum[7:0];
                carry    = sum[8];
                overflow = signed_mode ? (~(a[7] ^ b[7]) & (a[7] ^ sum[7]))
                                       : sum[8];
            end

            OP_SUB: begin
                sum      = {1'b0, a} - {1'b0, b};
                result   = sum[7:0];
                carry    = sum[8];                 // borrow
                overflow = signed_mode ? ((a[7] ^ b[7]) & (a[7] ^ sum[7]))
                                       : sum[8];
            end

            OP_AND:  result = a & b;
            OP_OR:   result = a | b;
            OP_XOR:  result = a ^ b;
            OP_NOT:  result = ~a;
            OP_NAND: result = ~(a & b);
            OP_NOR:  result = ~(a | b);
            OP_XNOR: result = ~(a ^ b);

            OP_INC: begin
                sum      = {1'b0, a} + 9'd1;
                result   = sum[7:0];
                carry    = sum[8];
                overflow = signed_mode ? (~a[7] & sum[7]) : sum[8];
            end

            OP_DEC: begin
                sum      = {1'b0, a} - 9'd1;
                result   = sum[7:0];
                carry    = sum[8];                 // borrow
                overflow = signed_mode ? (a[7] & ~sum[7]) : sum[8];
            end

            OP_SLL: begin
                result   = {a[6:0], 1'b0};
                carry    = a[7];
                overflow = signed_mode ? (a[7] ^ result[7]) : a[7];
            end

            OP_SHR: begin
                result = signed_mode ? {a[7], a[7:1]}   // arithmetic
                                     : {1'b0, a[7:1]};  // logical
                carry  = a[0];
            end

            default: result = 8'd0;
        endcase

        zero     = (result == 8'd0);
        negative = result[7];
    end

endmodule
