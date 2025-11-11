module saturate #(
    parameter IN_W  = 17,
    parameter OUT_W = 16
) (
    input  wire signed [IN_W-1:0]  in,
    output wire signed [OUT_W-1:0] out
);

    // Detect if the truncated bits (above OUT_W) are consistent with the sign bit
    wire not_overflow;
    assign not_overflow = &(in[IN_W-1:OUT_W-1]) | ~(|in[IN_W-1:OUT_W-1]);

    // Saturate if overflow: 
    //  - if positive overflow ? max positive (0111...1)
    //  - if negative overflow ? max negative (1000...0)
    assign out = not_overflow ?
                 in[OUT_W-1:0] :
                 {in[IN_W-1], {(OUT_W-1){~in[IN_W-1]}}};

endmodule
