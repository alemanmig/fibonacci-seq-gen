// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Module  : tb
// File    : verification/directed/tb/tb.sv
// Project : fibonacci-seq-gen
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Top-level testbench. Instantiates the clock generator, the virtual interface,
// the DUT (fibonacci), the SVA checker and functional coverage collector
// (both via bind), and the test module.
//
// Clock : 100 MHz  (period = 10 ns, half-period = 5 ns)
//
// -----------------------------------------------------------------------------

module tb;

  timeunit      1ns;
  timeprecision 100ps;

  import config_pkg::*;

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------
  localparam int unsigned W          = FibW;
  localparam int unsigned ClkPeriod  = 10; // ns — 100 MHz

  // ---------------------------------------------------------------------------
  // Clock generation
  // ---------------------------------------------------------------------------
  logic clk_i = 1'b0;

  always #(ClkPeriod / 2 * 1ns) clk_i = ~clk_i;

  // ---------------------------------------------------------------------------
  // Virtual interface
  // ---------------------------------------------------------------------------
  vif_if vif (clk_i); 

  // ---------------------------------------------------------------------------
  // DUT instantiation
  // ---------------------------------------------------------------------------
  fibonacci #(
    .W (W)
  ) dut (
    .clk_i     (vif.clk_i),
    .rst_ni    (vif.rst_ni),
    .enable_i  (vif.enable_i),
    .fib_out_o (vif.fib_out_o)
  );

  // ---------------------------------------------------------------------------
  // SVA checker — bound into the DUT scope
  //
  // sva.sv must be compiled and present in the filelist (sve.f).
  // The bind wires the checker to the DUT's internal signals.
  // ---------------------------------------------------------------------------
  bind dut sva #(.W(W)) dut_sva (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .enable_i  (enable_i),
    .fib_out_o (fib_out_o),
    .a_i       (a),        // internal state register — visible in DUT scope
    .b_i       (b)         // internal state register — visible in DUT scope
  );

  // ---------------------------------------------------------------------------
  // Functional coverage collector — bound into the DUT scope
  //
  // Completely independent of sva.sv and the testbench: a bug in the coverage
  // module cannot mask assertion failures or corrupt test stimulus.
  // fcover.sv must be compiled and present in the filelist (sve.f).
  // ---------------------------------------------------------------------------
  bind dut fcover #(.W(W)) dut_fcover (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .enable_i  (enable_i),
    .fib_out_o (fib_out_o),
    .a_i       (a),        // internal state register — visible in DUT scope
    .b_i       (b)         // internal state register — visible in DUT scope
  );

  // ---------------------------------------------------------------------------
  // Test
  // ---------------------------------------------------------------------------
  test top_test (vif);

  // ---------------------------------------------------------------------------
  // Simulation setup
  // ---------------------------------------------------------------------------
  initial begin
    $timeformat(-9, 1, "ns", 10);
  end

endmodule : tb
