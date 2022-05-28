`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2022 09:09:10 PM
// Design Name: 
// Module Name: track_correlator_gps_l1
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


module track_correlator_gps_l1
#(
    parameter INPUT_WIDTH='d32,
    parameter CORDIC_DLY = 12)
(
    input wire axis_aresetn,
    input wire axis_aclk,
    input wire adc_clk,
    input wire adc_aresetn,
    input wire s_axis_data_tvalid,
    input wire [(INPUT_WIDTH * 2)-1:0] i_acq_delay_samples,

    input wire [INPUT_WIDTH/2-1:0] s_axis_data_tdata,
    input wire [INPUT_WIDTH-1:0] i_correlator_length_samples,
    input wire [INPUT_WIDTH-1:0] ca_code_tdata,
    input wire acq_start,
    input wire ca_code_tvalid,
    input wire acq_stop,


    input wire [INPUT_WIDTH-1:0] initial_interp_counter_E,
    input wire [INPUT_WIDTH-1:0] initial_interp_counter_P,
    input wire [INPUT_WIDTH-1:0] initial_interp_counter_L,
    input wire [INPUT_WIDTH-1:0] initial_index_E,
    input wire [INPUT_WIDTH-1:0] initial_index_P,
    input wire [INPUT_WIDTH-1:0] initial_index_L,

    input wire [INPUT_WIDTH-1:0] code_phase_step_chips,
    input wire [INPUT_WIDTH-1:0] code_phase_rate,
   

    input wire [INPUT_WIDTH-1:0] rem_carr_phase_rad,
    input wire [INPUT_WIDTH-1:0] phase_step_rad,
     input wire [INPUT_WIDTH-1:0] phase_step_rate_rad,


    input wire i_go,
    input wire i_drop_samples,
    input wire i_stop_tracking,
    input wire start_tracking_valid,
    input wire drop_samples_valid,

    input wire i_clear_accum,

    input wire stop_tracking_valid,






/*DEBUG */
/*
    output wire [INPUT_WIDTH-1:0] phase_counter,
    output wire [INPUT_WIDTH+1:0] phase_rate,
    output reg [2:0] st_curr,
    output reg [2:0] st_next,
    output wire [INPUT_WIDTH/2-1:0] sincos,
    output wire sincos_valid,
    output reg start_tracking,
    output wire [INPUT_WIDTH-1:0] mixed_signal,
    output wire mixed_signal_valid,
    output wire fifo_valid1,
    output wire [INPUT_WIDTH/2-1:0] fifo_data1,
    output reg [INPUT_WIDTH - 1:0] num_points,
    */
    output wire fifo_almost_full_proc,
 
    output wire [INPUT_WIDTH * 2 - 1:0] o_data_count,
    output wire o_sample_count_vld,

    output wire [INPUT_WIDTH-1:0] o_iE,
    output wire [INPUT_WIDTH-1:0] o_qE,
    output wire [INPUT_WIDTH-1:0] o_iP,
    output wire [INPUT_WIDTH-1:0] o_qP,
    output wire [INPUT_WIDTH-1:0] o_iL,
    output wire [INPUT_WIDTH-1:0] o_qL,

    output wire o_ready



    );
    
 localparam ST_IDLE = 3'b000;//0
 localparam ST_IDLE2 = 3'b001; //1
 localparam ST_IDLE3 = 3'b010; //2
 localparam ST_PROCESSING = 3'b011;//3
 localparam ST_PROCESSING2 = 3'b100;//4
 localparam ST_IDLE4 = 3'b101;//5
 localparam ST_PROCESSING3 = 3'b110;//6
 localparam ST_PROCESSING4 = 3'b111;//7

    
 wire [16:0] fifo_wr_data_count_proc;
 reg [CORDIC_DLY-4:0]shift3;

 reg fifo_almost_full;
 wire fifo_overflow;
 wire [16:0] fifo_wr_data_count;
 //wire fifo_almost_full_proc;  
 reg cordic_valid;
 wire [INPUT_WIDTH/2-1:0] sincos;
 wire sincos_valid;

reg start_tracking;
reg [INPUT_WIDTH - 1:0] num_points;
reg stop_trk;
reg ready;
wire [INPUT_WIDTH-1:0] mixed_signal;
wire mixed_signal_valid;
reg [2:0] st_curr;
reg [2:0] st_next;


wire fifo_valid;
wire [INPUT_WIDTH/2-1:0] fifo_data;

reg drop_samples;
reg r_fifo_valid;
reg rr_fifo_valid;
reg rrr_fifo_valid;
reg [INPUT_WIDTH/2-1:0] r_fifo_data;
reg [INPUT_WIDTH/2-1:0] rr_fifo_data;
reg [INPUT_WIDTH/2-1:0] rrr_fifo_data;


always @(posedge axis_aclk)begin
    r_fifo_valid <= fifo_valid;
    rr_fifo_valid <= r_fifo_valid;
    rrr_fifo_valid <= rr_fifo_valid;
    
    r_fifo_data <= fifo_data;
    rr_fifo_data <= r_fifo_data;
    rrr_fifo_data <= rr_fifo_data;

end
wire fifo_valid1;
wire [INPUT_WIDTH/2-1:0] fifo_data1;

assign fifo_valid1 = rrr_fifo_valid;
assign fifo_data1 = rrr_fifo_data;

fifo_generator_1 fifo_generator_0_inst (
    .din(s_axis_data_tdata),
    .wr_en(s_axis_data_tvalid),
    .wr_clk(adc_clk),
    .wr_data_count(fifo_wr_data_count),
    .overflow(fifo_overflow),
    .rd_clk(axis_aclk),
    //.empty(fifo_empty),
    .dout(fifo_data),
    //.rd_en(drop_samples | (fifo_almost_full_proc & !fifo_almost_full2)| fifo_release),
    .rd_en(drop_samples |fifo_almost_full_proc ),
    .valid(fifo_valid)
    //.prog_full(fifo_almost_full)

);


always@(posedge axis_aclk)begin
    if (fifo_wr_data_count_proc <= 'd32700)
        fifo_almost_full <= 0;
    else if (fifo_wr_data_count_proc > 'd32750)
        fifo_almost_full <= 1;
end

cross_clock_fifo cross_clock_fifo_inst(
    .s_axis_tvalid(1'b1),
    .s_axis_tdata(fifo_wr_data_count),
    .s_axis_aresetn(adc_aresetn),
    .s_axis_aclk(adc_clk),
    .m_axis_aclk(axis_aclk),
    .m_axis_tvalid(),
    .m_axis_tready(1'b1),
    .m_axis_tdata(fifo_wr_data_count_proc)


);
assign fifo_almost_full_proc = fifo_almost_full;
always @(posedge axis_aclk)begin
    shift3 <= {start_tracking,shift3[CORDIC_DLY-4:1]};
end




//reg [INPUT_WIDTH/2 - 1:0] phase_counter;
 always@(posedge axis_aclk)begin
   if(fifo_valid && start_tracking)begin
        num_points <= num_points + 1;
     end
     else if (!start_tracking)
        num_points <= 0;
 end

 
 always@(posedge axis_aclk, negedge axis_aresetn)begin
    if ((axis_aresetn== 1'b1) || (i_stop_tracking && stop_tracking_valid))begin
        stop_trk <= 1'b0;
     end
    else if((acq_stop))begin
        stop_trk <= 1'b1; //
    end
 end

 
 always @(*)begin
    case(st_curr)
    ST_IDLE:begin
    if(i_drop_samples)//0
        st_next = ST_IDLE2;
    else
        st_next = ST_IDLE;
    end
    ST_IDLE2:begin//1
        //if(!i_drop_samples && drop_samples_valid)
        if(!i_drop_samples)
            st_next = ST_IDLE3;
        else
            st_next = ST_IDLE2;

    end
    ST_IDLE3:begin//2
        //if(!i_drop_samples && drop_samples_valid)begin
        //if(i_go && start_tracking_valid) begin
        //if ((i_current_data_count >= i_acq_delay_samples))
        //    st_next = ST_PROCESSING;
        //else
        if(i_go && start_tracking_valid)
            st_next = ST_PROCESSING2;
         else
            st_next = ST_IDLE3;


    end
    ST_PROCESSING:begin//3
       if(num_points >= i_correlator_length_samples)
            st_next = ST_IDLE3;
        else
            st_next = ST_PROCESSING;

    end
    ST_PROCESSING2:begin//4
        //if(num_points >= i_correlator_length_samples)
        //if(!i_drop_samples && drop_samples_valid)
        if(num_points >= i_correlator_length_samples)
            st_next = ST_IDLE4;
        else
            st_next = ST_PROCESSING2;

    end
    ST_IDLE4:begin//5
        //if(!i_drop_samples && drop_samples_valid)
        if (i_clear_accum)
            st_next = ST_PROCESSING3;
        else
            st_next = ST_IDLE4;

    end
    ST_PROCESSING3:begin//6
            if(i_go && start_tracking_valid)
                st_next = ST_PROCESSING4;
            else
                st_next = ST_PROCESSING3;

   end
   ST_PROCESSING4:begin//7
             //if(num_points >= i_correlator_length_samples)
             //if(!i_drop_samples && drop_samples_valid)
             if(num_points >= i_correlator_length_samples)
                    st_next = ST_IDLE4;
                else
                    st_next = ST_PROCESSING4;

            end
    default:
        st_next = ST_IDLE;
    endcase
end
 
 always @(posedge axis_aclk) begin

    //o_prn_enable = 1'b1;
    //prn_next = 1'b0;
    if (st_curr == ST_IDLE)begin
        start_tracking <= 1'b0;
        ready <= 1'b0;
        cordic_valid <=  1'b0;
        drop_samples <= 1'b1;

    end
    else if (st_curr == ST_IDLE2)begin
       //drop_samples <= 1'b1;
       drop_samples <= 1'b1;
       start_tracking <= 1'b0;
       ready <= 1'b0;
       cordic_valid <= 1'b0;




    end else if (st_curr == ST_IDLE3)begin
             //drop_samples <= 1'b1;
             drop_samples <= 1'b0;
             start_tracking <= 1'b0;
             ready <= 1'b0;
             cordic_valid <= 1'b0;




          end
     else if (st_curr == ST_PROCESSING2) begin
       //if(num_points >= i_correlator_length_samples)
        //        drop_samples <= 1'b0;
        //if(num_points >= i_correlator_length_samples)  
         //   ready <= 1'b1;
         //else
            ready <= 1'b0;

        if (o_data_count >= i_acq_delay_samples && !(num_points >= i_correlator_length_samples))begin
            if(shift3[0])
                drop_samples <= 1'b1;
            else //if (!start_tracking) begin
                drop_samples <= 1'b0;

            cordic_valid <= 1'b1;
            start_tracking <= 1'b1;

        end else begin
            start_tracking <= 1'b0;
            cordic_valid <= 1'b0;
            drop_samples <= 1'b1;
        end

       //o_drop_samples = 1'b1;
       //if(skip_initial_samples == sample_count -1)begin

       //if(skip_initial_samples >= sample_count -1 -DDS_DLY-1)
       //end
       //end


    end else if (st_curr == ST_IDLE4)begin
        ready <= 1'b1;
        start_tracking <= 1'b0;
        drop_samples <= 1'b0;
        cordic_valid <= 1'b0;
    end
    else if (st_curr == ST_PROCESSING3)begin
            ready <= 1'b0;
            //irq = 1'b0;
            start_tracking <= 1'b0;
            drop_samples <= 1'b0;
            cordic_valid <= 1'b0;

    end
    else if (st_curr == ST_PROCESSING4) begin
           if(shift3[0] && !(num_points >= i_correlator_length_samples))
            drop_samples <= 1'b1;
           else
            drop_samples <= 1'b0;
           //if(num_points >= i_correlator_length_samples)
           // drop_samples <= 1'b0;

           //if(num_points >= i_correlator_length_samples)
           // ready <= 1'b1;
           //else
           ready <= 1'b0;
           start_tracking <= 1'b1;
           cordic_valid <= 1'b1;


    end
end
always @(posedge axis_aclk)begin
    if(axis_aresetn == 1'b1 || (stop_tracking_valid && i_stop_tracking))//*|| (i_drop_samples && drop_samples_valid)*/)
        st_curr <= ST_IDLE;
    else if(i_drop_samples && drop_samples_valid)
        st_curr <= ST_IDLE2;
    else
        st_curr <= st_next;
 end

Carrier_Wipeoff_trk_0 Carrier_Wipeoff_trk_inst
(
    .i_phase_step_rad(phase_step_rad),
    .i_rem_carr_phase_rad(rem_carr_phase_rad),
    .i_phase_step_rate(phase_step_rate_rad),
    .i_correlator_length_samples(i_correlator_length_samples),
    .i_raw_data_valid(fifo_valid),
    .i_start_tracking(start_tracking),
    .i_delay_ready(shift3[0]),
    .axis_aclk(axis_aclk),
    .i_cordic_valid(cordic_valid),
    
   
    
    .o_sincos(sincos),
    .o_sincos_valid(sincos_valid)



);


 
  mix_raw mix_raw_inst
  (
   .s_axis_a_tdata(fifo_data),
   .s_axis_a_tvalid(fifo_valid && start_tracking),

   .s_axis_b_tdata(sincos ),
   .s_axis_b_tvalid(sincos_valid && start_tracking),

   .aclk(axis_aclk),

   .s_axis_ctrl_tdata(8'b00000000),
   .s_axis_ctrl_tvalid(1'b1),

   .m_axis_dout_tdata(mixed_signal),
   .m_axis_dout_tvalid(mixed_signal_valid)

  );
  
  
  
  Code_Resampler_TRK_0 Code_Resampler_TRK_inst
  (
    .i_ca_code_tdata(ca_code_tdata),
    .i_ca_code_tvalid(ca_code_tvalid),
    .axis_aclk(axis_aclk),
    .i_start_tracking_valid(start_tracking_valid),
    .i_clear_accum((axis_aresetn == 1'b1) || (st_curr == ST_PROCESSING3 && !ready) || (st_curr == ST_IDLE3) ),
    .i_clear(i_clear_accum),
    .i_mixed_signal_valid(mixed_signal_valid),
    .i_mixed_signal_data(mixed_signal),
    .i_initial_index_E(initial_index_E),
    .i_initial_index_P(initial_index_P),
    .i_initial_index_L(initial_index_L),
    .i_initial_interp_counter_E(initial_interp_counter_E),
    .i_initial_interp_counter_P(initial_interp_counter_P),
    .i_initial_interp_counter_L(initial_interp_counter_L),
    .i_code_phase_step_chips(code_phase_step_chips),
    .i_code_phase_step_chips_rate(code_phase_rate),
    
    .o_iE(o_iE),
    .o_qE(o_qE),
    .o_iP(o_iP),
    .o_qP(o_qP),
    .o_iL(o_iL),
    .o_qL(o_qL)
    );
  
  
sample_counter_2 sample_counter_inst2 (

    .axis_aclk(axis_aclk),
    .axis_aresetn(axis_aresetn),
    .i_start(acq_start),
    .i_vld(fifo_valid),
    //.i_vld(count_valid),
    .o_vld(o_sample_count_vld),
    .o_count(o_data_count)


);
assign o_ready = ready | stop_trk;

 
 
endmodule
