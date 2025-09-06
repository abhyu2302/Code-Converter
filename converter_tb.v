`timescale 1ns/1ps
module tb_code_converter;
  // Parameters
  localparam WIDTH  = 8;
  localparam DIGITS = 3;

  // DUT signals
  reg                  clk, rst;
  reg                  start;
  reg  [2:0]           opcode;
  reg  [WIDTH-1:0]     bin_in;
  reg  [WIDTH-1:0]     gray_in;
  reg  [DIGITS*4-1:0]  bcd_in;
  reg  [DIGITS*4-1:0]  ex3_in;

  wire [WIDTH-1:0]     bin_out;
  wire [WIDTH-1:0]     gray_out;
  wire [DIGITS*4-1:0]  bcd_out;
  wire [DIGITS*4-1:0]  ex3_out;
  wire                 busy, done;

  // Instantiate DUT
  code_converter_top #(.WIDTH(WIDTH), .DIGITS(DIGITS)) dut (
    .clk(clk), .rst(rst),
    .start(start), .opcode(opcode),
    .bin_in(bin_in), .gray_in(gray_in),
    .bcd_in(bcd_in), .ex3_in(ex3_in),
    .bin_out(bin_out), .gray_out(gray_out),
    .bcd_out(bcd_out), .ex3_out(ex3_out),
    .busy(busy), .done(done)
  );

  // Clock
  always #5 clk = ~clk;

  // Helper task: run a conversion
  task run_conversion;
    input [2:0] op;
    begin
      opcode = op;
      start  = 1;
      @(posedge clk);
      start  = 0;

      // Wait until done
      wait(done);
      @(posedge clk); // capture outputs

      case (op)
        3'd0: $display("BIN2GRAY: bin=%0d -> gray=%b", bin_in, gray_out);
        3'd1: $display("GRAY2BIN: gray=%b -> bin=%0d", gray_in, bin_out);
        3'd2: $display("BIN2BCD : bin=%0d -> bcd=%h", bin_in, bcd_out);
        3'd3: $display("BCD2BIN : bcd=%h -> bin=%0d", bcd_in, bin_out);
        3'd4: $display("BCD2EX3 : bcd=%h -> ex3=%h", bcd_in, ex3_out);
        3'd5: $display("EX32BCD : ex3=%h -> bcd=%h", ex3_in, bcd_out);
      endcase
      $display("------------------------------------------------");
    end
  endtask

  // Stimulus
  initial begin
    clk = 0; rst = 1; start = 0;
    bin_in = 0; gray_in = 0; bcd_in = 0; ex3_in = 0;
    opcode = 0;

    repeat (2) @(posedge clk);
    rst = 0;

    // BIN2GRAY (e.g. 13)
    bin_in = 8'd13;
    run_conversion(3'd0);

    // GRAY2BIN (gray for 13 is 1011)
    gray_in = 8'b1011;
    run_conversion(3'd1);

    // BIN2BCD (e.g. 197)
    bin_in = 8'd197;
    run_conversion(3'd2);

    // BCD2BIN (BCD for 197 is 0x197 → 1 9 7 nibbles)
    bcd_in = {4'd1,4'd9,4'd7};
    run_conversion(3'd3);

    // BCD2EX3 (e.g. 4 5 6 → 7 8 9)
    bcd_in = {4'd4,4'd5,4'd6};
    run_conversion(3'd4);

    // EX32BCD (e.g. 7 8 9 → 4 5 6)
    ex3_in = {4'd7,4'd8,4'd9};
    run_conversion(3'd5);

    $display("All conversions tested.");
    $finish;
  end
endmodule
