//
// This module show you how to infer an initialized SRAM block
// in your circuit using the standard Verilog code.  The initial
// values of the SRAM cells is defined in the text file "image.dat"
// Each line defines a cell value. The number of data in image.dat
// must match the size of the sram block exactly.

module sram
#(parameter DATA_WIDTH = 8, ADDR_WIDTH = 16, RAM_SIZE = 65536, FILE = "images.mem")
 (input clk, input en, input we1, input we2,
  input  [ADDR_WIDTH-1 : 0] addr1,
  input  [DATA_WIDTH-1 : 0] data_i1,
  output reg [DATA_WIDTH-1 : 0] data_o1,
  input  [ADDR_WIDTH-1 : 0] addr2,
  input  [DATA_WIDTH-1 : 0] data_i2,
  output reg [DATA_WIDTH-1 : 0] data_o2);

// Declareation of the memory cells
(* ram_style = "block" *) reg [DATA_WIDTH-1 : 0] RAM [RAM_SIZE - 1:0];

integer idx;

// ------------------------------------
// SRAM cell initialization
// ------------------------------------
// Initialize the sram cells with the values defined in "image.dat."
initial begin
    $readmemh(FILE, RAM);
end

// ------------------------------------
// SRAM read operation
// ------------------------------------
always @(posedge clk)
begin
  if (en & we1) begin
    RAM[addr1] <= data_i1;
    data_o1 <= data_i1;
  end else
    data_o1 <= RAM[addr1];
end

always @(posedge clk)
begin
  if (en & we2) begin
    RAM[addr2] <= data_i2;
    data_o2 <= data_i2;
  end else
    data_o2 <= RAM[addr2];
end

endmodule
