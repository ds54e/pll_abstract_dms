module top
`ifdef DMS
  import rnm_pkg::nreal;
`endif
();
  timeunit 1s;
  timeprecision 1ps;

  import uvm_pkg::*;
  import my_pkg::*;

  parameter realtime clk_period = 100ns;
  bit clk = 1'b0;

  initial begin
    forever begin
      #(0.5 * clk_period);
      clk = ~clk;
    end
  end

  pll_if intf (
    .rclk(clk)
  );

`ifdef DMS
  parameter real vhi = 1.0;
  parameter real vlo = 0.0;
  parameter real vth = 0.5;
  genvar i;
  nreal VSS; assign VSS  = (intf.vss ? vhi : vlo);
  nreal VDD; assign VDD = ((intf.vdd ? vhi : vlo) + VSS);
  nreal RCLK; assign RCLK = ((intf.rclk ? vhi : vlo) + VSS);
  nreal EN; assign EN = ((intf.en ? vhi : vlo) + VSS);
  nreal FBDIV [7:0];
  generate
    for (i = 0; i < 8; i++) begin assign FBDIV[i] = ((intf.fbdiv[i] ? vhi : vlo) + VSS); end
  endgenerate
  nreal VCLK; assign intf.vclk = ((VCLK - VSS) > vth);
  nreal LOCK; assign intf.lock = ((LOCK - VSS) > vth);
`else
  genvar i;
  wire VSS = intf.vss;
  wire VDD = intf.vdd;
  wire RCLK = intf.rclk;
  wire EN = intf.en;
  wire [7:0] FBDIV = intf.fbdiv;
  wire VCLK; assign intf.vclk = VCLK;
  wire LOCK; assign intf.lock = LOCK;
`endif

  PLL dut (
    .VDD,
    .VSS,
    .RCLK,
    .EN,
    .FBDIV,
    .VCLK,
    .LOCK
  );

  initial begin
    uvm_config_db#(virtual pll_if)::set(uvm_root::get(), "*", "vif", intf);
    run_test();
  end
  
endmodule