`timescale 1ns / 1ps

module tb_lms_128;

// -----------------------------------------------------------------------------
// Clock and reset
logic clk;
logic rst_n;

// -----------------------------------------------------------------------------
// I2S channel signals
logic ws_e, sck_e, sd_e;
logic ws_x, sck_x, sd_x;
logic ws_a, sck_a, sd_a;
logic ws_u, sck_u, sd_u;

// -----------------------------------------------------------------------------
// Instantiate DUT
hardware_top dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .ws_e   (ws_e),
    .sck_e  (sck_e),
    .sd_e   (sd_e),
    .ws_x   (ws_x),
    .sck_x  (sck_x),
    .sd_x   (sd_x),
    .ws_a   (ws_a),
    .sck_a  (sck_a),
    .sd_a   (sd_a),
    .ws_u   (ws_u),
    .sck_u  (sck_u),
    .sd_u   (sd_u)
);

// -----------------------------------------------------------------------------
// Clock generation
initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100 MHz system clock
end

// -----------------------------------------------------------------------------
// I2S bit clocks
initial begin
    sck_e = 1;
    sck_x = 1;
    sck_a = 1;
    sck_u = 1;
    forever begin
        #165 sck_e = ~sck_e;
        #165 sck_x = ~sck_x;
        #165 sck_a = ~sck_a;
        #165 sck_u = ~sck_u;
    end
end

// -----------------------------------------------------------------------------
// Random data generator class
class myRand;
    rand bit [23:0] rand_num;
    function new(); endfunction
endclass

// -----------------------------------------------------------------------------
// Queues for data and scoreboards
bit [23:0] data_e[$], data_x[$], data_a[$], data_u[$];
bit [15:0] sb_e[$],   sb_x[$],   sb_a[$],   sb_u[$];

localparam SAMPLES = 1000;


// -----------------------------------------------------------------------------
// Task for driving I2S channel
task automatic drive_i2s(
    ref logic ws,
    ref logic sck,
    ref logic sd,
    ref bit [23:0] data_q[$],
    ref bit [15:0] sb_q[$],
    input string name
);
    $display("[%s] START driving at %t", name, $time);
    $display(data_q.size);
    ws = 0;
    while (data_q.size()>0) begin
        repeat (32) @(negedge sck);
        ws = ~ws;

        for (int idx = 23; idx >= 0; idx--) begin
            if (idx == 8) begin
                sb_q.push_back(data_q[0][23:8]);
                $display("[%s] pushed sample %h to scoreboard", name, data_q[0][23:8]);
            end
            @(negedge sck);
            sd = data_q[0][idx];
        end

        data_q.pop_front();
        repeat (8) @(negedge sck);
        ws = ~ws;
    end
    $display("[%s] END driving at %t", name, $time);
endtask

// -----------------------------------------------------------------------------
// Main simulation flow
initial begin
    myRand rand_gen = new();
    for (int i = 0; i < SAMPLES; i++) begin
        rand_gen.randomize();
        data_e.push_back(rand_gen.rand_num);
        rand_gen.randomize();
        data_x.push_back(rand_gen.rand_num);
        rand_gen.randomize();
        data_a.push_back(rand_gen.rand_num);
        rand_gen.randomize();
        data_u.push_back(rand_gen.rand_num);
    end
    rst_n = 0;
    #50 rst_n = 1;

    fork
        drive_i2s(ws_e, sck_e, sd_e, data_e, sb_e, "Error Mic");
        drive_i2s(ws_x, sck_x, sd_x, data_x, sb_x, "Reference Mic");
        drive_i2s(ws_a, sck_a, sd_a, data_a, sb_a, "Audio In");
        drive_i2s(ws_u, sck_u, sd_u, data_u, sb_u, "Step Size");
    join

    $display("Simulation complete at time %t", $time);
    $finish;
end

endmodule
