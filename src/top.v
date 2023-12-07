`timescale 1ns/1ps
`include "src/io_deglitch.v"

module NS213_BMU_cpld_top
(
    input CPLD_CLK_50M,
    input CPLD_RST_N,

    input SCL,
    inout SDA,

    output CPLD_DEBUG3,
    output CPLD_DEBUG4,

    input CPLD_LED0_N,
    output CPLD_LED1_N,
    output CPLD_LED2_N,
    input CPLD_LED12_N,

// PORT0
    inout BMC_GPIOA1,
    inout BMC_GPIOA2,
    inout BMC_GPIOA3,
    inout BMC_GPIOC0,

    inout BMC_GPIOC1,
    inout BMC_GPIOC2,
    inout BMC_GPIOC4,
    inout BMC_GPIOC5,
// PORT1
    inout BMC_GPIOC6,
    inout BMC_GPIOC7,
    inout BMC_GPIOD3,
    inout BMC_GPIOD6,

    inout BMC_GPIOG0,
    inout BMC_GPIOG1,
    inout BMC_GPIOG3,
    inout BMC_GPIOH0
);
    
	wire 	clk, rst_l;
    assign 	clk = CPLD_CLK_50M;
    assign 	rst_l = CPLD_RST_N;


    wire [7:0] PORT0;
    assign {BMC_GPIOC5, BMC_GPIOC4, BMC_GPIOC2, BMC_GPIOC1,
            BMC_GPIOC0, BMC_GPIOA3, BMC_GPIOA2, BMC_GPIOA1} = PORT0;
    wire [7:0] PORT1;
    assign {BMC_GPIOH0, BMC_GPIOG3, BMC_GPIOG1, BMC_GPIOG0, 
            BMC_GPIOD6, BMC_GPIOD3, BMC_GPIOC7, BMC_GPIOC6} = PORT1;


    wire [3:0] ledout;
    // bit 3,2,1,0
    assign {CPLD_LED2_N, CPLD_LED1_N, CPLD_DEBUG3, CPLD_DEBUG4} = ~ledout;

    // assign 	CPLD_DEBUG3 = SCL;
    // assign 	CPLD_DEBUG4 = SDA;
    i2c i2c_nca9555(
        .clk(clk),
        .SCL(SCL),
        .SDA(SDA),
        .RST(rst_l),
        .LEDG(ledout),
        .PORT0(PORT0),
        .PORT1(PORT1)
  );
  
endmodule
