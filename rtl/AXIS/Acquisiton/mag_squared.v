`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2022 08:26:55 AM
// Design Name: 
// Module Name: mag_squared
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
module mag_squared #(
    parameter DSIZE = 32,
    parameter DSIZE_DIV2 = 16,
    parameter FFT_LENGTH_LOG2 = 16)(




    input wire s00_axis_aresetn,
    input wire s00_axis_aclk,
    input wire s00_axis_tvalid,
    input wire [DSIZE - 1:0] s00_axis_tdata,
    input wire [DSIZE_DIV2- 1 : 0] i_index,

  



    output wire [DSIZE_DIV2 - 1:0] o_max,
    output wire [DSIZE_DIV2 - 1:0] o_max_index,
    output wire o_done,
    input  wire s00_axis_tlast
    );

reg [DSIZE_DIV2:0] sum_squared;   
reg [DSIZE_DIV2:0] r_max;
wire [DSIZE_DIV2 -1:0] im;
wire [DSIZE_DIV2 - 1:0] re;
reg [DSIZE_DIV2 -1:0] abs_im;
reg [DSIZE_DIV2 - 1:0] abs_re;
reg [DSIZE_DIV2 - 1:0]r_max_index;
reg [DSIZE_DIV2 - 1:0]rr_max_index;
reg [DSIZE_DIV2 - 1:0]rrr_max_index;
wire is_greater;



reg r_last, rr_last,r_valid;
assign im = s00_axis_tdata[DSIZE-1:DSIZE_DIV2];
assign re = s00_axis_tdata[DSIZE_DIV2 - 1:0];

always @(posedge s00_axis_aclk)begin
    if(im[DSIZE_DIV2-1] == 1)
        abs_im <= -$signed(im);
     else
        abs_im <= im;
end

always @(posedge s00_axis_aclk)begin
    if(re[DSIZE_DIV2 - 1] == 1)
        abs_re <= -$signed(re);
     else
        abs_re <= re;
end


always @(posedge s00_axis_aclk)begin
    if(r_valid)
        sum_squared <= abs_im  +  abs_re;
     else
        sum_squared <= 0;
end



always @(posedge s00_axis_aclk)begin
    r_last <= s00_axis_tlast && s00_axis_tvalid;
    rr_last <= r_last;
    r_valid <= s00_axis_tvalid;
end
comparator_0 //#(.DSIZE(32))
comp_inst (
    .i_a(sum_squared),
    .i_b(r_max),
    .o_greater(is_greater));


always @(posedge s00_axis_aclk)begin
    r_max_index <= i_index;
    rr_max_index <= r_max_index;
    if(s00_axis_aresetn || !r_valid)begin
        rrr_max_index <= 'd0;
        r_max <= 'd0;
     end else if(is_greater == 1'b1)begin
        r_max <= sum_squared;
        //rrr_max_index <= r_max_index;
        //rrr_max_index <= i_index;
        rrr_max_index <= rr_max_index;
     end

end

assign o_max = r_max[DSIZE_DIV2:1];
assign o_max_index = rrr_max_index;
assign o_done = rr_last;


endmodule
