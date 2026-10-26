//==============================================================================
// Self-checking testbench for alu_8bit
//   Part 1 : directed tests (corner cases for every operation and flag)
//   Part 2 : exhaustive test of all 65,536 (a,b) pairs, in both unsigned and
//            signed mode, for ADD, SUB, AND, OR, XOR against an independent
//            integer-arithmetic reference model.
//==============================================================================
`timescale 1ns / 1ps

module tb_alu_8bit;

    // opcodes
    localparam [3:0] ADD = 4'b0000, SUB = 4'b0001, AND_ = 4'b0010, OR_ = 4'b0011,
                     XOR_ = 4'b0100, NOT_ = 4'b0101, INC = 4'b0110, DEC = 4'b0111,
                     SLL = 4'b1000, SHR = 4'b1001, NAND_ = 4'b1010, NOR_ = 4'b1011,
                     XNOR_ = 4'b1100;

    reg  [7:0] a, b;
    reg  [3:0] op;
    reg        smode;
    wire [7:0] result;
    wire       zero, negative, carry, overflow;

    integer errors = 0;
    integer checks = 0;

    alu_8bit dut (
        .a(a), .b(b), .op(op), .signed_mode(smode),
        .result(result), .zero(zero), .negative(negative),
        .carry(carry), .overflow(overflow)
    );

    // ---------- helpers ----------
    task apply(input [3:0] o, input [7:0] x, input [7:0] y, input m);
        begin
            op = o; a = x; b = y; smode = m;
            #1;
        end
    endtask

    // compare result + all flags against expected values
    task cmp(input [7:0] e_res, input e_c, input e_v, input [255:0] name);
        reg e_z, e_n;
        begin
            checks = checks + 1;
            e_z = (e_res == 8'd0);
            e_n = e_res[7];
            if (result !== e_res || carry !== e_c || overflow !== e_v ||
                zero !== e_z || negative !== e_n) begin
                errors = errors + 1;
                if (errors <= 25)
                    $display("[FAIL] %0s : op=%b a=%h b=%h smode=%b | got res=%h c=%b v=%b z=%b n=%b | exp res=%h c=%b v=%b z=%b n=%b",
                             name, op, a, b, smode,
                             result, carry, overflow, zero, negative,
                             e_res, e_c, e_v, e_z, e_n);
            end else
                $display("[ OK ] %0s", name);
        end
    endtask

    // ---------- reference-model variables ----------
    integer i, j, m;
    integer ia, ib, s, sa, sb, ss;
    reg [7:0] e_res;
    reg       e_c, e_v;

    initial begin
        $dumpfile("sim/alu.vcd");
        $dumpvars(0, tb_alu_8bit);

        //----------------------------------------------------------------
        $display("--- Part 1: directed tests ---");
        //----------------------------------------------------------------
        // ADD
        apply(ADD, 8'd10,  8'd20,  0); cmp(8'd30, 0, 0, "ADD 10+20");
        apply(ADD, 8'd100, 8'd27,  0); cmp(8'd127,0, 0, "ADD 100+27 unsigned");
        apply(ADD, 8'd100, 8'd28,  1); cmp(8'h80, 0, 1, "ADD 100+28 signed overflow");
        apply(ADD, 8'd100, 8'd28,  0); cmp(8'h80, 0, 0, "ADD 100+28 unsigned no overflow");
        apply(ADD, 8'hFF,  8'h01,  0); cmp(8'h00, 1, 1, "ADD 255+1 unsigned carry, zero");
        apply(ADD, 8'hFF,  8'h01,  1); cmp(8'h00, 1, 0, "ADD -1+1 signed no overflow, zero");
        apply(ADD, 8'h80,  8'h80,  1); cmp(8'h00, 1, 1, "ADD -128+-128 signed overflow");

        // SUB
        apply(SUB, 8'd30,  8'd10,  0); cmp(8'd20, 0, 0, "SUB 30-10");
        apply(SUB, 8'd5,   8'd10,  0); cmp(8'hFB, 1, 1, "SUB 5-10 unsigned borrow");
        apply(SUB, 8'd5,   8'd10,  1); cmp(8'hFB, 1, 0, "SUB 5-10 signed = -5 (negative)");
        apply(SUB, 8'h80,  8'h01,  1); cmp(8'h7F, 0, 1, "SUB -128-1 signed overflow");
        apply(SUB, 8'h7F,  8'hFF,  1); cmp(8'h80, 1, 1, "SUB 127-(-1) signed overflow");
        apply(SUB, 8'd77,  8'd77,  0); cmp(8'h00, 0, 0, "SUB equal -> zero");

        // Logic
        apply(AND_,  8'hF0, 8'h3C, 0); cmp(8'h30, 0, 0, "AND");
        apply(OR_,   8'hF0, 8'h0F, 0); cmp(8'hFF, 0, 0, "OR");
        apply(XOR_,  8'hAA, 8'hFF, 0); cmp(8'h55, 0, 0, "XOR");
        apply(XOR_,  8'hA5, 8'hA5, 0); cmp(8'h00, 0, 0, "XOR same -> zero");
        apply(NOT_,  8'h0F, 8'h00, 0); cmp(8'hF0, 0, 0, "NOT");
        apply(NAND_, 8'hF0, 8'h3C, 0); cmp(8'hCF, 0, 0, "NAND");
        apply(NOR_,  8'hF0, 8'h0F, 0); cmp(8'h00, 0, 0, "NOR");
        apply(XNOR_, 8'hAA, 8'hAA, 0); cmp(8'hFF, 0, 0, "XNOR");

        // INC / DEC
        apply(INC, 8'd9,   8'd0, 0); cmp(8'd10, 0, 0, "INC 9");
        apply(INC, 8'hFF,  8'd0, 0); cmp(8'h00, 1, 1, "INC 255 unsigned wrap");
        apply(INC, 8'hFF,  8'd0, 1); cmp(8'h00, 1, 0, "INC -1 signed = 0");
        apply(INC, 8'h7F,  8'd0, 1); cmp(8'h80, 0, 1, "INC 127 signed overflow");
        apply(INC, 8'h7F,  8'd0, 0); cmp(8'h80, 0, 0, "INC 127 unsigned ok");
        apply(DEC, 8'd10,  8'd0, 0); cmp(8'd9,  0, 0, "DEC 10");
        apply(DEC, 8'h00,  8'd0, 0); cmp(8'hFF, 1, 1, "DEC 0 unsigned borrow");
        apply(DEC, 8'h00,  8'd0, 1); cmp(8'hFF, 1, 0, "DEC 0 signed = -1");
        apply(DEC, 8'h80,  8'd0, 1); cmp(8'h7F, 0, 1, "DEC -128 signed overflow");
        apply(DEC, 8'h80,  8'd0, 0); cmp(8'h7F, 0, 0, "DEC 128 unsigned ok");

        // Shifts
        apply(SLL, 8'h01, 8'd0, 0); cmp(8'h02, 0, 0, "SLL 01");
        apply(SLL, 8'h81, 8'd0, 0); cmp(8'h02, 1, 1, "SLL 81 unsigned carry out");
        apply(SLL, 8'h40, 8'd0, 1); cmp(8'h80, 0, 1, "SLL 40 signed sign change");
        apply(SLL, 8'h40, 8'd0, 0); cmp(8'h80, 0, 0, "SLL 40 unsigned ok");
        apply(SHR, 8'h81, 8'd0, 0); cmp(8'h40, 1, 0, "SRL 81 logical");
        apply(SHR, 8'h81, 8'd0, 1); cmp(8'hC0, 1, 0, "SRA 81 arithmetic");
        apply(SHR, 8'h02, 8'd0, 1); cmp(8'h01, 0, 0, "SRA 02");

        // Undefined opcode
        apply(4'b1111, 8'hAB, 8'hCD, 0); cmp(8'h00, 0, 0, "undefined opcode -> 0");

        //----------------------------------------------------------------
        $display("--- Part 2: exhaustive ADD/SUB/AND/OR/XOR (unsigned + signed) ---");
        //----------------------------------------------------------------
        // quiet loop: only failures are printed (cmp prints OK lines, so
        // we use a separate silent compare here)
        for (m = 0; m < 2; m = m + 1) begin
            for (i = 0; i < 256; i = i + 1) begin
                for (j = 0; j < 256; j = j + 1) begin
                    ia = i; ib = j;
                    sa = (i > 127) ? i - 256 : i;
                    sb = (j > 127) ? j - 256 : j;

                    // ---- ADD ----
                    apply(ADD, i[7:0], j[7:0], m[0]);
                    s = ia + ib;                    e_res = s & 255;
                    e_c = (s > 255);
                    ss = sa + sb;
                    e_v = m ? ((ss > 127) || (ss < -128)) : e_c;
                    checks = checks + 1;
                    if (result !== e_res || carry !== e_c || overflow !== e_v ||
                        zero !== (e_res == 8'd0) || negative !== e_res[7]) begin
                        errors = errors + 1;
                        if (errors <= 25)
                            $display("[FAIL] exhaustive ADD m=%0d a=%0d b=%0d got %h c%b v%b exp %h c%b v%b",
                                     m, i, j, result, carry, overflow, e_res, e_c, e_v);
                    end

                    // ---- SUB ----
                    apply(SUB, i[7:0], j[7:0], m[0]);
                    s = ia - ib;                    e_res = s & 255;
                    e_c = (s < 0);
                    ss = sa - sb;
                    e_v = m ? ((ss > 127) || (ss < -128)) : e_c;
                    checks = checks + 1;
                    if (result !== e_res || carry !== e_c || overflow !== e_v ||
                        zero !== (e_res == 8'd0) || negative !== e_res[7]) begin
                        errors = errors + 1;
                        if (errors <= 25)
                            $display("[FAIL] exhaustive SUB m=%0d a=%0d b=%0d got %h c%b v%b exp %h c%b v%b",
                                     m, i, j, result, carry, overflow, e_res, e_c, e_v);
                    end

                    // ---- AND / OR / XOR ----
                    apply(AND_, i[7:0], j[7:0], m[0]);
                    checks = checks + 1;
                    if (result !== (i[7:0] & j[7:0]) || carry !== 1'b0 || overflow !== 1'b0) begin
                        errors = errors + 1;
                        if (errors <= 25) $display("[FAIL] exhaustive AND a=%0d b=%0d", i, j);
                    end

                    apply(OR_, i[7:0], j[7:0], m[0]);
                    checks = checks + 1;
                    if (result !== (i[7:0] | j[7:0]) || carry !== 1'b0 || overflow !== 1'b0) begin
                        errors = errors + 1;
                        if (errors <= 25) $display("[FAIL] exhaustive OR a=%0d b=%0d", i, j);
                    end

                    apply(XOR_, i[7:0], j[7:0], m[0]);
                    checks = checks + 1;
                    if (result !== (i[7:0] ^ j[7:0]) || carry !== 1'b0 || overflow !== 1'b0) begin
                        errors = errors + 1;
                        if (errors <= 25) $display("[FAIL] exhaustive XOR a=%0d b=%0d", i, j);
                    end
                end
            end
        end

        //----------------------------------------------------------------
        $display("-----------------------------------------");
        $display("Checks run : %0d", checks);
        if (errors == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: %0d ERROR(S)", errors);
        $finish;
    end

endmodule
