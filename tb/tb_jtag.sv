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

    //-----------------------
    //tdo - serial to parallel
    logic       [4:0]           tdo_5bit;
    logic       [65:0]          tdo_66bit;

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
        tck = 1'b0;

        //reset
        #(2*JTAG_CYCLE) cmd_reset;

        //ir - dmi
        #(2*JTAG_CYCLE) cmd_ir(5'h11);

        //dmi - write
        #(2*JTAG_CYCLE) cmd_dmi({32'h0a, 32'h8c, 2'h2});
        #(5*JTAG_CYCLE) dmi_response(2'b00, 32'h0);

        //dmi - read
        #(2*JTAG_CYCLE) cmd_dmi({32'h12, 32'h8c, 2'h1});
        #(5*JTAG_CYCLE) dmi_response(2'b00, 32'h123);

        //dmi - nop
        #(2*JTAG_CYCLE) cmd_dmi({32'h12, 32'h8c, 2'h0});

        //finish
        #(10*JTAG_CYCLE) $finish;
    end

    //clock
    always begin
        #(0.5*JTAG_CYCLE) tck = ~tck;
    end

    //waveform
    initial begin
        $dumpfile("wf_jtag.vcd");
        $dumpvars(tb_jtag);
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

    task cmd_reset;
        begin
            @(posedge tck) trstn = 1'b0;
            #(4*JTAG_CYCLE);
            @(posedge tck) trstn = 1'b1;
        end
    endtask

    task cmd_ir;
        input [4:0]ir;
        begin
            //posedge tck - RUN_TEST_IDLE
            @(negedge tck) tms = 1'b1; //-> SELECT_DR_SCAN
            @(negedge tck) tms = 1'b1; //-> SELECT_IR_SCAN
            @(negedge tck) tms = 1'b0; //-> CAPTURE_IR
            @(negedge tck) tms = 1'b0; //-> SHIFT_IR
            @(negedge tck) tms = 1'b0; tdi = ir[0]; //SHIFT_IR - #0
            @(posedge tck) tdo_5bit[0] = tdo; //store tdo #0
            @(negedge tck) tms = 1'b0; tdi = ir[1]; //SHIFT_IR - #1
            @(posedge tck) tdo_5bit[1] = tdo; //store tdo #1
            @(negedge tck) tms = 1'b0; tdi = ir[2]; //SHIFT_IR - #2
            @(posedge tck) tdo_5bit[2] = tdo; //store tdo #2
            @(negedge tck) tms = 1'b0; tdi = ir[3]; //SHIFT_IR - #3
            @(posedge tck) tdo_5bit[3] = tdo; //store tdo #3
            @(negedge tck) tms = 1'b1; tdi = ir[4]; //SHIFT_IR - #4 -> EXIT1_IR
            @(posedge tck) tdo_5bit[4] = tdo; //store tdo #4
            @(negedge tck) tms = 1'b0; //-> PAUSE_IR
            @(negedge tck) tms = 1'b1; //-> EXIT2_IR
            @(negedge tck) tms = 1'b1; //-> UPDATE_IR
            @(negedge tck) tms = 1'b0; //-> RUN_TEST_IDLE
        end
    endtask

    task cmd_dmi;
        input [65:0]dmi;
        begin
            //posedge tck - RUN_TEST_IDLE
            @(negedge tck) tms = 1'b1; //-> SELECT_DR_SCAN
            @(negedge tck) tms = 1'b0; //-> CAPTURE_DR
            @(negedge tck) tms = 1'b0; //-> SHIFT_DR
            for(int i=0; i<=64; i++) begin
                @(negedge tck) tms = 1'b0; tdi = dmi[i]; //SHIFT_DR - #i
                @(posedge tck) tdo_66bit[i] = tdo; //store tdo #i
            end
            @(negedge tck) tms = 1'b1; tdi = dmi[65]; //SHIFT_DR - #65 -> EXIT1_DR
            @(posedge tck) tdo_66bit[65] = tdo; //store tdo #65
            @(negedge tck) tms = 1'b0; //-> PAUSE_DR
            @(negedge tck) tms = 1'b1; //-> EXIT2_DR
            @(negedge tck) tms = 1'b1; //-> UPDATE_DR
            @(negedge tck) tms = 1'b0; //-> RUN_TEST_IDLE
        end
    endtask

    task dmi_response;
        input [1:0]op;
        input [32:0]rddata;
        begin
            @(posedge tck) begin
                dmi_op = op;
                dmi_ack = 1'b1;
                dmi_rdata = rddata;
                dmi_rdata_valid = 1'b1;
            end
            #(5*JTAG_CYCLE);
            @(posedge tck) begin 
                dmi_ack = 1'b0;
                dmi_rdata_valid = 1'b0;
                dmi_rdata = 32'h0;
            end
        end
    endtask
endmodule
