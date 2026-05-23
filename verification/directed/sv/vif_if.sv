// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Interface : vif_if
// File      : verification/directed/sv/vif_if.sv
// Project   : fibonacci-seq-gen
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Virtual interface for the fibonacci DUT. Bundles all DUT signals and
// provides a clocking block for synchronous stimulus and sampling in the
// testbench / test layers.
//
// Clocking block (cb):
//   - Input  skew : #1step  (sample just before clock edge — avoids race).
//   - Output skew : #1ns    (drive 1 ns after clock edge).
//
// -----------------------------------------------------------------------------

`ifndef VIF_IF_SV
`define VIF_IF_SV

interface vif_if #(
  parameter int unsigned W = 32
) (
  input logic clk_i
);

  timeunit      1ns;
  timeprecision 100ps;

  import config_pkg::*;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------
  logic          rst_ni;
  logic          enable_i;
  logic [W-1:0]  fib_out_o;

  // ---------------------------------------------------------------------------
  // Clocking block — synchronous testbench view
  //
  // Use cb.enable_i and cb.fib_out_o inside clocked tasks/test sequences
  // to guarantee setup/hold timing relative to clk_i.
  // ---------------------------------------------------------------------------
  clocking cb @(posedge clk_i);
    default input #1step output #1ns;
    output enable_i;
    input  fib_out_o;
  endclocking : cb

  // Modport for the test / driver layer (drives enable, reads output).
  modport tb_mp (
    clocking cb,
    output   rst_ni,
    input    clk_i
  );

endinterface : vif_if

`endif // VIF_IF_SV
