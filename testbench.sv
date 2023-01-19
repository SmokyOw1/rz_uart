/*
 * Testbench for rz_uart
 */

`timescale 1ns/1ps

module testbench (
);

  localparam DATA_WIDTH = 8;

  logic                  reset_n;

  logic                  rx_p;
  logic                  rx_n;
  logic                  rx_valid;
  logic [DATA_WIDTH-1:0] rx_data;

  logic                  tx_clk;
  logic                  tx_valid;
  logic [DATA_WIDTH-1:0] tx_data;
  logic                  tx_p;
  logic                  tx_n;

  logic                  tb_tx_complete;
  logic                  tb_rx_complete;

  initial
    begin
      reset_n = 1'b0;
      #10;
      reset_n = 1'b1;
      #10;
      wait( tb_tx_complete & tb_rx_complete );
      $display( "Testbench succesfully completed!" );
      $finish;
    end



  // TX side

  logic                  tb_tx_valid;
  logic [DATA_WIDTH-1:0] tb_tx_data;

  initial
    begin
      tx_clk = 1'b0;
      forever
        #10 tx_clk <= ~tx_clk;
    end

  initial
    begin

      tx_valid       = 1'b0;
      tx_data        = {DATA_WIDTH{1'b0}};
      tb_tx_complete = 1'b0;

      wait( reset_n );

      for( int i = 0; i < 10; i = i + 1 )
        begin
          @( negedge tx_clk );
          tx_valid = 1'b1;
          tx_data  = $random;
          @( negedge tx_clk );
          tx_valid = 1'b0;
          wait( tb_tx_valid );
          assert( tx_data == tb_tx_data )
            $display( "[TX] Send 0x%X, recieved 0x%X", tx_data, tb_tx_data );
          else
            $error( "[TX] Error: send 0x%X, but recieved 0x%X", tx_data, tb_tx_data );
        end

      tb_tx_complete = 1'b1;

    end



  // RX side

  task send_bit;
    input real  period;
    input logic value;
    begin
      rx_p =  value;
      rx_n = ~value;
      #(period / 2.0);
      rx_p = 1'b0;
      rx_n = 1'b0;
      #(period / 2.0);
    end
  endtask

  real                   tb_rx_period;
  logic [DATA_WIDTH-1:0] tb_rx_data;

  initial
    begin

      rx_p           = 1'b0;
      rx_n           = 1'b0;
      tb_rx_complete = 1'b0;

      wait( reset_n );

      for( int i = 0; i < 10; i = i + 1 )
        begin
          tb_rx_period  = $abs( $random ) / 400000.0;
          tb_rx_data    = $random;
          send_bit( tb_rx_period, 1'b0 );
          for( int i = 0; i < DATA_WIDTH; i = i + 1 )
            send_bit( tb_rx_period, tb_rx_data[i] );
          send_bit( tb_rx_period, 1'b1 );
          wait( rx_valid );
          assert( rx_data == tb_rx_data )
            $display( "[RX] Send 0x%X, recieved 0x%X", tb_rx_data, rx_data );
          else
            $error( "[RX] Error: send 0x%X, but recieved 0x%X", tb_rx_data, rx_data );
        end

      tb_rx_complete = 1'b1;

    end



  rz_uart #(
    .DATA_WIDTH ( DATA_WIDTH )
  ) dut (
    .reset_n  ( reset_n  ),
    .rx_p     ( rx_p     ),
    .rx_n     ( rx_n     ),
    .rx_valid ( rx_valid ),
    .rx_data  ( rx_data  ),
    .tx_clk   ( tx_clk   ),
    .tx_valid ( tx_valid ),
    .tx_data  ( tx_data  ),
    .tx_p     ( tx_p     ),
    .tx_n     ( tx_n     )
  );

  rz_uart #(
    .DATA_WIDTH ( DATA_WIDTH )
  ) verif (
    .reset_n  ( reset_n        ),
    .rx_p     ( tx_p           ),
    .rx_n     ( tx_n           ),
    .rx_valid ( tb_tx_valid    ),
    .rx_data  ( tb_tx_data     ),
    .tx_clk   ( 1'b0           ),
    .tx_valid ( 1'b0           ),
    .tx_data  ( '0             ),
    .tx_p     (                ),
    .tx_n     (                )
  );

endmodule : testbench
