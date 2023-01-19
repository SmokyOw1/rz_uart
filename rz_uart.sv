/*
 * rz_uart module
 */

module rz_uart #(

  parameter DATA_WIDTH

)(       

  input  logic                  reset_n,

  input  logic                  rx_p,
  input  logic                  rx_n,
  output logic                  rx_valid,
  output logic [DATA_WIDTH-1:0] rx_data,

  input  logic                  tx_clk,
  input  logic                  tx_valid,
  input  logic [DATA_WIDTH-1:0] tx_data,
  output logic                  tx_p,
  output logic                  tx_n

);

  // RX clock recovery

  logic rx_clk;

  always_comb
    rx_clk = rx_p ^ rx_n;

  // RX bit latch

  logic rx_bit;

  always_latch
    if( rx_p )
      rx_bit <= 1'b1;
    else if( rx_n )
      rx_bit <= 1'b0;

  // RX deserializer

  localparam [DATA_WIDTH:0] RX_START = {(DATA_WIDTH+1){1'b0}};
  localparam [DATA_WIDTH:0] RX_STOP  = {(DATA_WIDTH+1){1'b1}};

  logic [DATA_WIDTH-1:0] rx_shift;
  logic   [DATA_WIDTH:0] rx_state;

  always_ff @( negedge rx_clk or negedge reset_n )
    if( !reset_n )
      begin

        rx_valid <= 1'b0;
        rx_data  <= {DATA_WIDTH{1'b0}};
        rx_shift <= {(DATA_WIDTH-1){1'b0}};
        rx_state <= RX_START;

      end
    else
      begin

        case( rx_state )

          RX_START :
            begin
              rx_valid <= 1'b0;
              rx_state <= { !rx_bit, rx_state[DATA_WIDTH:1] };
            end

          RX_STOP : 
            begin
              rx_valid <= rx_bit;
              rx_data  <= rx_shift;
              rx_state <= RX_START;
            end

          default :
            begin
              rx_shift <= { rx_bit, rx_shift[DATA_WIDTH-1:1] };
              rx_state <= { 1'b1, rx_state[DATA_WIDTH:1] };
            end

        endcase

      end

  // TX latch

  logic                  tx_valid_meta;
  logic                  tx_valid_latch;
  logic [DATA_WIDTH-1:0] tx_data_meta;
  logic [DATA_WIDTH-1:0] tx_data_latch;

  always_ff @( posedge tx_clk or negedge reset_n )
    if( !reset_n )
      begin

        tx_valid_meta  <= 1'b0;
        tx_valid_latch <= 1'b0;
        tx_data_meta   <= {DATA_WIDTH{1'b0}};
        tx_data_latch  <= {DATA_WIDTH{1'b0}};

      end
    else
      begin

        { tx_valid_latch, tx_valid_meta } <= { tx_valid_meta, tx_valid };
        { tx_data_latch,  tx_data_meta  } <= { tx_data_meta,  tx_data  };

      end

  // TX serializer

  localparam [DATA_WIDTH+1:0] TX_STOP  = {(DATA_WIDTH+2){1'b0}};
  localparam [DATA_WIDTH+1:0] TX_START = {(DATA_WIDTH+2){1'b1}};

  logic                  tx_en;
  logic                  tx_bit;
  logic [DATA_WIDTH+1:0] tx_shift;
  logic [DATA_WIDTH+1:0] tx_state;

  always_ff @( posedge tx_clk or negedge reset_n )
    if( !reset_n )
      begin

        tx_en    <= 1'b0;
        tx_bit   <= 1'b0;
        tx_shift <= {(DATA_WIDTH+2){1'b0}};
        tx_state <= RX_START;

      end
    else
      begin

        case( tx_state )

          TX_STOP :
            begin
              if( tx_valid_latch )
                begin
                  tx_shift <= { 1'b1, tx_data_latch, 1'b0 };
                  tx_state <= TX_START;
                end
              tx_en  <= 1'b0;
              tx_bit <= 1'b0;
            end

          default :
            begin
              tx_en    <= 1'b1;
              tx_bit   <=  tx_shift[0];
              tx_shift <= { 1'b0, tx_shift[DATA_WIDTH+1:1] };
              tx_state <= { 1'b0, tx_state[DATA_WIDTH+1:1] };
            end

        endcase

      end

  // TX output

  assign tx_p = ( tx_en ) ?  tx_bit & tx_clk : 1'b0;
  assign tx_n = ( tx_en ) ? ~tx_bit & tx_clk : 1'b0;

endmodule : rz_uart
