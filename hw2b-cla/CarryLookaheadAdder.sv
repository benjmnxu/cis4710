`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits internally would generate a carry-out (independent of cin)
 * @param pout whether these 4 bits internally would propagate an incoming carry from cin
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

   assign cout[0] = gin[0] | (pin[0] & cin);
   assign cout[1] = gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)));
   assign cout[2] = gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))));

   assign pout = pin[0] & pin[1] & pin[2] & pin[3];
   assign gout = gin[3] | (pin[3] & gin[2]) | (pin[3] & pin[2] & gin[1]) | (pin[3] & pin[2] & pin[1] & gin[0]);

endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(input wire [7:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [6:0] cout);

   wire g_lo;
   wire p_lo;
   wire g_hi;
   wire p_hi;
   wire[2:0] c_lo;
   wire[2:0] c_hi;
   wire c_temp;

   gp4 lo(
      .gin(gin[3:0]),
      .pin(pin[3:0]),
      .cin(cin),
      .gout(g_lo),
      .pout(p_lo),
      .cout(c_lo)
   );

   assign c_temp = g_lo | (p_lo & cin);

   gp4 hi(
      .gin(gin[7:4]),
      .pin(pin[7:4]),
      .cin(c_temp),
      .gout(g_hi),
      .pout(p_hi),
      .cout(c_hi)
   );

   assign cout[2:0] = c_lo;
   assign cout[6:4] = c_hi;
   assign cout[3] = c_temp;

   assign pout = p_hi & p_lo;
   assign gout = g_hi | (p_hi & g_lo);

endmodule

module CarryLookaheadAdder
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);

   wire [31:0] g, p;
   genvar i;
   generate
      for (i = 0; i < 32; i = i + 1) begin : GP_BITS
         assign g[i] = a[i] & b[i];
         assign p[i] = a[i] ^ b[i];
      end
   endgenerate

   wire g0,p0,g1,p1,g2,p2,g3,p3;
   wire [6:0] c0, c1, c2, c3;
   wire c8, c16, c24;

   gp8 B0(.gin(g[7:0]),   .pin(p[7:0]),   .cin(cin), .gout(g0), .pout(p0), .cout(c0));
   assign c8  = g0 | (p0 & cin);

   gp8 B1(.gin(g[15:8]),  .pin(p[15:8]),  .cin(c8),  .gout(g1), .pout(p1), .cout(c1));
   assign c16 = g1 | (p1 & c8);

   gp8 B2(.gin(g[23:16]), .pin(p[23:16]), .cin(c16), .gout(g2), .pout(p2), .cout(c2));
   assign c24 = g2 | (p2 & c16);

   gp8 B3(.gin(g[31:24]), .pin(p[31:24]), .cin(c24), .gout(g3), .pout(p3), .cout(c3));

   wire [31:0] c_in;
   assign c_in[0]     = cin;
   assign c_in[7:1]   = c0[6:0];
   assign c_in[8]     = c8;
   assign c_in[15:9]  = c1[6:0];
   assign c_in[16]    = c16;
   assign c_in[23:17] = c2[6:0];
   assign c_in[24]    = c24;
   assign c_in[31:25] = c3[6:0];

   assign sum = p ^ c_in;

endmodule
