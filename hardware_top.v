module hardware_top (
    input wire clk,
    input wire byp_clk,
    input wire scan_clk,
    input wire rst_n,

    output wire mux_clk,
    
    output wire i2s_ws_rx,
    output wire i2s_sck_rx,
    
    // Error mic
    input wire sd_e,
    // Reference mic
    input wire sd_x,
    // Audio input
    input wire sd_a,
    // LMS step size input
    input wire sd_u,
    
    //OUT TO DAC
    output wire i2s_ws_tx,
    output wire i2s_sck_tx,
    output wire i2s_sd_out,
    
    output wire byp_rdy,
    
    // Initialization bits (serially shifted in on reset)
    input wire init_in,
    
    // FPGA bypass
    input wire signed [6:0] byp,
    input wire byp_vld,
    
    // Scan enable and out
    input  wire scan_en,
    input  wire scan_freeze,
    output wire scan_out_x,
    output wire scan_out_w
);

// -----------------------------------------------------------------------------
// glitch free clock mux
reg     [1:0]   sync_core_clk, sync_scan_clk;
wire    sync_core_out, sync_scan_out;

wire    scan_en_eff;   // declared here for use in mux (driven later)

always @( posedge clk or negedge rst_n )
    if ( ~rst_n )
        sync_core_clk   <= 0;
    else
        sync_core_clk   <= { sync_core_clk[0], (~scan_en_eff & ~sync_scan_out) };

assign  sync_core_out   = sync_core_clk[0];     // 1 for double FF and 0 for single FF
        
always @( posedge scan_clk or negedge rst_n )
    if ( ~rst_n )
        sync_scan_clk   <= 0;
    else
        sync_scan_clk   <= { sync_scan_clk[0], (scan_en_eff & ~sync_core_out) };

assign  sync_scan_out   = sync_scan_clk[0];     // 1 for double FF and 0 for single FF

assign mux_clk = (sync_core_out & clk) | (sync_scan_out & scan_clk);

wire scan_freeze_eff = scan_freeze | sync_scan_clk;

// -----------------------------------------------------------------------------
// i/o wires
wire signed [15:0] e_in;
wire signed [15:0] x_in;
wire signed [15:0] a_in;
wire signed [15:0] u_in;

wire e_vld, e_rdy;
wire x_vld, x_rdy;
wire a_vld, a_rdy;
wire u_vld, u_rdy;


// -----------------------------------------------------------------------------
// Initialization Sequence: Shifting in Initialization Bits
localparam init_len = 22;	// *Need to change counter length too, also see google sheets on current def
reg  [init_len-1:0] init_bits;
reg  [4:0]          init_cnt;
reg                 init_done;

// Latched config (stable after init_done)
reg  [7:0] i2s_in_clk_period_r, i2s_out_clk_period_r;
reg        bypass_mode_sel_r;
reg  [4:0] prog_delay_sel_r;

wire [init_len-1:0] init_bits_next;
assign init_bits_next = {init_in, init_bits[init_len-1:1]};

// decoded config wires (use latched regs)
wire [7:0] i2s_in_clk_period, i2s_out_clk_period;
wire       bypass_mode_sel;
wire [4:0] prog_delay_sel;

assign i2s_in_clk_period  = i2s_in_clk_period_r;
assign i2s_out_clk_period = i2s_out_clk_period_r;
assign bypass_mode_sel    = bypass_mode_sel_r;
assign prog_delay_sel     = prog_delay_sel_r;

// only allow scan clock switching after init finishes
assign scan_en_eff = scan_en & init_done;


// -----------------------------------------------------------------------------
// i2s interfaces
i2s_rx i2s_rx_e (.clk(clk), .rst_n(rst_n), .ws(i2s_ws_rx), .sck(i2s_sck_rx), .sd(sd_e), .dout(e_in), .dout_vld(e_vld), .dout_rdy(e_rdy), .sck_period(i2s_in_clk_period));
i2s_rx i2s_rx_x (.clk(clk), .rst_n(rst_n), .sd(sd_x), .dout(x_in), .dout_vld(x_vld), .dout_rdy(x_rdy), .sck_period(i2s_in_clk_period));
i2s_rx i2s_rx_a (.clk(clk), .rst_n(rst_n), .sd(sd_a), .dout(a_in), .dout_vld(a_vld), .dout_rdy(a_rdy), .sck_period(i2s_in_clk_period));
i2s_rx i2s_rx_u (.clk(clk), .rst_n(rst_n), .sd(sd_u), .dout(u_in), .dout_vld(u_vld), .dout_rdy(u_rdy), .sck_period(i2s_in_clk_period));

// -----------------------------------------------------------------------------
// Handshake with controller
wire data_valid;
wire controller_ready;

// Only enabling first 3 since u doesn't necessarily need to be updated and synchronized every cycle. Figure out later
vr_merge #(4) vr_merge_inst (
    .i_en(4'b1111),
    .i_valid({e_vld, x_vld, a_vld, u_vld}),
    .o_ready({e_rdy, x_rdy, a_rdy, u_rdy}),
    .o_valid(data_valid),
    .i_ready(controller_ready)
);

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        init_bits            <= 0;
        init_cnt             <= 0;
        init_done            <= 0;

        i2s_in_clk_period_r  <= 8'd0;
        i2s_out_clk_period_r <= 8'd0;
        bypass_mode_sel_r    <= 1'b0;
        prog_delay_sel_r     <= 5'd0;

    end else if (!init_done) begin
        init_bits <= init_bits_next;

    	if (init_cnt == init_len-1) begin
            init_done <= 1'b1;

            // Latch decoded config once (from the just-shifted value)
            {i2s_in_clk_period_r, i2s_out_clk_period_r, bypass_mode_sel_r, prog_delay_sel_r} <= init_bits_next;

    	end else begin
            init_cnt <= init_cnt + 1;
        end
    end
end

// -----------------------------------------------------------------------------
// ANC top
wire signed [15:0] out_sample;	// FIR filter output
wire               out_valid;	// output valid signal

anc_top anc_top_inst (
    .clk(clk),
    .byp_clk(byp_clk),
    .mux_clk(mux_clk),
    .rst_n(rst_n),

    .scan_en(scan_en_eff),
    .scan_freeze(scan_freeze_eff),
    .scan_out_x(scan_out_x),
    .scan_out_w(scan_out_w),

    .init_done(init_done),
    .prog_delay_sel(prog_delay_sel),
    .bypass_mode_sel(bypass_mode_sel),

    .in_valid(data_valid),
    .controller_ready(controller_ready),

    .u_in(u_in),
    .e_in(e_in),
    .x_in(x_in),
    .a_in(a_in),

    .out_sample(out_sample),
    .out_valid(out_valid),

    .weight_inject(byp),
    .bypass_valid(byp_vld),
    .bypass_ready(byp_rdy)
);


// -----------------------------------------------------------------------------
// i2s tx to DAC
i2s_tx i2s_tx_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .bclk_period(i2s_out_clk_period),

    .sample_vld (out_valid),
    .sample     (out_sample),

    .lr_clk     (i2s_ws_tx),
    .bclk       (i2s_sck_tx),
    .dout       (i2s_sd_out)
);

endmodule