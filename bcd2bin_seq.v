//BCD → Binary (sequential multiply-by-10 accumulate)
//We compute bin = (((digit0)*10 + digit1)*10 + digit2) ....

`timescale 1ns/1ps
module bcd2bin_seq #(
  parameter WIDTH  = 8,
  parameter DIGITS = 3
)(
  input  wire                clk,
  input  wire                rst,
  input  wire                start,
  input  wire [DIGITS*4-1:0] bcd_in, // [digit2|digit1|digit0], digit2 is hundreds for DIGITS=3
  output reg                 busy,
  output reg                 done,
  output reg  [WIDTH-1:0]    bin_out
);
  // State machine
  localparam S_IDLE = 2'd0, S_PREP = 2'd1, S_ACCUM = 2'd2, S_DONE = 2'd3;
  reg [1:0] state, nxt;

  // Index to walk digits MSB->LSB
  integer idx;
  reg [$clog2(DIGITS+1)-1:0] pos;
  reg [3:0] cur_digit;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= S_IDLE;
    else     state <= nxt;
  end

  always @(*) begin
    busy = 1'b0; done = 1'b0; nxt = state;
    case (state)
      S_IDLE: begin
        if (start) nxt = S_PREP;
      end
      S_PREP: begin
        busy = 1'b1;
        nxt  = (DIGITS==0) ? S_DONE : S_ACCUM;
      end
      S_ACCUM: begin
        busy = 1'b1;
        if (pos == 0) nxt = S_DONE;
        else          nxt = S_ACCUM;
      end
      S_DONE: begin
        done = 1'b1;
        if (!start) nxt = S_IDLE;
      end
      default: nxt = S_IDLE;
    endcase
  end

  // Multiply-by-10 helper: x*10 = (x<<3) + (x<<1)
  function [WIDTH-1:0] mul10(input [WIDTH-1:0] x);
    begin
      mul10 = (x << 3) + (x << 1);
    end
  endfunction

  // Walk through digits
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      bin_out <= {WIDTH{1'b0}};
      pos     <= '0;
    end else begin
      case (state)
        S_PREP: begin
          bin_out <= '0;
          pos     <= DIGITS[$clog2(DIGITS+1)-1:0];
        end
        S_ACCUM: begin
          // fetch next MSB digit at position pos-1
          idx       = (pos - 1) * 4;
          cur_digit = bcd_in[idx +: 4];
          bin_out   <= mul10(bin_out) + cur_digit;
          pos       <= pos - 1'b1;
        end
        default: ;
      endcase
    end
  end
endmodule

//Reads BCD digits from MSB to LSB and builds the binary number by repeated *10 + digit.
