/*
    SRAM using APB protocol.
*/
module apb_sram #(
    parameter MEM_ADDRBIT = 10,
    parameter MEM_ADDRAMOUNT = 1024,
    parameter MEM_DW = 32,
    parameter HAS_ERROR = 0
) (
    input wire clk,
    input wire rstn,
    input wire [MEM_ADDRBIT + 2 - 1: 0] paddr,
    input wire pwrite,
    input wire psel,
    input wire penable,
    input wire [MEM_DW - 1: 0] pwdata,
    input wire [3:0] pstrb,
    input wire [2:0] pprot,
    // input wire pclk_en,
    
    output wire pready,
    output reg [MEM_DW - 1: 0] prdata,
    output wire pslverr
);
    
reg [MEM_ADDRBIT - 1: 0] apb_addr;    //address got by ram

wire apb_write_w;    
reg apb_write_w_reg;     //1T delay of apb_write_w
reg apb_write;    //1T pulse during write period
reg [MEM_DW - 1: 0] apb_wdata;     //written data got by ram

//getting address for ram
always @(posedge clk) begin
    if (psel & (!penable)) begin
        apb_addr <= paddr[2 +: MEM_ADDRBIT];
    end else begin
        apb_addr <= apb_addr;
    end
end

//--- write
//In order to adjust for master's BUSY, this apb_slave need 3T to write data
assign apb_write_w = pwrite & psel &(!penable);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        apb_write_w_reg <= 1'b0;
    end else begin
        apb_write_w_reg <= apb_write_w;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        apb_write <= 1'b0;
    // end else if (apb_write_w) begin
    end else if (apb_write_w_reg && penable) begin
        apb_write <= 1'b1;
    // end else if (pready) begin
    end else if (apb_write == 1'b1) begin
        apb_write <= 1'b0;
    end else begin
        apb_write <= apb_write;
    end
end

//generate pulse for write period
// always @(posedge clk or negedge rstn) begin
//     if (!rstn) begin
//         apb_write <= 1'b0;
//     // end else if (apb_write_w) begin
//     end else if (apb_write_w) begin
//         apb_write <= 1'b1;
//     end else if (pready) begin
//         apb_write <= 1'b0;
//     end else begin
//         apb_write <= apb_write;
//     end
// end

//transfer data to ram input
always @(posedge clk) begin
    if (penable) begin
        apb_wdata <= pwdata;
    end else begin
        apb_wdata <= apb_wdata;
    end
end

//--- read
wire mem_cs;   //ram chip select
wire apb_read_w;  
reg apb_read;   //1T pulse for ram read 1T period

wire [MEM_DW - 1: 0] mem_dout;   //dout of ram
reg [1:0] apb_rd_d;    //2 pipes of apb_read

assign mem_cs = (apb_write | apb_read) && penable;
assign apb_read_w = psel & (!pwrite) & (!penable);

//get 1T pulse for 1T read period of ram
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        apb_read <= 1'b0;
    end else begin
        apb_read <= apb_read_w;
    end
end

//2 pipes of apb_rd
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        apb_rd_d <= 'd0;
    end else if (penable) begin
        apb_rd_d <= {apb_rd_d[0], apb_read};
    end
end

//get output data with 1T delay (1 pipe)
always @(posedge clk) begin
    if (apb_rd_d[0]) begin
        prdata <= mem_dout;
    end else begin
        prdata <= prdata;
    end
end

assign pready = (pwrite)? apb_write : apb_rd_d[1];
assign pslverr = ((HAS_ERROR == 1) && pready)? 1'b1 : 1'b0;

spram_generic_wbe4 #(
    .ADDR_BITS (MEM_ADDRBIT),
    .ADDR_AMOUNT (MEM_ADDRAMOUNT),
    .DATA_BITS (MEM_DW)
) u_mem (
    .clk (clk),
    .rstn (rstn),
    .en (mem_cs),
    .we (apb_write),
    .wbe (pstrb),
    .addr (apb_addr),
    .din (apb_wdata),

    .dout (mem_dout)
);


endmodule