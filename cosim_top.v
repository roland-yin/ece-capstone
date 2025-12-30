`timescale 1ns/1ps

// Cosim wrapper top for MATLAB/Simulink HDL co-sim.
// - Generates internal clocks:
//     clk      = 100 MHz  (T = 10 ns)
//     byp_clk  = 400 MHz  (T = 2.5 ns)
//     scan_clk = (default) 10 ns like clk (change if you want)
// - Generates a reset pulse.
// - Exposes ONLY non-clock pins to Simulink (recommended).
module cosim_top (
    // Optional: expose reset if you want Simulink to control it.
    // If you prefer purely HDL reset, comment this port out and keep internal rst_n.
    input  wire        rst_n,

    // Error mic / Reference mic / Audio input / LMS step size (serial)
    input  wire        sd_e,
    input  wire        sd_x,
    input  wire        sd_a,
    input  wire        sd_u,

    // Initialization bits shifted in during reset/init
    input  wire        init_in,

    // FPGA bypass
    input  wire signed [6:0] byp,
    input  wire        byp_vld,

    // Scan
    input  wire        scan_start,
    //output wire        scan_out,

    // I2S outputs (you can probe these in Simulink)
    output wire        i2s_ws_rx,
    output wire        i2s_sck_rx,
    output wire        i2s_ws_tx,
    output wire        i2s_sck_tx,
    output wire        i2s_sd_out,

    output wire        byp_rdy,

	// Simulation
	output reg	       clk,
	output reg		   byp_clk,
	output reg		   scan_clk
	
);

// ---------------------------------------------------------------------------
// Internal clocks

initial begin
	scan_clk = 1'b1;   // choose same as clk by defaul
	clk      = 1'b1;   // 100 MHz
	byp_clk  = 1'b1;   // 400 MHz
end


// 100 MHz: toggle every 5 ns -> 10 ns period
always #5.0  clk = ~clk;

// 400 MHz: toggle every 1.25 ns -> 2.5 ns period
always #1.25 byp_clk = ~byp_clk;

// Scan clock (default = 100 MHz). Adjust as needed.
always #2.5  scan_clk = ~scan_clk;

reg scan_en;

// Shift accumulator for one word
reg [25:0] accum_x;
reg [25:0] accum_w;
reg [25:0] captured_x [0:255];
reg [25:0] captured_w [0:255];
reg  [8:0] word_idx;              // 0..255
reg  [4:0] bit_idx;              // 0..25
reg        frame_done;
reg collect_start;

reg scan_sync_en;
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		scan_sync_en <= 1'b0;
	end else begin
		scan_sync_en <= 1'b0;
		if (!scan_en && scan_start) begin
			scan_sync_en <= 1'b1;
		end
	end
end

always @ (posedge scan_clk or negedge rst_n) begin
	if (!rst_n) begin
		scan_en			<= 1'b0;
		word_idx  		<= 9'd255;
		bit_idx   		<= 5'd0;
		accum_x   		<= 26'b0;
		accum_w   		<= 26'b0;
		frame_done		<= 1'b0;
		collect_start	<= 1'b0;
	end else begin
		frame_done <= 1'b0;
		if (scan_sync_en) begin
			scan_en <= 1'b1;
		end
		if (scan_en)
			collect_start <= 1'b1;	// Delay 1 cycle

		if (collect_start) begin
			// --- LSB-first assembly (scan_bit is LSB first) ---
			// first bit received goes to bit 0, next to bit 1, etc.
			accum_x[bit_idx] <= scan_out_x;
			accum_w[bit_idx] <= scan_out_w;

			if (bit_idx == 5'd25) begin
				// Completed one 26-bit word
				captured_x[word_idx] <= accum_x;
				captured_w[word_idx] <= accum_w;

				bit_idx <= 5'd0;

				if (word_idx == 9'd0) begin
					word_idx   <= 9'd255;
					frame_done <= 1'b1; // one full frame collected
					collect_start <= 1'b0;
					scan_en <= 1'b0;
				end else begin
					word_idx <= word_idx - 1'b1;
				end
			end else begin
				bit_idx <= bit_idx + 1'b1;
			end
		end
	end
end

// ---------------------------------------------------------------------------
// DUT instance
hardware_top dut (
	.clk       (clk),
	.byp_clk   (byp_clk),
	.scan_clk  (scan_clk),
	.rst_n     (rst_n),

	.i2s_ws_rx (i2s_ws_rx),
	.i2s_sck_rx(i2s_sck_rx),

	.sd_e      (sd_e),
	.sd_x      (sd_x),
	.sd_a      (sd_a),
	.sd_u      (sd_u),

	.i2s_ws_tx (i2s_ws_tx),
	.i2s_sck_tx(i2s_sck_tx),
	.i2s_sd_out(i2s_sd_out),

	.byp_rdy   (byp_rdy),

	.init_in   (init_in),

	.byp       (byp),
	.byp_vld   (byp_vld),

	.scan_en   (scan_en),
	.scan_out_x(scan_out_x),
	.scan_out_w(scan_out_w)
);

endmodule
