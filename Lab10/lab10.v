`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC, VGA_VSYNC,
    output [3:0] VGA_RED, VGA_GREEN, VGA_BLUE
    );

// Declare system variables
reg  [31:0] clk_fh1, clk_fh2, clk_fh3;
reg  [2:0]  speed_fh3;
wire [9:0]  pos1, pos2, pos3;
wire        regn_fh1, regn_fh2, regn_fh3;

// declare SRAM control signals
wire [16:0] sram_addr_bg, sram_addr_fh1, sram_addr_fh2, sram_addr_fh3;
wire [11:0] data_in;
wire [11:0] data_out_bg, data_out_fh1, data_out_fh2, data_out_fh3;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr_bg;
reg  [17:0] pixel_addr_fh1, pixel_addr_fh2, pixel_addr_fh3;

wire [3:0] btn_level, btn;
reg  [3:0] prev_btn;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH1_VPOS   = 80;  // Vertical location of the fish in the sea image.
localparam FISH2_VPOS   = 100; // Vertical location of the fish in the sea image.
localparam FISH3_VPOS   = 192; // Vertical location of the fish in the sea image.
localparam FISH_W       = 64;  // Width of the fish.
localparam FISH_H1      = 32;  // Height of the fish.
localparam FISH_H2      = 44;  // Height of the fish.
localparam FISH_H3      = 44;  // Height of the fish.
reg [17:0] fish1_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish2_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish3_addr[0:8];   // Address array for up to 8 fish images.

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish1_addr[0] = VBUF_W*VBUF_H;
  fish1_addr[1] = VBUF_W*VBUF_H + FISH_W*FISH_H1;
  fish1_addr[2] = VBUF_W*VBUF_H + FISH_W*FISH_H1*2;
  fish1_addr[3] = VBUF_W*VBUF_H + FISH_W*FISH_H1*3;
  fish1_addr[4] = VBUF_W*VBUF_H + FISH_W*FISH_H1*4;
  fish1_addr[5] = VBUF_W*VBUF_H + FISH_W*FISH_H1*5;
  fish1_addr[6] = VBUF_W*VBUF_H + FISH_W*FISH_H1*6;
  fish1_addr[7] = VBUF_W*VBUF_H + FISH_W*FISH_H1*7;

  fish2_addr[0] = 0;
  fish2_addr[1] = FISH_W*FISH_H2;
  fish2_addr[2] = FISH_W*FISH_H2*2;
  fish2_addr[3] = FISH_W*FISH_H2*3;
  fish2_addr[4] = FISH_W*FISH_H2*4;
  fish2_addr[5] = FISH_W*FISH_H2*5;
  fish2_addr[6] = FISH_W*FISH_H2*6;
  fish2_addr[7] = FISH_W*FISH_H2*7;

  fish3_addr[0] = 0;
  fish3_addr[1] = FISH_W*FISH_H2;
  fish3_addr[2] = FISH_W*FISH_H2*2;
  fish3_addr[3] = FISH_W*FISH_H2*3;
  fish3_addr[4] = FISH_W*FISH_H2*4;
  fish3_addr[5] = FISH_W*FISH_H2*5;
  fish3_addr[6] = FISH_W*FISH_H2*6;
  fish3_addr[7] = FISH_W*FISH_H2*7;
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

debounce btn_db0(.clk(clk), .btn_input(usr_btn[0]), .btn_output(btn_level[0]));
debounce btn_db1(.clk(clk), .btn_input(usr_btn[1]), .btn_output(btn_level[1]));
debounce btn_db2(.clk(clk), .btn_input(usr_btn[2]), .btn_output(btn_level[2]));
debounce btn_db3(.clk(clk), .btn_input(usr_btn[3]), .btn_output(btn_level[3]));

// Enable one cycle of btn_pressed per each button hit
always @(posedge clk) begin
  if (~reset_n) prev_btn <= 4'h0;
  else prev_btn <= btn_level;
end

assign btn = (btn_level & ~prev_btn);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H + 8*FISH_W*FISH_H1), .FILE("images1.mem"))
  ramA (.clk(clk), .en(sram_en), .we1(sram_we), .we2(sram_we),
          .addr1(sram_addr_bg), .data_i1(data_in), .data_o1(data_out_bg),
          .addr2(sram_addr_fh1), .data_i2(data_in), .data_o2(data_out_fh1));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(8*FISH_W*FISH_H2), .FILE("images2.mem"))
  ramB (.clk(clk), .en(sram_en), .we1(sram_we), .we2(sram_we),
          .addr1(sram_addr_fh2), .data_i1(data_in), .data_o1(data_out_fh2),
          .addr2(sram_addr_fh3), .data_i2(data_in), .data_o2(data_out_fh3));

assign sram_we = btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr_bg  = pixel_addr_bg;
assign sram_addr_fh1 = pixel_addr_fh1;
assign sram_addr_fh2 = pixel_addr_fh2;
assign sram_addr_fh3 = pixel_addr_fh3;
assign data_in = 12'h000;    // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos1 = clk_fh1[30:20]; // the x position of the right edge of the fish image
                             // in the 640x480 VGA screen
assign pos2 = clk_fh2[29:19];
assign pos3 = clk_fh3[29:19];
always @(posedge clk) begin
  if (~reset_n)
    clk_fh1 <= 0;
  else if (clk_fh1[31:21] > VBUF_W + FISH_W)
    clk_fh1 <= 0;
  else
    clk_fh1 <= clk_fh1 + 1;

  if (~reset_n)
    clk_fh2 <= 168100200;
  else if (clk_fh2[30:20] > VBUF_W + FISH_W)
    clk_fh2 <= 0;
  else
    clk_fh2 <= clk_fh2 + 1;

  if (~reset_n)
    clk_fh3 <= 0;
  else if (clk_fh3 == 0)
    clk_fh3[30:20] <= VBUF_W + FISH_W;
  else if (clk_fh1[2:0] <= speed_fh3)
    clk_fh3 <= clk_fh3 - 1;
  else
    clk_fh3 <= clk_fh3;
end
// End of the animation clock code.
// ------------------------------------------------------------------------

always @(posedge clk) begin
  if (~reset_n)
    speed_fh3 <= 3'h4;
  else if (btn[1] && speed_fh3 > 3'h1)
    speed_fh3 <= speed_fh3 - 1;
  else if (btn[0] && speed_fh3 < 3'h7)
    speed_fh3 <= speed_fh3 + 1;
  else
    speed_fh3 <= speed_fh3;
end

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign regn_fh1 =
           pixel_y >= (FISH1_VPOS<<1) && pixel_y < (FISH1_VPOS+FISH_H1)<<1 &&
           (pixel_x + 127) >= pos1 && pixel_x < pos1 + 1;
assign regn_fh2 =
           pixel_y >= (FISH2_VPOS<<1) && pixel_y < (FISH2_VPOS+FISH_H2)<<1 &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1;
assign regn_fh3 =
           pixel_y >= (FISH3_VPOS<<1) && pixel_y < (FISH3_VPOS+FISH_H3)<<1 &&
           (pixel_x + 127) >= pos3 && pixel_x < pos3 + 1;

always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr_bg  <= 0;
    pixel_addr_fh1 <= 0;
    pixel_addr_fh2 <= 0;
    pixel_addr_fh3 <= 0;
  end else begin
    pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    
    if (regn_fh1)
        pixel_addr_fh1 <= fish1_addr[clk_fh1[25:23]] +
                      ((pixel_y>>1)-FISH1_VPOS)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos1)>>1);
    else pixel_addr_fh1 <= fish1_addr[0];  // top-left of frame 0, should be 0x0F0

    if (regn_fh2)
        pixel_addr_fh2 <= fish2_addr[clk_fh2[25:23]] +
                      ((pixel_y>>1)-FISH2_VPOS)*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos2)>>1);
    else pixel_addr_fh2 <= fish2_addr[0];

    if (regn_fh3)
        pixel_addr_fh3 <= fish3_addr[clk_fh3[25:23]] +
                      ((pixel_y>>1)-FISH3_VPOS)*FISH_W -
                      ((pixel_x +(FISH_W*2-1)-pos3)>>1);
    else pixel_addr_fh3 <= fish3_addr[0];
  end
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next <= 12'h000; // Synchronization period, must set RGB values to zero.
  else if (data_out_fh1 != 12'h0F0)
    rgb_next <= data_out_fh1; // RGB value at (pixel_x, pixel_y)
  else if (data_out_fh2 != 12'h0F0)
    rgb_next <= data_out_fh2;
  else if (data_out_fh3 != 12'h0F0)
    rgb_next <= data_out_fh3;
  else
    rgb_next <= data_out_bg;
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule  // Lab 10
