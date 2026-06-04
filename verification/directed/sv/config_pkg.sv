`ifndef CONFIG_PKG_SV
`define CONFIG_PKG_SV

package config_pkg;

  // ====== TESTBENCH PARAMETERS ====== //

  localparam int unsigned ClkFreq       = 100_000_000; // 100 MHz
  localparam int unsigned StableTime    = 1;           // 1 ms

  localparam  W = 16;
endpackage : config_pkg

`endif // CONFIG_PKG_SV
