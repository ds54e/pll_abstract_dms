module pll_core #(
  parameter realtime vclk_initial_period = 1ns,
  parameter realtime freq_acq_time = 1us,
  parameter bit skip_phase_lock = 1'b0,
  parameter realtime delta_t_tol = 10ps,
  parameter int unsigned lock_count_max = 10,
  parameter real k_tdc = 1e-1,
  parameter bit use_adjusted_tdc_gain = 1'b1
)(
  input wire vdd,
  input wire vss,
  input wire rclk,
  input wire en,
  input wire [7:0] fbdiv,
  output wire vclk,
  output wire lock
);
  timeunit 1s;
`ifdef PLL_TIME_PRECISION
  timeprecision `PLL_TIME_PRECISION;
`else
  timeprecision 1fs;
`endif

  typedef enum int unsigned {POWER_DOWN, STAND_BY, ACTIVE} state_e;
  
  state_e state;
  
  always_comb begin
    if (vdd && !vss) begin
      if (en) begin
        state = ACTIVE;
      end else begin
        state = STAND_BY;
      end
    end else begin
      state = POWER_DOWN;
    end
  end

  int unsigned n_mult;

  always_comb begin
    case (state)
      STAND_BY, ACTIVE: begin
        if (fbdiv > 0) begin
          n_mult = fbdiv;
        end else begin
          n_mult = 1;
        end
      end
      default: begin
        n_mult = 0;
      end
    endcase
  end

  bit clk_enable;

  always_comb begin
    case (state)
      ACTIVE: begin
        clk_enable = 1'b1;
      end
      default: begin
        clk_enable = 1'b0;
      end
    endcase
  end

  bit clk_enable_sync;

  always_ff @(posedge rclk, negedge clk_enable) begin
    if (!clk_enable) begin
      clk_enable_sync <= 1'b0;
    end else begin
      clk_enable_sync <= clk_enable;
    end
  end

  realtime last_tr;
  realtime rclk_period;

  always_ff @(posedge rclk, negedge clk_enable_sync) begin
    if (!clk_enable_sync) begin
      rclk_period <= 0;
      last_tr <= 0;
    end else begin
      if (last_tr > 0) begin
        rclk_period <= ($realtime - last_tr);
      end
      last_tr <= $realtime;
    end
  end

  realtime vclk_target_period;

  always_ff @(posedge rclk, negedge clk_enable_sync) begin
    if (!clk_enable_sync) begin
      vclk_target_period <= 0;
    end else begin
      if (n_mult > 0) begin
        vclk_target_period <= (rclk_period / n_mult);
      end else begin
        vclk_target_period <= 0;
      end
    end
  end

  bit var_vclk;
  realtime delta_t;

  always @(posedge rclk, negedge clk_enable_sync) begin
    if (!clk_enable_sync) begin
      delta_t <= 0;
    end else begin
      @(posedge var_vclk);
      delta_t <= ($realtime - last_tr);
    end
  end

  realtime t_vclk_start;
  realtime t_freq_acq_start;
  realtime vclk_period;
  bit freq_acq_done;
  real tdc_gain;
  realtime tdc_out;

  initial forever begin
    wait(clk_enable_sync);
    t_vclk_start = $realtime;
    fork begin
      fork begin
        forever begin
          if (vclk_target_period > 0) begin
            if (t_freq_acq_start == 0) begin
              t_freq_acq_start = $realtime;
            end
            if ($realtime < (t_vclk_start + freq_acq_time)) begin
              freq_acq_done = 1'b0;
              vclk_period = (
                vclk_initial_period + (
                  (vclk_target_period - vclk_initial_period) * (
                    ($realtime - t_freq_acq_start) / (freq_acq_time - (t_freq_acq_start - t_vclk_start))
                  )
                )
              );
            end else begin
              freq_acq_done = 1'b1;
              if (skip_phase_lock) begin
                tdc_out = 0;
              end else begin
                if (use_adjusted_tdc_gain) begin
                  tdc_gain = (k_tdc / n_mult);
                end else begin
                  tdc_gain = k_tdc;
                end
                tdc_out = (tdc_gain * delta_t);
              end
              vclk_period = (vclk_target_period - tdc_out);
            end
          end else begin
            vclk_period = vclk_initial_period;
          end
          #(0.5 * vclk_period);
          var_vclk = ~var_vclk;
        end
      end join_none
      wait(!clk_enable_sync);
      disable fork;
    end join
    t_vclk_start = 0;
    t_freq_acq_start = 0;
    var_vclk = 1'b0;
    vclk_period = 0;
    freq_acq_done = 1'b0;
    tdc_out = 0;
  end

  assign vclk = var_vclk;

  bit lock_async;

  always_comb begin
    if (skip_phase_lock) begin
      lock_async = freq_acq_done;
    end else begin
      lock_async = (freq_acq_done && (delta_t < delta_t_tol));
    end
  end

  bit lock_flag;
  int unsigned lock_count;

  always_ff @(posedge rclk, negedge clk_enable_sync) begin
    if (!clk_enable_sync) begin
      lock_count <= 0;
      lock_flag <= 0;
    end else begin
      if (lock_async) begin
        if (lock_count >= lock_count_max) begin
          lock_count <= lock_count;
          lock_flag <= 1'b1;
        end else begin
          lock_count <= lock_count + 1;
          lock_flag <= 1'b0;
        end
      end else begin
        lock_count <= 0;
        lock_flag <= 1'b0;
      end
    end
  end

  assign lock = lock_flag;

endmodule