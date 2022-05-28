`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2021 10:25:13 PM
// Design Name: 
// Module Name: sample_counter_seconds
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


module sample_counter_seconds(

    input wire axis_aclk,
    input wire axis_aresetn,
    input wire i_current_data_count_valid,
    input wire i_stop_sample_counter,
    input wire [31:0] sample_counter_interval,
    
    output reg sample_count_ready


    );
    
    
     reg [31:0] sample_counter;
    always@(posedge axis_aclk)begin
       if(axis_aresetn)begin
           sample_count_ready <= 1'b0;
           sample_counter <= 'd0;
       end
       else if(i_current_data_count_valid && !i_stop_sample_counter)begin
           sample_counter <= sample_counter + 1;
           if (sample_counter == sample_counter_interval)begin
               sample_counter <= 'd0;
               sample_count_ready <= 1'b1;
           end
           else
               sample_count_ready <= 1'b0;
       end
       else if(i_stop_sample_counter) 
           sample_count_ready <= 1'b1;
       else
           sample_count_ready <= 1'b0;
    
    end
    
endmodule
