/* benjamin xu benxu */

`timescale 1ns / 1ns

// quotient = dividend / divisor

module DividerUnsigned (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);
    wire [31:0] dividend_stage  [0:32];
    wire [31:0] remainder_stage [0:32];
    wire [31:0] quotient_stage  [0:32];

    assign dividend_stage[0]  = i_dividend;
    assign remainder_stage[0] = 32'd0;
    assign quotient_stage[0]  = 32'd0;

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : GEN_DIV
            DividerOneIter iter (
                .i_dividend  (dividend_stage[i]),
                .i_divisor   (i_divisor),
                .i_remainder (remainder_stage[i]),
                .i_quotient  (quotient_stage[i]),

                .o_dividend  (dividend_stage[i+1]),
                .o_remainder (remainder_stage[i+1]),
                .o_quotient  (quotient_stage[i+1])
            );
        end
    endgenerate

    assign o_quotient  = quotient_stage[32];
    assign o_remainder = remainder_stage[32];

endmodule


module DividerOneIter (
    input  wire [31:0] i_dividend,
    input  wire [31:0] i_divisor,
    input  wire [31:0] i_remainder,
    input  wire [31:0] i_quotient,
    output wire [31:0] o_dividend,
    output wire [31:0] o_remainder,
    output wire [31:0] o_quotient
);
    wire [31:0] next_remainder;
    assign next_remainder = (i_remainder << 1) | ((i_dividend >> 31) & 32'd1);

    wire lt;
    assign lt = (next_remainder < i_divisor);

    assign o_quotient = lt ? (i_quotient << 1) : ((i_quotient << 1) | 32'd1);
    assign o_remainder = lt ? (next_remainder) : (next_remainder - i_divisor);

    assign o_dividend = i_dividend << 1;

endmodule
