package my_pkg;
  timeunit 1s;
  timeprecision 1ps;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  class simple_test extends uvm_test;
    `uvm_component_utils(simple_test)
    
    virtual pll_if vif;

    function new (string name="simple_test", uvm_component parent=null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual pll_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal(get_type_name(), "Failed to get vif")
      end
    endfunction

    virtual task run_phase (uvm_phase phase);
      phase.raise_objection(this);
      `uvm_info(get_type_name(), "Started", UVM_MEDIUM)
      vif.mp.power_down();
      `uvm_info(get_type_name(), "Power-down", UVM_MEDIUM)
      vif.mp.power_up();
      `uvm_info(get_type_name(), "Power-up", UVM_MEDIUM)
      vif.mp.enable(2);
      `uvm_info(get_type_name(), $sformatf("Enabled with FBDIV = %0d", 2), UVM_MEDIUM)
      vif.mp.wait_for_lock(100us);
      `uvm_info(get_type_name(), $sformatf("LOCK = %0b", vif.mp.is_locked), UVM_MEDIUM)
      if (!vif.mp.is_locked) begin
        `uvm_error(get_type_name(), "Failed to lock")
      end
      vif.mp.standby();
      `uvm_info(get_type_name(), "Stand-by", UVM_MEDIUM)
      vif.mp.delay(2);
      `uvm_info(get_type_name(), "Finished", UVM_MEDIUM)
      phase.drop_objection(this);
    endtask
  endclass
  
endpackage
