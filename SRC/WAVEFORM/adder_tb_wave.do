onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /adder_tb/UUT/i_clk
add wave -noupdate -radix unsigned /adder_tb/UUT/i_reset
add wave -noupdate -radix unsigned /adder_tb/UUT/i_A
add wave -noupdate -radix unsigned /adder_tb/UUT/i_B
add wave -noupdate -radix unsigned /adder_tb/UUT/o_C
add wave -noupdate -radix unsigned /adder_tb/UUT/A_u
add wave -noupdate -radix unsigned /adder_tb/UUT/B_u
add wave -noupdate -radix unsigned /adder_tb/UUT/C_u
add wave -noupdate -radix unsigned /adder_tb/UUT/reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10798 ps} 0}
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
