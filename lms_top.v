module lms_top (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         in_valid,           // new input sample valid
    input  wire signed [15:0] e_in,     // LMS e
    input  wire signed [15:0] x_in, // optional feedback or initial x
    input  wire signed [15:0] a_in,   // desired output
    input  wire signed [15:0] u_in,         // LMS step size
    output wire signed [31:0] out_sample,   // LMS filter output
    output wire               out_valid     // output valid signal
);

    parameter TAPS = 128;

    // ------------------------
    // Internal wires
    // ------------------------
    wire signed [31:0] x_controller;
    wire signed [31:0] weight_adjust_controller;
    wire               controller_out_valid;
    wire               fir_go;
    wire               fir_done;

    wire signed [15:0] e_buf;
    wire signed [15:0] x_buf;
    wire signed [15:0] a_buf;
    wire signed [15:0] u_buf;
    wire               buf_valid;

    // ------------------------
    // Input Buffer
    // ------------------------
    input_buffer ibuf (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .error_in(e_in),
        .feedforward_in(x_in),
        .desired_in(a_in),
        .u_in(u_in),
        .error_out(e_buf),
        .feedforward_out(x_buf),
        .desired_out(a_buf),
        .u_out(u_buf),
        .outvalid(buf_valid)
    );

    // ------------------------
    // Controller FSM + MAC
    // ------------------------
    controller controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(buf_valid),              // use buffered valid
        .e_in(e_buf),
        .x_in(x_buf),
        .a_in(a_buf),
        .u_in(u_buf),
        .fir_done(fir_done),               // FIR handshake
        .x_out(x_controller),
        .weight_adjust(weight_adjust_controller),
        .out_sample(out_sample),                     // optional: controller could output FIR capture if desired
        .out_valid(controller_out_valid),
        .fir_go(fir_go)                    // signal FIR to start
    );

    // ------------------------
    // Dual-MAC FIR + Weight Module
    // ------------------------
    fir #(
        .TAPS(TAPS)
    ) fir_inst (
        .clk(clk),
        .rst_n(rst_n),
        .feedforward_in(x_controller),
        .weight_adjust(weight_adjust_controller),
        .go(fir_go),
        .out_sample(out_sample),
        .out_valid(out_valid),
        .done(fir_done)
    );

endmodule
