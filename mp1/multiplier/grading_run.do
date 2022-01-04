transcript on
set a [pwd]
if [string equal $a /job/student] {cd multiplier}
pwd
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work {./include/types.sv}
vlog -sv -work work {./hdl/add_shift_multiplier.sv}
vlog -sv -work work {./grading/grader_types.sv}
vlog -sv -work work {./hvl/testbench.sv}
vlog -sv -work work {./hvl/top.sv}
vlog -sv -work work {./grading/grader_itf.sv}
vlog -sv -work work {./grading/grader.sv}
vlog -sv -work work {./grading/transaction_monitor.sv}
vlog -sv -work work {./grading/transaction_scoreboard.sv}


vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  top

run -all
