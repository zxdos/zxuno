onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clock_s
add wave -noupdate /tb/clock_vga_s
add wave -noupdate -radix unsigned /tb/cnt_hor_s
add wave -noupdate -radix unsigned /tb/cnt_ver_s
add wave -noupdate -radix unsigned /tb/rgb_col_s
add wave -noupdate -radix unsigned /tb/vga_col_s
add wave -noupdate /tb/vga_hsync_s
add wave -noupdate /tb/vga_vsync_s
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/u_target/wren
add wave -noupdate -radix unsigned /tb/u_target/addr_wr
add wave -noupdate -radix unsigned /tb/u_target/h
add wave -noupdate -radix unsigned /tb/u_target/hcnt
add wave -noupdate -radix unsigned /tb/u_target/window_hcnt
add wave -noupdate /tb/u_target/h_start
add wave -noupdate /tb/u_target/h_end
add wave -noupdate -radix unsigned /tb/u_target/vcnt
add wave -noupdate -radix unsigned /tb/u_target/window_vcnt
add wave -noupdate /tb/u_target/v_start
add wave -noupdate /tb/u_target/v_end
add wave -noupdate /tb/u_target/picture
add wave -noupdate -radix unsigned /tb/u_target/addr_rd
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13049167 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 264
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
WaveRestoreZoom {13048772 ns} {13049748 ns}
