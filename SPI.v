`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:57:55 05/16/2021 
// Design Name: 
// Module Name:    SPI 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module SPI
#(parameter mode = 0)
(
input clock,
input reset,

// MOSI
input [7:0] data_into_sys,     // receive data into SPI System from 8-bit bus
input send_data,               // command to send data to slave
output reg data_out_valid,         // acknowledges that data is transmitted to slave and is ready to receive next byte

//MISO
output reg rx_data,            // acknowledges that data is received from slave
output reg [7:0] data_out_sys, // output data to 8-bit bus from SPI system

//interface
output reg spi_out_clock,
input data_in_master,          // receive data from slave
output reg data_out_master     // send data to slave

 );


reg rising_edge, falling_edge;
reg [7:0] mem;                         // to store system input data
reg spi_clock;                         //
reg [2:0] bit_count_rx, bit_count_tx;
reg [4:0] clock_edges; 
reg [2:0] spi_clock_count;            //
reg send_data_reg;


wire cpha, cpol;

assign cpha= (mode==1)|(mode==3);
assign cpol= (mode==2)|(mode==3);


// generating SPI CLOCK OUT OFF MASTER 
always@(posedge clock or negedge reset)
begin
if(reset)
begin
spi_clock        <= cpol;     // default value as clock polarity in idle state
rising_edge      <= 0;
falling_edge     <= 0;
clock_edges      <= 0;
spi_clock_count  <= 0;
data_out_valid   <= 0;
end

else begin
rising_edge      <= 0;
falling_edge     <= 0;
end

if(data_out_valid==1)
begin
clock_edges     <= 16;
spi_clock_count <= 0;
end

else if( clock_edges > 0)
begin
data_out_valid <= 0;
end

else if(spi_clock_count ==3)         // sample on the 4th clock pulse, input to the system to make it falling
begin          
rising_edge      <= 0;
falling_edge     <= 1;
clock_edges      <= clock_edges - 1;
spi_clock        <= ~ spi_clock;
end

else if(spi_clock_count ==1)          // sample on the 2th clock pulse, input to the system to make it rising
begin                 
rising_edge      <= 1;
falling_edge     <= 0;
clock_edges      <= clock_edges - 1;
spi_clock        <= ~ spi_clock;
end

spi_clock_count= spi_clock_count + 1;



data_out_valid <= 1;
end

//to store system input data internally
always@(posedge clock or negedge reset)
begin
if(reset)
begin
mem           <= 0; 
send_data_reg <=0;
end

else if(send_data)
begin
send_data_reg  <=1;
mem            <= data_into_sys;
end
end


// to transmit data to slave bit wise
always@(posedge clock or negedge reset)
begin

if(reset)
begin 
bit_count_tx      <= 7;
data_out_master   <= 0;
end

else
begin

if(data_out_valid)
bit_count_tx      <= 7;

else if(send_data & ~cpha)
begin
data_out_master <= mem[7];
bit_count_tx    <= 6;
end

else if((rising_edge & ~cpha)|(falling_edge & cpha))
begin
data_out_master  <= mem[bit_count_tx];
bit_count_tx     <= bit_count_tx - 1;
end
end
end


// to receive data from slave bit wise
always@(posedge clock or negedge reset)
begin

if(reset)
begin 
bit_count_rx      <= 7;
rx_data           <= 0;
end

else
begin

if(data_out_valid)
bit_count_rx      <= 7;

else if((rising_edge & ~cpha)|(falling_edge & cpha))
begin
data_out_sys[bit_count_rx]      <= data_in_master; 
bit_count_rx                    <= bit_count_rx - 1;
end
end
end


always @(posedge clock or  negedge reset)
  begin
    if (~reset)
    begin
      spi_out_clock <= cpol;
    end
    else
      begin
        spi_out_clock <= spi_clock;
      end 
  end
endmodule
