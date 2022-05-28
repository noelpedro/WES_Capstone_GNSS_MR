`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2022 01:50:30 AM
// Design Name: 
// Module Name: acquisition_axis
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


module acquisition_axis#(parameter DATA_WIDTH=8,
    parameter FFT_LENGTH_LOG2 = 15,
    parameter FFT_LENGTH_TOTAL = 32768)(
    
    input wire axis_aclk,                              // processign clock 200MHz
    input wire axis_aresetn,                           // active high reset
    input wire acq_launch,                             // launch/start/go
    input wire acq_launch_valid,                       // valid launch/start/go, high for one clock cycle. 
    input wire [DATA_WIDTH*2 -1:0] l1_data_in,         // L1 Data, e1
    input wire [DATA_WIDTH*2-1:0] l5_data_in,          // L5 Data, e5a
    input wire l1_data_valid,                             // L1 data valid
    input wire l5_data_valid,                             // L5 data valid
    input wire [DATA_WIDTH*4-1:0]select_queue,         // select queue 0 for L1 / e1, 1 for L5 e5a
    input wire [DATA_WIDTH*4-1:0] vector_length,       // fft total length
    input wire [DATA_WIDTH*4-1:0] nsamples,            // number of raw dat samples needed (usually code lengths worth of samples)
    input wire [DATA_WIDTH*4-1:0] vector_length_log2,  // fft total length log2
    input wire [DATA_WIDTH*4-1:0] exclude_limit,       // eclude the limit near the highest peak
    input wire [DATA_WIDTH*4-1:0] doppler_min,         // doppler minimum 1_31
    input wire [DATA_WIDTH*4-1:0] doppler_step,        // doppler step 1_31
    input wire [DATA_WIDTH*4-1:0] num_sweeps,          // number of sweeps or bins (loop max)
    input wire [DATA_WIDTH*4-1:0] total_block_exp,     // total block exp
    input wire [DATA_WIDTH*4-1:0] clear_local_prn_mem, // clear locla prn mem, used to reset addr of fft gnss look up table
    input wire [DATA_WIDTH*4-1:0] fft_prn_code,        // fft gnss data loads LUT in hardware
    input wire clear_local_prn_mem_valid,              // valid signal for clearing prn mem (high for one clock cycle)
    input wire fft_prn_code_valid,                     // valid signal for ggt gnss that loads the LUT (high for one clock cycle)
    input wire stop_acquisition,                       // stops the acquisition, really unecessary
    input wire results_read,                           // signal that arm processor has read results (high for one clock cycle)
    

    output wire [DATA_WIDTH*4-1:0] o_first_peak,         // first peak (highest peak)
    output wire [DATA_WIDTH*4-1:0] o_second_peak,        // second peak of the same frequency bin of the highest peak outside of the exlude limit
    output wire [DATA_WIDTH*4-1:0] o_max_index,          // index of the max peak ( becomes codephase or delay samples)
    output wire [DATA_WIDTH*4-1:0] o_doppler_index,      // frequency bin index of the higest beak, becomes doppler
    output wire [DATA_WIDTH*4-1:0] o_total_block_exp,    // output of the FFT- IFFT block exp see XFFT 9.1 doc for more details
    output wire [DATA_WIDTH*4-1:0] o_sample_counter_lsw, // LSW of number of samples counted snce launching acquisition, dosent reset until CPU quits app
    output wire [DATA_WIDTH*4-1:0] o_sample_counter_msw, // MSW '' ''
    output wire o_acq_done,                              // done for this PRN we have reached the number of sweeps or bins.
    output reg start_acq                                 // signal to notify other IPs that acquisition has begun
    );
    
localparam ST_IDLE = 4'b0000;        /* IDLE waiting for arm to launch */
localparam ST_RECORDING = 4'b0001;   /* storing data to bram */
localparam ST_PROCESSING  = 4'b0010; /* launch processing */
localparam ST_PROCESSING2 = 4'b0011; /* Wait for FFT to complete */
localparam ST_PROCESSING3 = 4'b0100; /* wait for IFFT to complete */
localparam ST_SECOND_PEAK = 4'b0101; /* wait for second peak to complete */
localparam ST_UPDATE_BIN = 4'b0110;  /* update the bin counter */
localparam ST_ACQ_DONE = 4'b0111;    /* ACQ is done */  
localparam ST_WAIT = 4'b1000;        /* wait for results to be reasy and go back to IDLE */
localparam ST_WAIT2= 4'b1001;
localparam ST_WAIT3= 4'b1011;
localparam ST_WAIT4= 4'b1111;

localparam ST_FFT_IDLE0 = 3'b0000;      /* FFT IDLE */
localparam ST_FFT_IDLE00 = 3'b0001;     /* FFT IDLE FFT valid is high */ 
localparam ST_FFT_IDLE000 = 3'b0010;    /* FFT IDLE, FFT valid is high */
localparam ST_FFT_IDLE01 = 3'b011;      /* FFT IDLE, FFT valid high    */
localparam ST_FFT = 3'b0100;            /* FFT in progress wait for event frame started signal */
localparam ST_FFT_IDLE1 = 3'b0101;      /* FFT IDLE config valid for IFFT */ 
localparam ST_IFFT = 3'b110;            /* IFFT in progress wait for event  frame started signal */
localparam ST_FFT_IDLE2 = 3'b111;       /* FFT IDLE config valid for next FFT*/



reg [3:0] st_curr;
reg [3:0] st_next; 
reg [2:0] st_fft_curr;
reg [2:0] st_fft_next;

wire xfft_data_out_tvalid;
wire [DATA_WIDTH*4-1:0] xfft_data_out_tdata;
wire [DATA_WIDTH*2-1:0] input_data;
wire input_valid;
reg [FFT_LENGTH_LOG2:0] xfft_cntr;

wire xfft_config_tready;
reg [DATA_WIDTH*4-1:0] r_bin_counter;
wire [DATA_WIDTH*4-1:0] bin_counter;//
wire event_frame_started;

reg st_xfft_curr;
reg  st_xfft_next;
wire xfft_data_tready;
localparam ST_XFFT_FWD = 1'b1;
localparam ST_XFFT_INV = 1'b0;
wire reset;
assign reset = ~(st_curr == ST_IDLE) & ~axis_aresetn;



reg [DATA_WIDTH*4-1:0] fft_gnss_code_mem [FFT_LENGTH_TOTAL-1:0];

wire xfft_data_in_tvalid;
wire [DATA_WIDTH*4-1:0] xfft_data_in_tdata;


reg raw_signal_ready;
wire [DATA_WIDTH*4-1:0] phase_count;
wire [DATA_WIDTH*2 -1:0] sincos_data;
wire sincos_valid;
reg carr_mix;
reg data_To_FFT;

reg [FFT_LENGTH_LOG2-1:0] fft_dout_cntr;
reg [DATA_WIDTH*4-1:0] fft_gnss_code_adr;
wire xfft_data_out_tlast;
wire second_peak_done;

assign bin_counter = r_bin_counter;

reg [1:0] st_xfft_last_curr;
reg [1:0] st_xfft_last_next;
wire xfft_data_in_tlast;
always @(posedge axis_aclk)begin
        if(axis_aresetn == 1'b1 || st_curr == ST_IDLE)
                st_xfft_last_curr <= 0;
        else
                st_xfft_last_curr <= st_xfft_last_next;
end

always @(*)begin
        case(st_xfft_last_curr)
                2'b00:begin // waiting for arm to launch //0
                        if (xfft_cntr == vector_length-1)
                                st_xfft_last_next = 2'b01;
                        else
                                st_xfft_last_next = 2'b00;
                end
                2'b01:begin
                    st_xfft_last_next = 2'b10;
                end
                2'b10:begin
                    if (st_curr == ST_PROCESSING3)
                        st_xfft_last_next = 2'b00;
                    else
                        st_xfft_last_next = 2'b10;
                end
                default:
                        st_xfft_last_next = 2'b00;
        endcase
end


always @(posedge axis_aclk)begin
        if(axis_aresetn == 1'b1 || st_curr == ST_IDLE)
                st_xfft_curr <= ST_XFFT_FWD;
        else
                st_xfft_curr <= st_xfft_next;
end

always @(*)begin
        case(st_xfft_curr)
                ST_XFFT_FWD:begin // waiting for arm to launch //0
                        if (xfft_data_out_tlast)
                                st_xfft_next = ST_XFFT_INV;
                        else
                                st_xfft_next = ST_XFFT_FWD;
                end
                ST_XFFT_INV:begin
                    if (xfft_data_out_tlast)
                        st_xfft_next = ST_XFFT_FWD;
                    else
                        st_xfft_next = ST_XFFT_INV;
                end
                default:
                        st_xfft_next = ST_XFFT_FWD;
        endcase
end













always @(posedge axis_aclk)begin
        if(axis_aresetn == 1'b1 || results_read == 1'b1)
                st_curr <= ST_IDLE;
        else
                st_curr <= st_next;
end

always @(posedge axis_aclk)begin
        if(axis_aresetn == 1'b1 || st_curr == ST_IDLE)
                st_fft_curr <= ST_FFT_IDLE0;
        else
                st_fft_curr <= st_fft_next;
end

always @(*)begin
        case(st_fft_curr)
                ST_FFT_IDLE0:begin // waiting for arm to launch //0
                        if (st_curr == 1)
                                st_fft_next = ST_FFT_IDLE00;
                        else
                                st_fft_next = ST_FFT_IDLE0;
                end
                     ST_FFT_IDLE00:begin               
                    st_fft_next = ST_FFT_IDLE000;
                end
                     ST_FFT_IDLE000:begin               
                    st_fft_next = ST_FFT_IDLE01;
                end
                
                ST_FFT_IDLE01:begin               
                    st_fft_next = ST_FFT;
                end
                ST_FFT:begin
                    if (event_frame_started)
                        st_fft_next = ST_FFT_IDLE1;
                    else
                        st_fft_next = ST_FFT;
                end
                 ST_FFT_IDLE1:begin               
                    st_fft_next = ST_IFFT;
                end
                ST_IFFT:begin
                    if(event_frame_started)
                       st_fft_next = ST_FFT_IDLE2;
                    else
                        st_fft_next = ST_IFFT;
                end
                ST_FFT_IDLE2:begin
                    st_fft_next = ST_FFT;
                end
                default:
                        st_fft_next = ST_FFT_IDLE0;
        endcase
end
/* Latch the correct Data depending on what the user writes to select queue */



   
assign input_data = (select_queue == 32'd1) ? l5_data_in: l1_data_in;
assign input_valid = (select_queue == 32'd1) ? l5_data_valid:l1_data_valid;


wire acq_done;   
always @(*)begin
        case(st_curr)
                ST_IDLE:begin // waiting for arm to launch //0
                        if (acq_launch && acq_launch_valid)
                                st_next = ST_RECORDING;
                        else
                                st_next = ST_IDLE;
                end
                ST_RECORDING:begin //record samples //1
                        if (raw_signal_ready)
                                st_next = ST_PROCESSING;
                        else
                                st_next = ST_RECORDING;

                end
                ST_PROCESSING:begin // doppler sweep //2
                        if (phase_count == (nsamples-1)) //20 for cordic delay
                                st_next = ST_PROCESSING2;
                        else
                                st_next = ST_PROCESSING;
                end
                ST_PROCESSING2:begin // zero pad for FFT //3
                        if (xfft_data_out_tlast)
                                st_next = ST_PROCESSING3;
                        else
                                st_next = ST_PROCESSING2;
                end
                ST_PROCESSING3:begin // zero pad for FFT //4
                        if (xfft_data_out_tlast)
                                st_next = ST_SECOND_PEAK;
                        else
                                st_next = ST_PROCESSING3;
                end
                ST_SECOND_PEAK:begin
                        if (second_peak_done)
                                st_next = ST_UPDATE_BIN;
                        else
                                st_next = ST_SECOND_PEAK;
                end
                ST_UPDATE_BIN:begin
                        if (bin_counter < num_sweeps-1)
                                st_next = ST_PROCESSING;
                        else
                                st_next = ST_ACQ_DONE;
                end
                ST_ACQ_DONE:begin
                        if (acq_done)
                                st_next = ST_WAIT;
                        else
                                st_next = ST_ACQ_DONE;
                end
                ST_WAIT:begin
                        if (results_read)
                                st_next = ST_IDLE;
                        else
                                st_next = ST_WAIT;
                end
                default:
                        st_next = ST_IDLE;
        endcase
end

reg o_acq_done_;
always @(*)begin

        if(st_curr == ST_IDLE) begin
                start_acq = 1'b0;
                carr_mix = 1'b0;
                data_To_FFT = 1'b0;
                o_acq_done_ = 1'b0;
        end
        else if (st_curr == ST_RECORDING)begin
                start_acq =1'b1;
                carr_mix = 1'b0;
                data_To_FFT = 1'b0;
                o_acq_done_ = 1'b0;
        end
        else if (st_curr == ST_PROCESSING) begin
                carr_mix = 1'b1;
                start_acq = 1'b0;
                data_To_FFT = 1'b1;
                o_acq_done_ = 1'b0;
        end
        else if (st_curr == ST_PROCESSING2) begin
                carr_mix = 1'b0;
                start_acq = 1'b0;
                data_To_FFT = 1'b1;
                o_acq_done_ = 1'b0;
        end
        else if (st_curr == ST_PROCESSING3) begin
                carr_mix = 1'b0;
                start_acq = 1'b0;
                data_To_FFT = 1'b1;
                o_acq_done_ = 1'b0;
        end
        else if (st_curr == ST_WAIT)begin
                o_acq_done_ = 1'b1;
                carr_mix = 1'b0;
                start_acq = 1'b0;
        data_To_FFT = 1'b0;
        end

end

//wire [11:0] fifo_data_count;
wire raw_data_valid;
wire raw_data_last;
wire [DATA_WIDTH*2 -1:0] raw_data;
reg [8:0] cordic_dly;
always @(posedge axis_aclk)begin

    cordic_dly <= {carr_mix,cordic_dly[8:1]};

end

//assign raw_signal_ready = (fifo_data_count >= nsamples) ? 1:0;

/*
acq_fifo_generator_0 acq_fifo_generator_0_inst
(
    .clk(axis_aclk),
    .wr_en(input_valid & start_acq),
    .din(input_data),
    .dout(raw_data),
    .rd_en(cordic_dly[0]),
    .valid(raw_data_valid),
    .data_count(fifo_data_count)
    


);
*/
reg stop_irq;
always@(posedge axis_aclk)begin
    if (stop_acquisition == 1'b1)
        stop_irq <= 1'b1;
    if(st_curr == ST_IDLE)
        stop_irq <= 1'b0;

end

localparam IDLE = 2'b00, FILL = 2'b01, WAIT = 2'b11;
reg bram_ena;
reg bram_wea;
reg [FFT_LENGTH_LOG2-1:0] bram_natural_adr;
reg [DATA_WIDTH*2-1:0] bram_din;

reg [1:0] state;
wire[FFT_LENGTH_LOG2-1:0] bram_adr;

/* RECORD RAW DATA samples to buffer */

always @(posedge axis_aclk) begin
    if(st_curr == ST_IDLE)begin
        bram_ena <= 1'b0;
        bram_wea <= 1'b0;
        bram_natural_adr <= 'd0;
        bram_din <= 'd0;
        raw_signal_ready <= 1'b0;
        state <= IDLE;
    end else begin
        case(state)
            IDLE:begin
                bram_natural_adr <= 'd0;
                if(start_acq && input_valid)
                    raw_signal_ready <= 1'b0;
                else
                    raw_signal_ready <= raw_signal_ready;

                //if(toBram_tvalid && bram_store)begin
                if(start_acq && input_valid)begin
                    bram_din <= input_data;
                    bram_ena <= 1'b1;
                    bram_wea <= 1'b1;
                    state <= FILL;
                    //fe_corr_ready <= 1'b0;
                end else begin
                    bram_din <= 'd0;
                    bram_ena <= 1'b0;
                    bram_wea <= 1'b0;
                    //fe_corr_ready <= fe_corr_ready;
                    state <= IDLE;
                end
            end

            FILL:begin
                raw_signal_ready <= 1'b0;
                if(start_acq && input_valid)begin
                    bram_din <= input_data;
                    bram_ena <= 1'b1;
                    bram_wea <= 1'b1;
                    bram_natural_adr <= bram_natural_adr + 1;
          if(bram_natural_adr == nsamples)
                        state <= WAIT;
                end else begin
                    state <= FILL;
                end
            end
            WAIT:begin
                bram_ena <= 1'b0;
                bram_wea <= 1'b0;
                bram_natural_adr <= 'd0;
                bram_din <= 'd0;
                state <= WAIT; // wait for reset or enable to go low
                raw_signal_ready <= 1'b1;
                //state <= WAIT;
      end
        endcase
    end
end



assign bram_adr = bram_natural_adr;

reg [FFT_LENGTH_LOG2-1:0] rd_ptr = {(FFT_LENGTH_LOG2){1'b0}};
reg [FFT_LENGTH_LOG2-1:0] rd_ptr_next;
reg [FFT_LENGTH_LOG2-1:0] rd_addr = {(FFT_LENGTH_LOG2){1'b0}};

reg re;
reg mem_read_data_valid = 1'b0;
reg r_mem_read_data_valid;
reg mem_read_data_valid_next;
reg m_axis_tvalid_next;
reg r_m_axis_tvalid;

reg [DATA_WIDTH*2-1:0] r_m_data;
reg [3:0] r_m_tlast;

wire [DATA_WIDTH*2-1:0] ram_data_out;

raw_signal_bram raw_signal_bram_inst(
  // Port A Data In
  .clka(axis_aclk),    // input wire clka
  .ena(bram_ena),      // input wire ena
  .wea(bram_wea),      // input wire [0 : 0] wea
  .addra(bram_adr),  // input wire [14 : 0] bram_adr
  .dina(bram_din),    // input wire [47 : 0] dina
  //.douta(),  // output wire [47 : 0] douta
  // Port B Data Out
  .clkb(axis_aclk),    // input wire clkb
  .enb(re),      // input wire enb
  //.web(),      // input wire [0 : 0] web
  .addrb(rd_addr),  // input wire [14 : 0] addrb
  //.dinb(),    // input wire [47 : 0] dinb
  .doutb(ram_data_out)  // output wire [47 : 0] doutb
);


reg play_recorded;
always @(posedge axis_aclk)begin
    if(st_curr == ST_IDLE)begin
     //if(!m_axis_aresetn)begin
        play_recorded <= 1'b0;
        re <= 1'b0;
    end else if(cordic_dly[0])begin
        play_recorded <= 1'b1;
        re <= 1'b1;
    end else if (r_m_tlast[1])begin
        play_recorded <= 1'b0;
        re <= 1'b0;
    end else begin
        play_recorded <= play_recorded;
        re <= re;
    end
end





// Read Logic
always @* begin
    mem_read_data_valid_next = mem_read_data_valid;

    // output data not valid OR currently being transferred  
    if (play_recorded ) begin  // cannot read until FFT done due to Bit Reversal
        // not empty, perform read 
        if (|r_m_tlast[3:1])
                mem_read_data_valid_next = 1'b0;
        else
                mem_read_data_valid_next = 1'b1;
        rd_ptr_next = rd_ptr + 1;

    end else begin
        // empty, invalidate  
        rd_ptr_next = 0;
        mem_read_data_valid_next = 1'b0;

    end

end


always @(posedge axis_aclk) begin
    if (st_curr == ST_IDLE) begin
    //if (!s_axis_aresetn) begin
        rd_ptr <= {(FFT_LENGTH_LOG2){1'b0}};
        mem_read_data_valid <= 1'b0;
        r_mem_read_data_valid <= 1'b0;
        r_m_tlast <= 0;
    end else begin
        rd_ptr <= rd_ptr_next;
        mem_read_data_valid <= mem_read_data_valid_next;
        r_mem_read_data_valid <= mem_read_data_valid;
        if(rd_ptr_next >= (nsamples) )begin
            r_m_tlast <= {r_m_tlast[2:0],1'b1};
        end else begin
            r_m_tlast <= {r_m_tlast[2:0],1'b0};
        end
    end
    rd_addr <= rd_ptr_next;
end

// Output register  
always @* begin
    m_axis_tvalid_next = r_m_axis_tvalid;

    if ( ~r_m_axis_tvalid) begin
        m_axis_tvalid_next = r_mem_read_data_valid;
    end
end

always @(posedge axis_aclk) begin
    if (st_curr == ST_IDLE) begin
        r_m_axis_tvalid <= 1'b0;
    end else begin
        r_m_axis_tvalid <= m_axis_tvalid_next;
    end
    r_m_data <= ram_data_out;
end



assign raw_data_valid = r_m_axis_tvalid;
assign raw_data  = r_m_data;
assign raw_data_last  = r_m_tlast[3];





always@(posedge axis_aclk)begin
        if (st_curr == ST_IDLE)begin
                r_bin_counter <= 0;
        end else if (st_curr == ST_UPDATE_BIN)
                r_bin_counter <= r_bin_counter + 1;
end

assign bin_counter = r_bin_counter;


carrier_wipeoff_0 carrier_wipeoff_0_inst(
    .axis_aclk(axis_aclk),
    .axis_aresetn(st_curr == ST_IDLE),
    .doppler_step(doppler_step),
    .doppler_min(doppler_min),
    .bin_counter(bin_counter),
    .enable(carr_mix),
    
    .o_phase_count(phase_count),
    .sincos_output(sincos_data),
    .sincos_valid(sincos_valid)

);


always@(posedge axis_aclk)begin
        if((clear_local_prn_mem_valid == 1'b1) && (clear_local_prn_mem == 32'h10000000))begin
                fft_gnss_code_adr <= 0;
        end
        else if (fft_prn_code_valid && fft_gnss_code_adr < vector_length) begin
                fft_gnss_code_mem[fft_gnss_code_adr] <= fft_prn_code;
                fft_gnss_code_adr <= fft_gnss_code_adr + 1;

        end
end

wire cmpy_tvalid;
wire [DATA_WIDTH*4-1:0] cmpy_tdata;
wire switch_position;
assign switch_position = (st_fft_next == ST_FFT_IDLE0 || st_fft_next == ST_FFT_IDLE01 || 
st_fft_next == ST_FFT_IDLE2 || st_fft_next == ST_FFT_IDLE00 || st_fft_next == ST_FFT_IDLE000)? 1:0;
cmpy_doppler_sweep inst_cmpy_mult(

        .aclk(axis_aclk),
        .s_axis_a_tvalid(sincos_valid),
        .s_axis_a_tdata(sincos_data),

        .s_axis_b_tvalid(sincos_valid),
        .s_axis_b_tdata(raw_data),

        .s_axis_ctrl_tdata(8'b00000000),
        .s_axis_ctrl_tvalid(1'b1),

        .m_axis_dout_tvalid(cmpy_tvalid),
        .m_axis_dout_tdata(cmpy_tdata)
);


reg xfft_valid;
wire xfft_last;
reg [DATA_WIDTH*4 -1 :0] xfft_data;
assign xfft_last = (st_xfft_last_curr == 2'b01) ? 1:0;

/* zero padd the fft input data */
always @(posedge axis_aclk)begin
    if(st_curr != ST_PROCESSING  && st_curr != ST_PROCESSING2)begin
        xfft_valid <= 1'b0;
                xfft_cntr <= 0;
                xfft_data <= 0;
    end
    else begin
        if (cmpy_tvalid && xfft_cntr < (nsamples) )begin
                xfft_data <= cmpy_tdata;
                xfft_cntr <= xfft_cntr + 1;
                xfft_valid <= 1'b1;
        end
        else if (xfft_cntr >= (nsamples) && xfft_cntr < vector_length)begin
                xfft_data <= 0;
                xfft_cntr <= xfft_cntr + 1;
                xfft_valid <= 1'b1;
                end
    else
        xfft_valid <= 1'b0;

        end
end



reg [DATA_WIDTH*4 -1 :0] r_fft_gnss_code_data;

always @(posedge axis_aclk)begin
        if( xfft_data_out_tvalid && (st_xfft_curr == ST_XFFT_FWD))begin
                 fft_dout_cntr <= fft_dout_cntr + 1;
                 r_fft_gnss_code_data <= fft_gnss_code_mem[fft_dout_cntr + 1];
         end  else begin
                 fft_dout_cntr <= 0;
                 r_fft_gnss_code_data <= fft_gnss_code_mem[fft_dout_cntr];
        end
end

wire [DATA_WIDTH*4 -1 :0] fft_gnss_data;
assign fft_gnss_data = r_fft_gnss_code_data;
wire cmpy2_tvalid;
wire cmpy2_tlast;
wire [DATA_WIDTH*4-1:0] cmpy2_tdata;



cmpy_fft inst_cmpy_mult2(

        .aclk(axis_aclk),
        .s_axis_a_tvalid(xfft_data_out_tvalid && (st_xfft_curr == ST_XFFT_FWD)),
        .s_axis_a_tdata(xfft_data_out_tdata),
        .s_axis_a_tlast(xfft_data_out_tlast),
        
        .s_axis_b_tvalid(xfft_data_out_tvalid && (st_xfft_curr == ST_XFFT_FWD)),
        .s_axis_b_tdata(fft_gnss_data),
        .s_axis_b_tlast(xfft_data_out_tlast),

        .s_axis_ctrl_tdata(8'b00000000),
        .s_axis_ctrl_tvalid(1'b1),
        
        .m_axis_dout_tlast(cmpy2_tlast),
        .m_axis_dout_tvalid(cmpy2_tvalid),
        .m_axis_dout_tdata(cmpy2_tdata)
);





assign xfft_data_in_tvalid = xfft_valid ? xfft_valid:cmpy2_tvalid;
assign xfft_data_in_tdata = xfft_valid ? xfft_data:cmpy2_tdata;
assign xfft_data_in_tlast = xfft_last ? xfft_last:cmpy2_tlast;
wire [DATA_WIDTH*2 -1:0] config_xfft_data;
wire config_xfft_valid;

assign config_xfft_valid = (st_fft_next == ST_FFT_IDLE01 || st_fft_next == ST_FFT_IDLE1 || st_fft_next == ST_FFT_IDLE2
 || st_fft_next == ST_FFT_IDLE00 || st_fft_next == ST_FFT_IDLE000) ? 1:0;
assign config_xfft_data = {7'b0000000,switch_position,3'b000,vector_length_log2[4:0]};
wire [4:0] xfft_status;
wire [23:0] xfft_tuser;
xfft xfft_inst2 (
   .aclk(axis_aclk),                          // input wire aclk
    .aresetn(!(st_next == ST_IDLE)),
   //.aresetn(bram_reset),                    // input wire aresetn
   // Config
   .s_axis_config_tdata(config_xfft_data),         // input wire [15 : 0] s_axis_config_tdata (do Forward FFT)
   .s_axis_config_tvalid(config_xfft_valid),               // input wire s_axis_config_tvalid
   .s_axis_config_tready(xfft_config_tready),                   // output wire s_axis_config_tready
   // Input From ADC
   .s_axis_data_tdata(xfft_data_in_tdata), // input wire [63 : 0] s_axis_data_tdata
   .s_axis_data_tvalid(xfft_data_in_tvalid), // input wire s_axis_data_tvalid
   .s_axis_data_tready(xfft_data_tready), // output wire s_axis_data_tready
   .s_axis_data_tlast(xfft_data_in_tlast), // input wire s_axis_data_tlast
   // Input From PRN Generator
   .m_axis_status_tdata(xfft_status),
   .m_axis_status_tready(1'b1),
   .m_axis_data_tdata(  xfft_data_out_tdata), //fft_cmpy_tdata),      // output wire [63 : 0] m_axis_data_tdata
   .m_axis_data_tvalid( xfft_data_out_tvalid ), //fft_cmpy_tvalid),     // output wire m_axis_data_tvalid
   .m_axis_data_tready( 1'b1          ), // input wire m_axis_data_tready
   .m_axis_data_tlast( xfft_data_out_tlast  ), // output wire m_axis_data_tlast
   .m_axis_data_tuser(xfft_tuser),
   // Debug Signals
   .event_frame_started(event_frame_started),
   .event_tlast_unexpected(),
   .event_tlast_missing(),
   .event_status_channel_halt(),
   .event_data_in_channel_halt(),
   .event_data_out_channel_halt()
 );
wire [DATA_WIDTH*2 -1:0] xfft_index;
assign xfft_index = xfft_tuser[15:0];
assign o_total_block_exp = xfft_status;

wire xfft_tvalid1;

assign xfft_tvalid1 = (xfft_data_out_tvalid && (xfft_index >= vector_length - nsamples) && (st_xfft_curr == ST_XFFT_INV)) ? xfft_data_out_tvalid : 0;
wire [DATA_WIDTH * 2-1:0] max_peak;
wire [FFT_LENGTH_LOG2-1:0] max_index;
wire max_index_done;

mag_squared_0 //#(.DSIZE(DATA_WIDTH*4),
               //.DSIZE_DIV2(DATA_WIDTH*2),
               //.FFT_LENGTH_LOG2(FFT_LENGTH_LOG2)
              // )
               mag_squared_inst(
        .s00_axis_tdata(xfft_data_out_tdata),
        .s00_axis_tlast(xfft_data_out_tlast ),
        .s00_axis_tvalid(xfft_tvalid1),
        .s00_axis_aresetn((st_curr == ST_IDLE)),
        .s00_axis_aclk(axis_aclk),
        .i_index(xfft_index),

        .o_max(max_peak),
        .o_max_index(max_index),
        .o_done(max_index_done)


);


wire second_peak_valid;
wire second_peak_last;
wire [DATA_WIDTH*4 - 1:0] second_peak_data;
wire [DATA_WIDTH*4 -1:0] second_peak;

/* get second  peak of data */
second_peak_detector_0 //#(.DSIZE(DSIZE *2),
                        //.DSIZE_DIV2(DSIZE),
                        //.FFT_LENGTH_LOG2(FFT_LENGTH_LOG2)) second_peak_detector_inst(
        (.s_axis_tdata(xfft_data_out_tdata),
        .s_axis_tvalid(xfft_tvalid1),
        .i_index(xfft_index),
        .i_first_peak_index(max_index),
        .s_axis_aclk(axis_aclk),
        .s_axis_aresetn((st_curr == ST_IDLE)),
        .s_axis_tlast(xfft_data_out_tlast),
        .exclude_limit(exclude_limit),
        .fft_length_total(vector_length),


        .o_vld(second_peak_valid),
        .o_lst(second_peak_last),
        .ifft_data(second_peak_data)

);


mag_squared_1 //#(//.DSIZE(DATA_WIDTH *2),
               //.DSIZE_DIV2(DATA_WIDTH),
               //.FFT_LENGTH_LOG2(FFT_LENGTH_LOG2))
                mag_squared_int2(
        .s00_axis_tdata(second_peak_data),
        .s00_axis_tlast(second_peak_last),
        .s00_axis_tvalid(second_peak_valid),
        .s00_axis_aresetn((st_curr == ST_IDLE) || (st_curr == ST_PROCESSING)),
        .s00_axis_aclk(axis_aclk),
        .i_index(), // dont really care about index of second peak, can check to debug

        .o_max(second_peak),
        .o_done(second_peak_done)
);

maximum_index_0//#(
    //.DSIZE(DATA_WIDTH*2),
    //.FFT_LENGTH_LOG2(FFT_LENGTH_LOG2),
    //.ROW_SIZE(16)) 
    maximum_index_inst(
        .i_first_peak_done(max_index_done),
        .i_second_peak(second_peak),
        .i_second_peak_done(second_peak_done),
        .i_first_peak(max_peak),
        .i_code_phase(max_index),
        .axis_aclk(axis_aclk),
        .axis_aresetn((st_curr == ST_IDLE)),
        .bin(bin_counter),
        .i_nbins(num_sweeps),

        .first_peak(o_first_peak),
        .second_peak(o_second_peak),
        .code_phase(o_max_index),
        .doppler_index(o_doppler_index),
        .o_done(acq_done)




);
wire [(DATA_WIDTH * 8) - 1:0] l1_count;
wire [(DATA_WIDTH * 8) - 1:0] l5_count;
sample_counter_acq_0 sample_counter_acq_inst(



    .axis_aclk(axis_aclk),
    .axis_aresetn(axis_aresetn),
    //.i_rstn(reset),
    .i_start(start_acq),
    .i_vld(l1_data_valid),

    .o_vld(),
    .o_count(l1_count)



);


sample_counter_acq_1 sample_counter_acq_inst2(



    .axis_aclk(axis_aclk),
    .axis_aresetn(axis_aresetn),
    //.i_rstn(reset),
    .i_start(start_acq),
    .i_vld(l5_data_valid),

    .o_vld(),
    .o_count(l5_count)



);


assign o_sample_counter_lsw = (select_queue == 32'd1) ? l5_count[DATA_WIDTH*4-1:0] : l1_count[DATA_WIDTH*4-1:0];
assign o_sample_counter_msw = (select_queue == 32'd1) ? l5_count[(DATA_WIDTH*8) - 1:DATA_WIDTH*4 ]: l1_count[(DATA_WIDTH*8) - 1:DATA_WIDTH*4 ];


assign o_acq_done = (o_acq_done_ || stop_irq);

endmodule
