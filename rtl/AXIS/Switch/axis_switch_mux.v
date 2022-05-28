`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2021 11:21:02 PM
// Design Name: 
// Module Name: axis_switch_mux
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


module axis_switch_mux #(
    parameter NUM=2,
    parameter DATA_WIDTH=32)(
    
    input wire s_axis_aclk,
    input wire [NUM-1:0] s_axis_tvalid,
    input wire [NUM * DATA_WIDTH - 1:0] s_axis_tdata,
    input wire [NUM-1:0] position,
    
    
    output reg m_axis_tvalid,
    output reg [DATA_WIDTH-1:0] m_axis_tdata
     

    );
    
    
    
    always@(posedge s_axis_aclk)begin
        if(position == 0)begin
        m_axis_tvalid <= s_axis_tvalid[0:0];
        m_axis_tdata <= s_axis_tdata[DATA_WIDTH-1:0];
    end
    else if(position == 2)
    begin
        m_axis_tvalid <= s_axis_tvalid[1:1];
        m_axis_tdata <= s_axis_tdata[DATA_WIDTH*2-1:DATA_WIDTH];
        
    end
    else
        begin

        m_axis_tdata <= 16'd0;
        m_axis_tvalid <= 1'b0;


        end
   end

endmodule
