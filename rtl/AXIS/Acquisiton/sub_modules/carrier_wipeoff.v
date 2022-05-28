`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2022 05:49:35 AM
// Design Name: 
// Module Name: carrier_wipeoff
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


module carrier_wipeoff
#(parameter DATA_WIDTH = 32,
  parameter CORDIC_INPUT_DATA_WIDTH=34,
  parameter CORDIC_OUTPUT_DATA_WIDTH=16)(
  
  input wire axis_aclk,
  input wire axis_aresetn,

  input wire [DATA_WIDTH-1:0] doppler_step,
  input wire [DATA_WIDTH-1:0] doppler_min,
  input wire [DATA_WIDTH-1:0] bin_counter,
  input wire enable,
  
  output wire [DATA_WIDTH/2-1:0] o_phase_count,
  output wire [CORDIC_OUTPUT_DATA_WIDTH-1:0] sincos_output,
  output wire sincos_valid
      );
    
wire [CORDIC_INPUT_DATA_WIDTH-1:0] cordic_input;   
wire cordic_valid;

reg [CORDIC_INPUT_DATA_WIDTH-1:0] r_cordic_input;
reg [DATA_WIDTH-1:0] phase;
reg [DATA_WIDTH-1:0] r_phase;
reg [DATA_WIDTH/2-1:0] phase_count;
reg r_cordic_valid;



always @(posedge axis_aclk)begin
        phase <= doppler_min + doppler_step * bin_counter;
end


always @(posedge axis_aclk)begin
    if(axis_aresetn == 1'b1)
        r_cordic_valid <= 1'b0;
     else if(enable)
        r_cordic_valid <= 1'b1;
     else
        r_cordic_valid <= 1'b0;
end

always @(posedge axis_aclk)begin
    if (r_cordic_valid)begin
        r_phase <= (phase_count + 1) * phase;
        phase_count <= phase_count + 1;
    end
    else begin
        r_phase <= phase_count * phase;
        phase_count <= 0;
    end

end


assign o_phase_count = phase_count;
/* sign extend data from 32 bits to 34 bits, COrdic expects 34 bits 3_31 */
always @(*)begin
    if (r_phase[DATA_WIDTH-1] == 1)
        r_cordic_input = $signed(r_phase);
    else
        r_cordic_input = r_phase;
end


assign cordic_input = r_cordic_input;
assign cordic_valid = r_cordic_valid;

             
/* Generate sin and cosine */
cordic_sin_cos inst_cordic(

        .s_axis_phase_tdata(cordic_input),
        .s_axis_phase_tvalid(cordic_valid),
        .aclk(axis_aclk),
        .m_axis_dout_tdata(sincos_output),
        .m_axis_dout_tvalid(sincos_valid)

);


endmodule
