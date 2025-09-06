//Binary → BCD (double-dabble / shift-add-3)
//The classic hardware-friendly approach iterates WIDTH times: before each left shift, add 3 to any BCD nibble ≥ 5.

`timescale 1ns/1ps
module bin2bcd_dd #(
  parameter WIDTH  = 8,   // binary input width
  parameter DIGITS = 3    // number of BCD digits (e.g., 8-bit needs up to 3 digits: 0..255)
)(
  input  wire              clk,
  input  wire              rst,
  input  wire              start,
  input  wire [WIDTH-1:0]  bin_in,
  output reg               busy,
  output reg               done,
  output reg  [DIGITS*4-1:0] bcd_out
);
  // Internal registers
  reg [WIDTH-1:0]        bin_shift;
  reg [DIGITS*4-1:0]     bcd_work;
  reg [$clog2(WIDTH+1)-1:0] count;

  // State machine
  localparam S_IDLE = 2'd0, S_PREP = 2'd1, S_LOOP = 2'd2, S_DONE = 2'd3;
  reg [1:0] state, nxt;

  integer d;

  // State register
  always @(posedge clk or posedge rst) begin
    if (rst) state <= S_IDLE;
    else     state <= nxt;
  end

  // Next-state and outputs
  always @(*) begin
    busy = 1'b0; done = 1'b0; nxt = state;
    case (state)
      S_IDLE: begin
        if (start) nxt = S_PREP;
      end
      S_PREP: begin
        busy = 1'b1;
        nxt  = (WIDTH==0) ? S_DONE : S_LOOP;
      end
      S_LOOP: begin
        busy = 1'b1;
        if (count == 0) nxt = S_DONE;
        else            nxt = S_LOOP;
      end
      S_DONE: begin
        done = 1'b1;
        if (!start) nxt = S_IDLE; // wait for start to deassert
      end
      default: nxt = S_IDLE;
    endcase
  end

  // Datapath operations
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      bin_shift <= {WIDTH{1'b0}};
      bcd_work  <= {DIGITS*4{1'b0}};
      bcd_out   <= {DIGITS*4{1'b0}};
      count     <= '0;
    end
    else begin
      case (state)
        S_IDLE: begin
          // wait
        end
        S_PREP: begin
          bin_shift <= bin_in;
          bcd_work  <= {DIGITS*4{1'b0}};
          count     <= WIDTH[$clog2(WIDTH+1)-1:0];
        end
        S_LOOP: begin
          // 1) For each BCD nibble >= 5, add 3
          for (d = 0; d < DIGITS; d = d + 1) begin
            if (bcd_work[d*4 +: 4] >= 5)
              bcd_work[d*4 +: 4] <= bcd_work[d*4 +: 4] + 4'd3;
          end
          // 2) Shift left across the concatenated register: {bcd_work, bin_shift}
          {bcd_work, bin_shift} <= {bcd_work, bin_shift} << 1;
          count <= count - 1'b1;
        end
        S_DONE: begin
          bcd_out <= bcd_work;
        end
      endcase
    end
  end
endmodule
