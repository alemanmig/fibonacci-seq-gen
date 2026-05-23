// Copyright 2026 fibonacci-seq-gen contributors
// SPDX-License-Identifier: Apache-2.0
//
// -----------------------------------------------------------------------------
// Module  : fcover
// File    : verification/directed/fcover/fcover.sv
// Project : fibonacci-seq-gen
// Spec    : docs/verif_plan.md (Section 4.3)
// -----------------------------------------------------------------------------
//
// Description
// -----------
// Functional coverage collector for the fibonacci DUT.
// Instantiated via bind in tb.sv inside the DUT scope — completely isolated
// from the testbench and assertions so neither can interfere with the other.
//
// Covergroup / coverpoint map
// ─────────────────────────────────────────────────────────────────────────────
//  Covergroup  │ Coverpoint         │ Description
// ─────────────┼────────────────────┼──────────────────────────────────────────
//  fib_cg      │ cp_enable          │ enable asserted / de-asserted
//              │ cp_rst             │ reset active / inactive
//              │ cp_en_transition   │ enable rise (0→1) and fall (1→0)
//              │ cp_rst_transition  │ reset assert (1→0) and release (0→1)
//              │ cp_fib_value       │ output value range bins
//              │ cp_b_value         │ internal b register range bins
//              │ cp_en_run          │ consecutive enabled cycles (run length)
//              │ cp_hold_run        │ consecutive hold cycles (hold length)
//              │ cp_overflow        │ wrap-around observed during enable
//              │ cp_rst_while_en    │ reset asserted while enable is high
//              │ cp_rst_while_hold  │ reset asserted while enable is low
//              │ x_en_rst           │ cross: enable × reset state
//              │ x_val_en           │ cross: fib_value range × enable state
//              │ x_run_val          │ cross: run length × output value range
// ─────────────────────────────────────────────────────────────────────────────
//
// Notes
// -----
// • All coverpoints are sampled at posedge clk_i.
// • The run-length counter (en_run) counts consecutive cycles with enable=1
//   and resets to 0 when enable falls or rst_ni falls.
// • The hold-length counter (hold_run) does the symmetrical tracking.
// • overflow_flag is a sticky bit: set on the first observed wrap-around
//   (fib_out_o decreases during enable), cleared only by reset.
//   This ensures COV_OVERFLOW is closed as soon as overflow happens once.
// • rst_while_en / rst_while_hold are sampled on negedge rst_ni so they
//   capture the state of enable at the exact moment reset is asserted.
//
// -----------------------------------------------------------------------------

`default_nettype none

module fcover #(
  parameter int unsigned W = 32
) (
  input logic           clk_i,
  input logic           rst_ni,
  input logic           enable_i,
  input logic [W-1:0]   fib_out_o,   // DUT port (= register a)
  input logic [W-1:0]   a_i,         // DUT internal register a
  input logic [W-1:0]   b_i          // DUT internal register b
);

  // ---------------------------------------------------------------------------
  // Internal tracking state (simulation-only)
  // ---------------------------------------------------------------------------

  // Consecutive cycles with enable=1 (run length).
  int unsigned en_run;

  // Consecutive cycles with enable=0 while out of reset (hold length).
  int unsigned hold_run;

  // Sticky overflow flag — set when fib_out_o wraps during an enabled step.
  logic overflow_flag;

  // Capture enable state at the moment reset is asserted (negedge rst_ni).
  logic rst_while_en;
  logic rst_while_hold;

  // Previous output, used to detect wrap-around (output decreases).
  logic [W-1:0] prev_fib_out;

  // ── Run / hold length counters ───────────────────────────────────────────
  always_ff @(posedge clk_i or negedge rst_ni) begin : run_counters
    if (!rst_ni) begin
      en_run       <= 0;
      hold_run     <= 0;
      overflow_flag <= 1'b0;
      prev_fib_out  <= '0;
    end else begin
      prev_fib_out <= fib_out_o;
      if (enable_i) begin
        en_run   <= en_run + 1;
        hold_run <= 0;
        // Overflow: output decreased while advancing → unsigned wrap-around.
        if (fib_out_o < prev_fib_out) begin
          overflow_flag <= 1'b1;
        end
      end else begin
        hold_run <= hold_run + 1;
        en_run   <= 0;
      end
    end
  end : run_counters

  // ── Capture enable state at async reset assertion (negedge rst_ni) ───────
  always_ff @(negedge rst_ni) begin : rst_capture
    rst_while_en   <= enable_i;
    rst_while_hold <= ~enable_i;
  end : rst_capture

  // ---------------------------------------------------------------------------
  // Functional coverage
  // ---------------------------------------------------------------------------
  covergroup fib_cg @(posedge clk_i);

    // ── 1. Enable state ──────────────────────────────────────────────────────
    // Verifies that both enable=1 (advance) and enable=0 (hold) are observed.
    cp_enable : coverpoint enable_i {
      bins enabled  = {1'b1};
      bins disabled = {1'b0};
    }

    // ── 2. Reset state ───────────────────────────────────────────────────────
    // Verifies that reset is both active and inactive during simulation.
    cp_rst : coverpoint rst_ni {
      bins active   = {1'b0};    // reset asserted
      bins inactive = {1'b1};    // normal operation
    }

    // ── 3. Enable edge transitions ───────────────────────────────────────────
    // Confirms that enable toggles: rising edge (start of a run) and
    // falling edge (start of a hold) are both exercised.
    cp_en_transition : coverpoint enable_i {
      bins rise = (1'b0 => 1'b1);   // hold → advance
      bins fall = (1'b1 => 1'b0);   // advance → hold
    }

    // ── 4. Reset edge transitions ────────────────────────────────────────────
    // Confirms that reset is asserted at least once and released at least once.
    cp_rst_transition : coverpoint rst_ni {
      bins assert_rst  = (1'b1 => 1'b0);  // reset applied
      bins release_rst = (1'b0 => 1'b1);  // reset released
    }

    // ── 5. Output value range (fib_out_o / register a) ──────────────────────
    // Bins cover the progression from early Fibonacci values through the
    // entire unsigned range, including the post-overflow territory.
    // Boundaries are meaningful regardless of W (relative proportion).
    cp_fib_value : coverpoint fib_out_o {
      bins zero         = {0};
      bins f1_to_f10    = {[1:55]};         // F(1)=1  … F(10)=55
      bins f11_to_f15   = {[56:610]};       // F(11)=89 … F(15)=610
      bins f16_to_f20   = {[611:6765]};     // F(16)=987 … F(20)=6765
      bins f21_to_f25   = {[6766:75025]};   // F(21)=10946 … F(25)=75025
      bins f26_plus     = {[75026:$]};      // F(26)+ including post-overflow
    }

    // ── 6. Internal register b value range ───────────────────────────────────
    // b holds the lookahead value. Tracking its range separately from a
    // ensures the full recurrence state space is exercised.
    cp_b_value : coverpoint b_i {
      bins zero         = {0};
      bins small        = {[1:610]};
      bins medium       = {[611:75025]};
      bins large        = {[75026:$]};
    }

    // ── 7. Enable run length ─────────────────────────────────────────────────
    // How many consecutive cycles enable stays high.
    // Short runs (1-3) test single/double-step; long runs (8+) exercise
    // the steady-state sequence and overflow scenarios.
    cp_en_run : coverpoint en_run {
      bins run_1    = {1};
      bins run_2    = {2};
      bins run_3    = {3};
      bins run_4_7  = {[4:7]};
      bins run_8_15 = {[8:15]};
      bins run_16p  = {[16:$]};
    }

    // ── 8. Hold run length ───────────────────────────────────────────────────
    // How many consecutive cycles enable stays low (output held stable).
    // Exercising hold_1 through hold_10+ validates the HLD requirements.
    cp_hold_run : coverpoint hold_run {
      bins hold_1    = {1};
      bins hold_2    = {2};
      bins hold_3    = {3};
      bins hold_4_9  = {[4:9]};
      bins hold_10p  = {[10:$]};
    }

    // ── 9. Overflow / wrap-around ────────────────────────────────────────────
    // Sticky flag: closed as soon as one wrap-around is observed.
    // Ensures OVF-001 is exercised at least once per simulation run.
    cp_overflow : coverpoint overflow_flag {
      bins no_overflow = {1'b0};
      bins overflow    = {1'b1};
    }

    // ── 10. Reset context: asserted during enable vs. during hold ────────────
    // Distinguishes the two reset scenarios from Specs RST-001/RST-002.
    cp_rst_while_en : coverpoint rst_while_en {
      bins rst_during_enable = {1'b1};
      bins rst_during_hold   = {1'b0};
    }

    // ── Cross coverpoints ────────────────────────────────────────────────────

    // x_en_rst: every combination of enable × reset state.
    // Includes the unusual corner: enable=1 while rst_ni=0.
    x_en_rst : cross cp_enable, cp_rst;

    // x_val_en: confirms that a wide range of Fibonacci values are observed
    // both while the generator is advancing (enable=1) and during hold (enable=0).
    x_val_en : cross cp_fib_value, cp_enable;

    // x_run_val: correlates run length with the output value range reached.
    // A long run should reach higher Fibonacci values or overflow.
    x_run_val : cross cp_en_run, cp_fib_value;

  endgroup : fib_cg

  // ---------------------------------------------------------------------------
  // Instantiate the covergroup
  // ---------------------------------------------------------------------------
  fib_cg fib_cg_inst = new();

endmodule : fcover

`default_nettype wire
