`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2020 06:17:51 PM
// Design Name: 
// Module Name: SeqMultiplier_tb
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


module SeqMultiplier_tb;
    reg clk = 1;
    reg enable = 0;
    reg [7:0] A;
    reg [7:0] B;
    
    wire [7:0] m;
    assign m = uut.mult;
    
    wire [15:0] C;
    
    SeqMultiplier uut(
        .clk(clk),
        .enable(enable),
        .A(A),
        .B(B),
        .C(C)
    );
    
    always
        #5 clk = ~clk;
        
    initial begin
        A = 0; B = 0;
        
        #20
        A = 8'd239;
        B = 8'd163;
        
        #20
        enable = 1;
        
        #100
        $finish;
    end
endmodule
