//Converter datapath (registers, muxes, submodules)
`timescale 1ns/1ps
module converter_datapath #(
  parameter WIDTH  = 8,
  parameter DIGITS = 3
)(
  input  wire                   clk,
  input  wire                   rst,

  // Raw inputs (one of these is used depending on opcode)
  input  wire [WIDTH-1:0]       bin_in,
  input  wire [WIDTH-1:0]       gray_in,
  input  wire [DIGITS*4-1:0]    bcd_in,
  input  wire [DIGITS*4-1:0]    ex3_in,

  // Control from controller
  input  wire                   start_bin2bcd,
  input  wire                   start_bcd2bin,
  input  wire [2:0]             op,          // operation select
  output wire                   busy_any,    // OR of internal busy lines
  output wire                   done_any,    // one-cycle done pulse from chosen engine

  // Outputs (registered by controller at DONE)
  output wire [WIDTH-1:0]       bin_out_comb,
  output wire [WIDTH-1:0]       gray_out_comb,
  output wire [DIGITS*4-1:0]    bcd_out_comb,
  output wire [DIGITS*4-1:0]    ex3_out_comb,

  // Handshakes from engines
  output wire                   bin2bcd_busy,
  output wire                   bin2bcd_done,
  output wire                   bcd2bin_busy,
  output wire                   bcd2bin_done
);
  // --- Simple combinational sub-converters
  wire [WIDTH-1:0] gray_from_bin, bin_from_gray;
  bin2gray #(WIDTH) u_b2g(.bin(bin_in), .gray(gray_from_bin));
  gray2bin #(WIDTH) u_g2b(.gray(gray_in), .bin(bin_from_gray));

  // Vector Excess-3 helpers
  wire [DIGITS*4-1:0] ex3_from_bcd, bcd_from_ex3;
  bcd_to_ex3_vector #(DIGITS) u_bcd2ex3(.bcd_in(bcd_in), .ex3_out(ex3_from_bcd));
  ex3_to_bcd_vector #(DIGITS) u_ex32bcd(.ex3_in(ex3_in), .bcd_out(bcd_from_ex3));

  // --- Sequential engines
  wire [DIGITS*4-1:0] bcd_from_bin;
  bin2bcd_dd #(WIDTH, DIGITS) u_bin2bcd (
    .clk(clk), .rst(rst), .start(start_bin2bcd),
    .bin_in(bin_in), .busy(bin2bcd_busy), .done(bin2bcd_done), .bcd_out(bcd_from_bin)
  );

  wire [WIDTH-1:0] bin_from_bcd;
  bcd2bin_seq #(WIDTH, DIGITS) u_bcd2bin (
    .clk(clk), .rst(rst), .start(start_bcd2bin),
    .bcd_in(bcd_in), .busy(bcd2bin_busy), .done(bcd2bin_done), .bin_out(bin_from_bcd)
  );

  // Output selectors (pure combinational “views”)
  // We expose all so the controller can latch the right one on DONE.
  assign bin_out_comb  = (op == 3'd1) ? bin_from_gray : // GRAY2BIN
                         (op == 3'd3) ? bin_from_bcd  : // BCD2BIN
                         {WIDTH{1'b0}};

  assign gray_out_comb = (op == 3'd0) ? gray_from_bin : // BIN2GRAY
                         {WIDTH{1'b0}};

  assign bcd_out_comb  = (op == 3'd2) ? bcd_from_bin  : // BIN2BCD
                         (op == 3'd5) ? bcd_from_ex3  : // EX32BCD
                         {DIGITS*4{1'b0}};

  assign ex3_out_comb  = (op == 3'd4) ? ex3_from_bcd  : // BCD2EX3
                         {DIGITS*4{1'b0}};

  // Busy/Done aggregation for the selected op
  assign busy_any =
      ((op == 3'd2) & bin2bcd_busy) |
      ((op == 3'd3) & bcd2bin_busy);

  assign done_any =
      ((op == 3'd0) ? 1'b1 : 1'b0) |         // BIN2GRAY is combinational; controller pulses done
      ((op == 3'd1) ? 1'b1 : 1'b0) |         // GRAY2BIN combinational
      ((op == 3'd2) ? bin2bcd_done : 1'b0) | // BIN2BCD sequential
      ((op == 3'd3) ? bcd2bin_done : 1'b0) | // BCD2BIN sequential
      ((op == 3'd4) ? 1'b1 : 1'b0) |         // BCD2EX3 combinational
      ((op == 3'd5) ? 1'b1 : 1'b0);          // EX32BCD combinational
endmodule

/*
What it does:

Instantiates all leaf converters.
Provides combinational “views” of each possible result.
Exposes engine handshakes for the controller to know when a sequential op finishes.

Opcode map (op):
0: BIN2GRAY, 1: GRAY2BIN, 2: BIN2BCD, 3: BCD2BIN, 4: BCD2EX3, 5: EX32BCD.
*/

