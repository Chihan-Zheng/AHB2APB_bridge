/*
    AHB to APB bridge with write data register config and read data config.
    PCLK can be slower than HCLK, controlled by pclk_en.
*/
module ahb2apb_bridge #(
    parameter ADDRWIDTH = 16,
    parameter REGISTER_RDATA = 0,
    parameter REGISTER_WDATA = 0
) (
    input wire hclk,
    input wire pclk_en,
    input wire hrstn,

    input wire hsel,
    input wire [ADDRWIDTH - 1: 0] haddr,
    input wire [1:0] htrans,
    input wire [2:0] hsize,
    input wire [3:0] hprot,
    input wire hwrite,
    input wire hready,
    input wire [31:0] hwdata,

    input wire pready,
    input wire [31:0] prdata,
    input wire pslverr,

    output wire [ADDRWIDTH - 1: 0] paddr,
    output wire psel,
    output wire penable,
    output wire pwrite,
    output wire [3:0] pstrb,
    output wire [2:0] pprot,
    output wire [31:0] pwdata,

    output reg hreadyout,
    output wire [31:0] hrdata,
    output wire hresp
);

//state machine's states
parameter ST_APB_IDLE = 3'b000;
parameter ST_APB_WAIT = 3'b001;
parameter ST_APB_TRNF1 = 3'b010;
parameter ST_APB_TRNF2 = 3'b011;
parameter ST_APB_ENDOK = 3'b100;
parameter ST_APB_ERR1 = 3'b101;
parameter ST_APB_ERR2 = 3'b110;
parameter ST_APB_ILLEGLE = 3'b111;

reg [2:0] sta, nxt_sta;   //current state and next state

wire reg_rdata_cfg;
wire reg_wdata_cfg;
wire apb_select;
wire [1:0] pprot_nxt;
reg [1:0] pprot_reg;
reg [ADDRWIDTH - 3: 0] addr_reg;
wire [3:0] pstrb_nxt;
reg [3:0] pstrb_reg;
reg hwrite_reg; 

assign reg_rdata_cfg = (REGISTER_RDATA == 0)? 1'b1 : 1'b0;    //whether to register prdata
assign reg_wdata_cfg = (REGISTER_WDATA == 0)? 1'b1 : 1'b0;   //whether to register hwdata
assign apb_select = hsel && htrans[1] && hready;     //slave will accept address right after this period 
assign pprot_nxt[0] = hprot[1];      //pprot = {pprot_reg[1], 1'b0, pprot_reg[0]}
assign pprot_nxt[1] = ~hprot[0];

//get pstrb
assign pstrb_nxt[0] = hsize[1] || (hsize[0] && !haddr[1]) || (!hsize[0] && haddr[1:0] == 2'b00);
assign pstrb_nxt[1] = hsize[1] || (hsize[0] && !haddr[1]) || (!hsize[0] && haddr[1:0] == 2'b01);
assign pstrb_nxt[2] = hsize[1] || (hsize[0] && haddr[1]) || (!hsize[0] && haddr[1:0] == 2'b10);
assign pstrb_nxt[3] = hsize[1] || (hsize[0] && haddr[1]) || (!hsize[0] && haddr[1:0] == 2'b11);

//register control signals when apb-slave needs to get control signals
always @(posedge hclk or hrstn) begin
    if (!hrstn) begin
        pprot_reg <= 2'b00;
        addr_reg <= 'd0;
        pstrb_reg <= 'd0;
        hwrite_reg <= 1'b0;
    end else if (apb_select) begin        
       pprot_reg <= pprot_nxt;
       addr_reg <= haddr[ADDRWIDTH - 1: 2];
       pstrb_reg <= pstrb_nxt;
       hwrite_reg <= hwrite; 
    end
end

//state machine
always @(*) begin
    case (sta)
        ST_APB_IDLE: begin           
            if (apb_select && !(reg_wdata_cfg && hwrite) && pclk_en) begin
                nxt_sta = ST_APB_TRNF1;
            end else if (apb_select) begin
                nxt_sta = ST_APB_WAIT;
            end else begin
                nxt_sta = ST_APB_IDLE;
            end
        end

        ST_APB_WAIT: begin
            if (pclk_en) begin
                nxt_sta = ST_APB_TRNF1;
            end else begin
                nxt_sta = ST_APB_WAIT;
            end
        end
        
        ST_APB_TRNF1: begin
            if (pclk_en) begin
                nxt_sta = ST_APB_TRNF2;
            end else begin
                nxt_sta = ST_APB_TRNF1;
            end
        end

        ST_APB_TRNF2: begin
            if (pclk_en && pslverr && pready) begin
                nxt_sta = ST_APB_ERR1;
            end else if (pclk_en && !pslverr && pready) begin
                if (reg_rdata_cfg && !hwrite) begin
                    nxt_sta = ST_APB_ENDOK;
                end else if (reg_wdata_cfg && hwrite && apb_select) begin
                    nxt_sta = ST_APB_WAIT;
                end else if (apb_select) begin
                    nxt_sta = ST_APB_TRNF1;
                end else begin
                    nxt_sta = ST_APB_IDLE;
                end
            end else begin
                nxt_sta = ST_APB_TRNF2;
            end
        end

        ST_APB_ENDOK: begin
            if (pclk_en && apb_select && !(reg_wdata_cfg && hwrite)) begin
                nxt_sta = ST_APB_TRNF1;
            end else if (apb_select) begin
                nxt_sta = ST_APB_WAIT;
            end else begin
                nxt_sta = ST_APB_IDLE;
            end
        end

        ST_APB_ERR1: begin
            nxt_sta = ST_APB_ERR2;
        end 

        ST_APB_ERR2: begin
            if (pclk_en && apb_select && !(reg_wdata_cfg && hwrite)) begin
                nxt_sta = ST_APB_TRNF1;
            end else if(apb_select) begin
                nxt_sta = ST_APB_WAIT;
            end else begin
                nxt_sta = ST_APB_IDLE;
            end
        end

        default: nxt_sta = ST_APB_IDLE;
    endcase
end

//sta transfers
always @(posedge hclk or negedge hrstn) begin
    if (!hrstn) begin
        sta <= 'd0;
    end else begin
        sta <= nxt_sta;
    end

end

wire sample_wdata_set;     //1T before sample_wdata_vld needs to be set
wire sample_wdata_clr;   //1T before sample_wdata_vld needs to be cleared
reg sample_wdata_vld;    //flag to sample write data

assign sample_wdata_set = hwrite && apb_select && reg_wdata_cfg;   //only when wdata needs to be registered in a active write process
assign sample_wdata_clr = sample_wdata_vld && pclk_en;     //clear sample_wdata_vld when it is high and pclk is coming

always @(posedge hclk or negedge hrstn) begin
    if (!hrstn) begin
        sample_wdata_vld <= 1'b0;
    end else if (sample_wdata_set || sample_wdata_clr) begin
        sample_wdata_vld <= sample_wdata_set;
    end
end

reg [31:0] rwdata_reg;  //put registered rdata and registered wdata in this reg

always @(posedge hclk or negedge hrstn) begin
    if (!hrstn) begin
        rwdata_reg <= 'd0;
    end else if (sample_wdata_vld && pclk_en) begin       //sample when pclk comes and sample_wdata_vld is high
        rwdata_reg <= hwdata; 
    end else if (reg_rdata_cfg && (sta == ST_APB_TRNF2) && pready && pclk_en && !hwrite) begin   //when the last period of ST_APB_TRNF2 during registered read process and pclk comes
        rwdata_reg <= prdata;
    end
end

assign paddr = {addr_reg, 2'b00};     //only needs word address, because of pstrob
assign pwrite = hwrite_reg;      
assign psel = (sta == ST_APB_TRNF1) || (sta == ST_APB_TRNF2);      //psel is high during TRANSFER states
assign penable = (htrans == 2'b01)? 1'b0 : (sta == ST_APB_TRNF2);       //penable should be low when master is busy, otherwise should be high during ST_APB_TRNF2
assign pprot = {pprot_reg[1], 1'b0, pprot_reg[0]};   //pprot is set to be secure mode
assign pstrb = pstrb_reg;
assign pwdata = (reg_wdata_cfg)? rwdata_reg : hwdata;   

wire apb_active;    //period when apb is active

//get hreadyout
always @(*) begin
    case (sta)
        ST_APB_IDLE: hreadyout = 1'b1;
        ST_APB_WAIT: hreadyout = 1'b0;
        ST_APB_TRNF1: hreadyout = 1'b0;
        ST_APB_TRNF2: hreadyout = pready && (!pslverr) && !(reg_rdata_cfg && !hwrite) && pclk_en;
        ST_APB_ENDOK: hreadyout = reg_rdata_cfg;
        ST_APB_ERR1: hreadyout = 1'b0;
        ST_APB_ERR2: hreadyout = 1'b1;
        default: hreadyout = 1'bx;
    endcase
end

assign hrdata = (reg_rdata_cfg)? rwdata_reg : prdata;      
assign hresp = (sta == ST_APB_ERR1) || (sta == ST_APB_ERR2);    //hresp should be 2T high during ERR states
assign apb_active = (hsel && apb_select) || (|sta);        


endmodule
