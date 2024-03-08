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
    input                   trsn_i,
    input                   tck_i,
    input                   tms_i,
    input                   tdi_i,
    output                  tdo_o,
    output                  tdo_enable_o

    //-----------------------
    //register interface
);
    ////////////////////////////////////////////////////////////////////////////
    //param declaration
    ////////////////////////////////////////////////////////////////////////////
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

    logic                                           capture_dr;
    logic                                           shift_dr;
    logic                                           update_dr;
    logic                                           capture_ir;
    logic                                           shift_ir;
    logic                                           update_ir;



    ////////////////////////////////////////////////////////////////////////////
    //design description
    ////////////////////////////////////////////////////////////////////////////
    //tap controller - FSM - update current state
    always_ff @(posedge tck_i or negedge rstn_i) begin
        if(~rstn_i) begin
            cr_state <= STATE_TEST_LOGIC_RESET;
        end else begin
            cr_state <= nx_state;
        end
    end

    //tap controller - FSM - next state generate
    always_comb @(tms_i, cr_state) begin
        case(cr_state)
            STATE_TEST_LOGIC_RESET: nx_state = tms_i ? STATE_TEST_LOGIC_RESET : STATE_RUN_TEST_IDLE;
            STATE_RUN_TEST_IDLE: nx_state = tms_i ? STATE_SELECT_DR_SCAN : STATE_RUN_TEST_IDLE;
            STATE_SELECT_DR_SCAN: nx_state = tms_i ? STATE_SELECT_IR_SCAN : STATE_CAPTURE_DR;
            STATE_CAPTURE_DR: nx_state = tms_i ? STATE_EXIT1_DR : STATE_SHIFT_DR;
            STATE_SHIFT_DR: nx_state = tms_i ? STATE_EXIT1_DR : STATE_SHIFT_DR;
            STATE_EXIT1_DR: nx_state = tms_i ? STATE_UPDATE_DR : STATE_PAUSE_DR;
            STATE_PAUSE_DR: nx_state = tms_i ? STATE_EXIT2_DR : STATE_PAUSE_DR;
            STATE_EXIT2_DR: nx_state = tms_i ? STATE_UPDATE_DR : STATE_SHIFT_DR;
            STATE_UPDATE_DR: nx_state = tms_i ? STATE_SELECT_DR_SCAN : STATE_RUN_TEST_IDLE;
            STATE_SELECT_IR_SCAN: nx_state = tms_i ? STATE_TEST_LOGIC_RESET : STATE_CAPTURE_IR;
            STATE_CAPTURE_IR: nx_state = tms_i ? STATE_EXIT1_IR : STATE_SHIFT_IR;
            STATE_SHIFT_IR: nx_state = tms_i ? STATE_EXIT1_IR : STATE_SHIFT_IR;
            STATE_EXIT1_IR: nx_state = tms_i ? STATE_UPDATE_IR : STATE_PAUSE_IR;
            STATE_PAUSE_IR: nx_state = tms_i ? STATE_EXIT2_IR : STATE_PAUSE_IR;
            STATE_EXIT2_IR: nx_state = tms_i ? STATE_UPDATE_IR : STATE_SHIFT_IR;
            STATE_UPDATE_IR: nx_state = tms_i ? STATE_SELECT_IR_SCAN : STATE_RUN_TEST_IDLE;
        endcase
    end

    //tap controller - FSM - controll logic
    assign capture_dr = (cr_state == STATE_CAPTURE_DR) ? 1'b1 : 1'b0;
    assign shift_dr = (cr_state == STATE_SHIFT_DR) ? 1'b1 : 1'b0;
    assign update_dr = (cr_state == STATE_UPDATE_DR) ? 1'b1 : 1'b0;
    assign capture_dr = (cr_state == STATE_CAPTURE_IR) ? 1'b1 : 1'b0;
    assign shift_dr = (cr_state == STATE_SHIFT_IR) ? 1'b1 : 1'b0;
    assign update_dr = (cr_state == STATE_UPDATE_IR) ? 1'b1 : 1'b0;

endmodule
