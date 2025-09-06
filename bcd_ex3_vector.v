//Small vector helpers for BCD ↔ Excess-3 (multi-digit)
`timescale 1ns/1ps
module bcd_to_ex3_vector #(parameter DIGITS = 3)(
  input  wire [DIGITS*4-1:0] bcd_in,
  output wire [DIGITS*4-1:0] ex3_out
);
  genvar i;
  generate
    for (i = 0; i < DIGITS; i = i + 1) begin : B2E
      bcd_to_ex3_digit u(.bcd(bcd_in[i*4 +: 4]), .ex3(ex3_out[i*4 +: 4]));
    end
  endgenerate
endmodule

`timescale 1ns/1ps
module ex3_to_bcd_vector #(parameter DIGITS = 3)(
  input  wire [DIGITS*4-1:0] ex3_in,
  output wire [DIGITS*4-1:0] bcd_out
);
  genvar i;
  generate
    for (i = 0; i < DIGITS; i = i + 1) begin : E2B
      ex3_to_bcd_digit u(.ex3(ex3_in[i*4 +: 4]), .bcd(bcd_out[i*4 +: 4]));
    end
  endgenerate
endmodule

//Applies the single-digit add/sub-3 across all digits in parallel.
