`timescale 1ns / 1ps

module main(
    input clk,
    input reset_n,
    input [3:0] usr_sw,
    input [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
);

// ------------------------------------------------------------------------
// Variables accross (main, game, display)

/*
 * Debounced button
 *
 * Using vim-like key mapping
 * 3: left,  2: down,  1: up,  0: right
 */
wire [3:0] btn_level;  // main -> game

/*
 * Map of current game
 *
 * map[x][y] = 0 - 63
 *
 * type of snake body (0 - 15)
 *  0: empty,          1: down-to-up,    2: down-to-right,   3: down-to-left,
 *  4: up-to-down,     5: reserved,      6: up-to-right,     7: up-to-left,
 *  8: right-to-down,  9: right-to-up,  10: reserved,       11: right-to-left,
 * 12: left-to-down,  13: left-to-up,   14: left-to-right,  15: reserved,
 *
 * type of head and tail (16 - 23)
 * 16: head down,  17: head up,  18: head right,  19: head left,
 * 20: tail down,  21: tail up,  22: tail right,  23: tail left,
 *
 * others
 *  0: empty
 * 24 - 39: walls
 * 40: hole
 * 41: stone
 * 42: point
 */
wire [0:7] map_pos;  // game -> display
wire [5:0] map;  // game -> display

wire [9:0] score;  // game -> display

wire is_started;  // game -> display
wire is_dead;  // game -> display

// End of variables accross (main, game, display)
// ------------------------------------------------------------------------

debounce db0(.clk(clk), .btn_input(usr_btn[0]), .btn_output(btn_level[0]));
debounce db1(.clk(clk), .btn_input(usr_btn[1]), .btn_output(btn_level[1]));
debounce db2(.clk(clk), .btn_input(usr_btn[2]), .btn_output(btn_level[2]));
debounce db3(.clk(clk), .btn_input(usr_btn[3]), .btn_output(btn_level[3]));

game game(
    .clk(clk), .reset_n(reset_n), .usr_sw(usr_sw), .btn_level(btn_level),
    .map_pos(map_pos), .map_out(map),
    .score(score), .is_started(is_started), .is_dead(is_dead)
);

display display(
    .clk(clk), .reset_n(reset_n), .usr_sw(usr_sw),
    .map_pos(map_pos), .map_in(map),
    .score(score), .is_started(is_started), .is_dead(is_dead),
    .VGA_HSYNC(VGA_HSYNC), .VGA_VSYNC(VGA_VSYNC),
    .VGA_RED(VGA_RED), .VGA_GREEN(VGA_GREEN), .VGA_BLUE(VGA_BLUE)
);

endmodule

