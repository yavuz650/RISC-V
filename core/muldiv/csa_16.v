`timescale 1ns/1ps
/* verilator lint_off UNOPTFLAT */
module full_add(
    input x, y, cin,
    output s, cout
    );
    
    assign s = x ^ y ^ cin;
    assign cout = (x & y) | (x & cin) | (y & cin);
    
endmodule

module csa_16(
    input [15:0] x, y, z, 
    output [15:0] s, c
    );
    genvar i;
    
    for (i = 0; i < 16; i = i + 1) begin
        full_add full_add_i(.x      (x[i]), 
                            .y      (y[i]),
                            .cin    (z[i]), 
                            .s      (s[i]),
                            .cout   (c[i])
                            );
    end
endmodule

