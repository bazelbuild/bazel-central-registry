module child (
    input  logic clk,
    input  logic rst_n,
    input  logic in,
    output logic out
);
    /*verilator hier_block*/

    logic in_reg;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            in_reg <= 1'b0;
        else
            in_reg <= in;

    assign out = in_reg;

endmodule
