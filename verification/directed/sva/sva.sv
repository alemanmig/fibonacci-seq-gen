import config_pkg::*;
module sva (
  input logic             clk,
  input logic             rst_n,
  input logic             enable,
  input logic [W-1:0]     fib_out,
  input logic [W-1:0]     a,
  input logic [W-1:0]     b
);

logic [W-1:0] Last_out;

always  @(posedge clk, negedge rst_n) begin
  if  (!rst_n)  begin
    Last_out  <= '0;
  end
  else  begin
    if  (enable)  begin
      Last_out  <=  fib_out;
    end
  end
end

property  seq_proper;
  @(posedge clk)
    disable iff(!rst_n  ||  (fib_out ==  'd0) ||  (Last_out == 'd0))
      enable  |=> fib_out ==  $past(fib_out)  + $past(Last_out);
endproperty

property  Rst_proper;
  @(negedge rst_n or posedge clk)
    !rst_n  |-> (fib_out=='d0);
endproperty

property  Begin_proper;
  @(posedge clk)
    disable iff(!rst_n)
      ((enable==1'b1) &&  (fib_out=='d0)) &&  (rst_n==1'b1)  |=> ($rose(fib_out));
endproperty

property  Double_one_proper;
  @(posedge clk)
    disable iff(!rst_n)
      ((enable==1'b1)  &&  (fib_out=='d1) &&  ($past(fib_out)=='d0)) |=> (fib_out=='d1);
endproperty

property  First_seq_proper;
  @(posedge clk)
    disable iff(!rst_n)
      ( (($past(fib_out,4)=='d0)  &&  ($past(enable,4)==1'b1))  &&
        (($past(fib_out,3)=='d1)  &&  ($past(enable,3)==1'b1))  &&
        (($past(fib_out,2)=='d1)  &&  ($past(enable,2)==1'b1))  &&
        (($past(fib_out,1)=='d2)  &&  ($past(enable,1)==1'b1))  &&
        ((fib_out=='d3)           &&  (enable==1'b1)))  |=>
      (fib_out=='d5);
endproperty

property  Hold_proper;
  @(posedge clk)
    disable iff(!rst_n || !$past(rst_n))
      (!enable  && $stable(enable)  &&  $stable(rst_n)) |-> $stable(fib_out);
endproperty

Rst_Assert  : assert  property(Rst_proper)
  $info("Reset Passed");
else
  $error("Reset not Passed");

Begin_assert  : assert  property(Begin_proper)
  $info("Inicio correcto");
else
  $display("enable_past=%b,rst_past=%b, fib_out_past=%0d, enable_cur=%b,rst_cur=%b, fib_out_cur=%0d",$past(enable), $past(rst_n), $past(fib_out), enable, rst_n, fib_out);

Double_one_Assert : assert  property(Double_one_proper)
  $info("Inicio correcto");
else
  $error("Inicio incorrecto");

First_full_seq_assert : assert  property(First_seq_proper)
  $info("Primera secuencia correcta");
else
  $error("Primera secuencia incorrecta");

Hold_assert : assert  property(Hold_proper)
  $info("Salida estable durante HOLD");
else
  $error("Salida NO estable durante HOLD");

seq_assert  : assert  property(seq_proper)
  $info("Secuencia correcta");
else
  $error("Secuencia incorrecta");

endmodule

bind fib_gen  sva sva_fibgen(.*);