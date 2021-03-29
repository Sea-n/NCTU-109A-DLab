`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2020 05:56:23 PM
// Design Name: 
// Module Name: FullAdder_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FullAdder_tb;
    reg clk = 1;
    reg [3:0] A, B;
    reg Cin;
    
    wire [3:0] S;
    wire Cout;
    
    FullAdder uut(
        .A(A),
        .B(B),
        .Cin(Cin),
        .S(S),
        .Cout(Cout)
    );
    
    always
        #5 clk = ~clk;
        
    initial begin
        A = 0; B = 0; Cin = 0;
        
        #100 A = 4'd5;  B = 4'd10;
        
        #50  A = 4'd15; B = 4'd1;
        
        #50  A = 4'd0;  B = 4'd15; Cin = 1'b1;
        
        #50  A = 4'd6;  B = 4'd1;
        
        #100 $finish;
    end
endmodule
