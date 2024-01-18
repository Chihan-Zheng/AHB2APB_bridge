onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/u_ahb2apb_bridge/hrstn
add wave -noupdate /tb/u_ahb2apb_bridge/hclk
add wave -noupdate /tb/u_ahb2apb_bridge/hsel
add wave -noupdate /tb/u_ahb2apb_bridge/hwrite
add wave -noupdate /tb/u_ahb2apb_bridge/haddr
add wave -noupdate /tb/u_ahb2apb_bridge/htrans
add wave -noupdate /tb/u_ahb2apb_bridge/hsize
add wave -noupdate /tb/u_ahb2apb_bridge/hprot
add wave -noupdate /tb/u_ahb2apb_bridge/hwdata
add wave -noupdate /tb/u_ahb2apb_bridge/hrdata
add wave -noupdate /tb/u_ahb2apb_bridge/hready
add wave -noupdate -divider apb_ram_ctl
add wave -noupdate /tb/u_ahb2apb_bridge/apb_active
add wave -noupdate /tb/u_ahb2apb_bridge/pclk_en
add wave -noupdate /tb/pclk
add wave -noupdate /tb/u_ahb2apb_bridge/pwrite
add wave -noupdate -color Yellow -itemcolor Yellow /tb/u_ahb2apb_bridge/apb_select
add wave -noupdate /tb/u_ahb2apb_bridge/paddr
add wave -noupdate -radix binary /tb/u_ahb2apb_bridge/pstrb
add wave -noupdate -color Magenta -itemcolor Magenta /tb/u_ahb2apb_bridge/psel
add wave -noupdate -color Magenta -itemcolor Magenta /tb/u_ahb2apb_bridge/penable
add wave -noupdate /tb/u_ahb2apb_bridge/pwdata
add wave -noupdate /tb/u_apb_sram/apb_wdata
add wave -noupdate -radix hexadecimal -childformat {{{/tb/u_ahb2apb_bridge/prdata[31]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[30]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[29]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[28]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[27]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[26]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[25]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[24]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[23]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[22]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[21]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[20]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[19]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[18]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[17]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[16]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[15]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[14]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[13]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[12]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[11]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[10]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[9]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[8]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[7]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[6]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[5]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[4]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[3]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[2]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[1]} -radix hexadecimal} {{/tb/u_ahb2apb_bridge/prdata[0]} -radix hexadecimal}} -subitemconfig {{/tb/u_ahb2apb_bridge/prdata[31]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[30]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[29]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[28]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[27]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[26]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[25]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[24]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[23]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[22]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[21]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[20]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[19]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[18]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[17]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[16]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[15]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[14]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[13]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[12]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[11]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[10]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[9]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[8]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[7]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[6]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[5]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[4]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[3]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[2]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[1]} {-height 15 -radix hexadecimal} {/tb/u_ahb2apb_bridge/prdata[0]} {-height 15 -radix hexadecimal}} /tb/u_ahb2apb_bridge/prdata
add wave -noupdate /tb/u_ahb2apb_bridge/pready
add wave -noupdate /tb/u_ahb2apb_bridge/hreadyout
add wave -noupdate /tb/u_ahb2apb_bridge/sta
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/u_ahb_lite_ms_model/ref_mem
add wave -noupdate /tb/u_apb_sram/u_mem/mem
add wave -noupdate /tb/u_apb_sram/apb_addr
add wave -noupdate -radix binary /tb/u_apb_sram/u_mem/wbe
add wave -noupdate /tb/u_apb_sram/apb_wdata
add wave -noupdate /tb/u_apb_sram/apb_read_w
add wave -noupdate /tb/u_apb_sram/apb_read
add wave -noupdate /tb/u_apb_sram/mem_dout
add wave -noupdate /tb/u_apb_sram/mem_cs
add wave -noupdate /tb/u_apb_sram/apb_write
add wave -noupdate /tb/u_apb_sram/pslverr
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/u_ahb_lite_ms_model/bus_fir_beat
add wave -noupdate /tb/u_ahb_lite_ms_model/hwdata_pre
add wave -noupdate /tb/u_ahb_lite_ms_model/bt_wdata
add wave -noupdate /tb/u_ahb_lite_ms_model/haddr_d
add wave -noupdate /tb/u_ahb_lite_ms_model/last_wdata_don_chk_flg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {17134347850 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 271
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
configure wave -timelineunits ps
update
WaveRestoreZoom {17134239960 ps} {17134403160 ps}
