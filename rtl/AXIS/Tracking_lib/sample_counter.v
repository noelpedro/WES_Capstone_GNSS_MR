`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2022 01:39:49 AM
// Design Name: 
// Module Name: sample_counter
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

module sample_counter(
    input wire axis_aclk,
    input wire axis_aresetn,
    input wire i_start,
    input wire i_vld,
    output reg o_vld,
    output reg [1:0] st,
    output reg [1:0] st_next,
    output reg [63:0] o_count
    );

localparam ST_IDLE = 2'b00, ST_COUNT = 2'b01, ST_WAIT = 2'b11;
//reg [1:0] st, st_next;


always @(*) begin
    case(st)
    ST_IDLE:begin
        if(i_start)
            st_next = ST_COUNT;
         else
            st_next = ST_IDLE;
    end
    ST_COUNT:begin
        st_next = ST_WAIT;
    end
    ST_WAIT:begin
        st_next = ST_COUNT;
    end
    default:
        st_next = ST_IDLE;
    endcase
end

always @(posedge axis_aclk) begin
    if(axis_aresetn == 1'b1)
        st <= ST_IDLE;
     else
        st <= st_next;
end

always @(posedge axis_aclk)begin
    if(axis_aresetn == 1'b1)begin
        o_count <= 64'd0;
        o_vld <= 1'b0;
     end else if(i_vld && st != ST_IDLE) begin
        o_vld <= i_vld;
        o_count <= o_count + 1;
     end
     else begin
        o_vld <= 0;
  
     end
end

endmodule
