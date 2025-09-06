`timescale 1ns/1ps
module gray2bin #(parameter WIDTH = 8)(
  input  wire [WIDTH-1:0] gray,
  output wire [WIDTH-1:0] bin
);
  // Iterative XOR from MSB downwards.
  // bin[MSB] = gray[MSB]; bin[i] = bin[i+1] ^ gray[i]
  genvar i;
  assign bin[WIDTH-1] = gray[WIDTH-1];
  generate
    for (i = WIDTH-2; i >= 0; i = i - 1) begin : G2B
      assign bin[i] = bin[i+1] ^ gray[i];
    end
  endgenerate
endmodule
