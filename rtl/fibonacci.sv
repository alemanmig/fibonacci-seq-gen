// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Module   : fibonacci
// File     : rtl/fibonacci.sv
// ID       : rtl8
// Project  : fibonacci-seq-gen
// Spec     : docs/Specs.md
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Parameterizable Fibonacci sequence generator with synchronous enable and
// asynchronous active-low reset.
//
// The module maintains two state registers (a, b) implementing the recurrence:
//
//   F(0) = 0,  F(1) = 1,  F(n) = F(n-1) + F(n-2)  for n >= 2
//
// State transition on rising clock edge:
//   - reset  : a <= 0,  b <= 1        (fib_out_o = 0)
//   - enable : a <= b,  b <= a + b    (fib_out_o advances)
//   - hold   : a <= a,  b <= b        (fib_out_o unchanged)
//
// Output convention:
//   fib_out_o reflects register 'a' directly via continuous assignment.
//   Value is 0 after reset and follows 0,1,1,2,3,5,8,... when enable is
//   continuously asserted.
//
// Overflow behaviour:
//   Arithmetic is unsigned and wraps at 2^W (natural truncation). No saturation
//   logic is included. The reference model mirrors this (see verif_plan.md).
//
// Parameters
// ----------
//   W : int unsigned — Data width in bits for output and internal registers.
//                      Default: 32.
//
// Ports
// -----
//   clk_i     : i  1    System clock, active rising edge.
//   rst_ni    : i  1    Asynchronous reset, active-low.
//   enable_i  : i  1    Sequence advance enable, active-high.
//   fib_out_o : o  W    Current Fibonacci value.
//
// -----------------------------------------------------------------------------

`default_nettype none

module fibonacci #(
  parameter W = 16
)(
  input  logic          clk_i,
  input  logic          rst_ni,
  input  logic          enable_i,
  output logic [W-1:0]  fib_out_o
);
  logic [W-1:0] a, b;

  // a=0, b=1 on reset → outputs: 0, 1, 1, 2, 3, 5, ...
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      a <= '0;
      b <= 1;
    end else if (enable_i) begin
      a <= b;
      b <= a + b;
    end
  end

  assign fib_out_o = a;
  
endmodule : fibonacci

`default_nettype wire
