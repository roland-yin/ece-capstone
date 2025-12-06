module prog_delay #(
    parameter N = 4,
    parameter L = 16    // Length of the shift register
) (
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire signed [15:0]   a_in,
    output wire signed [15:0]   a_out,
    input  wire        [N-1:0]  sel
    
);

reg signed [15:0] shift_reg [0:L-1];

integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < L; i = i + 1) begin
            shift_reg[i] <= 16'sd0;
        end
    end else begin
        shift_reg[0] <= a_in;
        for (i = 1; i < L; i = i + 1) begin
            shift_reg[i] <= shift_reg[i-1];
        end
    end
end

assign a_out = shift_reg[sel];

endmodule
