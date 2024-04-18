module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);

    // Full adder combinational logic
    assign sum  = a ^ b ^ cin;
    assign cout = ((a ^ b) & cin) | (a & b);

endmodule