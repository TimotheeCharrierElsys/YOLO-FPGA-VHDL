onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal /adder_tb/UUT/i_clk
add wave -noupdate -radix decimal /adder_tb/UUT/i_reset
add wave -noupdate -radix decimal /adder_tb/UUT/i_A
add wave -noupdate -radix decimal /adder_tb/UUT/i_B
add wave -noupdate -radix decimal /adder_tb/UUT/o_result
add wave -noupdate -radix decimal /adder_tb/UUT/A_signed
add wave -noupdate -radix decimal /adder_tb/UUT/B_signed
add wave -noupdate -radix decimal /adder_tb/UUT/sum_signed
add wave -noupdate -radix decimal /adder_tb/UUT/result_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {43564 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {105 ns}
