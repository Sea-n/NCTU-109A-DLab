`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2020 05:25:38 PM
// Design Name: 
// Module Name: alu
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


module alu(accum, data, opcode, clk, reset, alu_out, zero);
    input  wire [7:0] data, accum;
    input  wire [2:0] opcode;
    input  wire clk, reset;
    output wire [7:0] alu_out;
    output wire zero;
    
    reg  signed [7:0] out;
    wire signed [3:0] sa, sd;
    reg ze;
    assign alu_out = out;
    assign zero = ze;
    assign sa = accum[3:0];
    assign sd = data[3:0];

    //define mnemonics to represent opcodes
    `define PASSA 3'b000
    `define ADD   3'b001
    `define SUB   3'b010
    `define AND   3'b011
    `define XOR   3'b100
    `define ABS   3'b101
    `define MUL   3'b110
    `define PASSD 3'b111

    always @(posedge clk) begin
        if (reset)
            out <= 0;
        else casez (opcode)
            `PASSA : out <= accum;
            `ADD   : out <= accum + data;
            `SUB   : out <= accum + (~data + 1);
            `AND   : out <= accum & data;
            `XOR   : out <= accum ^ data;
            `ABS   : out <= {8{~accum[7]}} & accum | {8{accum[7]}} & (~accum + 1);
            `MUL   : out <= sa * sd;
          //  `MUL   : if (~accum[3] & ~data[3]) out <=     accum[3:0]               *   data[3:0];
          //      else if (~accum[3] &  data[3]) out <= ~(  accum[3:0]               * ((data[3:0]-1)&4'hf^4'hf)) + 1;
          //      else if ( accum[3] & ~data[3]) out <= ~(((accum[3:0]-1)&4'hf^4'hf) *   data[3:0]              ) + 1;
          //      else if ( accum[3] &  data[3]) out <=   ((accum[3:0]-1)&4'hf^4'hf) * ((data[3:0]-1)&4'hf^4'hf);
            `PASSD : out <= data;
            default: out <= 0;
        endcase
    end
    
    always @(accum) begin
        if (opcode[0] === 1'bx)
            ze <= 0;
        else
            ze <= ~|accum;
    end
endmodule
