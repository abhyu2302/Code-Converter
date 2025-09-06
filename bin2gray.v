`timescale 1ns/1ps
module bin2gray #(parameter WIDTH = 8)(
  input  wire [WIDTH-1:0] bin,
  output wire [WIDTH-1:0] gray
);
  // Gray = bin ^ (bin >> 1)
  assign gray = bin ^ (bin >> 1);
endmodule
