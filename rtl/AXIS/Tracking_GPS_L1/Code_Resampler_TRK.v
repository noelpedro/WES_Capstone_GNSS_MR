`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2022 06:16:20 PM
// Design Name: 
// Module Name: Code_Resampler_TRK
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


module Code_Resampler_TRK#(parameter DSIZE=32,
                           parameter CODE_LENGTH=1023,
                           parameter NUM_ACCUM = 3,
                           parameter CODE_LENGTH_LOG2 = 10)(
    input wire axis_aclk,
    input wire i_start_tracking_valid,
    input wire i_clear,
    input wire i_clear_accum,
    
    input wire [DSIZE-1:0] i_ca_code_tdata,
    input wire i_ca_code_tvalid,
    input wire i_mixed_signal_valid,
    input wire [DSIZE - 1:0] i_mixed_signal_data,
    input wire [DSIZE-1:0] i_initial_index_E,
    input wire [DSIZE-1:0] i_initial_index_P,
    input wire [DSIZE-1:0] i_initial_index_L,
    
    input wire [DSIZE-1:0] i_initial_interp_counter_E,
    input wire [DSIZE-1:0] i_initial_interp_counter_P,
    input wire [DSIZE-1:0] i_initial_interp_counter_L,
    
    input wire [DSIZE-1:0] i_code_phase_step_chips,
    input wire [DSIZE-1:0] i_code_phase_step_chips_rate,
    
    
    output wire [DSIZE-1:0] o_iE,
    output wire [DSIZE-1:0] o_iP,
    output wire [DSIZE-1:0] o_iL,
    
    output wire [DSIZE-1:0] o_qE,
    output wire [DSIZE-1:0] o_qP,
    output wire [DSIZE-1:0] o_qL
    

    

    );
    
    
 reg [DSIZE-1:0] counter;
 reg [(DSIZE *2):0] local_code_chip_index_E;
reg [(DSIZE *2):0] local_code_chip_index_P;
reg [(DSIZE *2):0] local_code_chip_index_L;

reg [CODE_LENGTH_LOG2-1:0] local_code_chip_index_e_;
reg [CODE_LENGTH_LOG2-1:0] local_code_chip_index_p_;
reg [CODE_LENGTH_LOG2-1:0] local_code_chip_index_l_;


wire [(DSIZE + 11)-1:0] index_E;
wire [(DSIZE + 11)-1:0] index_P;
wire [(DSIZE + 11)-1:0] index_L;
wire [DSIZE-1:0] accum_i [0:NUM_ACCUM-1];
wire [DSIZE-1:0] accum_q [0:NUM_ACCUM-1];



reg [NUM_ACCUM-1:0] ca_bits;

assign index_E[DSIZE-2:0] = {i_initial_interp_counter_E};
assign index_E[DSIZE + CODE_LENGTH_LOG2:DSIZE-1] = {i_initial_index_E};
assign index_P[DSIZE - 2:0] = {i_initial_interp_counter_P};
assign index_P[DSIZE + CODE_LENGTH_LOG2:DSIZE - 1] = {i_initial_index_P};
assign index_L[DSIZE - 2:0] = {i_initial_interp_counter_L};
assign index_L[DSIZE + CODE_LENGTH_LOG2:DSIZE-1] = {i_initial_index_L};
reg [0:0] ca_codes [CODE_LENGTH-1:0];
reg [CODE_LENGTH_LOG2-1:0] ca_code_cntr;
wire [DSIZE-1:0] n_;
wire [DSIZE-1:0] n_squared;
assign n_ = counter;
assign n_squared = n_ * n_;


reg [(DSIZE + 11)-1:0] r_prod1;
reg [(DSIZE + 11)-1:0] rr_prod1;
reg [(DSIZE + 11)-1:0] r_prod2_E;
reg [(DSIZE + 11)-1:0] rr_prod2_E;
reg [(DSIZE + 11)-1:0] r_prod2_P;
reg [(DSIZE + 11)-1:0] rr_prod2_P;
reg [(DSIZE + 11)-1:0] r_prod2_L;
reg [(DSIZE + 11)-1:0] rr_prod2_L;

 always@(posedge axis_aclk)begin
    if(i_ca_code_tdata == 32'h10000000)begin
        ca_code_cntr <= 'd0;
    end
    else if (i_ca_code_tvalid && ca_code_cntr < CODE_LENGTH && i_ca_code_tdata != 32'h10000000)begin
        ca_codes[ca_code_cntr] <= i_ca_code_tdata[0:0];
        ca_code_cntr <= ca_code_cntr + 1;
    end
 end

reg r_start_tracking_valid;
reg rr_start_tracking_valid;

reg r_mixed_signal_valid;
reg rr_mixed_signal_valid;

reg [DSIZE-1:0]r_mixed_signal_data;
reg [DSIZE-1:0]rr_mixed_signal_data;


wire [(DSIZE + 11)-1:0] sum_E;
wire [(DSIZE + 11)-1:0] sum_P;
wire [(DSIZE + 11)-1:0] sum_L;


 always @(posedge axis_aclk)begin
	r_start_tracking_valid <= i_start_tracking_valid;
	rr_start_tracking_valid <= r_start_tracking_valid;
    
    r_mixed_signal_data <= i_mixed_signal_data;
    rr_mixed_signal_data <= r_mixed_signal_data;
    
	r_mixed_signal_valid <= i_mixed_signal_valid;
	rr_mixed_signal_valid <= r_mixed_signal_valid;

	r_prod1 <= n_squared;
	rr_prod1 <= r_prod1;

	r_prod2_E <= i_code_phase_step_chips * n_ + index_E;
	r_prod2_P <= i_code_phase_step_chips * n_ + index_P;
	r_prod2_L <= i_code_phase_step_chips * n_ + index_L;
	
	rr_prod2_E <= r_prod2_E;
	rr_prod2_P <= r_prod2_P;
	rr_prod2_L <= r_prod2_L;

 end
assign sum_E = (rr_prod1 * i_code_phase_step_chips_rate)+ rr_prod2_E;
assign sum_P = (rr_prod1 * i_code_phase_step_chips_rate)+ rr_prod2_P;
assign sum_L = (rr_prod1 * i_code_phase_step_chips_rate)+ rr_prod2_L;

wire [DSIZE-1:0] mixed_signal_data_;
assign mixed_signal_data_ = rr_mixed_signal_data;

always@(posedge axis_aclk)begin
    if(i_start_tracking_valid)begin
    //if(rr_start_tracking_valid)begin
        counter <=1;
        //ca_counter <= 0;
        //local_code_chip_index_E <= (code_phase_step_chips ) * counter;// Early
        //local_code_chip_index_P <= (code_phase_step_chips )* counter;// Prompt
        //local_code_chip_index_L <= (code_phase_step_chips ) * counter;// Late
        //local_code_chip_index_CP_IDX <= (code_phase_step_chips) * counter;



        //index_E <= 0;
        //index_P <= 0;
        //index_L <= 0;
        //index_cpx_idx <= 0;
        local_code_chip_index_e_ <= i_initial_index_E;
        local_code_chip_index_p_ <= i_initial_index_P;
        local_code_chip_index_l_ <= i_initial_index_L;
        
        //local_code_chip_index_E <= index_E;// Early 
        //local_code_chip_index_P <= index_P;// Prompt
        //local_code_chip_index_L <= index_L;// Late
        //local_code_chip_index_CP_IDX <= index_cpx_idx;
        ca_bits[0] <= ca_codes[ i_initial_index_E[CODE_LENGTH_LOG2-1:0]];// Early 
        ca_bits[1] <= ca_codes[ i_initial_index_P[CODE_LENGTH_LOG2-1:0]];// Prompt
        ca_bits[2] <= ca_codes[ i_initial_index_L[CODE_LENGTH_LOG2-1:0]];// Late

        local_code_chip_index_E <= (i_code_phase_step_chips) * n_ + index_E;// Early 
        local_code_chip_index_P <= (i_code_phase_step_chips) * n_ + index_P;// Prompt
        local_code_chip_index_L <= (i_code_phase_step_chips) * n_ + index_L;// Late
        
	    //local_code_chip_index_E <= sum_E;// Early 
        //local_code_chip_index_P <= sum_P;// Prompt
        //local_code_chip_index_L <= sum_L;// Late
       

    end
    else if(i_mixed_signal_valid)begin
    //else if(rr_mixed_signal_valid)begin
        //index_E[30:0] <= {initial_interp_counter_E};
        //index_E[63:31] <= {initial_index_E};
        //index_P[30:0] <= {initial_interp_counter_P};
        //index_P[63:31] <= {initial_index_P};
        //index_L[30:0] <= {initial_interp_counter_L};
        //index_L[63:31] <= {initial_index_L};
        //index_cpx_idx[30:0] <= {initial_interp_counter_cp_idx};
        //index_cpx_idx[63:31] <= {initial_index_cp_idx};
        ca_bits[0] <= ca_codes[ local_code_chip_index_e_];// Early 
        ca_bits[1] <= ca_codes[ local_code_chip_index_p_];// Prompt
        ca_bits[2] <= ca_codes[ local_code_chip_index_l_];// Late
        counter <= counter +1;

        local_code_chip_index_E <= (i_code_phase_step_chips) * n_ + index_E;// Early 
        local_code_chip_index_P <= (i_code_phase_step_chips) * n_ + index_P;// Prompt
        local_code_chip_index_L <= (i_code_phase_step_chips) * n_ + index_L;// Late
        
	    //local_code_chip_index_E <= sum_E;// Early 
        //local_code_chip_index_P <= sum_P;// Prompt
        //local_code_chip_index_L <= sum_L;// Late
       

        local_code_chip_index_e_ <=  local_code_chip_index_E[DSIZE*2:DSIZE-1] % CODE_LENGTH;
        local_code_chip_index_p_ <=  local_code_chip_index_P[DSIZE*2:DSIZE-1] % CODE_LENGTH;
        local_code_chip_index_l_ <=  local_code_chip_index_L[DSIZE*2:DSIZE-1] % CODE_LENGTH;
        
        /*if (local_code_chip_index_E[43:31] >= 'd1023)begin
           // local_code_chip_index_e_ <= 0;
             local_code_chip_index_e_ <= local_code_chip_index_E[43:31] - 'd1023;
            end
        else
            local_code_chip_index_e_ <= local_code_chip_index_E[40:31];
        if (local_code_chip_index_P[43:31] >= 'd1023)
            local_code_chip_index_p_<=  local_code_chip_index_P[43:31] - 'd1023;
        else

*/
    end
    //else if(!i_go)begin
    else if(i_clear)begin
        counter <= 1;
    end
    
    /*if(counter == 'd1022)begin
        ca_counter <= ca_counter + 1;
        counter <= 0;
    end*/
end

genvar i;
generate
for(i=0; i<NUM_ACCUM; i = i+1)begin

    track_accumulator_0 
    accum_i_inst
    (
        .i_clk(axis_aclk),
        //.i_rstn(axis_aresetn && !i_clear_accum),
        //.i_rstn(axis_aresetn && !i_clear_accum),
        //.i_rstn(axis_aresetn && !(st_curr == ST_PROCESSING3 && !ready ) && !(st_curr == ST_IDLE3)),
        .i_rstn(i_clear_accum),
        .i_en(i_mixed_signal_valid),
        //.i_baseband(mixed_signal[INPUT_WIDTH/2 -1:0]),
        .i_baseband(i_mixed_signal_data[DSIZE-1:DSIZE/2]),
        //.i_baseband(mixed_signal[INPUT_WIDTH*2-1:INPUT_WIDTH]),
        .i_ca_bit(ca_bits[i]),
        .o_accumulator(accum_i[i])



    );

      // Quadrature
      track_accumulator_0
      accum_q_inst
      (
          .i_clk(axis_aclk),
          //.i_rstn(axis_aresetn && !i_clear_accum),
          .i_rstn(i_clear_accum),
          //.i_rstn(axis_aresetn && !(st_curr == ST_PROCESSING3 && !ready ) && !(st_curr == ST_IDLE3 )),
          .i_en(i_mixed_signal_valid),
          .i_baseband(i_mixed_signal_data[DSIZE/2 -1:0]),
          //.i_baseband(mixed_signal[INPUT_WIDTH-1:0]),
          //.i_baseband(mixed_signal[INPUT_WIDTH-1:INPUT_WIDTH/2]),
          .i_ca_bit(ca_bits[i]),
          .o_accumulator(accum_q[i])
      );
  end
  endgenerate

 assign o_iE = accum_i[0];
 assign o_iP = accum_i[1];
 assign o_iL = accum_i[2];
 assign o_qE = accum_q[0];
 assign o_qP = accum_q[1];
 assign o_qL = accum_q[2];

endmodule
