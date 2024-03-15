////////////////////////////////////////////////////////////////////////////////
// Filename    : tb_jtag.v
// Description : 
//
// Author      : Phu Vuong
// History     : Mar 15, 2042 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/10ps
module tb_jtag;
    ////////////////////////////////////////////////////////////////////////////
    //param declaration
    ////////////////////////////////////////////////////////////////////////////
    parameter   JTAG_CYCLE      = 100; //ns -> 10MHz

    parameter   VERSION         = 4'h0;
    parameter   PART_NUMBER     = 16'h1;
    parameter   MANUFLD         = 11'h12;

    ////////////////////////////////////////////////////////////////////////////
    //logic declaration
    ////////////////////////////////////////////////////////////////////////////
    //-----------------------
    //jtag inteface
    logic                       trstn;
    logic                       tck;
    logic                       tms;
    logic                       tdi;
    logic                       jtag_tdo;
    logic                       tdo_enable;

    //-----------------------
    //dmi register
    logic                       dmi_ack;
    logic                       dmi_op;
    logic       [31:0]          dmi_rdata;
    logic                       dmi_rdata_valid;
    logic       [31:0]          dmi_addr;
    logic       [31:0]          dmi_wdata;
    logic                       dmi_we;
    logic                       dmi_req;

    //-----------------------
    //dtmcs register
    logic       [3:0]           dtmcs_version;
    logic       [5:0]           dtmcs_abits;
    logic       [1:0]           dtmcs_dmistat;
    logic       [2:0]           dtmcs_idle;
    logic                       dtmcs_dmireset;
    logic                       dtmcs_dmihardreset;

    //-----------------------
    //tdo buffer
    logic                       tdo;
    
    ////////////////////////////////////////////////////////////////////////////
    //instance (dut)
    ////////////////////////////////////////////////////////////////////////////
    jtag #(
        .VERSION(VERSION),
        .PART_NUMBER(PART_NUMBER),
        .MANUFLD(MANUFLD)
    ) i_jtag (
        //-----------------------
        //jtag inteface
        .jtag_trstn_i(trstn),
        .jtag_tck_i(tck),
        .jtag_tms_i(tms),
        .jtag_tdi_i(tdi),
        .jtag_tdo_o(jtag_tdo),
        .jtag_tdo_enable_o(tdo_enable),

        //-----------------------
        //dmi register
        .dmi_ack_i(dmi_ack),
        .dmi_op_i(dmi_op),
        .dmi_rdata_i(dmi_rdata),
        .dmi_rdata_valid_i(dmi_rdata_valid),
        .dmi_addr_o(dmi_addr),
        .dmi_wdata_o(dmi_wdata),
        .dmi_we_o(dmi_we),
        .dmi_req_o(dmi_req),

        //-----------------------
        //dtmcs register
        .dtmcs_version_i(dtmcs_version),
        .dtmcs_abits_i(dtmcs_abits),
        .dtmcs_dmistat_i(dtmcs_dmistat),
        .dtmcs_idle_i(dtmcs_idle),
        .dtmcs_dmireset_o(dtmcs_dmireset),
        .dtmcs_dmihardreset_o(dtmcs_dmihardreset)
    );
	
	
    ////////////////////////////////////////////////////////////////////////////
    //internal connection
    ////////////////////////////////////////////////////////////////////////////
    //tdo buffer
    assign tdo = tdo_enable ? jtag_tdo : 1'bz;


    ////////////////////////////////////////////////////////////////////////////
    //testbench
    ////////////////////////////////////////////////////////////////////////////
    initial begin
        //init
        init_jtag();
        init_dmi();
        init_dtmcs();

        //init reset and clock
        trstn = 1'b1;
        tck = 1'b1;


        //finish
        #(10 * JTAG_CYCLE) $finish;
    end

    //clock
    always begin
        #JTAG_CYCLE tck = ~tck;
    end

    //waveform
    initial begin
        $dumpfile("jtag.vcd");
        $dumpvars(0, tb_jtag);
    end

    ////////////////////////////////////////////////////////////////////////////
    //task
    ////////////////////////////////////////////////////////////////////////////
    task init_dtmcs;
        begin
            dtmcs_version = 4'h0;
            dtmcs_abits = 6'h32;
            dtmcs_dmistat = 2'h0;
            dtmcs_idle = 3'h1;
        end
    endtask

    task init_dmi;
        begin
            dmi_ack = 1'h0;
            dmi_op = 2'h0;
            dmi_rdata = 32'h0;
            dmi_rdata_valid = 1'h0;
        end
    endtask

    task init_jtag;
        begin
            tms = 1'b0;
            tdi = 1'b0;
        end
    endtask
endmodule
