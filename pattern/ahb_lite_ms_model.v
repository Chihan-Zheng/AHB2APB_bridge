// `include "tb.v"
// `include "../rtl/ahb_sram_simple.v"

`define MEM_PATH tb.u_apb_sram.u_mem
`define EN_BACK2BACK
`define PCLK_LOW_SPEED

/*
    AHB-Lite master model.
    This model support idle/busy/nonseq/seq trans: 8bit/16bit/32bit data size.
    This model doesn't check for hresp.
*/
module ahb_lite_ms_model #(
    parameter mem_dw = 32,
    parameter mem_abit = 10,
    parameter mem_depth = 1024
) (
    input wire clk,
    input wire rstn,
    input wire hreadyout,
    input wire [mem_dw - 1: 0] hrdata,
    input wire hresp,

    output wire hsel,
    output wire [mem_abit - 1 + 2: 0] haddr,
    output wire [2:0] hburst,
    output wire [1:0] htrans,
    output wire [2:0] hsize,
    output wire [3:0] hprot,
    output wire hwrite,
    output wire [mem_dw - 1: 0] hwdata,
    output wire hready,
    output wire pclk_en
);
// parameter REGISTER_RDATA = 1;

reg [7:0] ref_mem[0: (mem_depth*4) - 1];     //reference memory

wire [mem_dw - 1: 0] hrdata_i;
reg hsel_i;
reg [mem_abit - 1 + 2: 0] haddr_i;
reg [2:0] hburst_i;
reg [1:0] htrans_i;
reg [2:0] hsize_i;
reg hwrite_i;
reg [mem_dw - 1: 0] hwdata_i;
reg pclk_en_i;

assign #1 hrdata_i = hrdata;
assign #1 hsel = hsel_i;
assign #1 haddr = haddr_i;
assign #1 hburst = hburst_i;
assign #1 htrans = htrans_i;
assign #1 hsize = hsize_i;
assign hprot = 4'b1110;
assign #1 hwrite = hwrite_i;
assign #1 hwdata = hwdata_i;
assign #1 hready = hreadyout;
// assign pclk_en = 1'b1;

reg [1:0] bt_size;    //hsize[1:0]
reg [2:0] addr_step;     //address variation step
reg [4:0] bt_len;         //burst length
reg [mem_abit - 1 + 2: 0] bt_addr;         //first byte address 
reg [31:0] rand1;
reg bt_wrap;      //whether to wrapping transfer
reg [2:0] addr_wrap_bloc;            //the index used in wrapping transfer
reg [mem_abit - 1 + 2: 0] bt_addr_array[0:15];   //array to store all the addresses generated
reg [mem_abit - 1 + 2: 0] bt_end_addr;     //last address used for 1K boundry check
reg [mem_abit - 1 + 2: 0] inc_bt_addr;
reg [4:0] addr_lcnt;

integer acnt;
// integer addr_wrap_bloc_int;

//--- generate hsize, burst len, whether to wrap, addresses
task bt_info_gen;
reg [31:0] addr_mask;

begin
    rand1 = $random;
    if (rand1[7:0] <= 'd128) begin
        bt_size = 'd2;
        
        bt_wrap = 1'b1;
    end else begin
        bt_size = {1'b0, rand1[5]};

        bt_wrap = 1'b0;
    end

    addr_step = 2 ** bt_size;

    if (rand1[15:8] <= 'd128 + 'd64 + 'd32) begin
        case (rand1[11:10])
            'd0: bt_len = 'd4;
            'd1: bt_len = 'd8; 
            default: bt_len = 'd16;
        endcase

    end else if (rand1[15:8] <= 'd128 + 'd64 + 'd32 + 'd16) begin
        bt_len = 'd1;
    end else begin
        bt_len = rand1[12:9];
    end

    if (bt_wrap) begin
        addr_wrap_bloc = bt_size + $clog2(bt_len);
    end else begin
        addr_wrap_bloc = 'd8;
    end

    // addr_wrap_bloc_int = $unsigned(addr_wrap_bloc);

    //adjust first address based on hsize
    bt_addr = $random;
    if (bt_size == 'd1) begin
        bt_addr[0] =1'b0;
    end else if (bt_size == 'd2) begin
        bt_addr[1:0] = 2'b00;
    end else begin
        bt_addr = bt_addr;
    end

    //1K boundry check
    bt_end_addr = bt_addr + addr_step * (bt_len - 1);
    // if ((bt_end_addr[10] != bt_addr[10]) && (bt_end_addr[9:0] != 'd0)) begin
    //     bt_addr = {bt_end_addr[mem_abit + 2 - 1: 10], 10'h0} - (2 ** bt_size) * bt_len;
    // end
    if (bt_end_addr[mem_abit - 1 + 2: 10] != 'd0) begin
        addr_mask = (1 << 10) - 1;
        bt_addr = (bt_end_addr & addr_mask) - addr_step * (bt_len - 1);
        bt_end_addr = bt_addr + addr_step * (bt_len - 1);
    end
    

    if (bt_end_addr > (1 << 10)) begin
        $display("Address exceed 1K byte boundry!");
    end

    //put every address to bt_addr_array
    inc_bt_addr = bt_addr;
    addr_lcnt = 0;
    
    for (acnt = 0; acnt < bt_len; acnt = acnt + 1) begin
        bt_addr_array[acnt] = inc_bt_addr;
        inc_bt_addr = inc_bt_addr + addr_step;

        if ((inc_bt_addr[addr_wrap_bloc] != bt_addr[addr_wrap_bloc]) && bt_wrap) begin
            addr_mask = ~((1 << addr_wrap_bloc) - 1);
            inc_bt_addr = bt_addr & addr_mask;
            // inc_bt_addr = {bt_addr[mem_abit - 1 + 2: addr_wrap_bloc_int],{addr_wrap_bloc_int{1'b0}}};
            addr_lcnt = 'd0;
            bt_addr_array[acnt] = inc_bt_addr;
        end else begin
            addr_lcnt = addr_lcnt + 'd1;
        end
    end
end
endtask

//generate hburst and get hsize_i
always @(*) begin
    hsize_i = bt_size;

    if (bt_len == 'd4) begin
        hburst_i = {2'b01, ~bt_wrap};
    end else if (bt_len == 'd8) begin
        hburst_i = {2'b10, ~bt_wrap};
    end else if (bt_len == 'd16) begin
        hburst_i = {2'b11, ~bt_wrap};
    end else if (bt_len == 'd1) begin
        hburst_i = 3'b000;
    end else begin
        hburst_i = 3'b001;
    end
end

reg [31:0] rand2;

//--- insert busy trans
task bt_busy_trans;
reg has_busy;    //whether to insert busy trans or not
reg [2:0] busy_cyc;     //busy cycle 

begin
    rand2 = $random;
    if (rand2[3:0] <= 'd4) begin
        has_busy = 1'b1;

        if(rand2[6:4] <= 'd4) begin
            busy_cyc = 'd1;
        end else if (rand2[6:4] == 'd4 + 'd1) begin
            busy_cyc = 'd2;
        end else if (rand2[6:4] == 'd6) begin
            busy_cyc = 'd3;
        end else begin
            busy_cyc = {1'b1, rand2[8:7]};
        end
    end else begin
        has_busy = 1'b0;
    end

    if (has_busy) begin
        while (busy_cyc != 'd0) begin
            htrans_i = 2'b01;
            @(posedge clk);
            busy_cyc = busy_cyc - 'd1;
            
            // while (!hready) begin
            //     @(posedge clk);
            // end
        end
    end
end
endtask

//--- generate read burst
integer rcnt;
reg skip_info_gen;
reg [4:0] bt_wait; 

task ahb_rd_burst;
begin
    repeat(bt_wait) @(posedge clk);    //wait bt_wait periods

    if (!skip_info_gen) begin
        bt_info_gen;     //generate burst info and address info automatically
    end 

    hwrite_i = 1'b0;     

    for (rcnt = 0; rcnt < bt_len; rcnt = rcnt + 1) begin
        haddr_i = bt_addr_array[rcnt];     //output current address

        //insert busy trans
        if (rcnt != 0) begin
            bt_busy_trans;
        end

        //generate htrans
        if (rcnt == 0) begin
            htrans_i = 2'b10;
        end else begin
            htrans_i = 2'b11;
        end

        @(posedge clk);
        //wait for hready to be high
        while (!hready) begin
            @(posedge clk);
        end
    end

    htrans_i = 2'b00;      //return to IDLE trans
end
endtask


//--- generate write burst
integer wcnt;
reg [7:0] bt_wdata[0: 4*16 -1];
reg [mem_dw - 1: 0] hwdata_pre;     //1T pre the sent data

task ahb_wr_burst;
begin
    repeat(bt_wait) @(posedge clk);    

    if (!skip_info_gen) begin     
        bt_info_gen;
    end

    hwrite_i = 1'b1;
    addr_step = 2 ** bt_size;

    //generate write data -->store every written byte
    for (wcnt = 0; wcnt < addr_step * bt_len; wcnt = wcnt + 1) begin
        bt_wdata[wcnt] = $random;
    end

    for (acnt = 0; acnt < bt_len; acnt = acnt + 1) begin
        haddr_i = bt_addr_array[acnt];   //output address

        //combine byte(s) to get pre-write data of 32 bits
        case (bt_size)
            2'b00: begin
                case (haddr_i[1:0])
                    2'b00: hwdata_pre = {24'hf0f0f0, bt_wdata[acnt]};
                    2'b01: hwdata_pre = {16'hf0f0, bt_wdata[acnt], 8'hf0};
                    2'b10: hwdata_pre = {8'hf0, bt_wdata[acnt], 16'hf0f0};
                    2'b11: hwdata_pre = {bt_wdata[acnt], 24'hf0f0f0};
                    default: hwdata_pre = hwdata_pre;
                endcase
            end

            2'b01: begin
                if (haddr_i[1]) begin
                    hwdata_pre = {bt_wdata[addr_step * acnt + 1], bt_wdata[addr_step * acnt], 16'hf0f0};
                end else begin
                    hwdata_pre = {16'hf0f0, bt_wdata[addr_step * acnt + 1], bt_wdata[addr_step * acnt]};
                end
            end

            2'b10: begin
                hwdata_pre = {bt_wdata[addr_step * acnt + 3], bt_wdata[addr_step * acnt + 2],
                                bt_wdata[addr_step * acnt + 1], bt_wdata[addr_step * acnt]};
            end

            default: hwdata_pre = hwdata_pre;
        endcase

        //insert busy trans
        if (acnt != 0) begin
            bt_busy_trans;
        end 

        if (acnt == 0) begin
            htrans_i = 2'b10;
        end else begin
            htrans_i = 2'b11;
        end

        @(posedge clk);
        while (!hready) begin
            @(posedge clk);
        end

        //write data of current address to ref_mem
        // ref_mem[bt_addr_array[0] + acnt] = bt_wdata[acnt];
        #1;
        for (wcnt = 0; wcnt < addr_step; wcnt = wcnt + 1) begin
            ref_mem[bt_addr_array[acnt] + wcnt] = bt_wdata[acnt*addr_step + wcnt];
        end
    end

    htrans_i = 2'b00;
end
endtask

//delay hwdata_pre for 1T to get output data
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        hwdata_i <= 'd0;
    end else if (hready)begin
        hwdata_i <= hwdata_pre;
    end
end

//--- check ahb_sram's content with ref_mem
task mem_content_chk;
integer cnt;
reg [31:0] dut;
reg [31:0] ref_data;

begin
    for (cnt = 0; cnt < mem_depth; cnt = cnt + 1) begin
        dut = `MEM_PATH.mem[cnt];

        ref_data[1*8 - 1: 0*8] = ref_mem[(cnt << 2) + 0];
        ref_data[2*8 - 1: 1*8] = ref_mem[(cnt << 2) + 1];
        ref_data[3*8 - 1: 2*8] = ref_mem[(cnt << 2) + 2];
        ref_data[4*8 - 1: 3*8] = ref_mem[(cnt << 2) + 3];

        // $display("ref_data = %8h", ref_data);
        if (dut != ref_data) begin
            $display("Error: AHB SRAM content error at byte addr %4h: DUT is %8h, should be %8h.", 
                    cnt << 2, dut, ref_data);
            repeat(2) @(posedge clk);
            $finish();
        end
    end
end
endtask

//--- check read data
wire bus_rd;    //period when bus has nonseq/seq read
reg bus_rd_d;  //1T delay of bus_rd
reg [2:0] bus_rd_d_3T;
reg [mem_abit - 1 + 2: 0] haddr_d;    //1T delay of haddr_i
reg [mem_dw - 1: 0] ref_rdata;     //rdata from ref_mem
wire rd2wr_flg;
wire wr2rd_flg;
reg hwrite_reg;
// reg last_rdata_chk_flg;
reg last_wdata_don_chk_flg;    //a pulse that include the last hready of wdata, which controls not to do read checkd in this period
//----------------------
wire bus_fir_beat;    //first beat with htans == NONSEQ
reg bus_fir_beat_d;    //1T delay of bus_fir_beat
// wire bus_idle_beat;
// reg bus_idle_beat_d;
  
assign bus_fir_beat = hsel && hready && (htrans_i == 2'b10);
assign bus_idle_beat = hsel && hready && (htrans_i == 2'b00);
//----------------------
// assign bus_rd = hsel && hready && (htrans[1] == 1'b1) && (!hwrite);
assign bus_rd = hsel && (htrans[1] == 1'b1) && (!hwrite);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        bus_rd_d <= #1 1'b0;
        haddr_d <= #1 'd0;
    end else begin
        bus_rd_d <= #1 bus_rd;
        if (hready) begin
            haddr_d <= #1 haddr_i;      //delay 1T for read check, because current addr is next addr, so should store previous addr
        end
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        hwrite_reg <= 1'b0;
    end else begin
        hwrite_reg <= hwrite_i;
    end
end

//--- ensure when wr transfer to rd, the last write data will not be read-checked
// assign rd2wr_flg = hwrite_i && (~hwrite_reg);
assign wr2rd_flg = (~hwrite_i) && hwrite_reg;      //a 1T pulse when wr transfers to rd  

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        // last_rdata_chk_flg <= #1 1'b0;
        last_wdata_don_chk_flg <= #1 1'b0;      
    // end else if (rd2wr_flg) begin
    //     last_rdata_chk_flg <= #1 1'b1;
    end else if (wr2rd_flg) begin
        last_wdata_don_chk_flg <= #1 1'b1;
    end else if (bus_fir_beat) begin
        // last_rdata_chk_flg <= #1 1'b0;
        last_wdata_don_chk_flg <= #1 1'b0;
    end 
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin

    // end else if (bus_rd_d) begin
    // end else if (bus_rd_d && hready) begin
    // end else if (((bus_rd_d && hready) || (last_rdata_chk_flg && hready && hwrite_i))  && !(last_wdata_don_chk_flg && hready && !hwrite_i)) begin
    end else if ((bus_rd_d && hready)  && !(last_wdata_don_chk_flg && hready && (!hwrite))) begin
        ref_rdata[1*8 - 1: 0*8] = ref_mem[((haddr_d >> 2) << 2) + 0];
        ref_rdata[2*8 - 1: 1*8] = ref_mem[((haddr_d >> 2) << 2) + 1];
        ref_rdata[3*8 - 1: 2*8] = ref_mem[((haddr_d >> 2) << 2) + 2];
        ref_rdata[4*8 - 1: 3*8] = ref_mem[((haddr_d >> 2) << 2) + 3];

        if (hrdata_i != ref_rdata) begin
            $display("test_cnt: %8h",test_cnt);
            $display("ref_rdata: %8h", ref_rdata);
            $display("ref_mem: %8h", {ref_mem[haddr_d + 3],ref_mem[haddr_d + 2],ref_mem[haddr_d + 1],ref_mem[haddr_d + 0]});

            $display("Error: AHB SRAM read error at byte addr %4h: DUT is %8h, should be %8h.", 
                    haddr_d, hrdata_i, ref_rdata);
            repeat(2) @(posedge clk);
            $finish();
        end
    end
end

//--- mem content check
// wire bus_fir_beat;    //first beat with htans == NONSEQ
// reg bus_fir_beat_d;    //1T delay of bus_fir_beat
// // wire bus_idle_beat;
// // reg bus_idle_beat_d;
  
// assign bus_fir_beat = hsel && hready && (htrans_i == 2'b10);
// assign bus_idle_beat = hsel && hready && (htrans_i == 2'b00);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        bus_fir_beat_d <= 1'b0;
    end else begin
        bus_fir_beat_d <= bus_fir_beat;
    end
end

// always @(posedge clk or negedge rstn) begin
//     if (!rstn) begin
//         bus_idle_beat_d <= 1'b0;
//     end else begin
//         bus_idle_beat_d <= bus_fir_beat;
//     end
// end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
    `ifdef EN_BACK2BACK  //whether one operation is following another one 
    end else if (bus_fir_beat_d && bus_rd_d) begin      //check at the first rd finished
    `else
    end else if (bus_fir_beat_d) begin                  //check at the first cmd trans of next op finished 
     `endif
        mem_content_chk;
    end
end

//--- start send burst
wire [31:0] max_test;
integer test_cnt;
reg [mem_dw - 1: 0] rand_data;
reg [63:0] addr_wrap_back;
reg [31:0] wait_rand;
reg [31:0] rw_rand;

assign max_test = (1 << 14);

`ifdef PCLK_LOW_SPEED
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pclk_en_i <= 1'b0;
        end else begin
            pclk_en_i <= ~pclk_en_i;
        end
    end
    assign #1 pclk_en = pclk_en_i;
`else
    assign #1 pclk_en = 1'b1;
`endif 
initial begin
    bt_wait = 'd1;
    hsel_i = 1'b0;
    haddr_i = 'd0;
    htrans_i = 'd0;
    hburst_i = 'd0;
    pclk_en_i = 'd0;
    @(posedge rstn);
    hsel_i = 1'b1;

    //initialize apb_sram's ram and ref_mem
    for (acnt = 0; acnt < mem_depth; acnt = acnt + 1) begin
        rand_data = $random;
        `MEM_PATH.mem[acnt] = rand_data;

        ref_mem[(acnt << 2) + 0] = rand_data[1*8 - 1: 0*8];
        ref_mem[(acnt << 2) + 1] = rand_data[2*8 - 1: 1*8];
        ref_mem[(acnt << 2) + 2] = rand_data[3*8 - 1: 2*8];
        ref_mem[(acnt << 2) + 3] = rand_data[4*8 - 1: 3*8];

    //     if (`MEM_PATH.mem[acnt] != {ref_mem[(acnt << 2) + 3], ref_mem[(acnt << 2) + 2],ref_mem[(acnt << 2) + 1],ref_mem[(acnt << 2) + 0]}) begin
    //         $display("Initilization Error.");
    //     end
    end

    repeat(2) @(posedge clk);

    skip_info_gen = 1'b1;
    //--- t0: addr = 0, r/w
    bt_addr = 'd0; bt_size = 'd2; bt_len = 'd8; bt_wrap = 1'b0;
    //get address array
    
    for (acnt = 0; acnt < bt_len; acnt = acnt + 1) begin
        bt_addr_array[acnt] = bt_addr + 4 * acnt;
    end
    
    ahb_rd_burst;
    ahb_wr_burst;       //mem chk will starts at next burst if no back2back; otherwise will start at next rd burst
    $display("t0 test pass.");

    //--- t1: addr = max, r/w
    bt_addr = (mem_depth - 1) * 4; bt_size = 'd2; bt_len = 'd8; bt_wrap = 1'b1;
    bt_addr_array[0] = bt_addr;    //first address
    addr_wrap_back = 4 * bt_len;  //wrap block size

    for (acnt = 1; acnt < bt_len; acnt = acnt + 1) begin
        bt_addr_array[acnt] = bt_addr + 4 - addr_wrap_back + (acnt - 1)*4;
    end
    
    ahb_rd_burst;
    ahb_wr_burst;
    $display("t1 test pass.");

    //--- random test
    $display("Random Test starts.");
    skip_info_gen = 1'b0;

    for (test_cnt = 0; test_cnt < max_test; test_cnt = test_cnt + 1) begin
        // $display("test_cnt = %8h", test_cnt);

        //obtain random bt_wait
        wait_rand = $random;
        if (wait_rand[7:0] <= 128) begin
            bt_wait = 'd0;
        end else if (wait_rand[7:0] <= 128 + 64 + 32) begin
            bt_wait = 'd1;
        end else if (wait_rand[7:0] <= 128 + 64 + 32 + 16) begin
            bt_wait = 'd2;
        end else if (wait_rand[7:0] <= 64 + 32 + 16 + 8) begin
            bt_wait = 'd3;
        end else begin
            bt_wait = wait_rand[11:8];
        end

        //if EN_BACK2BACK is not enabled, then one burst shouldn't be followed by another burst
        `ifndef EN_BACK2BACK
            if (bt_wait == 'd0) begin
                bt_wait = 'd1;
            end
        `endif 
        
        rw_rand = $random;
        if (test_cnt < (max_test >> 1)) begin   //read domain
            if (rw_rand[7:0] < 128 + 64 + 32) begin
                ahb_rd_burst;
            end else begin
                ahb_wr_burst;
            end 
        end else begin
            if (rw_rand[15:8] < 128 + 64 + 32) begin    //write domain
                ahb_wr_burst;
            end else begin
                ahb_rd_burst;
            end 
        end
    end

    ahb_rd_burst;  //rd check doesn't happens during the beginning of read process if last op is wr burst
                   //mem chk only happens at the end of the first cmd trans of the rd burst
    repeat(20) @(posedge clk);
    $display("sim pass!");
    $finish();
end


endmodule