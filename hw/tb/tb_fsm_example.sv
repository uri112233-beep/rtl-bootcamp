`timescale 1ns/1ps
// Minimal TB demonstrating clean Verilator-friendly style.
// - Use non-blocking assignment for delayed clock toggle
// - Keep DUT reset async; use async reset in TB for the synchronized copy as well
module tb_fsm_example;

  logic clk, rst_n, start, busy, done;

  // Clock: non-blocking assignment avoids BLKSEQ warning in Verilator
  initial clk = 0;
  always #5 clk <= ~clk; // 100 MHz

  // Use async reset in TB for the monitor copy; avoids async/sync mixing on 'rst_n'
  logic rst_n_q;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) rst_n_q <= 1'b0;
    else        rst_n_q <= 1'b1;
  end

  // DUT
  fsm_example #(.WAIT_CYCLES(5)) dut (
    .clk_i   (clk),
    .rst_ni  (rst_n),
    .start_i (start),
    .busy_o  (busy),
    .done_o  (done)
  );

  // Stimulus
  initial begin
    $display("[%0t] TB start", $time);
    rst_n = 0; start = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    // Transaction 1
    @(posedge clk); start = 1;
    @(posedge clk); start = 0;
    wait (done == 1); @(posedge clk);

    // Transaction 2
    @(posedge clk); start = 1;
    @(posedge clk); start = 0;
    wait (done == 1); @(posedge clk);

    $display("[%0t] TB finished", $time);
    $finish;
  end

  // Monitor
  always @(posedge clk) begin
    if (rst_n_q) begin
      $display("[%0t] busy=%0b done=%0b", $time, busy, done);
    end
  end

endmodule
