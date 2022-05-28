
`timescale 1 ns / 1 ps

	module Acquisition_AXI_v1_0 #
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
		/* Inputs AKA results */
		input wire [C_S00_AXI_DATA_WIDTH-1:0] sample_counter_lsw,
		input wire [C_S00_AXI_DATA_WIDTH-1:0] sample_counter_msw,
		input wire [C_S00_AXI_DATA_WIDTH-1:0] first_peak,
		input wire [C_S00_AXI_DATA_WIDTH-1:0] second_peak,
		input wire [C_S00_AXI_DATA_WIDTH-1:0] max_index,
		input wire [C_S00_AXI_DATA_WIDTH-1:0] doppler_index,
		input wire [C_S00_AXI_DATA_WIDTH-1:0] total_block_exp,
		input wire i_acq_done,


		output wire [C_S00_AXI_DATA_WIDTH-1:0] select_queue,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] vector_length,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] nsamples,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] vector_length_log2,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] exclude_limit,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] doppler_min,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] doppler_step,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] num_sweeps,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] o_total_block_exp,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] clear_local_prn_mem,
		output wire [C_S00_AXI_DATA_WIDTH-1:0] fft_prn_code,
		output wire 			       clear_local_prn_mem_valid,
		output wire 			       fft_prn_code_valid,
		output wire			       irq,
	    output wire                launch_acq_valid,
	    output wire                results_read_valid,
		output wire[2:0]			acquisition_control,
			
       
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
	Acquisition_AXI_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) Acquisition_AXI_v1_0_S00_AXI_inst (
		.sample_counter_lsw(sample_counter_lsw),
		.sample_counter_msw(sample_counter_msw),
		.first_peak(first_peak),
		.second_peak(second_peak),
		.max_index(max_index),
		.doppler_index(doppler_index),
        .i_acq_done(i_acq_done),

		.select_queue(select_queue),
		.vector_length(vector_length),
		.nsamples(nsamples),
		.vector_length_log2(vector_length_log2),
		.exclude_limit(exclude_limit),
		.doppler_min(doppler_min),
		.doppler_step(doppler_step),
		.num_sweeps(num_sweeps),
		.total_block_exp(total_block_exp),
		.clear_local_prn_mem(clear_local_prn_mem),
		.fft_prn_code(fft_prn_code),
		.clear_local_prn_mem_valid(clear_local_prn_mem_valid),
		.fft_prn_code_valid(fft_prn_code_valid),
		.irq(irq),
        .launch_acq_valid(launch_acq_valid),
	    .results_read_valid(results_read_valid),
	
		.acquisition_control(acquisition_control),	
       
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
