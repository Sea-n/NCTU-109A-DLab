module game(
    input clk,
    input reset_n,
    input [3:0] usr_sw,
    input [3:0] btn_level,

    output reg [0:7] map_pos, // map_pos = (x, y)
    output reg [5:0] map_out, // map_out = map[map_pos]
    output reg [9:0] score,
    output wire is_started,
    output reg is_dead
);

// ------------------------------------------------------------------------
// Variables

reg [5:0] map [0:15][0:15];
localparam DOWN = 0;
localparam UP = 1;
localparam RIGHT = 2;
localparam LEFT = 3;

reg [1:0] heading, next_heading;
reg [31:0] snake_counter;

reg [31:0] snake_rate;    // Moves snake every snake_rate clks
reg [4:0] head_pos [0:1]; // head_x, head_y
reg [4:0] tail_pos [0:1]; // tail_x, tail_y
reg [4:0] next_head_pos [0:1];
reg [4:0] next_tail_pos [0:1];

// End of variables
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// The FSM logic

// At least 32x32 to fill the map
localparam INIT_DELAY = 5_000;
reg [$clog2(INIT_DELAY):0] init_counter;

localparam [1:0] S_MAIN_INIT = 0, // reading default map from SRAM
                 S_MAIN_IDLE = 1, // initialized, press any button to start
                 S_MAIN_PLAY = 2, // playing
                 S_MAIN_DEAD = 3; // snake dead, display the score and wait for button press

reg [1:0] P, P_next;

always @(posedge clk) begin
    if (~reset_n) P <= S_MAIN_INIT;
    else P <= P_next;
end

always @(*) begin // FSM next-state logic
    case (P)
        S_MAIN_INIT:
            if (init_counter > INIT_DELAY) P_next <= S_MAIN_IDLE;
            else P_next <= S_MAIN_INIT;
        S_MAIN_IDLE:
            if (|btn_level) P_next <= S_MAIN_PLAY;
            else P_next <= S_MAIN_IDLE;
        S_MAIN_PLAY:
            if (is_dead) P_next <= S_MAIN_DEAD;
            else P_next <= S_MAIN_PLAY;
        S_MAIN_DEAD:
            if (|btn_level) P_next <= S_MAIN_INIT;
            else P_next <= S_MAIN_DEAD;
    endcase
end

assign is_started = P != S_MAIN_INIT && P != S_MAIN_IDLE;

// End of the FSM logic
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// game_tick

reg [31:0] game_tick; // modulo 2^32

always @(posedge clk) begin
    if (~reset_n) game_tick <= 0;
    else if (P != S_MAIN_INIT) game_tick <= game_tick + 1;
end

// End of game_tick
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// SRAM control

reg [9:0] sram_addr1, sram_addr2;
wire [5:0] data_in;
wire [5:0] data_out1, data_out2;
wire sram_we, sram_en;

sram #(
    .DATA_WIDTH(6),   // 00 - 3f
    .ADDR_WIDTH(10),  // scene 0: 000-3ff,  1: 400-7ff,  ...  31: 3c00-3fff
    .RAM_SIZE(1024),  // 4 scenes, 16x16 map
    .FILE("game.mem")
) ram0 (
    .clk(clk), .en(sram_en),
    .we1(sram_we),       .we2(sram_we),
    .addr1(sram_addr1),  .addr2(sram_addr2),
    .data_i1(data_in),   .data_i2(data_in),
    .data_o1(data_out1), .data_o2(data_out2)
);

assign sram_we = usr_sw[3]; // Vivado is bugged, don't assign this to 0
assign sram_en = 1;         // Here, we always enable the SRAM block.
assign data_in = 6'h00;     // SRAM is read-only so we tie inputs to zeros.

// End of the SRAM memory block.
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// Iterate over 30x30 map every 900 clock

reg [0:3] map_pos_next [1:0];
reg [0:7] map_pos_prev;

always @(posedge clk) begin
    if (~reset_n) begin
        map_pos_next[0] <= 4'h00;
        map_pos_next[1] <= 4'h00;
    end else begin
        map_pos_next[0] <= map_pos_next[0] + 1;
        if (map_pos_next[0] == 4'hf) begin
            map_pos_next[1] <= map_pos_next[1] + 1;
        end
    end
end

always @(posedge clk) begin
    if (~reset_n) begin
        map_out <= 6'h00;
        map_pos <= 8'h00;
        map_pos_prev <= 8'h00;
    end else begin
        map_out <= map[ map_pos_next[0] ][ map_pos_next[1] ];
        map_pos <= {map_pos_next[0], map_pos_next[1]};
        map_pos_prev <= map_pos;
    end
end

always @(posedge clk) begin
    if (~reset_n) begin
        init_counter <= 0;
        sram_addr1 <= 10'h000;
        sram_addr2 <= 10'h000;
    end else if (P == S_MAIN_INIT) begin
        init_counter <= init_counter + 1;
        sram_addr1 <= {game_tick[1:0], map_pos_next[1], map_pos_next[0]};
    end else begin
        init_counter <= 0;
    end
end

// End of iterate over 30x30 map every 900 clock
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// Snake variable rate

always @(posedge clk) begin
    if (~reset_n || score < 2) snake_rate <= 50_000_000;
    else if (score < 4) snake_rate <= 40_000_000;
    else if (score < 6) snake_rate <= 32_000_000;
    else if (score < 8) snake_rate <= 25_000_000;
    else snake_rate <= 20_000_000;
end

// End of snake variable rate
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// The logic for snake start

reg food_gone;

always @(posedge clk) begin
    if (~reset_n || P == S_MAIN_INIT) begin
        snake_counter <= 0;
    end else if (P == S_MAIN_PLAY) begin
        if (snake_counter == snake_rate) snake_counter <= 0;
        else snake_counter <= snake_counter + 1;
    end
end

always @(posedge clk) begin
    if (~reset_n) begin
        next_heading <= heading;
    end else if (P == S_MAIN_PLAY) begin
        if      (btn_level[3] && heading != RIGHT) next_heading <= LEFT;
        else if (btn_level[2] && heading != UP)    next_heading <= DOWN;
        else if (btn_level[1] && heading != DOWN)  next_heading <= UP;
        else if (btn_level[0] && heading != LEFT)  next_heading <= RIGHT;
    end else begin
        next_heading <= heading;
    end
end

always @(posedge clk) begin
    next_head_pos[ ~next_heading[1] ]
      <= head_pos[ ~next_heading[1] ]
             + 1 - (next_heading[0]<<1);
    next_head_pos[  next_heading[1] ]
      <= head_pos[  next_heading[1] ];

    next_tail_pos[ ~map[ tail_pos[0] ][ tail_pos[1] ][1] ]
      <= tail_pos[ ~map[ tail_pos[0] ][ tail_pos[1] ][1] ]
             + 1 - (map[ tail_pos[0] ][ tail_pos[1] ][0]<<1);
    next_tail_pos[  map[ tail_pos[0] ][ tail_pos[1] ][1] ]
      <= tail_pos[  map[ tail_pos[0] ][ tail_pos[1] ][1] ];
end

// Move snake body
always @(posedge clk) begin
    if (~reset_n) begin
        head_pos[0] <= 0;
        head_pos[1] <= 0;
        tail_pos[0] <= 0;
        tail_pos[1] <= 0;
        heading <= RIGHT;
    end else if (P == S_MAIN_INIT) begin
        map[ map_pos_prev[0 +: 4] ][ map_pos_prev[4 +: 4] ] <= data_out1;
        if (data_out1[5:2] == 4'h4) begin
            head_pos[0] <= map_pos_prev[0 +: 4];
            head_pos[1] <= map_pos_prev[4 +: 4];
            heading     <= data_out1[1:0];
        end

        if (data_out1[5:2] == 4'h5) begin
            tail_pos[0] <= map_pos_prev[0 +: 4];
            tail_pos[1] <= map_pos_prev[4 +: 4];
        end

        score <= 0;
        is_dead <= 0;
        food_gone <= 0;
    end else if (P == S_MAIN_PLAY) begin
        if (snake_counter == snake_rate) begin
            heading     <= next_heading;

            // If nothing's on the head's tile
            if (map[ next_head_pos[0] ][ next_head_pos[1] ] == 0) begin
                map[ next_head_pos[0] ][ next_head_pos[1] ] <=
                    {4'h4, next_heading};
                map[      head_pos[0] ][      head_pos[1] ] <=
                    {2'h0, map[ head_pos[0] ][ head_pos[1] ][1:0] ^ 2'h1, next_heading};
                map[ next_tail_pos[0] ][ next_tail_pos[1] ] <=
                    {4'h5, map[ next_tail_pos[0] ][ next_tail_pos[1] ][1:0]};
                map[      tail_pos[0] ][      tail_pos[1] ] <= 6'h00;

                head_pos[0] <= next_head_pos[0];
                head_pos[1] <= next_head_pos[1];
                tail_pos[0] <= next_tail_pos[0];
                tail_pos[1] <= next_tail_pos[1];
            end
            // Ate something
            else if (map[ next_head_pos[0] ][ next_head_pos[1] ] == 42) begin
                map[ next_head_pos[0] ][ next_head_pos[1] ] <=
                    {4'h4, next_heading};
                map[      head_pos[0] ][      head_pos[1] ] <=
                    {2'h0, map[ head_pos[0] ][ head_pos[1] ][1:0] ^ 2'h1, next_heading};
                score <= score + 1;
                food_gone <= 1;

                head_pos[0] <= next_head_pos[0];
                head_pos[1] <= next_head_pos[1];
            end
            // Hit a rock
            else if (map[ next_head_pos[0] ][ next_head_pos[1] ] == 41) begin
                if (score > 0) score <= score - 1;
                else is_dead <= 1;
            end else begin
                is_dead <= 1;
            end
        end else begin
            // Assert food will be back within 1 * snake_rate
            if (food_gone
                    && map[ map_pos[0 +: 4] ][ map_pos[4 +: 4] ] == 0) begin
                map[ map_pos[0 +: 4] ][ map_pos[4 +: 4] ] <= 42;
                food_gone <= 0;
            end
        end
    end
end

endmodule
