module test (
    vif_if vif
);
  // =================== DPI FUNCTIONS ==================== //
  //import "DPI-C" function real ref_model(real initial_value);

  // ================== GLOBAL VARIABLES ================== //

  import config_pkg::*;

  // =================== MAIN SEQUENCE ==================== //

  initial begin
    // Initial values
    $display("Begin Of Simulation.");
//    get_config_args();

    // Apply reset
    reset();
    //
    TC_RST_01();
    TC_RST_02();
    TC_RST_03();
    reset();
    TC_SEQ_01();
    reset();
    TC_SEQ_02();
    reset();
    TC_SEQ_03();
    reset();
    TC_HLD_01();
    reset();
    TC_HLD_02();

    // Drain time
    #(100ns);
    $display("End Of Simulation.");
    $finish;
  end


  // ======================= TASKS ======================== //

  task automatic reset();
    vif.rst_n = 1'b1;
    repeat (2) @(posedge vif.clk);
    vif.rst_n = 1'b0;
    @(posedge vif.clk);
    vif.rst_n = 1'b1;
    @(posedge vif.clk);
  endtask : reset

  task  automatic init();
    @(posedge vif.clk);
    vif.rst_n   = 1'b1;
    vif.enable  = 1'b0;
    @(posedge vif.clk);
  endtask

  task  automatic EnDis();
    vif.enable  = 1'b1;
    @(posedge vif.clk);
    vif.enable  = 1'b0;
    @(posedge vif.clk);
  endtask : EnDis

  /*
  TC-RST-01: Reset asíncrono desde estado arbitrario
  Se aplica reset en un estado avanzado arbitrario
  */
  task automatic  TC_RST_01();
    init();
    vif.enable  = 1'b1;
    @(vif.fib_out=='d55);
    #7;
    vif.rst_n   = 1'b0;
    repeat  (2) @(posedge vif.clk);
    vif.rst_n   = 1'b1;
    @(posedge vif.clk);
  endtask : TC_RST_01
  /*
  TC-RST-02: Reset asíncrono — independiente de enable
  */
  task  automatic TC_RST_02();
    init();
    vif.enable = 1'b1;
    @(vif.fib_out=='d13);
    vif.enable  = 1'b0;
    @(posedge vif.clk);
    vif.rst_n   = 1'b0;
    repeat  (2) @(posedge vif.clk);
    vif.rst_n   = 1'b1;
    @(posedge vif.clk);
  endtask : TC_RST_02
  /*
  TC-RST-03: Secuencia correcta tras liberar reset
  */
  task  automatic TC_RST_03();
    init();
    vif.rst_n = 1'b0;
    @(posedge vif.clk);
    vif.rst_n = 1'b1;
    vif.enable  = 1'b1;
    repeat(8)@(posedge vif.clk);
    vif.enable  = 1'b0;
  endtask : TC_RST_03
  /*
  TC-SEQ-01: Secuencia Fibonacci continua (enable siempre activo)
  */
  task  automatic TC_SEQ_01();
    init();
    vif.enable  = 1'b1;
    repeat  (12)  @(posedge vif.clk);
    vif.enable  = 1'b0;
    @(posedge vif.clk);
  endtask : TC_SEQ_01
  /*
  TC-SEQ-02: Verificación de la relación F(n) = F(n-1) + F(n-2)
  */
  task  automatic TC_SEQ_02();
    init();
    vif.enable  = 1'b1;
    repeat  (20)  @(posedge vif.clk);
    vif.enable  = 1'b0;
    @(posedge vif.clk);
  endtask : TC_SEQ_02
  /*
  TC-SEQ-03: Pulso de enable de un solo ciclo
  */
  task  automatic TC_SEQ_03();
    init();
    repeat (20)EnDis();
  endtask
  /*
  TC-HLD-01: Hold prolongado — enable=0 por múltiples ciclos
  */
  task  automatic TC_HLD_01();
    init();
    vif.enable  = 1'b1;
    repeat  (5) @(posedge vif.clk);
    vif.enable  = 1'b0;
    repeat  (10)  @(posedge vif.clk);
  endtask : TC_HLD_01
  /*
  TC-HLD-02: Reanuda desde valor retenido
  */
  task  automatic TC_HLD_02();
    TC_HLD_01();
    vif.enable  = 1'b1;
    repeat  (5) @(posedge vif.clk);
  endtask : TC_HLD_02

  // ===================== FUNCTIONS ====================== //

  // =====================   COVER   ====================== //


endmodule : test
