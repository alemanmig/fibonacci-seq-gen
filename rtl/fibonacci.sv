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
  parameter int unsigned W = 32
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic             enable_i,
  output logic [W-1:0]     fib_out_o
);

  // ---------------------------------------------------------------------------
  // Signal declarations
  // ---------------------------------------------------------------------------

  // State registers:
  //   a — current Fibonacci value, driven to fib_out_o.
  //   b — next Fibonacci value, loaded into a on the next advance.
  logic [W-1:0] a, b;

  // Combinational adder result: a + b (unsigned, wraps at 2^W).
  logic [W-1:0] next_b;

  // ---------------------------------------------------------------------------
  // Combinational logic — next value of b
  //
  // Kept in a dedicated always_comb block so the adder is clearly separated
  // from the sequential state and synthesis can optimise it independently.
  // ---------------------------------------------------------------------------
  always_comb begin : comb_sum
    next_b = a + b;
  end

  // ---------------------------------------------------------------------------
  // Sequential logic — state registers a and b
  //
  // Reset  (asynchronous, active-low): a=0, b=1 initialises the recurrence
  //        so that fib_out_o=0 at reset and the first enabled output is 1.
  // Enable (synchronous, active-high): advance the Fibonacci recurrence.
  // Hold   (enable de-asserted):       implicit — FF retains previous state.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin : seq_regs
    if (!rst_ni) begin
      a <= '0;                          // fib_out_o = 0 after reset  [RST-001]
      b <= W'(1);                       // b = 1 → first advance yields F(1)=1
    end else if (enable_i) begin
      a <= b;                           // advance: a ← b             [SEQ-001]
      b <= next_b;                      // advance: b ← a+b           [SEQ-002]
    end
    // else: hold — FF retains a and b implicitly                    [HLD-001]
  end

  // ---------------------------------------------------------------------------
  // Output assignment
  //
  // Direct continuous assignment; no extra logic on the output path.
  // ---------------------------------------------------------------------------
  assign fib_out_o = a;

endmodule : fibonacci

`default_nettype wire
