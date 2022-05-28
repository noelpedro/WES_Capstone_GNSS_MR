`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2022 08:16:24 AM
// Design Name: 
// Module Name: maximum_index
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


module maximum_index#(
parameter DSIZE = 32,
parameter FFT_LENGTH_LOG2 = 12,
parameter ROW_SIZE = 6)(
    input wire i_first_peak_done,
     input wire i_second_peak_done,
    input wire [DSIZE -1:0] i_first_peak,
    input wire [DSIZE -1:0] i_second_peak,
    input wire [FFT_LENGTH_LOG2 - 1:0] i_code_phase,
    input wire [DSIZE-1-1:0] bin,
    output wire [DSIZE -1:0] first_peak,
    output wire [DSIZE -1:0] second_peak,
    output wire [FFT_LENGTH_LOG2 - 1:0] code_phase,
    output wire [DSIZE - 1:0] doppler_index,
    output reg o_done,


    input wire axis_aclk,
    input wire axis_aresetn,
    input wire [DSIZE-1:0] i_nbins
    );
reg [DSIZE-1:0] r_first_peak;
reg [DSIZE-1:0] r_second_peak;
reg [FFT_LENGTH_LOG2-1:0] r_code_phase;
reg [DSIZE-1-1:0] r_bin;

always @(posedge axis_aclk)begin
    if(axis_aresetn) begin

        r_first_peak <= 0;

        r_code_phase <= 0;
        r_bin <= 0;
    end
    else if (i_first_peak_done) begin
    if (i_first_peak > r_first_peak)begin
        r_first_peak <= i_first_peak;
        r_code_phase <= i_code_phase;

        r_bin <= bin;

        end
    end

end

always @(posedge axis_aclk)begin
    if(axis_aresetn) begin
    r_second_peak <= 0;
    end
    else if (i_second_peak_done && (doppler_index == bin)) begin
        r_second_peak <= i_second_peak;
    end
    end



always @(posedge axis_aclk)begin
if (axis_aresetn)begin
     o_done <= 1'b0;
 end
else if (bin == i_nbins)
        o_done <= 1'b1;

end
assign first_peak = r_first_peak;
assign second_peak = r_second_peak;
assign code_phase = r_code_phase;
assign doppler_index = r_bin;


endmodule
