module adder100 (
    input [99:0] a,
    input [99:0] b,
    input cin,
    output cout,
    output [99:0] sum
);

    assign {cout, sum} = a + b + cin;

endmodule