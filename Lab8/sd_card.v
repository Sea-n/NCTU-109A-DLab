`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: National Chiao Tung University
// Engineer: Cheng-Ju Lin
//
// Create Date:    15:05:48 08/27/2015 
// Module Name:    sd_card
//
// Description:    SD card host controller.
//
//     This SD card controller only reads data from the SD card.
//     An SD card is composed of many blocks. Each block is of 512 bytes.
//     Once we trigger the reading of a block by setting 'rd_req' to '1' and
//     'block_addr' to the block ID to read, the output port 'dout' will
//     return one byte of data from the block per clock cycle whenever the
//     flag 'sd_valid' is '1'.
//////////////////////////////////////////////////////////////////////////////////

module sd_card(
  /* spi signals */
  output cs,
  output sclk,
  output mosi,
  input  miso,

  /* SD controller signals */
  input  clk,
  input  rst,
  input  rd_req,               // "rd_req <= 1" triggers the reading of a block.
  input  [31:0] block_addr,    // The block number of the SD card to read.
  output reg init_finished,    // SD card initialization is finished?
  output reg [7:0] dout,       // Output one byte of data in the block.
  output reg sd_valid          // The output byte in "dout" is ready
);

/*FSM state*/
parameter RST                   = 5'd0 ;
parameter CARD_INIT_START       = 5'd1 ;
parameter SET_CMD0              = 5'd2 ;
parameter CHECK_CMD0_RESPONSE   = 5'd3 ;
parameter SET_CMD8              = 5'd4 ;
parameter CHECK_CMD8_RESPONSE   = 5'd5 ;
parameter SET_CMD55             = 5'd6 ;
parameter SET_ACMD41            = 5'd7 ;
parameter POLL_ACMD41           = 5'd8 ;
parameter CARD_READY            = 5'd9 ;
parameter SET_READ_CMD          = 5'd10;
parameter WAIT_READ_START       = 5'd11;
parameter READ_BLOCK            = 5'd12;
parameter READ_CRC              = 5'd13;
parameter SEND_COMMAND          = 5'd14;

parameter RECEIVE_RESPONSE_WAIT = 5'd15;
parameter RECEIVE_BYTE          = 5'd16;
parameter RESPONSE_ERROR        = 5'd17;

reg [4:0] c_state = RST;
reg [4:0] return_state;
reg cs_reg, sclk_reg;
reg [7:0] bit_counter;
reg [8:0] byte_counter;
reg rd_req_reg;
reg [31:0] block_addr_reg;

reg [55:0] cmd_out;
reg [7:0] recv_data;
reg [39:0] R7_response;

assign cs = cs_reg;
assign sclk = sclk_reg;
assign mosi = cmd_out[55];

always@(posedge clk)
begin
  if (rst) begin
    c_state <= RST;
    return_state <= RST;

    cs_reg <= 1'd1;
    sclk_reg <= 1'd0;
    sd_valid <= 1'd0;
    init_finished <= 1'd0;
    cmd_out <= 56'hFFFFFFFFFFFFFF;
    bit_counter <= 8'd0;
    byte_counter <= 9'd0;
    recv_data <= 8'd0;
    R7_response <= 40'd0;
    block_addr_reg <= 32'd0;
  end
  else begin
    case (c_state)
    RST:
    begin
      c_state <= CARD_INIT_START;
      return_state <= return_state;
      bit_counter <= 8'd160;
      init_finished <= 1'd0;
      cs_reg <= 1'd1;
      sclk_reg <= 1'd0;
    end

    CARD_INIT_START:  // wait 80 cycles
    begin
      if (bit_counter==0) begin
        c_state <= SET_CMD0;
        cs_reg <= 1'd0;
      end
      else begin
        bit_counter <= bit_counter - 8'd1;
        sclk_reg <= ~sclk_reg;
      end
    end

    SET_CMD0:
    begin
      c_state <= SEND_COMMAND;
      return_state <= CHECK_CMD0_RESPONSE;

      cmd_out <= 56'hFF400000000095;
      bit_counter <= 8'd55;
      cs_reg <= 1'd0;
    end

    CHECK_CMD0_RESPONSE:
    begin
      if (recv_data[0]==1) // Idle bit=1, this means SD card is in SPI mode
        c_state <= SET_CMD8;
      else
        c_state <= RESPONSE_ERROR;
    end
      
    SET_CMD8:
    begin
      c_state <= SEND_COMMAND;
      return_state <= CHECK_CMD8_RESPONSE;
                
      cmd_out <= {8'hFF,    2'b01, 6'b001000, 20'h00000, 4'b0001, 8'hAA,               8'h87};
//                    , start bit,   cmd idx,          ,     VHS, check pattern, crc7+endbit
      bit_counter <= 8'd55;
    end
      
    CHECK_CMD8_RESPONSE:
    begin
      if((R7_response[39:32]==8'h01) && (R7_response[11:8]==4'b0001) && (R7_response[7:0]==8'hAA))
        c_state <= SET_CMD55;
      else
        c_state <= RESPONSE_ERROR;
    end
      
    SET_CMD55:
    begin
      c_state <= SEND_COMMAND;
      return_state <= SET_ACMD41;
        
      cmd_out <= 56'hFF770000000001;
      bit_counter <= 8'd55;
    end
      
    SET_ACMD41:
    begin
      c_state <= SEND_COMMAND;
      return_state <= POLL_ACMD41;
        
      /* If SD card type is SDHC, HCS bit must set to 1 */
      cmd_out <= 56'hFF694000000001;
      bit_counter <= 8'd55;
    end
      
    POLL_ACMD41:
    begin
      if (recv_data[0] == 0) //IDLE bit=0 means SD card is ready to work.
        c_state <= CARD_READY;
      else
        c_state <= SET_CMD55;
    end

    CARD_READY:
    begin
      init_finished <= 1'd1;
      if (rd_req_reg == 1)
      begin
        c_state <= SET_READ_CMD;
        block_addr_reg <= block_addr;
      end
    end

    SET_READ_CMD:
    begin
      c_state <= SEND_COMMAND;
      return_state <= WAIT_READ_START;
        
      bit_counter <= 8'd55;
      cmd_out <= {8'hFF, 8'h51, block_addr_reg, 8'hFF};
    end

    WAIT_READ_START:
    begin
      sclk_reg <= ~sclk_reg;
      if (sclk_reg==1 && miso==0)
      begin
        /* start receive first byte of block */
        c_state <= RECEIVE_BYTE;  
        return_state <= READ_BLOCK;
          
        byte_counter <= 9'd511;
        bit_counter <= 8'd7;
      end
    end
      
    READ_BLOCK:
    begin
      sd_valid <= 1'd0;
      if (byte_counter==0)
      begin
        c_state <= RECEIVE_BYTE;
        return_state <= READ_CRC;
          
        bit_counter <= 8'd7;
      end
        
      else 
      begin
        c_state <= RECEIVE_BYTE;
        return_state <= READ_BLOCK;
          
        byte_counter <= byte_counter -8'd1;
        bit_counter <= 8'd7;
      end
    end
      
    READ_CRC:
    begin
      c_state <= RECEIVE_BYTE;
      return_state <= CARD_READY;

      sd_valid <= 1'd0;
      bit_counter <= 8'd7;
    end
      
    SEND_COMMAND:
    begin
      sclk_reg <= ~sclk_reg;
      if (sclk_reg==1)begin
        if (bit_counter==0)
          c_state <= RECEIVE_RESPONSE_WAIT;
        else begin
          bit_counter <= bit_counter -8'd1;
          cmd_out <= {cmd_out[54:0], 1'd1};
        end
      end        
    end
      
    RECEIVE_RESPONSE_WAIT:
    begin
      sclk_reg <= ~sclk_reg;
      /* response start bit always = 0 */
      if (sclk_reg==1) begin
        if (miso==0) begin
          recv_data <= 8'd0;
          c_state <= RECEIVE_BYTE;
          /* already read first bit */
          if (return_state == CHECK_CMD8_RESPONSE) begin
            bit_counter <= 8'd38;
            R7_response <= 40'd0;
          end
          else
            bit_counter <= 8'd6;
        end
      end
    end

    RECEIVE_BYTE:
    begin
      sclk_reg <= ~sclk_reg;
      if (sclk_reg == 1) begin
        recv_data <= {recv_data[6:0], miso};
        R7_response <= {R7_response[38:0], miso};
        if (bit_counter == 0) begin
          c_state <= return_state;
          /* Read SD card block data */
          if (return_state == READ_BLOCK) begin
            dout <= {recv_data[6:0], miso};
            sd_valid <= 1;
          end
        end
      else
        bit_counter <= bit_counter - 8'd1;
      end
    end

    RESPONSE_ERROR:
    begin
      c_state <= c_state;
      return_state <= return_state;
    end

    default:
    begin
      c_state <= RST;
      return_state <= return_state;
    end
    endcase
  end
end

always@(posedge clk)
begin
  if (rst)
    rd_req_reg <= 0;
  else if (c_state == SET_READ_CMD)
    rd_req_reg <= 1'd0;
  else if (rd_req == 1'd1)
    rd_req_reg <= 1'd1;
end

endmodule
