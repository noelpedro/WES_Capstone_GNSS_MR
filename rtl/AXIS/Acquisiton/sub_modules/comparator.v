`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2022 08:23:32 AM
// Design Name: 
// Module Name: comparator
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


module comparator
#(
    parameter DATA_WIDTH = 32
 )
    (
    input wire [DATA_WIDTH:0] i_a,
    input wire [DATA_WIDTH:0] i_b,
    output reg o_greater
    );


always @(*) begin
if (i_a < i_b)
    o_greater = 1'b0;
 else if (i_a > i_b)
    o_greater = 1'b1;
 else
    o_greater = 1'b0;
end
endmodule
