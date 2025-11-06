`timescale 1ns/1ps

module tb_lms_top;

    reg clk;
    reg valid;
    reg rst_n;
    reg signed [15:0] error_in;
    reg signed [15:0] feedforward_in;
    reg signed [15:0] desired_in;
    reg signed [15:0] u_in;

    wire signed [31:0] out_sample;
    wire out_valid;

    parameter CLK_PERIOD = 10; // 100 MHz clock
    parameter real FREQ_HZ = 1.0e3; // 1 kHz low frequency
    parameter real CLK_FREQ = 1.0e8; // 100 MHz
    parameter real TWO_PI = 6.28318530718;

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Instantiate LMS top module
    lms_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(valid),
        .error_in(error_in),
        .feedforward_in(feedforward_in),
        .desired_in(desired_in),
        .u_in(u_in),
        .out_sample(out_sample),
        .out_valid(out_valid)
    );

    // Testbench stimulus
    integer i;
    reg [15:0] cycle_count;
    real phase;
    integer k =1 ;
    initial begin
        rst_n = 0;
        valid = 0;
        error_in = 0;
        feedforward_in = 0;
        desired_in = 0;
        u_in = 1; // step size Q1.15 format
        cycle_count = 0;
        phase = 0.0;

        #50;
        rst_n = 1;

        // Run simulation for a while
        for (i = 0; i < 20000; i = i + 1) begin
            cycle_count = cycle_count + 1;

            if (cycle_count == 200) begin
                valid = 1;
                error_in = 1;
                feedforward_in = 1;
                desired_in = 0;
                cycle_count = 0;
            end else begin
                valid = 0;
                error_in = 0;
                feedforward_in = 0;
                desired_in = 0;
            end

            @(posedge clk);
        end

        $stop;
    end

    // VCD dump for waveform
    initial begin
        $dumpfile("lms_tb.vcd");
        $dumpvars(0, tb_lms_top);
        for (i = 0; i < 128; i = i + 1)
            $dumpvars(0, tb_lms_top.dut.fir_inst.w_reg[i]);
            $dumpvars(0, tb_lms_top.dut.fir_inst.x_reg[i]);
    end

    // Display output when valid
    always @(posedge clk) begin
        if (out_valid) begin
            $display("Time %0t: out_sample = %d", $time, out_sample,error_in);
        end
    end

endmodule
