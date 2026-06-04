module tb;

  timeunit      1ns;
  timeprecision 100ps;

  import config_pkg::*;

  // Clock signal
  logic clk = 0;
  localparam int unsigned ClkPeriod = 10;  // 100 MHz -> 10 ns period
  always #( (ClkPeriod / 2) * 1ns) clk = ~clk;

  // Interface
  vif_if vif (clk);

  // Test
  test top_test (vif);

  // Instantiation
  fib_gen #(
    .W        (W)
  ) dut (
    .clk      (vif.clk),
    .rst_n    (vif.rst_n),
    .enable   (vif.enable),
    .fib_out  (vif.fib_out)
  );

bind dut sva
dut_sva (
  .clk      (vif.clk),
  .rst_n    (vif.rst_n),
  .enable   (vif.enable),
  .fib_out  (vif.fib_out)
);

bind dut fcover
dut_fcover (
  .clk      (clk),
  .rst_n    (rst_n),
  .enable   (enable),
  .fib_out  (fib_out),
  .fib_a    (a),
  .fib_b    (b)
);

  initial begin
    $timeformat(-9, 1, "ns", 10);
  end

endmodule : tb
