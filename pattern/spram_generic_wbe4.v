/*
    Generic SPRAM with 4 bits wbe port.
    DATA WIDTH is 32 bits.
*/
module spram_generic_wbe4 #(
    parameter ADDR_BITS = 7,
    parameter ADDR_AMOUNT = 128,
    parameter DATA_BITS = 32
) (
    input wire clk,
    input wire rstn,
    input wire en,
    input wire we,
    input wire [3:0] wbe,
    input wire [ADDR_BITS - 1: 0] addr,
    input wire [DATA_BITS - 1: 0] din,

    output reg [DATA_BITS - 1: 0] dout
);

reg [DATA_BITS - 1: 0]  mem [0:ADDR_AMOUNT - 1];

always @(posedge clk) begin
    if (en) begin
        if (we) begin
            if (wbe[0] == 1'b1) begin
                mem[addr][0 +: 8] <= din[0 +: 8];
            end

            if (wbe[1] == 1'b1) begin
                mem[addr][8 +: 8] <= din[8 +: 8];
            end

            if (wbe[2] == 1'b1) begin
                mem[addr][2*8 +: 8] <= din[2*8 +: 8];
            end

            if (wbe[3] == 1'b1) begin
                mem[addr][3*8 +: 8] <= din[3*8 +: 8];
            end 
        end else begin
            dout <= mem[addr];
        end
    end
end

    
endmodule