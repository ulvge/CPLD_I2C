`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    15:44:55 04/19/10
// Design Name:    
// Module Name:    timer_1s
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
//`include "timer_define.v"
module timer_1s(sys_clk, sys_rst_n, cnt_en, cnt_pulse, timeout);
    input sys_clk;
    input sys_rst_n;
    input cnt_en;
    input cnt_pulse;
    output timeout;

	 //*********************
    // Port Types        **
    //*********************

    wire sys_clk;
    wire sys_rst_n;
    wire cnt_en;
    wire count_pulse;
    wire timeout;

    //*********************
    //local signals      **								  
    //*********************

    reg[9:0] one_s_cntr;
	 `define COUNT_1S            10'd1000

    always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            one_s_cntr <= 10'b0;
        else if ((cnt_en == 1'b1) && (one_s_cntr == `COUNT_1S))
            one_s_cntr <= 10'b0;
        else if (cnt_en == 1'b0)    // Reset counter when counter enable is deasserted
            one_s_cntr <= 10'b0;
        else if ((cnt_en == 1'b1) && (cnt_pulse == 1'b1))
            one_s_cntr <= one_s_cntr + 1'b1;
    end

    assign timeout = (cnt_en == 1'b1) & (one_s_cntr == `COUNT_1S);

endmodule
