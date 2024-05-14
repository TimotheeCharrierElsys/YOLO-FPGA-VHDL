onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /acc_tb/UUT/i_clk
add wave -noupdate -radix unsigned /acc_tb/UUT/i_reset
add wave -noupdate -radix unsigned /acc_tb/UUT/i_A
add wave -noupdate -radix unsigned /acc_tb/UUT/i_B
add wave -noupdate -radix unsigned /acc_tb/UUT/i_C
add wave -noupdate -radix unsigned /acc_tb/UUT/o_result
add wave -noupdate -radix unsigned /acc_tb/UUT/u_A
add wave -noupdate -radix unsigned /acc_tb/UUT/u_B
add wave -noupdate -radix unsigned /acc_tb/UUT/u_C
add wave -noupdate -radix unsigned /acc_tb/UUT/u_mult
add wave -noupdate -radix unsigned /acc_tb/UUT/u_sum
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {105463 ps} 0}
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
WaveRestoreZoom {100250 ps} {205250 ps}
