//Controller FSM
`timescale 1ns/1ps
module converter_controller(
  input  wire        clk,
  input  wire        rst,
  input  wire        start,
  input  wire [2:0]  op,

  // Engine handshakes
  input  wire        bin2bcd_busy,
  input  wire        bin2bcd_done,
  input  wire        bcd2bin_busy,
  input  wire        bcd2bin_done,

  // Command pulses to engines
  output reg         start_bin2bcd,
  output reg         start_bcd2bin,

  // Top-level handshakes
  output reg         busy,
  output reg         done,

  // Latch enables for outputs
  output reg         latch_bin,
  output reg         latch_gray,
  output reg         latch_bcd,
  output reg         latch_ex3
);
  // States
  localparam S_IDLE = 3'd0,
             S_KICK = 3'd1,
             S_WAIT = 3'd2,
             S_DONE = 3'd3;

  reg [2:0] state, nxt;

  // Edge: which ops are sequential?
  wire is_seq = (op == 3'd2) | (op == 3'd3);

  // Done-wire from engines (for selected op)
  wire engine_done = (op == 3'd2) ? bin2bcd_done :
                     (op == 3'd3) ? bcd2bin_done : 1'b1; // combinational ops: treat as instant

  // Busy-wire from engines (for selected op)
  wire engine_busy = (op == 3'd2) ? bin2bcd_busy :
                     (op == 3'd3) ? bcd2bin_busy : 1'b0;

  // State register
  always @(posedge clk or posedge rst) begin
    if (rst) state <= S_IDLE;
    else     state <= nxt;
  end

  // Next-state and control
  always @(*) begin
    // defaults
    start_bin2bcd = 1'b0;
    start_bcd2bin = 1'b0;
    latch_bin  = 1'b0;
    latch_gray = 1'b0;
    latch_bcd  = 1'b0;
    latch_ex3  = 1'b0;
    busy = 1'b0;
    done = 1'b0;
    nxt  = state;

    case (state)
      S_IDLE: begin
        if (start) nxt = S_KICK;
      end

      S_KICK: begin
        busy = 1'b1;
        // fire the right engine or go straight to DONE for combinational
        if (op == 3'd2)      start_bin2bcd = 1'b1; // BIN2BCD
        else if (op == 3'd3) start_bcd2bin = 1'b1; // BCD2BIN

        if (is_seq) nxt = S_WAIT;
        else        nxt = S_DONE; // combinational ops complete immediately
      end

      S_WAIT: begin
        busy = 1'b1;
        if (engine_done) nxt = S_DONE;
      end

      S_DONE: begin
        // Latch the appropriate output at DONE
        case (op)
          3'd0: latch_gray = 1'b1; // BIN2GRAY -> gray_out
          3'd1: latch_bin  = 1'b1; // GRAY2BIN -> bin_out
          3'd2: latch_bcd  = 1'b1; // BIN2BCD -> bcd_out
          3'd3: latch_bin  = 1'b1; // BCD2BIN -> bin_out
          3'd4: latch_ex3  = 1'b1; // BCD2EX3 -> ex3_out
          3'd5: latch_bcd  = 1'b1; // EX32BCD -> bcd_out
          default: ;
        endcase
        done = 1'b1;
        if (!start) nxt = S_IDLE; // wait for start to deassert
      end
      default: nxt = S_IDLE;
    endcase
  end
endmodule
