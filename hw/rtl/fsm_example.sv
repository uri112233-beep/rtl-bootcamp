// SPDX-License-Identifier: MIT
// Simple FSM used for Week 1 foundations.
// Clean sizing, clear separation of comb/seq logic, async reset with sync release.
module fsm_example #(
  parameter int unsigned WAIT_CYCLES = 5
) (
  input  logic clk_i,
  input  logic rst_ni,    // active-low reset (async assert, sync release)
  input  logic start_i,
  output logic busy_o,
  output logic done_o
);
  // Counter width; typedef gives us a concrete vector type for casting
  localparam int unsigned CNTW = $clog2(WAIT_CYCLES + 1);
  typedef logic [CNTW-1:0] cnt_t;
  localparam cnt_t CNT_MAX = cnt_t'(WAIT_CYCLES - 1);  // width-matched cast

  typedef enum logic [1:0] { S_IDLE, S_BUSY, S_DONE } state_e;

  state_e state_q, state_d;
  cnt_t   cnt_q,  cnt_d;

  // Combinational next-state / outputs
  always_comb begin
    state_d = state_q;
    cnt_d   = cnt_q;
    busy_o  = 1'b0;
    done_o  = 1'b0;

    unique case (state_q)
      S_IDLE: if (start_i) begin
        state_d = S_BUSY;
        cnt_d   = '0;
      end

      S_BUSY: begin
        busy_o = 1'b1;
        if (cnt_q == CNT_MAX) begin
          state_d = S_DONE;
        end else begin
          // Sized +1 using the same vector type as the counter
          cnt_d = cnt_q + cnt_t'(1);
        end
      end

      S_DONE: begin
        done_o  = 1'b1;   // one-cycle pulse
        state_d = S_IDLE;
      end

      default: begin
        state_d = S_IDLE;
        cnt_d   = '0;
      end
    endcase
  end

  // Sequential state/counter with async reset, sync release
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= S_IDLE;
      cnt_q   <= '0;
    end else begin
      state_q <= state_d;
      cnt_q   <= cnt_d;
    end
  end

endmodule
