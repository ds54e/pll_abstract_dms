interface pll_if (
  input logic rclk
);
  timeunit 1s;
  timeprecision 1ps;

  localparam realtime input_skew = 0.2ns;
  localparam realtime output_skew = 0.2ns;

  logic vdd;
  logic vss;
  logic en;
  logic [7:0] fbdiv;
  logic vclk;
  logic lock;

  clocking cb @(posedge rclk);
    default input #(input_skew) output #(output_skew);
    output vdd;
    output vss;
    output en;
    output fbdiv;
    input lock;
  endclocking

  modport mp (
    clocking cb,
    input rclk,
    input vclk,
    import power_down,
    import power_up,
    import standby,
    import enable,
    import wait_for_lock,
    import is_locked,
    import delay
  );

  task automatic power_down ();
    @(cb);
    cb.vdd <= 1'b0;
    cb.vss <= 1'b0;
    cb.en <= 1'b0;
    cb.fbdiv <= 8'b0;
  endtask

  task automatic power_up ();
    @(cb);
    cb.vdd <= 1'b1;
    cb.vss <= 1'b0;
    cb.en <= 1'b0;
    cb.fbdiv <= 8'b0;
  endtask

  task automatic standby ();
    @(cb);
    cb.en <= 1'b0;
  endtask

  task automatic enable (logic [7:0] n);
    @(cb);
    cb.fbdiv <= n;
    @(cb);
    cb.en <= 1'b1;
  endtask

  task automatic wait_for_lock (realtime timeout);
    bit timed_out;
    if (timeout > 0) begin
      fork begin
        fork begin
          #(timeout);
          timed_out = 1'b1;
        end join_none
        wait(cb.lock || timed_out);
        disable fork;
      end join
    end else begin
      wait(cb.lock);
    end
  endtask

  function automatic is_locked ();
    return (lock === 1'b1);
  endfunction

  task automatic delay (int unsigned n);
    repeat (n) begin
      @(cb);
    end
  endtask

endinterface