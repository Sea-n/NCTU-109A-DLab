`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
    input clk,
    input reset_n,
    input [3:0] usr_btn,
    output [3:0] usr_led,
    output LCD_RS,
    output LCD_RW,
    output LCD_E,
    output [3:0] LCD_D
);

wire [3:0] btn;
wire [127:0] rowA, rowB;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg [ 7:0] cnt=8'h0, cntA, cntB;
reg [15:0] numA=16'hB520, numB=16'h0000;
reg [25:0] timer = 1;
reg rev = 1;
reg en = 0;

assign usr_led = cnt[3:0];

LCD_module lcd0(
    .clk(clk),
    .reset(~reset_n),
    .row_A(row_A),
    .row_B(row_B),
    .LCD_E(LCD_E),
    .LCD_RS(LCD_RS),
    .LCD_RW(LCD_RW),
    .LCD_D(LCD_D)
);

debounce btn_db3(
    .clk(clk),
    .btn_input(usr_btn[3]),
    .btn_output(btn[3])
);

h2a mA0(cntA[ 7: 4], rowA[79:72]);
h2a mA1(cntA[ 3: 0], rowA[71:64]);
h2a mA2(numA[15:12], rowA[31:24]);
h2a mA3(numA[11: 8], rowA[23:16]);
h2a mA4(numA[ 7: 4], rowA[15: 8]);
h2a mA5(numA[ 3: 0], rowA[ 7: 0]);

h2a mB0(cntB[ 7: 4], rowB[79:72]);
h2a mB1(cntB[ 3: 0], rowB[71:64]);
h2a mB2(numB[15:12], rowB[31:24]);
h2a mB3(numB[11: 8], rowB[23:16]);
h2a mB4(numB[ 7: 4], rowB[15: 8]);
h2a mB5(numB[ 3: 0], rowB[ 7: 0]);

always @(posedge clk, negedge reset_n) begin
    if (~reset_n) begin
        cnt   <= 8'h0;
        numA  <= 16'hB520;
        numB  <= 16'h0000;
        timer <= 1;
        rev <= 1;
        en <= 0;
    end else begin
        if (en & ~usr_btn[0])  // pause
            timer <= timer + 1;
            
        if (btn[3]) begin
            rev <= ~rev;
            en <= 1;
        end

        if (timer == 0) begin
            if (rev == 0) begin
                numA <= numB;
                if (cnt == 8'h18) begin
                    cnt  <= 8'h0;
                    numB <= 16'h0000;
                end else if (cnt == 0) begin
                    cnt  <= cnt + 1;
                    numB <= 16'h0001;
                end else begin
                    cnt  <= cnt + 1;
                    numB <= numA + numB;
                end
            end else begin
                numB <= numA;
                if (cnt == 1) begin
                    cnt  <= cnt - 1;
                    numA <= 16'hB520;
                end else if (cnt == 0) begin
                    cnt  <= 8'h18;
                    numA <= 16'h6FF1;
                end else begin
                    cnt  <= cnt - 1;
                    numA <= numB - numA;
                end
            end
        end
    end
end


always @(en, rowA, rowB) begin
    if (en) begin
        row_A <= "Fibo #__ is ____";
        row_A[79:64] <= rowA[79:64];
        row_A[31: 0] <= rowA[31: 0];

        row_B <= "Fibo #__ is ____";
        row_B[79:64] <= rowB[79:64];
        row_B[31: 0] <= rowB[31: 0];
    end else begin
        row_A <= "Press BTN3 to   ";
        row_B <= "show a message..";
    end
end

always @(cnt)
    if (cnt == 0)
        cntA <= 8'h19;
    else
        cntA <= cnt;

always @(cnt)
    if (cnt == 8'h19)
        cntB <= 1;
    else
        cntB <= cnt + 1;

assign usr_led = cnt;

endmodule


module debounce(
    input clk,
    input btn_input,
    output btn_output
    );

    reg [23:0] cnt = 24'h000000;
    reg sig  = 0;
    reg prev = 0;

    assign btn_output = sig;

    always @(posedge clk) begin
        if (sig == 1) begin
            sig <= 0;
            prev <= 1;
        end else if (~prev && cnt == 24'haabbcc)
            sig = 1;
        else if (prev && cnt == 0)
            prev <= 0;
        else if ( btn_input && ~prev)
            cnt <= cnt + 1;
        else if (~btn_input && cnt)
            cnt <= cnt - 1;
    end
endmodule


module h2a(
    input  [3:0] in,
    output [7:0] ascii);

    reg [7:0] out;
    assign ascii = out;

    always @(in) begin
        if (in > 9)
            out <= 8'h37 + in;
        else
            out <= 8'h30 | in;
    end
endmodule