module display(
    input clk,
    input reset_n,
    input [3:0] usr_sw,
    input [0:7] map_pos,
    input [5:0] map_in,
	input [9:0] score,
    input is_started,
	input is_dead,

    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
);

reg [5:0] map [0:15][0:15];
always @(posedge clk) begin
    map[ map_pos[0 +: 4] ][ map_pos[4 +: 4] ] <= map_in;
end

// General VGA control signals
reg  vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)

reg [11:0] rgb_reg;   // RGB value for the current pixel
reg [11:0] rgb_next;  // RGB value for the next pixel
  
// Instiantiate the VGA sync signal generator
vga_sync vs0(
    .clk(vga_clk),
    .reset(~reset_n),
    .oHS(VGA_HSYNC),
    .oVS(VGA_VSYNC),
    .visible(video_on),
    .p_tick(pixel_tick),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y)
);

always @(posedge clk)
    vga_clk = ~vga_clk;

// ------------------------------------------------------------------------
// Read background, snake, wall images from SRAM
// Currently only the first port is used

// declare SRAM control signals
wire [15:0] sram_addr1, sram_addr2;
wire [11:0] data_in;
wire [11:0] data_out1, data_out2;
wire sram_we, sram_en;

localparam MAP_SPRITE_SIZE = 16 * 16 * 43;
localparam DIGIT_SPRITE_SIZE = 16 * 32 * 10;
localparam TEXT_SCORE_SPRITE_SIZE = 96 * 32 * 1;
localparam TEXT_START_SPRITE_SIZE = 144 * 96 * 1;
localparam TEXT_END_SPRITE_SIZE = 144 * 96 * 1;

localparam MAP_SPRITE_START = 0;
localparam DIGIT_SPRITE_START =
    MAP_SPRITE_START + MAP_SPRITE_SIZE;
localparam TEXT_SCORE_SPRITE_START =
    DIGIT_SPRITE_START + DIGIT_SPRITE_SIZE;
localparam TEXT_START_SPRITE_START =
    TEXT_SCORE_SPRITE_START + TEXT_SCORE_SPRITE_SIZE;
localparam TEXT_END_SPRITE_START =
    TEXT_START_SPRITE_START + TEXT_START_SPRITE_SIZE;
localparam SPRITE_TOTAL =
    TEXT_END_SPRITE_START + TEXT_END_SPRITE_SIZE;

sram #(
    .DATA_WIDTH(12),
    .ADDR_WIDTH(16), // sram[type][x][y] = color
    .RAM_SIZE(SPRITE_TOTAL),
    .FILE("display.mem")
) ram0 (
    .clk(clk), .en(sram_en),
    .we1(sram_we),       .we2(sram_we),
    .addr1(sram_addr1),  .addr2(sram_addr2),
    .data_i1(data_in),   .data_i2(data_in),
    .data_o1(data_out1), .data_o2(data_out2)
);

assign sram_we = usr_sw[3];  // Vivado is bugged, don't assign this to 0
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign data_in = 12'h000;    // SRAM is read-only so we tie inputs to zeros.

// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Assign addr at current pixel

// Values: (OLD)
// Width, Height =  [640, 480]
// Tile =           [16, 16]
// Playarea =       [0:479]  [0:479]   ([0+:30 * 16] [0+:30 * 16] )
// Score text =     [480:575][0:31]    ([480+:6 * 16][0+:2 * 16]  )
// Score digits =   [576:639][0:31]    ([576+:4 * 16][0+:2 * 16]  )
// Start/end text = [168:311][224:255] ([168+:9 * 16][224+:2 * 16])

reg [9:0] pixel_x_prev;
reg [9:0] score_prev;
reg [3:0] score_bcd [0:3];

reg [15:0] pixel_addr1;
reg [15:0] pixel_addr2;
assign sram_addr1 = pixel_addr1;
assign sram_addr2 = pixel_addr2;
reg [11:0] bg_color;

assign should_draw_map = pixel_x >= 0 && pixel_x < 448
    && pixel_y >= 0 && pixel_y < 448;

assign should_draw_score_text = pixel_x >= 480 && pixel_x < 576
    && pixel_y >= 0 && pixel_y < 32;

assign should_draw_score_digit = pixel_x >= 576 && pixel_x < 640
    && pixel_y >= 0 && pixel_y < 32;

assign should_draw_starttext = pixel_x >= 152 && pixel_x < 296
    && pixel_y >= 176 && pixel_y < 272
    && !is_started;

assign should_draw_endtext = pixel_x >= 152 && pixel_x < 296
    && pixel_y >= 176 && pixel_y < 272
    && is_dead;

// Abstract: Updates old variables when "tearing" won't happen
reg [1:0] i;
always @(posedge clk) begin
    if (~reset_n) begin
        // cached map reset shouldn't be a problem?
        pixel_x_prev <= 87;
        score_prev <= 0;
        score_bcd[0] <= 0;
        score_bcd[1] <= 0;
        score_bcd[2] <= 0;
        score_bcd[3] <= 0;
        i <= 0;
    end else begin
        pixel_x_prev <= pixel_x;

        // With the assumption of that the score isn't updated
        // faster than 16 ms (monitor's refresh rate),
        // all the following should be safe

        if (i == 3) begin
            if (pixel_y >= 32) begin
                if (score_prev < score) begin
                    score_bcd[0] <= score_bcd[0] + 1;
                    score_prev <= score_prev + 1;
                end else if (score_prev > score) begin
                    score_bcd[0] <= score_bcd[0] - 1;
                    score_prev <= score_prev - 1;
                end
            end
        end else begin
            if (score_bcd[i] == 10) begin
                score_bcd[i + 1] <= score_bcd[i + 1] + 1;
                score_bcd[i] <= 0;
            end else if (score_bcd[i] == 15) begin // -1
                score_bcd[i + 1] <= score_bcd[i + 1] - 1;
                score_bcd[i] <= 9;
            end
        end

        i <= i + 1;
    end
end

// Abstract: Determines the address on the sprites SRAM to pick
always @(posedge clk) begin
    if (~reset_n) begin
        pixel_addr1 <= 0;
        pixel_addr2 <= 0;
        bg_color <= 0;
    end else begin
        // bg
        if (should_draw_map) begin
            bg_color <= pixel_x[5] != pixel_y[5] ? 12'h080 : 12'h040;
        end else begin
            bg_color <= 12'h000;
        end

        // addr1
        if (should_draw_map) begin
            pixel_addr1 <= MAP_SPRITE_START
                + (map[pixel_x[9:5] + 1][pixel_y[9:5] + 1] << 8)
                + (pixel_y[4:1] << 4)
                + pixel_x[4:1];
            // Alternates between two shades of dark green
        end else if (should_draw_score_text) begin
            pixel_addr1 <= TEXT_SCORE_SPRITE_START
                + (pixel_y * 96)
                + (pixel_x - 480);
        end else if (should_draw_score_digit) begin
            pixel_addr1 <= DIGIT_SPRITE_START
                + (score_bcd[39 - pixel_x[9:4]] << 9)
                + (pixel_y << 4)
                + pixel_x[3:0];
        end else begin
            pixel_addr1 <= 0;
        end

        // addr2 (overlay)
        if (should_draw_endtext) begin
            pixel_addr2 <= TEXT_END_SPRITE_START
                + ((pixel_y - 176) * 144)
                + (pixel_x - 152);
        end else if (should_draw_starttext) begin
            pixel_addr2 <= TEXT_START_SPRITE_START
                + ((pixel_y - 176) * 144)
                + (pixel_x - 152);
        end else begin
            pixel_addr2 <= 0;
        end
    end
end

// End of Assign addr at current pixel
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

always @(posedge clk) begin
    if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
    if (~video_on) rgb_next = 12'h000; // Synchronization period, must be 0
    else begin
        rgb_next = data_out2 != 12'h0f0 ? data_out2
            : data_out1 != 12'h0f0 ? data_out1
            : bg_color;
    end
end

// End of the video data display code.
// ------------------------------------------------------------------------

endmodule

