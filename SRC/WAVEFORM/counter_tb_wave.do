onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /counter_tb/UUT/i_clk
add wave -noupdate /counter_tb/UUT/i_reset
add wave -noupdate /counter_tb/UUT/i_enable
add wave -noupdate /counter_tb/UUT/i_init_value
add wave -noupdate /counter_tb/UUT/o_count
add wave -noupdate /counter_tb/UUT/r_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {99273 ps} 0}
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
