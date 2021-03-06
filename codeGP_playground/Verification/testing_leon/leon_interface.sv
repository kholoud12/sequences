interface GUVM_interface(input  clk );
   import uvm_pkg::*;
`include "uvm_macros.svh"
    import iface::*; // importing leon interface package: includes the records
    import target_package::*; // importing leon core package

    // core interface ports: declaring records
    //bit clk ; 
    logic       clk_pseudo;
    logic       rst;
    logic       pciclk;
    logic       pcirst;
    //for debugging only 
    

    iu_in_type integer_unit_input; // to the core
    iu_out_type integer_unit_output; // from the core
    
    icache_out_type icache_output; // to the core
    icache_in_type icache_input; // address to the instruction cach

    dcache_out_type dcache_output; // to the core
    
    dcache_in_type dcache_input ; // to the data cach

    icdiag_in_type dcache_output_diag; // inside dcache_out_type package // what is this ? 

    // declaring the monitor
    GUVM_monitor monitor_h;

    bit allow_pseudo_clk;

    // initializing the clk_pseudo signal
    initial begin
        clk_pseudo = 0;
        allow_pseudo_clk = 0 ;
	end	


    always @(clk) begin
        if (allow_pseudo_clk)begin
            clk_pseudo = clk;
        end
    end

    always @ (posedge clk_pseudo)  force dut.iu0.de.cwp=7; // 
	
    // sending data to the core
    function void send_data(logic [31:0] data);
        dcache_output.data = data ;
    endfunction

    // sending instructions to the core
    function void send_inst(logic [31:0] inst);
        icache_output.data = inst ; 
    endfunction
	
    // sending the instruction to be verified
	task verify_inst(logic [31:0] inst);
        send_inst(inst) ; 
        allow_pseudo_clk =1 ;
        @(posedge clk_pseudo) ;
        allow_pseudo_clk =0 ;
    endtask

	// reveiving data from the DUT
    function logic [31:0] receive_data();//should be protected
        monitor_h.write_to_monitor(dcache_input.edata);
        return dcache_input.edata;
    endfunction 
	
	// dealing with the register file with the following load and store functions 
    //function logic [31:0] store(logic [4:0] ra);
    task store(logic [31:0] inst );
        send_inst(inst);
        allow_pseudo_clk =1 ;
        repeat(2)@(posedge clk_pseudo);        
        bfm.nop();
        repeat(2)@(posedge clk_pseudo);//repeat onde might cause a problem ???????????
		$display("result = %0d",receive_data());
        repeat(10)@(posedge clk_pseudo);
        allow_pseudo_clk =0 ;
    endtask

    task load(logic [31:0] inst, logic [31:0] rd );
        send_inst(inst);
        send_data(rd);
        allow_pseudo_clk =1 ;
        repeat(1)@(posedge clk_pseudo);
        nop();
        repeat(4)@(posedge clk_pseudo);
        allow_pseudo_clk =0 ;
    endtask

    // no operation
    function void nop();
        icache_output.data = 32'h01000000;
    endfunction

    // initializing the core
    task set_Up();
        send_data(32'h100);
        send_inst(32'h01000000);
		pciclk = 1'b0;
        pcirst = 1'b0;

        // iui
        integer_unit_input.irl = 4'b0000;

        // ico
        // icache_output.data = 32'h8E00C002;
        icache_output.exception = 1'b0;
        icache_output.hold = 1'b1;
        icache_output.flush = 1'b0; 
        icache_output.diagrdy = 1'b0;
        icache_output.diagdata = 32'h00000000; 
        icache_output.mds = 1'b0;

        // dco
        //dcache_output.data = 32'h13; // Data bus address
        dcache_output.mexc = 1'b0; // memory exception
        dcache_output.hold = 1'b1;
        dcache_output.mds = 1'b1;
        dcache_output.werr = 1'b0; // memory write error

        dcache_output_diag.addr = 15 ;
        //dcache_output_diag.enable = 32'h0;
        dcache_output_diag.enable = 1'b0;
        dcache_output_diag.read = 1'b0;
        dcache_output_diag.tag = 1'b0;
        dcache_output_diag.flush = 1'b0;

        dcache_output.icdiag=dcache_output_diag;
        $display("we reached this point at set up");
        allow_pseudo_clk =1 ;
        repeat(10)@(posedge clk_pseudo);
        allow_pseudo_clk =0 ;
    endtask

    task reset_dut();
        rst = 1'b0;
        allow_pseudo_clk =1 ;
        $display("we reached this point at reset");
        repeat(10)@(posedge clk_pseudo);     
		rst = 1'b1;
        repeat(1)@(posedge clk_pseudo);
        allow_pseudo_clk =0 ;
    endtask : reset_dut

endinterface: GUVM_interface