module parent #(
    parameter int NUM_CHILDREN = 8
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [NUM_CHILDREN-1:0] in,
    output logic [NUM_CHILDREN-1:0] out
);

    for (genvar i=0; i<NUM_CHILDREN; i++) begin: g_children
        child u_child(
            .clk(clk),
            .rst_n(rst_n),
            .in(in[i]),
            .out(out[i])
        );
    end

endmodule
