`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2022 12:05:25 AM
// Design Name: 
// Module Name: second_peak_detector
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

module second_peak_detector #(
    parameter DSIZE = 32,
    parameter DSIZE_DIV2 = 16,
    parameter FFT_LENGTH_LOG2 = 16 )(
    input wire [DSIZE_DIV2 - 1:0] i_index,
    input wire [DSIZE_DIV2 - 1:0] i_first_peak_index,
    input wire s_axis_aclk,
    input wire s_axis_aresetn,
    input wire [DSIZE -1:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    input wire [DSIZE_DIV2 - 1:0] exclude_limit,
    input wire [DSIZE-1:0] fft_length_total,
   
    output wire  o_vld,
    output wire  o_lst,
    output wire [DSIZE - 1:0] ifft_data
    );


reg [DSIZE - 1:0] r_ifft_data;//1
reg [(DSIZE * 8) -1 :0] data_q;
reg [(FFT_LENGTH_LOG2 * 8) - 1:0] index_q;



reg [FFT_LENGTH_LOG2 - 1:0] r_index;
reg [FFT_LENGTH_LOG2 -1:0] exclude_range_index1;
reg [FFT_LENGTH_LOG2 :0] exclude_range_index2;

reg [7:0] r_shift_vld;
reg [7:0] r_shift_lst;


always @(posedge s_axis_aclk)begin
    if(s_axis_aresetn == 1'b1)begin
        r_ifft_data <= 0;
        exclude_range_index1 <= 0;
        exclude_range_index2 <= 0;
        r_index <= 0;
        r_shift_vld <= 0;
        r_shift_lst <= 0;
    end
    else begin
     r_shift_vld <= {s_axis_tvalid , r_shift_vld[7:1]};
     r_shift_lst <= {s_axis_tlast , r_shift_lst[7:1]};
     index_q <= {i_index, index_q[(FFT_LENGTH_LOG2 * 8) - 1 : (FFT_LENGTH_LOG2)]};
     exclude_range_index1 <= i_first_peak_index - exclude_limit;
     exclude_range_index2 <= (i_first_peak_index) + exclude_limit;
     data_q <= {s_axis_tdata, data_q[(DSIZE *8) - 1: DSIZE]};

      if (exclude_range_index1 < 'd0) begin// on the left most edge
        exclude_range_index1 <= fft_length_total + exclude_range_index1;
      end
      else if (exclude_range_index2 >= fft_length_total) begin//on the right most edge
        exclude_range_index2 <= exclude_range_index2 - (fft_length_total);
      end
    if ( exclude_range_index1 > exclude_range_index2)begin
        if( index_q[(FFT_LENGTH_LOG2)*5 -1:FFT_LENGTH_LOG2 * 4] <= exclude_range_index2  ||index_q[(FFT_LENGTH_LOG2)*5 -1:FFT_LENGTH_LOG2 * 4] >= exclude_range_index1) begin
            r_ifft_data <=0;
            data_q <= 0;
         end
     end
     else if (index_q[(FFT_LENGTH_LOG2)*5 -1:FFT_LENGTH_LOG2 * 4] >= exclude_range_index1 && index_q[(FFT_LENGTH_LOG2)*5 -1:FFT_LENGTH_LOG2 * 4] <= exclude_range_index2) begin
          r_ifft_data <= 0;
          data_q <= 0;
      end
      else begin
        r_ifft_data <= s_axis_tdata;

        end
    end

end
assign ifft_data = data_q[(DSIZE) - 1:0];
assign o_vld = r_shift_vld[0];
assign o_lst = r_shift_lst[0];

endmodule
