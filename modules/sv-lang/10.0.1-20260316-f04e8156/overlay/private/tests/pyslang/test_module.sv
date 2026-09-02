module test_module(
    input wire [3:0] a,       // 4-bit input A
    input wire [3:0] b,       // 4-bit input B
    input wire cin,           // Carry input
    output wire [3:0] sum,    // 4-bit sum output
    output wire cout          // Carry output
);

    // 4-bit adder with carry
    assign {cout, sum} = a + b + cin;

endmodule
