`include "uvm_macros.svh"
import uvm_pkg::*;

////////////////////// item_select_transaction //////////////////
class item_sel_trans#(parameter int MAX_ITEMS = 32) extends uvm_sequence_item;
  `uvm_object_param_utils(item_sel_trans#(MAX_ITEMS)) // Factory registration

  rand bit item_select_valid;
  rand bit [$clog2(MAX_ITEMS)-1  : 0] item_select;
  
  function new(string name="item_sel_trans");
    super.new(name);
  endfunction
  
endclass

////////////////////// item_select_generator //////////////////
class item_sel_gen extends uvm_sequence#(item_sel_trans#(32));
  `uvm_object_utils(item_sel_gen) // Factory registration

  function new(string name="item_sel_gen");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(10) begin
      item_sel_trans#(32) tg;
      tg = item_sel_trans#(32)::type_id::create("tg");
      start_item(tg);
      assert(tg.randomize());
      `uvm_info("GEN", $sformatf("item_select_valid:%b || item_select:%d", tg.item_select_valid, tg.item_select), UVM_NONE)
      finish_item(tg);
    end
  endtask
  
endclass

////////////////////// item_select_driver //////////////////
class item_sel_drv extends uvm_driver#(item_sel_trans#(32));
  `uvm_component_utils(item_sel_drv) // Factory registration

  virtual item_sel_if #(32) sif;
  
  function new(string name="item_sel_drv", uvm_component parent =null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual item_sel_if #(32))::get(this, "", "sif", sif))
      `uvm_error("DRV", "unable to access config db")
  endfunction
      
  virtual task run_phase(uvm_phase phase);
    forever begin
      item_sel_trans#(32) td;
      td = item_sel_trans#(32)::type_id::create("td");
      
      seq_item_port.get_next_item(td);
      sif.item_select_valid <= td.item_select_valid;
      sif.item_select <= td.item_select;
      
      `uvm_info("DRV", $sformatf("item_select_valid:%b || item_select:%d", td.item_select_valid, td.item_select), UVM_NONE)
      
      #10;
      seq_item_port.item_done();
    end
  endtask
  
endclass

////////////////////// item_select_monitor //////////////////
class item_sel_mon extends uvm_monitor;
  `uvm_component_utils(item_sel_mon) // Factory registration

  virtual item_sel_if #(32) sif;
  
  function new(string path="item_sel_mon", uvm_component parent=null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual item_sel_if #(32))::get(this, "", "sif", sif))
      `uvm_error("MON", "Unable to access config db");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      `uvm_info("MON", $sformatf("item_select_valid:%b || item_select:%d", sif.item_select_valid, sif.item_select), UVM_NONE)
    end
  endtask
  
endclass

////////////////////// item_select_agent //////////////////
class item_sel_agn extends uvm_agent;
  `uvm_component_utils(item_sel_agn) // Factory registration

  item_sel_drv d;
  item_sel_mon m;
  uvm_sequencer#(item_sel_trans#(32)) item_sel_seqr;
  
  function new(string path="item_sel_agent", uvm_component parent=null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d = item_sel_drv::type_id::create("d", this);
    m = item_sel_mon::type_id::create("m", this);
    item_sel_seqr = uvm_sequencer#(item_sel_trans#(32))::type_id::create("item_sel_seqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(item_sel_seqr.seq_item_export);
  endfunction
  
endclass

////////////////////// item_select_test //////////////////
class item_sel_test extends uvm_test;
  `uvm_component_utils(item_sel_test) // Factory registration

  item_sel_agn agn;
  
  function new(string name="item_sel_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agn = item_sel_agn::type_id::create("agn", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    item_sel_gen gen;
    gen = item_sel_gen::type_id::create("gen");

    phase.raise_objection(this);
    gen.start(agn.item_sel_seqr);
    phase.drop_objection(this);
  endtask
endclass

////////////////////// Testbench Module //////////////////
module tb;
  item_sel_if #(32) sif();

  initial begin
    uvm_config_db#(virtual item_sel_if#(32))::set(null, "*", "sif", sif);
    run_test("item_sel_test"); 
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
