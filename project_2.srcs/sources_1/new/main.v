`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/25/2024 03:41:20 PM
// Design Name: 
// Module Name: main
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

`include "uart_tx.v"
`include "uart_rx.v"

module main(
    input clk,
    output je8,   // output to RXD of pmod pins 
    input je9    // input from TXD of pmod pins 
    );
     
  // Zybo clk uses a 125 MHz (125 million cycles a second, 1cycle = 8ns) clock
  // Want to interface to 115200 baud (115200 bits per second) UART
  // 125000000 / 115200 = 1085 Cycles Per Bit. 1 second / 115200 = ~8600 nanoseconds per bit
  parameter c_CLOCK_PERIOD_NS = 8;
  parameter c_CLKS_PER_BIT    = 1085;
  parameter c_BIT_PERIOD      = 8600;
  
  reg r_Clock = 0;
  reg r_Tx_DV = 0;
  wire w_Tx_Done;
  reg [7:0] r_Tx_Byte = 0;
  wire [7:0] w_Rx_Byte;
 
 uart_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST
(.i_Clock(clk),
 .i_Rx_Serial(je9),
 .o_Rx_DV(),
 .o_Rx_Byte(w_Rx_Byte)
 );

uart_tx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_INST
(.i_Clock(clk),
 .i_Tx_DV(r_Tx_DV),
 .i_Tx_Byte(r_Tx_Byte),
 .o_Tx_Active(),
 .o_Tx_Serial(je8),
 .o_Tx_Done(w_Tx_Done)
 );

  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

parameter TX_START = 3'b001;
parameter TX_TEST = 3'b010;
parameter TX_WAIT = 3'b011;
parameter TX_END = 3'b000;
parameter TX_IDLE      = 3'b100;

reg [2:0]    state     = TX_START;
reg [2:0]    next_state     = TX_START;
reg [7:0]    r_Clock_Count = 0;
reg [7:0]    wait_clock = 0;


// this physical test is based on the simulation code at https://nandland.com/uart-serial-port-module/

always @(posedge clk) begin
    case (state)
        TX_START:
        begin
            // wait 2 clock cycles (16ns) before test, wait time is relative to current clk counter
            wait_clock <= r_Clock_Count + 2;  
            state <= TX_WAIT;
            next_state <= TX_TEST;
        end
        TX_WAIT:
        begin
            // switch to intended next_state after x amount of positive edge
            if (r_Clock_Count == wait_clock)   
                state <= next_state;
        end
        TX_TEST:
        begin
            // Data valid = 1
            // data payload = 0xAB, but i receive 0x00 on the computer
            r_Tx_DV <= 1'b1;
            r_Tx_Byte <= 8'hAB;
            wait_clock <= r_Clock_Count + 1;
            state <= TX_WAIT;
            next_state <= TX_END;
        end
        TX_END:
        begin
            r_Tx_DV <= 1'b0;    // Data valid = 0
            state <= TX_START;  // <= TX_IDLE
        end
        TX_IDLE:
        begin
            #1000;         // switch here in case I want to execute the test a limited number of times
        end
    endcase
    r_Clock_Count <= r_Clock_Count + 1;

end


    
endmodule
