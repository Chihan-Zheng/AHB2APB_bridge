`define PCLK_LOW_SPEED
/*
    Test bench for ahb_sram_simple module.
*/
`timescale 1ns / 10ps
module tb ();
   
parameter mem_abit = 10;
parameter mem_depth = 1024;
parameter mem_dw = 32;
parameter CLK_CYC = 10.0;

reg clk, rstn;
wire hreadyout;
wire [mem_dw - 1: 0] hrdata;
wire hresp;

wire hsel;
wire [mem_abit - 1 + 2: 0] haddr;
wire [2:0] hburst;
wire [1:0] htrans;
wire [2:0] hsize;
wire [3:0] hprot;
wire hwrite;
wire [mem_dw - 1: 0] hwdata;
wire hready;

wire [mem_abit - 1 + 2: 0] paddr;
wire [mem_abit - 1 + 2: 0] paddr_d;
wire psel;
wire psel_d;
wire penable;
wire penable_d;
wire pwrite;
wire pwrite_d;
wire [3:0] pstrb;
wire [3:0] pstrb_d;
wire [2:0] pprot;
wire [2:0] pprot_d;
wire pclk_en;
wire [mem_dw - 1: 0] pwdata;
wire [mem_dw - 1: 0] pwdata_d;

wire pready;
wire pready_d;
wire [mem_dw - 1: 0] prdata;
wire [mem_dw - 1: 0] prdata_d;
wire pslverr;
wire pslverr_d;

reg pclk;
wire pclk_d;

always #(CLK_CYC / 2) clk = ~clk;

assign #1 pclk_d = pclk;
assign #1.1 paddr_d = paddr;
assign #1.1 psel_d = psel;
assign #1.1 penable_d = penable;
assign #1.1 pwrite_d = pwrite;
assign #1.1 pstrb_d = pstrb;
assign #1.1 pprot_d = pprot;
assign #1.1 pwdata_d = pwdata;

assign #1.1 pready_d = pready;
assign #1.1 prdata_d = prdata;
assign #1.1 pslverr_d = pslverr;

`ifdef PCLK_LOW_SPEED
    always @(posedge clk) begin
        pclk <= pclk_en;
    end
`else
    always @(*) begin
        pclk = clk;
    end
`endif

initial begin
    clk = 'd0; rstn = 'd0;
    repeat(10) @(posedge clk);
    rstn = 'd1;
end

ahb_lite_ms_model #(
    .mem_abit (mem_abit),
    .mem_depth (mem_depth)
) u_ahb_lite_ms_model (
    .clk (clk),
    .rstn (rstn),
    .hreadyout (hreadyout),
    .hrdata (hrdata),
    .hresp (hresp),
    .pclk_en (pclk_en),

    .hsel (hsel),
    .haddr (haddr),
    .hburst (hburst),
    .htrans (htrans),
    .hsize (hsize),
    .hprot (hprot),
    .hwrite (hwrite),
    .hwdata (hwdata),
    .hready (hready)
);

ahb2apb_bridge #(
    .ADDRWIDTH (mem_abit + 2),
    .REGISTER_RDATA (0),
    .REGISTER_WDATA (0)
) u_ahb2apb_bridge (
    //input from master
    .hclk (clk),
    .hrstn (rstn),
    .hsel (hsel),
    .haddr (haddr),
    .htrans (htrans),
    .hsize (hsize),
    .hprot (hprot),
    .hwrite (hwrite),
    .hready (hready),
    .hwdata (hwdata),
    .pclk_en (pclk_en),
    
    //input from slave
    .pready (pready_d),
    .prdata (prdata_d),
    .pslverr (pslverr_d),

    //output to master
    .hreadyout (hreadyout),
    .hrdata (hrdata),
    .hresp (hresp),

    //output to slave
    .paddr (paddr),
    .psel (psel),
    .penable (penable),
    .pwrite (pwrite),
    .pstrb (pstrb),
    .pprot (pprot),
    .pwdata (pwdata)
);

apb_sram #(
    .MEM_ADDRBIT (mem_abit),
    .MEM_ADDRAMOUNT (mem_depth),
    .MEM_DW (mem_dw)
) u_apb_sram (
    .clk (pclk_d),
    .rstn (rstn),
    .paddr (paddr_d),
    .pwrite (pwrite_d),
    .psel (psel_d),
    .penable (penable_d),
    .pstrb (pstrb_d),
    .pprot (pprot_d),
    // .pclk_en (pclk_en),
    .pwdata (pwdata_d),

    .pready (pready),
    .prdata (prdata),
    .pslverr (pslverr)
);


endmodule