`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2022 08:56:57 PM
// Design Name: 
// Module Name: track_accumulator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module track_accumulator#(
    parameter INPUT_WIDTH = 'd16,
    parameter OUTPUT_WIDTH = 'd32
)
(
    input i_clk,
    input i_rstn,
    input i_en,
    input [(INPUT_WIDTH-1):0] i_baseband,
    input i_ca_bit,
    output reg [(OUTPUT_WIDTH-1):0] o_accumulator
);

reg [(OUTPUT_WIDTH-1):0] r_accum;

// Remove CA Bit and Sing Extend
wire[(OUTPUT_WIDTH-1):0] ca_removed;

assign ca_removed = i_en ? (i_ca_bit ? $signed(i_baseband) : -$signed(i_baseband)) : 0;

// Accumulate
// Delay r_accum to meet timing 
always @(posedge i_clk) begin
    if(i_rstn == 1'b1)begin
        r_accum <= 0;
        o_accumulator <= 0;
    end else begin
        r_accum <= ca_removed;
        o_accumulator <=  r_accum + o_accumulator;
    end

end

endmodule