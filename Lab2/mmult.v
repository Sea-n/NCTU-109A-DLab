`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2020 03:57:53 PM
// Design Name: 0816146 Sean
// Module Name: mmult
// Project Name: Lab 2
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


module mmult(
	input  wire clk, reset_n, enable,
	input  wire [0:9*8-1] A_mat, B_mat,
	output wire valid,
	output wire [0:9*17-1] C_mat);

	reg [0:9* 8-1] A, B;
	reg [0:9*17-1] C;  // Warning: Overflow when 209x209 ~ 255x171
	reg [0:1] cnt;

	assign C_mat = C;
	assign valid = &cnt;

	always @(posedge clk) begin
		if (~reset_n | ~enable) begin
            A <= A_mat;
            B <= B_mat;
            C <= 0;
            cnt <= 0;
		end else if (enable & ~valid) begin
			A <= A << 24;
			C <= C << 51
				| (A[0:7]*B[ 0: 7] + A[8:15]*B[24:31] + A[16:23]*B[48:55])  << 34
				| (A[0:7]*B[ 8:15] + A[8:15]*B[32:39] + A[16:23]*B[56:63])  << 17
				| (A[0:7]*B[16:23] + A[8:15]*B[40:47] + A[16:23]*B[64:71]);
			cnt <= cnt + 1;
		end
	end
endmodule
