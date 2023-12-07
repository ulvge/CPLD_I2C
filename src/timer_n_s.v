`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:    16:32:30 04/19/10
// Design Name:    
// Module Name:    timer_n_s
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
module timer_n_s(sys_clk, sys_rst_n, cnt_en, cnt_size, cnt_pulse, timeout);
    input sys_clk;
    input sys_rst_n;
    input cnt_en;
    input [8:0] cnt_size;
    input cnt_pulse;
    output timeout;

	 //*********************
    // Port Types        **
    //*********************

    wire sys_clk;
    wire sys_rst_n;
    wire cnt_en;
    wire[8:0] cnt_size;
    wire cnt_pulse;
    wire timeout;

    //*********************
    // Local Signals     **
    //*********************

    reg[8:0]  prog_cntr;

    always@(posedge sys_clk or negedge sys_rst_n)
    begin
        if (sys_rst_n == 1'b0)
            prog_cntr <= 9'b0;
        else if (cnt_en == 1'b0)    // Reset counterm when counter enable is deasserted
            prog_cntr <= 9'b0;
        else if ((cnt_en == 1'b1) && (cnt_pulse == 1'b1) && !timeout)
            prog_cntr <= prog_cntr + 1'b1;
        else 
            prog_cntr <= prog_cntr;

    end

    assign timeout = (cnt_en == 1'b1) & (prog_cntr == cnt_size);


endmodule
