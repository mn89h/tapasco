`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2016 02:45:51 PM
// Design Name: 
// Module Name: tb
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


module tb(

    );
  wire [31:0]io_deq_bits;
  wire io_deq_valid;
  wire clk;
  wire rst;
  reg deq_ready;
  reg [31:0] cnt;
  initial cnt = 'd0;
  initial deq_ready = 'b0;

  design_1_wrapper inst(
    .io_deq_bits( io_deq_bits ),
    .io_deq_valid( io_deq_valid ),
    .clk( clk ),
    .reset( rst ),
    .io_deq_ready( deq_ready )
  );
  
  initial begin
    inst.design_1_i.processing_system7_bfm_0.inst.pre_load_mem_from_file(
      "preload_ddr.txt", 32'h0010_0000, 640*480*2
    );
  end
  
  reg started;
  initial started = 'b0;
  initial begin
    repeat (100) @(posedge clk);
    started = 'b1;
  end
    
  always @(posedge clk) begin
    if (deq_ready) begin
      cnt <= cnt + io_deq_valid;
      if (io_deq_valid) begin
        $display("#%d - received: 0x%08x", cnt, io_deq_bits);
      end
    end
  end
  
  always @(negedge rst) deq_ready <= 'b1;   
endmodule
