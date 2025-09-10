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

 // Always_comb for "clear at end" policy (with top defaults)
// (English-only comments)
always_comb begin
  // ---- global defaults (prevent latches; create HOLD leg) ----
  state_d = state_q;   // HOLD by default
  cnt_d   = cnt_q;     // HOLD by default
  busy_o  = 1'b0;
  done_o  = 1'b0;

  unique case (state_q)
    S_IDLE: begin
      cnt_d = '0;                    // keep cleared while idle
      if (start_i) state_d = S_BUSY; // start counting from 0
    end

    S_BUSY: begin
      busy_o = 1'b1;
      if (cnt_q == CNT_MAX) begin
        state_d = S_DONE;
        cnt_d   = '0;                // clear at terminal (end)
      end else begin
        cnt_d   = cnt_q + cnt_t'(1); // increment while counting
      end
    end

    S_DONE: begin
      done_o  = 1'b1;                // one-cycle pulse
      state_d = S_IDLE;
      cnt_d   = '0;                  // stay cleared during DONE
    end

    default: begin
      // illegal-state recovery (not related to top defaults)
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
