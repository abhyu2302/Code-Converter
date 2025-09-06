//BCD TO Excess-3 and vice versa

`timescale 1ns/1ps
module bcd_to_ex3_digit(
  input  wire [3:0] bcd,   // 0..9 expected
  output wire [3:0] ex3    // bcd + 3
);
  assign ex3 = bcd + 4'd3;
endmodule

`timescale 1ns/1ps
module ex3_to_bcd_digit(
  input  wire [3:0] ex3,   // 3..12 expected for valid digits
  output wire [3:0] bcd    // ex3 - 3
);
  assign bcd = ex3 - 4'd3;
endmodule
