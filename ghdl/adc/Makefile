all: modules-a modules-e testbenches

modules-a:
	echo "*** modules analysis ***"
	ghdl -a ../integration/common.vhd
#	ghdl -a const_bram.vhd
	ghdl -a adc_test_patterns.vhd
	ghdl -a adc_bram.vhd
	ghdl -a adc_registers.vhd
	ghdl -a adc_unit.vhd

modules-e:
	echo "*** module elaboration ***"
	ghdl -e adc_test_patterns
	ghdl -e adc_bram
	ghdl -e adc_registers
#	ghdl -e adc_daq
	ghdl -e adc_unit


testbenches:
	#echo "*** testbench analysis and elaboration ***"
	#ghdl -a -fsynopsys tb/adc_test_patterns_tb.vhd
	#ghdl -a -fsynopsys tb/adc_bram_tb.vhd
	#ghdl -a -fsynopsys tb/adc_registers_tb.vhd
	#ghdl -a -fsynopsys tb/adc_unit_tb.vhd
	#ghdl -e -fsynopsys adc_test_patterns_tb
	#ghdl -e -fsynopsys adc_bram_tb
	#ghdl -e -fsynopsys adc_registers_tb
	#ghdl -e -fsynopsys adc_unit_tb

run-testbenches:
	echo "*** running ***"
#	ghdl -r -fsynopsys adc_test_patterns_tb --stop-time=1ms
#	ghdl -r -fsynopsys adc_daq_tb --stop-time=1ms
#	ghdl -r -fsynopsys adc_unit_tb --stop-time=1ms --vcd=bl.vcd 
	#ghdl -r -fsynopsys adc_reg_tb --stop-time=1ms --vcd=bl.vcd 
	#ghdl -r -fsynopsys adc_daq_tb --stop-time=1ms --vcd=bl.vcd 
	#ghdl -r -fsynopsys adc_unit_tb --stop-time=1ms --vcd=bl.vcd 

