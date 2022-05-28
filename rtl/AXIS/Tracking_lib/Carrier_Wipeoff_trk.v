`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2022 05:10:20 PM
// Design Name: 
// Module Name: Carrier_Wipeoff_trk
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


module Carrier_Wipeoff_trk#(parameter DSIZE = 32)(
    
    input wire [DSIZE-1:0] i_phase_step_rad,
    input wire [DSIZE-1:0] i_rem_carr_phase_rad,
    input wire [DSIZE-1:0] i_phase_step_rate,
    input wire [DSIZE-1:0] i_correlator_length_samples,
    
    input wire i_raw_data_valid,
    input wire i_start_tracking,
    input wire i_delay_ready,
    input wire axis_aclk,
    input wire i_cordic_valid,
    /* DEBUG */
   // output reg [DSIZE - 1:0] phase_counter,
    //output reg [DSIZE + 1:0] r_phase_rate,
    
    output wire [DSIZE/2 -1:0] o_sincos,
    output wire o_sincos_valid


    );
reg [DSIZE - 1:0] phase_rate;


reg [DSIZE - 1:0] phase_counter;

reg [DSIZE + 1:0] r_phase_rate;
wire [DSIZE + 1:0] cordic_data; 
wire cordic_valid;
wire [DSIZE-1:0] n_;
wire en1;
wire en2;

assign en1 = i_start_tracking && !i_delay_ready;
assign en2 = i_start_tracking && i_delay_ready && i_raw_data_valid;

reg r_valid;
reg rr_valid;

reg r_valid1;
reg rr_valid1;

reg [DSIZE-1:0] prod1;
reg [DSIZE-1:0] r_prod1;
reg [DSIZE-1:0] rr_prod1;
reg [DSIZE-1:0] r_prod2;
reg [DSIZE-1:0] rr_prod2;
wire [DSIZE-1:0] sum_;
assign n_ = phase_counter;
wire [DSIZE-1:0] n_squared;

assign n_squared = n_ * n_;

always @(posedge axis_aclk)begin
	r_valid <= en1;
	rr_valid <= r_valid;

	r_valid1 <= en2;
	rr_valid1 <= r_valid1;
	
	r_prod1 <= n_squared;
	rr_prod1 <= r_prod1;
	
	r_prod2 <= i_phase_step_rad * n_ + i_rem_carr_phase_rad;
	rr_prod2 <= r_prod2;

end	

assign sum_ = (rr_prod1 * i_phase_step_rate) + rr_prod2;
    
     always@(posedge axis_aclk)begin
    if (en1) begin
    //if (rr_valid) begin
        phase_rate <=  (i_phase_step_rad * (phase_counter) + i_rem_carr_phase_rad);
        
    end else if(en2)begin
    //end else if(rr_valid1)begin
        phase_rate <=  (i_phase_step_rad * (phase_counter) + i_rem_carr_phase_rad);
        //phase_rate <=  sum_;
        
    end else if(!i_start_tracking)begin
        phase_rate <=  (i_rem_carr_phase_rad);
        //phase_counter <= 'd1;
    end
  end


always @(posedge axis_aclk)begin
    if (en1)
        phase_counter <= phase_counter + 1;
    else if(en2)
	    phase_counter <= phase_counter +1;
    else if(!i_start_tracking)
	    phase_counter <= 1;
    if ( phase_counter == i_correlator_length_samples - 1)
        phase_counter <= 'd0;


end
reg r_cordic_valid;
reg rr_cordic_valid;
reg rrr_cordic_valid;

always@(posedge axis_aclk)begin
    r_cordic_valid <= i_cordic_valid;
    rr_cordic_valid <= r_cordic_valid;
    rrr_cordic_valid <= rr_cordic_valid;
end
wire cordic_valid_dly;
assign cordic_valid_dly = rr_cordic_valid;
always @(*)begin

        r_phase_rate = $signed(phase_rate);

end


  assign cordic_data = r_phase_rate;
  assign cordic_valid = i_cordic_valid;// && fifo_valid;
  sincos sincos_inst
  (
  .s_axis_phase_tdata(cordic_data),
  .s_axis_phase_tvalid(cordic_valid),
  .aclk(axis_aclk),

  .m_axis_dout_tdata(o_sincos),
  .m_axis_dout_tvalid(o_sincos_valid)


  );


endmodule
