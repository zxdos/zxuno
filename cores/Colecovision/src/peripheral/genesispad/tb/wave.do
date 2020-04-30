onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/reset_s
add wave -noupdate /tb/clock_s
add wave -noupdate /tb/but_up_s
add wave -noupdate /tb/but_down_s
add wave -noupdate /tb/but_left_s
add wave -noupdate /tb/but_right_s
add wave -noupdate /tb/but_a_s
add wave -noupdate /tb/but_b_s
add wave -noupdate /tb/but_c_s
add wave -noupdate /tb/but_x_s
add wave -noupdate /tb/but_y_s
add wave -noupdate /tb/but_z_s
add wave -noupdate /tb/but_start_s
add wave -noupdate /tb/but_mode_s
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/pad_p1_s
add wave -noupdate /tb/pad_p2_s
add wave -noupdate /tb/pad_p3_s
add wave -noupdate /tb/pad_p4_s
add wave -noupdate /tb/pad_p6_s
add wave -noupdate /tb/pad_p7_s
add wave -noupdate /tb/pad_p9_s
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/u_target/pass_14u_s
add wave -noupdate /tb/u_target/cnt_14u_q
add wave -noupdate /tb/u_target/cnt_idle_q
add wave -noupdate /tb/u_target/state_q
add wave -noupdate /tb/u_target/state_s
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10212660 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 235
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {10021784 ns} {10498968 ns}
