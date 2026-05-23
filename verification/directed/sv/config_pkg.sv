// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Package : config_pkg
// File    : verification/directed/sv/config_pkg.sv
// Project : fibonacci-seq-gen
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Testbench-wide parameters shared across tb, test, and interface layers.
//
// -----------------------------------------------------------------------------

`ifndef CONFIG_PKG_SV
`define CONFIG_PKG_SV

package config_pkg;

  // DUT data width (must match parameter W in fibonacci.sv instantiation).
  localparam int unsigned FibW = 32;

  // Clock frequency and derived period.
  localparam int unsigned ClkFreqHz  = 100_000_000; // 100 MHz
  localparam int unsigned ClkPeriodNs = 10;          // 10 ns

endpackage : config_pkg

`endif // CONFIG_PKG_SV
