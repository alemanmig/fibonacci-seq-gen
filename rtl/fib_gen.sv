// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Module   : fib_gen
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
//   - reset  : a <= 0,  b <= 1          → fib_out = 0
//   - enable : a <= b,  b <= a + b      → fib_out advances
//   - hold   : a <= a,  b <= b          → fib_out unchanged
//
// Output convention:
//   fib_out is a registered copy of 'a', updated on each enabled clock edge.
//   The output is 0 after reset and follows the sequence 0,1,1,2,3,5,8,...
//   when enable is continuously asserted.
//
// Overflow behaviour:
//   Arithmetic is unsigned and wraps naturally at 2^W. No saturation logic is
//   included. The verification model mirrors this behaviour (see verif_plan.md).
//
// Parameters
// ----------
//   W : integer — Output and internal register width in bits (default 32).
//
// Ports
// -----
//   clk     : i 1   System clock, active on rising edge.
//   rst_n   : i 1   Asynchronous reset, active-low.
//   enable  : i 1   Sequence advance enable, active-high.
//   fib_out : o W   Current Fibonacci value.
//
// -----------------------------------------------------------------------------

`default_nettype none

module fib_gen #(
  parameter int unsigned W = 32
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             enable,
  output logic [W-1:0]     fib_out
);

  // ---------------------------------------------------------------------------
  // Signal declarations
  // ---------------------------------------------------------------------------

  // State registers.
  // a : holds the current Fibonacci value  → driven to fib_out.
  // b : holds the next Fibonacci value     → loaded into a on next advance.
  logic [W-1:0] a, b;

  // Combinational next-state for b: computed as a + b (unsigned, wraps at 2^W).
  logic [W-1:0] next_b;

  // ---------------------------------------------------------------------------
  // Combinational logic — next value of b
  //
  // Separating the adder into an always_comb block makes the intent explicit
  // and allows synthesis tools to optimise the adder independently.
  // ---------------------------------------------------------------------------
  always_comb begin : comb_sum
    next_b = a + b;
  end

  // ---------------------------------------------------------------------------
  // Sequential logic — state registers a and b
  //
  // Reset  (asynchronous, active-low): initialise to produce sequence
  //        starting with 0,1,1,2,3,5,...  → a=0, b=1 so fib_out=0 at reset.
  // Enable (synchronous, active-high) : advance the recurrence.
  // Hold   (enable de-asserted)        : retain current state.
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin : seq_regs
    if (!rst_n) begin
      a <= '0;          // fib_out = 0 after reset  (REQ: RST-001)
      b <= {{(W-1){1'b0}}, 1'b1};  // b = 1 so next advance yields F(1)=1
    end else if (enable) begin
      a <= b;           // advance: current becomes previous next (REQ: SEQ-001)
      b <= next_b;      // next becomes a+b                      (REQ: SEQ-002)
    end
    // else: hold — implicit retention of a and b               (REQ: HLD-001)
  end

  // ---------------------------------------------------------------------------
  // Output assignment
  //
  // fib_out is the registered value of 'a'. No additional logic on the output
  // path keeps the timing clean and avoids glitches on hold cycles.
  // ---------------------------------------------------------------------------
  assign fib_out = a;

  // ---------------------------------------------------------------------------
  // Assertions (inline, for simulation only)
  //
  // These are companion checks to the SVA checker in verification/.
  // Synthesis tools should strip them automatically; for explicit exclusion
  // wrap with `ifndef SYNTHESIS ... `endif if required by the flow.
  // ---------------------------------------------------------------------------

  // After reset is released fib_out must be 0.
  // RST-001
  `ifndef SYNTHESIS
  assert_rst_out_zero : assert property (
    @(posedge clk) disable iff (!rst_n)
    ($rose(rst_n) |-> (fib_out == '0))
  ) else $error("[fib_gen] RST-001 FAIL: fib_out is not 0 after reset release");

  // fib_out must not change while enable is de-asserted.
  // HLD-001
  assert_hold_stable : assert property (
    @(posedge clk) disable iff (!rst_n)
    (!enable |=> $stable(fib_out))
  ) else $error("[fib_gen] HLD-001 FAIL: fib_out changed while enable=0");
  `endif

endmodule : fib_gen

`default_nettype wire
