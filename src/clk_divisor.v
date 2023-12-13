`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    2022-9-13
// Design Name:    
// Module Name:    clk_divisor
// Project Name:   
// Target Device:  
// Tool versions:  
// Description:
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
module clk_divisor (sys_clk, clkout);
    input sys_clk;
    output wire clkout;
    
    //parameter high = 10416, low = 10416; //50M,->2.4Khz
    parameter high = 25000000, low = 25000000; //50M,->2.4Khz
    reg [31:0] count_r;
    reg q;
    always @ (posedge sys_clk)
        begin
            if (count_r < high) 
                begin
                    count_r <= count_r+1'b1;
                    q <= 1;
                end
            else if (count_r >= high+low-1) 
                begin
                    q <= 0;
                    count_r <= 1'b0;
                end
            else
                begin
                    count_r <= count_r+1'b1;
                    q <= 0;
                end
        end
    
    assign clkout = q;

endmodule
