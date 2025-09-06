`timescale 1ns/1ps
module code_converter_top #(
  parameter WIDTH  = 8,
  parameter DIGITS = 3
)(
  input  wire                   clk,
  input  wire                   rst,

  // Control
  input  wire                   start,
  input  wire [2:0]             opcode,
  // 0: BIN2GRAY, 1: GRAY2BIN, 2: BIN2BCD, 3: BCD2BIN, 4: BCD2EX3, 5: EX32BCD

  // Inputs (drive only the one relevant to your opcode)
  input  wire [WIDTH-1:0]       bin_in,
  input  wire [WIDTH-1:0]       gray_in,
  input  wire [DIGITS*4-1:0]    bcd_in,
  input  wire [DIGITS*4-1:0]    ex3_in,

  // Outputs
  output reg  [WIDTH-1:0]       bin_out,
  output reg  [WIDTH-1:0]       gray_out,
  output reg  [DIGITS*4-1:0]    bcd_out,
  output reg  [DIGITS*4-1:0]    ex3_out,

  // Handshake
  output wire                   busy,
  output wire                   done
);
  // Wires between controller and datapath
  wire start_bin2bcd, start_bcd2bin;
  wire bin2bcd_busy, bin2bcd_done;
  wire bcd2bin_busy, bcd2bin_done;

  wire [WIDTH-1:0]    bin_out_comb;
  wire [WIDTH-1:0]    gray_out_comb;
  wire [DIGITS*4-1:0] bcd_out_comb;
  wire [DIGITS*4-1:0] ex3_out_comb;

  wire latch_bin, latch_gray, latch_bcd, latch_ex3;

  // Datapath
  converter_datapath #(.WIDTH(WIDTH), .DIGITS(DIGITS)) u_dp (
    .clk(clk), .rst(rst),
    .bin_in(bin_in), .gray_in(gray_in), .bcd_in(bcd_in), .ex3_in(ex3_in),
    .start_bin2bcd(start_bin2bcd), .start_bcd2bin(start_bcd2bin),
    .op(opcode),
    .busy_any(), .done_any(), // aggregated flags internal, controller uses engine flags instead
    .bin_out_comb(bin_out_comb),
    .gray_out_comb(gray_out_comb),
    .bcd_out_comb(bcd_out_comb),
    .ex3_out_comb(ex3_out_comb),
    .bin2bcd_busy(bin2bcd_busy), .bin2bcd_done(bin2bcd_done),
    .bcd2bin_busy(bcd2bin_busy), .bcd2bin_done(bcd2bin_done)
  );

  // Controller
  converter_controller u_ctrl (
    .clk(clk), .rst(rst), .start(start), .op(opcode),
    .bin2bcd_busy(bin2bcd_busy), .bin2bcd_done(bin2bcd_done),
    .bcd2bin_busy(bcd2bin_busy), .bcd2bin_done(bcd2bin_done),
    .start_bin2bcd(start_bin2bcd), .start_bcd2bin(start_bcd2bin),
    .busy(busy), .done(done),
    .latch_bin(latch_bin), .latch_gray(latch_gray),
    .latch_bcd(latch_bcd), .latch_ex3(latch_ex3)
  );

  // Output registers latch at DONE according to controller
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      bin_out  <= {WIDTH{1'b0}};
      gray_out <= {WIDTH{1'b0}};
      bcd_out  <= {DIGITS*4{1'b0}};
      ex3_out  <= {DIGITS*4{1'b0}};
    end else begin
      if (latch_bin)  bin_out  <= bin_out_comb;
      if (latch_gray) gray_out <= gray_out_comb;
      if (latch_bcd)  bcd_out  <= bcd_out_comb;
      if (latch_ex3)  ex3_out  <= ex3_out_comb;
    end
  end
endmodule
