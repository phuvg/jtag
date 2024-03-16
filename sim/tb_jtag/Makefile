# Guide :
#	"make compile" : compiles RTL code.
#	"make sim" : run simulation.
#	"make view" : invoke waveform.

#-----------------------------------------------------------------------------
#Source code directory
RTL_DIR = ../../rtl
TB_DIR = ../../tb
TEST = tb_jtag.sv
#-----------------------------------------------------------------------------
#RTL code
RTL_SRC = $(RTL_DIR)/*
#-----------------------------------------------------------------------------
#TB code
TB_SRC = $(TB_DIR)/$(TEST)
#-----------------------------------------------------------------------------
#Tools
COMPILER = vlog
SIMULATOR = vsim
#-----------------------------------------------------------------------------
#Tool options, compile and simulate flags
COFLAGS = -f
SFLAGS = -c\
	 -l report.log\
	 -voptargs="+acc"\
	 -do "run -all" work.tb_jtag
#-t ns\
#-----------------------------------------------------------------------------
#Tool output


#-----------------------------------------------------------------------------
#PHONY
.PHONY : compile sim view clean
#-----------------------------------------------------------------------------
#MAKE DIRECTIVES
compile: $(TB_SRC) $(RTL_SRC)
	vlib work
	vmap work work
	$(COMPILER) $(TB_SRC) $(RTL_SRC)

sim:
	$(SIMULATOR) $(SFLAGS)
	vcd2wlf wf_jtag.vcd wf_jtag.wlf	
view:
	vsim -i -view wf_jtag.wlf &
clean: 
	rm -rf wf_jtag.vcd \
	wf_jtag.wlf \
	report.log \
	work
