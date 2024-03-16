onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_jtag/trstn
add wave -noupdate /tb_jtag/tck
add wave -noupdate /tb_jtag/i_jtag/cr_state
add wave -noupdate /tb_jtag/tms
add wave -noupdate /tb_jtag/tdi
add wave -noupdate /tb_jtag/tdo
add wave -noupdate -radix binary /tb_jtag/i_jtag/shift_out_ir
add wave -noupdate /tb_jtag/i_jtag/update_out_ir
add wave -noupdate /tb_jtag/i_jtag/shift_out_dmi
add wave -noupdate /tb_jtag/i_jtag/update_out_dmi
add wave -noupdate /tb_jtag/i_jtag/rdata
add wave -noupdate /tb_jtag/i_jtag/dmi_reg_in
add wave -noupdate /tb_jtag/i_jtag/dmi_req_o
add wave -noupdate /tb_jtag/i_jtag/dmi_we_o
add wave -noupdate /tb_jtag/i_jtag/dmi_addr_o
add wave -noupdate /tb_jtag/i_jtag/dmi_wdata_o
add wave -noupdate /tb_jtag/i_jtag/dmi_ack_i
add wave -noupdate /tb_jtag/i_jtag/dmi_rdata_i
add wave -noupdate /tb_jtag/i_jtag/dmi_rdata_valid_i
add wave -noupdate /tb_jtag/tdo_5bit
add wave -noupdate /tb_jtag/tdo_66bit
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10550000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 158
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {28822500 ps}
