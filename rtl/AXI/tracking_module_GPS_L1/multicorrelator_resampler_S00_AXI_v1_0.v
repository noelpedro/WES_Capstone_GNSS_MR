
`timescale 1 ns / 1 ps

	module multicorrelator_resampler_S00_AXI_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 7
	)
	(
		// Users to add ports here
        output wire [C_S00_AXI_DATA_WIDTH-1:0] code_phase_step_chips_num, //0
        output wire [C_S00_AXI_DATA_WIDTH-1:0] initial_index_E, // 1, Early
        output wire [C_S00_AXI_DATA_WIDTH-1:0] initial_index_P, // 3, Prompt 
        output wire [C_S00_AXI_DATA_WIDTH-1:0] initial_index_L, // 4, Late
        output wire [C_S00_AXI_DATA_WIDTH-1:0] initial_interp_counter_E, //7
        output wire [C_S00_AXI_DATA_WIDTH-1:0] initial_interp_counter_P, //8
        output wire [C_S00_AXI_DATA_WIDTH-1:0] initial_interp_counter_L, //9
        output wire [C_S00_AXI_DATA_WIDTH-1:0] nsamples_minus_1, //13
        output wire [C_S00_AXI_DATA_WIDTH-1:0] code_length_minus_1, //14
        output wire [C_S00_AXI_DATA_WIDTH-1:0] rem_carr_phase_rad, //15
        output wire [C_S00_AXI_DATA_WIDTH-1:0] phase_step_rad, //16
        output wire [C_S00_AXI_DATA_WIDTH-1:0] prog_mems, //17
        output wire drop_samples, //18
        output wire [C_S00_AXI_DATA_WIDTH-1:0] initial_counter_value_lsw, //19
        output wire [C_S00_AXI_DATA_WIDTH-1:0] initial_counter_value_msw, //20
        output wire [C_S00_AXI_DATA_WIDTH-1:0] code_phase_step_chips_rate, //21
        output wire [C_S00_AXI_DATA_WIDTH-1:0] phase_step_rate, //22
        output wire                            stop_tracking,//23
        output wire                            start_flag,//30
        output wire irq,
        output wire prog_mem_valid,
        output wire clear_trk_accum,
        output wire start_flag_valid,
        output wire stop_tracking_valid,
        output wire drop_samples_valid,
        
        input wire [C_S00_AXI_DATA_WIDTH-1:0] i_iE,
        input wire [C_S00_AXI_DATA_WIDTH-1:0] i_qE,
        input wire [C_S00_AXI_DATA_WIDTH-1:0] i_iP,
        input wire [C_S00_AXI_DATA_WIDTH-1:0] i_qP,
        input wire [C_S00_AXI_DATA_WIDTH-1:0] i_iL,
        input wire [C_S00_AXI_DATA_WIDTH-1:0] i_qL,
        input wire [C_S00_AXI_DATA_WIDTH-1:0] i_sample_counter_lsw,
        input wire [C_S00_AXI_DATA_WIDTH-1:0] i_sample_counter_msw,
        input wire i_results_ready, 
        
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	multicorrelator_resampler_S00_AXI_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) multicorrelator_resampler_S00_AXI_v1_0_S00_AXI_inst (
	
	 .code_phase_step_chips_num(code_phase_step_chips_num), //0
     .initial_index_E(initial_index_E), // 1, Early
     .initial_index_P(initial_index_P), // 3, Prompt 
     .initial_index_L(initial_index_L), // 4, Late
     .initial_interp_counter_E(initial_interp_counter_E), //7
     .initial_interp_counter_P(initial_interp_counter_P), //8
     .initial_interp_counter_L(initial_interp_counter_L), //9
     .nsamples_minus_1(nsamples_minus_1), //13
     .code_length_minus_1(code_length_minus_1), //14
     .rem_carr_phase_rad(rem_carr_phase_rad), //15
     .phase_step_rad(phase_step_rad), //16
     .prog_mems(prog_mems), //17
     .drop_samples(drop_samples), //18
     .initial_counter_value_lsw(initial_counter_value_lsw), //19
     .initial_counter_value_msw(initial_counter_value_msw), //20
     .code_phase_step_chips_rate(code_phase_step_chips_rate), //21
     .phase_step_rate(phase_step_rate), //22
     .stop_tracking(stop_tracking),//23
     .start_flag(start_flag),//30
     .irq(irq),
     .prog_mem_valid(prog_mem_valid),
     .clear_trk_accum(clear_trk_accum),
     .start_flag_valid(start_flag_valid),
     .stop_tracking_valid(stop_tracking_valid),
     .drop_samples_valid(drop_samples_valid),
        
     .i_iE(i_iE),
     .i_qE(i_qE),
     .i_iP(i_iP),
     .i_qP(i_qP),
     .i_iL(i_iL),
     .i_qL(i_qL),
     .i_sample_counter_lsw(i_sample_counter_lsw),
     .i_sample_counter_msw(i_sample_counter_msw),
     .i_results_ready(i_results_ready), 
	
	
	
	
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule
