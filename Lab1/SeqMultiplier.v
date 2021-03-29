`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2020 06:12:09 PM
// Design Name: 
// Module Name: SeqMultiplier
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


module SeqMultiplier(
    input wire clk,
    input wire enable,
    input wire [7:0] A,
    input wire [7:0] B,
    output wire [15:0] C);
    
    reg [15:0] prod;
    reg [7:0]  mult;
    reg [3:0]  counter;
    wire       shift;
    
    assign C = prod;
    assign shift = |(counter^7);
    
    always @(posedge clk) begin
        if (!enable) begin
            mult <= B;
            prod <= 0;
            counter <= 0;
        end else begin
            mult <= mult<<1;
            prod <= (prod + (A & {8{mult[7]}})) << shift;
            counter <= counter + shift;
        end
    end
endmodule
