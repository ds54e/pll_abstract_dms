module PLL
`ifdef DMS
  import rnm_pkg::nreal;
`endif
#(
`ifdef DMS
  parameter real vhi = 1.0,
  parameter real vlo = 0.0,
  parameter real vth = 0.5,
`endif
  parameter realtime vclk_initial_period = 1ns,
  parameter realtime freq_acq_time = 1us,
  parameter bit skip_phase_lock = 1'b0,
  parameter realtime delta_t_tol = 10ps,
  parameter int unsigned lock_count_max = 10,
  parameter real k_tdc = 1e-1,
  parameter bit use_adjusted_tdc_gain = 1'b1
)(
`ifdef DMS
  inout nreal VDD,
  inout nreal VSS,
  input nreal RCLK,
  input nreal EN,
  input nreal FBDIV [7:0],
  output nreal VCLK,
  output nreal LOCK
`else
  inout wire VDD,
  inout wire VSS,
  input wire RCLK,
  input wire EN,
  input wire [7:0] FBDIV,
  output wire VCLK,
  output wire LOCK
`endif
);
  timeunit 1s;
`ifdef PLL_TIME_PRECISION
  timeprecision `PLL_TIME_PRECISION;
`else
  timeprecision 1fs;
`endif

  wire VDD$logic;
  wire VSS$logic;
  wire RCLK$logic;
  wire EN$logic;
  wire [7:0] FBDIV$logic;
  wire VCLK$logic;
  wire LOCK$logic;

`ifdef DMS
  genvar i;
  assign VDD$logic = (VDD - VSS > vth);
  assign VSS$logic = (VSS > vth);
  assign RCLK$logic = ((RCLK - VSS) > vth);
  assign EN$logic = ((EN - VSS) > vth);
  generate
    for (i = 0; i < 8; i++) begin assign FBDIV$logic[i] = ((FBDIV[i] - VSS) > vth); end
  endgenerate
  assign VCLK = ((VCLK$logic ? vhi : vlo) + VSS);
  assign LOCK = ((LOCK$logic ? vhi : vlo) + VSS);
`else
  assign VDD$logic = VDD;
  assign VSS$logic = VSS;
  assign RCLK$logic = RCLK;
  assign EN$logic = EN;
  assign FBDIV$logic = FBDIV;
  assign VCLK = VCLK$logic;
  assign LOCK = LOCK$logic;
`endif

  pll_core #(
    .vclk_initial_period(vclk_initial_period),
    .freq_acq_time(freq_acq_time),
    .skip_phase_lock(skip_phase_lock),
    .delta_t_tol(delta_t_tol),
    .lock_count_max(lock_count_max),
    .k_tdc(k_tdc),
    .use_adjusted_tdc_gain(use_adjusted_tdc_gain)
  ) core (
    .vdd(VDD$logic),
    .vss(VSS$logic),
    .rclk(RCLK$logic),
    .en(EN$logic),
    .fbdiv(FBDIV$logic),
    .vclk(VCLK$logic),
    .lock(LOCK$logic)
  );

endmodule