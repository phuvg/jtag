////////////////////////////////////////////////////////////////////////////////
// Filename    : jtag.sv
// Description : 
//
// Author      : Phu Vuong
// History     : Jul 31, 2022 : Initial     
//
////////////////////////////////////////////////////////////////////////////////
module jtag(
    //-----------------------
    //jtag inteface
    input                   jtag_trstn_i,
    input                   jtag_tck_i,
    input                   jtag_tms_i,
    input                   jtag_tdi_i,
    output  logic           jtag_tdo_o,
    output  logic           jtag_tdo_enable_o,

    //dmi register
    input                   dmi_ack_i,
    input           [1:0]   dmi_op_i,
    input           [31:0]  dmi_rdata_i,
    input                   dmi_rdata_valid_i,
    output  logic   [31:0]  dmi_addr_o,
    output  logic   [31:0]  dmi_wdata_o,
    output  logic           dmi_we_o,
    output  logic           dmi_req_o,

    //dtmcs register
    input           [3:0]   dtmcs_version_i,
    input           [5:0]   dtmcs_abits_i,
    input           [1:0]   dtmcs_dmistat_i,
    input           [2:0]   dtmcs_idle_i,
    output  logic           dtmcs_dmireset_o,
    output  logic           dtmcs_dmihardreset_o
);
    ////////////////////////////////////////////////////////////////////////////
    //param declaration
    ////////////////////////////////////////////////////////////////////////////
    parameter       VERSION                         = 4'h0;
    parameter       PART_NUMBER                     = 16'h1;
    parameter       MANUFLD                         = 11'h12;
    
    localparam      STATE_TEST_LOGIC_RESET          = 4'h0;
    localparam      STATE_RUN_TEST_IDLE             = 4'h1;
    localparam      STATE_SELECT_DR_SCAN            = 4'h2;
    localparam      STATE_CAPTURE_DR                = 4'h3;
    localparam      STATE_SHIFT_DR                  = 4'h4;
    localparam      STATE_EXIT1_DR                  = 4'h5;
    localparam      STATE_PAUSE_DR                  = 4'h6;
    localparam      STATE_EXIT2_DR                  = 4'h7;
    localparam      STATE_UPDATE_DR                 = 4'h8;
    localparam      STATE_SELECT_IR_SCAN            = 4'h9;
    localparam      STATE_CAPTURE_IR                = 4'ha;
    localparam      STATE_SHIFT_IR                  = 4'hb;
    localparam      STATE_EXIT1_IR                  = 4'hc;
    localparam      STATE_PAUSE_IR                  = 4'hd;
    localparam      STATE_EXIT2_IR                  = 4'he;
    localparam      STATE_UPDATE_IR                 = 4'hf;
    
	
	
    ////////////////////////////////////////////////////////////////////////////
    //logic - wire - reg name declaration
    ////////////////////////////////////////////////////////////////////////////
    //tap controller - FSM
    logic           [3:0]                           cr_state;
    logic           [3:0]                           nx_state;

    logic                                           select_ir;
    logic                                           capture_ir;
    logic                                           shift_ir;
    logic                                           update_ir;
    logic                                           select_dr;
    logic                                           capture_dr;
    logic                                           shift_dr;
    logic                                           update_dr;

    //clock bar
    logic                                           tckn;

    //IR - instruction register
    logic           [4:0]                           shift_out_ir;
    logic           [4:0]                           nx_shift_out_ir;
    logic           [4:0]                           update_out_ir;
    logic           [4:0]                           nx_update_out_ir;

    //IR - decoder
    logic                                           select_bypass;
    logic                                           select_idcode;
    logic                                           select_dtmcs;
    logic                                           select_dmi;

    logic                                           capture_bypass;
    logic                                           shift_bypass;
    logic                                           capture_idcode;
    logic                                           shift_idcode;
    logic                                           capture_dtmcs;
    logic                                           shift_dtmcs;
    logic                                           update_dtmcs;
    logic                                           capture_dmi;
    logic                                           shift_dmi;
    logic                                           update_dmi;
    logic                                           update_dmi_wr;

    //DR - data register - BYPASS
    logic                                           shift_out_bypass;
    logic                                           nx_shift_out_bypass;

    //DR - data register - IDCODE
    logic           [31:0]                          shift_out_idcode;
    logic           [31:0]                          nx_shift_out_idcode;

    //DR - data register - DTMCS
    logic           [31:0]                          shift_out_dtmcs;
    logic           [31:0]                          nx_shift_out_dtmcs;
    logic           [31:0]                          dtmcs_reg_in;

    //DR - data register - DMI
    logic           [65:0]                          shift_out_dmi;
    logic           [65:0]                          nx_shift_out_dmi;
    logic           [65:0]                          update_out_dmi;
    logic           [65:0]                          nx_update_out_dmi;

    logic           [65:0]                          dmi_reg_in;
    logic           [65:0]                          dmi_reg_in_lat;

    //dm interface
    logic                                           dmi_rdata_valid_lat;
    logic                                           dmi_rdata_valid_rising_edgedet;
    logic           [31:0]                          rdata;
    logic           [31:0]                          nx_rdata;

    logic                                           dmi_ack_lat;
    logic                                           req_clr;
    logic                                           req_set;
    logic                                           nx_req;

    //output - tdo
    logic                                           nx_tdo;
    logic                                           nx_tdo_enable;


    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //tap controller - FSM - update current state
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            cr_state <= STATE_TEST_LOGIC_RESET;
        end else begin
            cr_state <= nx_state;
        end
    end

    //tap controller - FSM - next state generate
    always_comb begin
        case(cr_state)
            STATE_TEST_LOGIC_RESET: nx_state = jtag_tms_i ? STATE_TEST_LOGIC_RESET : STATE_RUN_TEST_IDLE;
            STATE_RUN_TEST_IDLE: nx_state = jtag_tms_i ? STATE_SELECT_DR_SCAN : STATE_RUN_TEST_IDLE;
            STATE_SELECT_DR_SCAN: nx_state = jtag_tms_i ? STATE_SELECT_IR_SCAN : STATE_CAPTURE_DR;
            STATE_CAPTURE_DR: nx_state = jtag_tms_i ? STATE_EXIT1_DR : STATE_SHIFT_DR;
            STATE_SHIFT_DR: nx_state = jtag_tms_i ? STATE_EXIT1_DR : STATE_SHIFT_DR;
            STATE_EXIT1_DR: nx_state = jtag_tms_i ? STATE_UPDATE_DR : STATE_PAUSE_DR;
            STATE_PAUSE_DR: nx_state = jtag_tms_i ? STATE_EXIT2_DR : STATE_PAUSE_DR;
            STATE_EXIT2_DR: nx_state = jtag_tms_i ? STATE_UPDATE_DR : STATE_SHIFT_DR;
            STATE_UPDATE_DR: nx_state = jtag_tms_i ? STATE_SELECT_DR_SCAN : STATE_RUN_TEST_IDLE;
            STATE_SELECT_IR_SCAN: nx_state = jtag_tms_i ? STATE_TEST_LOGIC_RESET : STATE_CAPTURE_IR;
            STATE_CAPTURE_IR: nx_state = jtag_tms_i ? STATE_EXIT1_IR : STATE_SHIFT_IR;
            STATE_SHIFT_IR: nx_state = jtag_tms_i ? STATE_EXIT1_IR : STATE_SHIFT_IR;
            STATE_EXIT1_IR: nx_state = jtag_tms_i ? STATE_UPDATE_IR : STATE_PAUSE_IR;
            STATE_PAUSE_IR: nx_state = jtag_tms_i ? STATE_EXIT2_IR : STATE_PAUSE_IR;
            STATE_EXIT2_IR: nx_state = jtag_tms_i ? STATE_UPDATE_IR : STATE_SHIFT_IR;
            STATE_UPDATE_IR: nx_state = jtag_tms_i ? STATE_SELECT_IR_SCAN : STATE_RUN_TEST_IDLE;
        endcase
    end

    //tap controller - FSM - controll logic
    assign select_ir =  cr_state == STATE_CAPTURE_IR ? 1'b1 : 
                        cr_state == STATE_SHIFT_IR ? 1'b1 :
                        cr_state == STATE_EXIT1_IR ? 1'b1 :
                        cr_state == STATE_PAUSE_IR ? 1'b1 :
                        cr_state == STATE_EXIT2_IR ? 1'b1 :
                        cr_state == STATE_UPDATE_IR ? 1'b1 : 1'b0;
    assign capture_ir = cr_state == STATE_CAPTURE_IR ? 1'b1 : 1'b0;
    assign shift_ir = cr_state == STATE_SHIFT_IR ? 1'b1 : 1'b0;
    assign update_ir = cr_state == STATE_UPDATE_IR ? 1'b1 : 1'b0;
    assign select_dr =  cr_state == STATE_CAPTURE_DR ? 1'b1 : 
                        cr_state == STATE_SHIFT_DR ? 1'b1 :
                        cr_state == STATE_EXIT1_DR ? 1'b1 :
                        cr_state == STATE_PAUSE_DR ? 1'b1 :
                        cr_state == STATE_EXIT2_DR ? 1'b1 :
                        cr_state == STATE_UPDATE_DR ? 1'b1 : 1'b0;
    assign capture_dr = cr_state == STATE_CAPTURE_DR ? 1'b1 : 1'b0;
    assign shift_dr = cr_state == STATE_SHIFT_DR ? 1'b1 : 1'b0;
    assign update_dr = cr_state == STATE_UPDATE_DR ? 1'b1 : 1'b0;

    //clock bar
    assign tckn = ~jtag_tck_i;

    //IR - instruction register
    assign nx_shift_out_ir =    shift_ir ? {jtag_tdi_i, shift_out_ir[4:1]} :
                                capture_ir ? 5'b0_0001 : shift_out_ir;
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            shift_out_ir <= 5'h0;
        end else begin
            shift_out_ir <= nx_shift_out_ir;
        end
    end

    assign nx_update_out_ir = update_ir ? shift_out_ir : update_out_ir;
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            update_out_ir <= 5'h0;
        end else begin
            update_out_ir <= nx_update_out_ir;
        end
    end

    //IR - decoder
    assign select_bypass = (update_out_ir == 5'h00 | update_out_ir == 5'h1f) ? 1'b1 : 1'b0;
    assign select_idcode = update_out_ir == 5'h01 ? 1'b1 : 1'b0;
    assign select_dtmcs = update_out_ir == 5'h10 ? 1'b1 : 1'b0;
    assign select_dmi = update_out_ir == 5'h11 ? 1'b1 : 1'b0;

    assign capture_bypass = select_bypass & capture_dr;
    assign shift_bypass = select_bypass & shift_dr;

    assign capture_idcode = select_idcode & capture_dr;
    assign shift_idcode = select_idcode & shift_dr;

    assign capture_dtmcs = select_dtmcs & capture_dr;
    assign shift_dtmcs = select_dtmcs & shift_dr;
    assign update_dtmcs = select_dtmcs & update_dr;

    assign capture_dmi = select_dmi & capture_dr;
    assign shift_dmi = select_dmi & shift_dr;
    assign update_dmi = select_dmi & update_dr & ((~shift_out_dmi[1] & shift_out_dmi[0]) | (shift_out_dmi[1] & ~shift_out_dmi[0]));
    assign update_dmi_wr = select_dmi & update_dr & shift_out_dmi[1] & ~shift_out_dmi[0];

    //DR - data register - BYPASS
    assign nx_shift_out_bypass =    shift_bypass ? jtag_tdi_i :
                                    capture_bypass ? 1'b0 : shift_out_bypass;
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin 
            shift_out_bypass <= 1'h0;
        end else begin
            shift_out_bypass <= nx_shift_out_bypass;
        end
    end

    //DR - data register - IDCODE
    assign nx_shift_out_idcode =    shift_idcode ? {jtag_tdi_i, shift_out_idcode[31:1]} :
                                    capture_idcode ? {VERSION, PART_NUMBER, MANUFLD} : shift_out_idcode;
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            shift_out_idcode <= 32'h0;
        end else begin
            shift_out_idcode <= nx_shift_out_idcode;
        end
    end

    //DR - data register - DTMCS
    assign dtmcs_reg_in = {14'h0, dtmcs_dmihardreset_o, dtmcs_dmireset_o, 1'h0, dtmcs_idle_i, dtmcs_dmistat_i, dtmcs_abits_i, dtmcs_version_i};
    assign nx_shift_out_dtmcs = shift_dtmcs ? {jtag_tdi_i, shift_out_dtmcs[31:1]} :
                                capture_dtmcs ? dtmcs_reg_in : shift_out_dtmcs;
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            shift_out_dtmcs <= 32'h0;
        end else begin
            shift_out_dtmcs <= nx_shift_out_dtmcs;
        end
    end

    //DR - data register - DMI
    assign dmi_reg_in = (select_dmi & ~dmi_we_o) ? {dmi_addr_o, rdata, dmi_op_i} :
                        (select_dmi & dmi_we_o) ? {dmi_addr_o, dmi_wdata_o, dmi_op_i} : dmi_reg_in_lat;
    assign nx_shift_out_dmi = shift_dmi ? {jtag_tdi_i, shift_out_dmi[65:1]} :
                             capture_dmi ? dmi_reg_in : shift_out_dmi;
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            shift_out_dmi <= 32'h0;
        end else begin
            shift_out_dmi <= nx_shift_out_dmi;
        end
    end

    assign nx_update_out_dmi[65:34] = update_dmi ? shift_out_dmi[65:34] : update_out_dmi[65:34];
    assign nx_update_out_dmi[33:2] = update_dmi_wr ? shift_out_dmi[33:2] : update_out_dmi[33:2];
    assign nx_update_out_dmi[1:0] = update_dmi ? shift_out_dmi[1:0] : update_out_dmi[1:0];
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            update_out_dmi <= 32'h0;
        end else begin
            update_out_dmi <= nx_update_out_dmi;
        end
    end

    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            dmi_reg_in_lat <= 32'h0;
        end else begin
            dmi_reg_in_lat <= dmi_reg_in;
        end
    end

    //output - dtmcs
    assign dtmcs_dmihardreset_o = update_dtmcs & shift_out_dtmcs[17];
    assign dtmcs_dmireset_o = update_dtmcs & shift_out_dtmcs[16];

    //dm interface
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            dmi_rdata_valid_lat <= 1'b0;
        end else begin
            dmi_rdata_valid_lat <= dmi_rdata_valid_i;
        end
    end
    assign dmi_rdata_valid_rising_edgedet = dmi_rdata_valid_i & ~dmi_rdata_valid_lat;

    assign nx_rdata = (dmi_rdata_valid_rising_edgedet & ~dmi_we_o) ? dmi_rdata_i : rdata;
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            rdata <= 32'h0;
        end else begin
            rdata <= nx_rdata;
        end
    end

    assign dmi_addr_o = update_out_dmi[65:34];
    assign dmi_wdata_o = update_out_dmi[33:2];
    assign dmi_we_o = update_out_dmi[1];

    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            dmi_ack_lat <= 1'h0;
        end else begin
            dmi_ack_lat <= dmi_ack_i;
        end
    end
    assign req_clr = dmi_ack_i & ~dmi_ack_lat;
    assign req_set = update_dmi;
    assign nx_req = req_clr ? 1'b0 : 
                    req_set ? 1'b1 : dmi_req_o;
    always_ff @(posedge jtag_tck_i or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            dmi_req_o <= 1'b0;
        end else begin
            dmi_req_o <= nx_req;
        end
    end

    //output - tdo
    assign nx_tdo = select_ir ? shift_out_ir[0] :
                    select_dmi ? shift_out_dmi[0] :
                    select_dtmcs ? shift_out_dtmcs[0] :
                    select_idcode ? shift_out_idcode[0] :
                    select_bypass ? shift_out_bypass : jtag_tdo_o;
    always_ff @(posedge tckn or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            jtag_tdo_o <= 1'b0;
        end else begin
            jtag_tdo_o <= nx_tdo;
        end
    end

    assign nx_tdo_enable = (cr_state == STATE_SHIFT_IR || cr_state == STATE_SHIFT_DR) ? 1'b1 : 1'b0;
    always_ff @(posedge tckn or negedge jtag_trstn_i) begin
        if(~jtag_trstn_i) begin
            jtag_tdo_enable_o <= 1'b0;
        end else begin
            jtag_tdo_enable_o <= nx_tdo_enable;
        end
    end
endmodule
