module vr_fifo
#(
    parameter   D_WIDTH = 64,
    parameter   D_DEPTH = 8,
    localparam  A_WIDTH = $clog2( D_DEPTH ) + ( D_DEPTH == 1)   // $clog2( 1 ) = 0
)
(
    input   clk,
    input   rst_n,

    input   wr_vld,
    output  wr_rdy,
    input   [D_WIDTH - 1:0]  wr_data,

    output  rd_vld,
    input   rd_rdy,
    output  [D_WIDTH - 1:0]  rd_data,

    output  reg     [A_WIDTH:0] cnt
);

reg     [ D_WIDTH - 1 : 0 ]   storage   [ D_DEPTH ];
reg     [ A_WIDTH - 1 : 0 ]   wr_ptr, rd_ptr;

wire    full    = ( cnt ==  D_DEPTH );
wire    empty   = ( cnt == 0 );

assign  wr_rdy  = ~full | ( rd_vld & rd_rdy );
assign  rd_vld  = ~empty;

// write
always @( posedge clk or negedge rst_n )
    if ( ~rst_n )
        wr_ptr  <= 0;
    else if ( wr_vld & wr_rdy )
    begin
        storage[ wr_ptr ]   <= wr_data;
        wr_ptr              <= ( wr_ptr == D_DEPTH - 1 ) ? 0 : wr_ptr + 1;
    end

// read
always @( posedge clk or negedge rst_n )
    if ( ~rst_n )
        rd_ptr  <= 0;
    else if ( rd_vld & rd_rdy )
        rd_ptr  <= ( rd_ptr == D_DEPTH - 1 ) ? 0 : rd_ptr + 1;

// count
always @( posedge clk or negedge rst_n )
    if ( ~rst_n )  cnt <= 0;
    else        cnt <= cnt + ( wr_vld & wr_rdy ) - ( rd_vld & rd_rdy );

assign  rd_data = storage[ rd_ptr ];

endmodule
