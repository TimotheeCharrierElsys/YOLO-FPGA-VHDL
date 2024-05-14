onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /accumulator_tb/i_clk
add wave -noupdate -radix unsigned /accumulator_tb/i_reset
add wave -noupdate -radix unsigned /accumulator_tb/i_A
add wave -noupdate -radix unsigned /accumulator_tb/i_B
add wave -noupdate -radix unsigned /accumulator_tb/i_C
add wave -noupdate -radix unsigned /accumulator_tb/I_D
add wave -noupdate -radix unsigned /accumulator_tb/o_E
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
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
