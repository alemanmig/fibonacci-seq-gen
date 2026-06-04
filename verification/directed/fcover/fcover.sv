`default_nettype none
module  fcover  (
  input logic             clk,
  input logic             rst_n,
  input logic             enable,
  input logic [W-1:0]     fib_out,
  input logic [W-1:0]     fib_a,
  input logic [W-1:0]     fib_b
);
covergroup  fib_cov @(posedge clk);
    fib_en :    coverpoint  enable  {
        bins    en_enabled     =   {1'b1};
        bins    en_disabled    =   {1'b0};
    }
    fib_rst :   coverpoint  rst_n   {
        bins    res_enabled     =   {1'b1};
        bins    res_disabled    =   {1'b0};
    }
    fib_output  :   coverpoint  fib_out {
        bins    zero        =   {0};
        bins    f1_2_f10    =   {[1:55]};
    }
endgroup    :   fib_cov

fib_cov fib_cov_data    =   new();

endmodule

`default_nettype wire