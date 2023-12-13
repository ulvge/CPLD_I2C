`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:  
// Design Name:    
// Module Name:    timer_1us
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
module timer_1us(sys_clk, sys_rst_n, cnt_en, cnt_pulse, timeout);
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
    wire cnt_pulse;
    wire timeout;

    //*********************
    //local signals      **								  
    //*********************
	 `define COUNT_1US		     6'd50
    reg[5:0] one_us_cntr;


    always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            one_us_cntr <= 6'b0;
        else if (cnt_en == 1'b0)    // Reset counter when counter enable is deasserted
            one_us_cntr <= 6'b0;
        else if ((cnt_en == 1'b1) && (one_us_cntr == `COUNT_1US))
            one_us_cntr <= 6'b0;
        else if ((cnt_en == 1'b1) && (cnt_pulse == 1'b1))
            one_us_cntr <= one_us_cntr + 1'b1;
        else
            one_us_cntr <= one_us_cntr;
    end

    assign timeout = (cnt_en == 1'b1) & (one_us_cntr == `COUNT_1US);

endmodule
