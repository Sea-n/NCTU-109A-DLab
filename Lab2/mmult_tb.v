`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/09/19 13:54:59
// Design Name: 
// Module Name: mmult_tb
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

module mmult_tb;

// ---------------------------------------------------------------------
// Begin of the simulation code for clock and reset_n signals
//
reg clk = 1;
reg reset_n = 1;

// 100MHz clock generator
always
  #5 clk = !clk;

// Reset signal simulator
event reset_trigger;

initial begin
  forever begin
    @ (reset_trigger);
    @ (negedge clk);
    reset_n = 0;
    @ (negedge clk);
    reset_n = 1;
  end
end
//
//  End of simulation code for clock and reset_n signals
// ---------------------------------------------------------------------

// ---------------------------------------------------------------------
// Begin of the testbench code
//
reg  [0:9*8-1]  A, B;   // 3x3 matrices
wire [0:9*17-1] C;
reg  enable;
wire valid;

reg  [0:9*17-1] result; // The output matrix, 3x3 entries of 17-bit numbers

integer idx;

// Instiantiates a 3x3 matrix multiplier
mmult uut(
  .clk(clk),
  .reset_n(reset_n),
  .enable(enable),
  .A_mat(A),
  .B_mat(B),
  .valid(valid),
  .C_mat(C)
);

initial begin
  // Add stimulus here
  A = 72'h_0E_5E_03_39_1D_02_00_31_08;
  B = 72'h_0A_09_07_1D_05_02_01_28_09;

  // Issue a reset signal
  #10 -> reset_trigger;

  // Wait 100 ns for global reset to finish
  #100 enable = 1;

  #100 enable = 0;

  A = 72'h_FF_FF_FF_FF_FF_FF_04_04_04;
  B = 72'h_FF_FF_FF_FF_FF_FF_04_04_04;

  #10 enable = 1;
  
  #100 enable = 0;

  A = 72'h_01_00_00_00_01_00_00_00_01;
  B = 72'h_FF_FF_FF_FF_FF_FF_FF_FF_FF;

  #10 enable = 1;

end

// The matrices multiplication is done. Display the result.
always @(*) begin
  @(posedge valid);

  // Wait one clock cycle so that the output is saved in the result[] register
  #10 $display ("\nMatrix A is:\n");

  for (idx = 0; idx < 9; idx = idx+1)
  begin
    $write (" %d ", A[idx*8 +: 8]);
    if (idx%3 == 2) $write("\n");
  end

  #10 $display ("\nMatrix B is:\n");

  for (idx = 0; idx < 9; idx = idx+1)
  begin
    $write (" %d ", B[idx*8 +: 8]);
    if (idx%3 == 2) $write("\n");
  end

  $display ("\nThe result of C = A x B is:\n");

  for (idx = 0; idx < 9; idx = idx+1)
  begin
    $write (" %d ", result[idx*17 +: 17]);
    if (idx%3 == 2) $write("\n");
  end

  $write("\n");
end

// Save output C matrix in the result register when (valid == 1)
always @(posedge clk) begin
  if (~reset_n)
    result <= 0;
  else if (valid)
    result <= C;
  else
    result <= result;
end
//
//  End of the testbench code
// ---------------------------------------------------------------------

endmodule
