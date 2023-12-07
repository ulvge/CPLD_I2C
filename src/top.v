`timescale 1ns/1ps
`include "src/io_deglitch.v"

module ns213_bmu_cpld_top
(
    input FPGA_CLK_50M,
    //input CPLD_RST_N,

    input CPLD_LED0_N,
    output CPLD_LED1_N,
    output CPLD_LED2_N,
    input CPLD_LED12_N,

    input BMC_GPIO0,
    input BMC_GPIO1,
    input BMC_GPIO2,
    input BMC_GPIO3,

    input GPIO_RSVD1,// unsed
    input GPIO_RSVD2,// unsed
    input QSPI_CSN0,
    
    output QSPI_CSN0_FPGA,
    output QSPI_CSN1_FPGA,
    
    input R_BMC_I2C_SCL1,
    inout R_BMC_I2C_SDA1,

    input R_BMC_PCIE_RST_N, // BMC_PCIE复位
    input R_BMC_PHY_RST_N, // PHY复位
    input R_BMC_RSTN_EXT,   // BMC复位
    output R_BMC_RSTN_FPGA,
    input R_CPU_POR_N,

    output USB_SWITCH_EN,

    output CPLD_DEBUG3,
    output CPLD_DEBUG4,

    input R_RESERVE0,
    input R_RESERVE1,
    input R_RESERVE2,
    input R_RESERVE3,
    input R_RESERVE4,
    input R_RESERVE5,
    input R_RESERVE6,
    input R_RESERVE7,
    input R_RESERVE8,
    input R_RESERVE9,
    input R_RESERVE10,
    input R_RESERVE11,
    input R_RESERVE12,
    input R_RESERVE13,
    input R_RESERVE14,
    input R_RESERVE15,
    input R_RESERVE16,
    input R_RESERVE17,
    input R_RESERVE18,
    input R_RESERVE19,

    input VCORE_EN,
    input P1V8_EN,
    input P1V1_EN,
    input P3V3_EN,
    input VCORE_PWRGD,
    input P1V8_PWRGD,
    input P3V3_PWRGD,
    input P1V1_PWRGD,


// PORT0
   inout R_FPGA_GPIO0,
    inout R_FPGA_GPIO1,
    inout R_FPGA_GPIO2,
    inout R_FPGA_GPIO3,
    inout R_FPGA_GPIO4,
    inout R_FPGA_GPIO5,
    inout R_FPGA_GPIO6,
    inout R_FPGA_GPIO7,

// PORT1
    inout R_FPGA_GPIO8,
    inout R_FPGA_GPIO9,
    inout R_FPGA_GPIO10,
    inout R_FPGA_GPIO11,
    inout R_FPGA_GPIO12,
    inout R_FPGA_GPIO13,
    inout R_FPGA_GPIO14,
    inout R_FPGA_GPIO15
);
    
	wire 	clk, rst_l;
    assign 	clk = FPGA_CLK_50M;
    assign 	rst_l = VCORE_EN;
    //assign 	rst_l = CPLD_RST_N;

    assign 	USB_SWITCH_EN = 1'b1;
    assign 	R_BMC_RSTN_FPGA = R_BMC_RSTN_EXT & R_CPU_POR_N;


    wire [7:0] PORT0;
    assign {R_FPGA_GPIO7,R_FPGA_GPIO6,R_FPGA_GPIO5,R_FPGA_GPIO4,
            R_FPGA_GPIO3,R_FPGA_GPIO2,R_FPGA_GPIO1,R_FPGA_GPIO0} = PORT0;
    wire [7:0] PORT1;
    assign {R_FPGA_GPIO15,R_FPGA_GPIO14,R_FPGA_GPIO13,R_FPGA_GPIO12,
            R_FPGA_GPIO11,R_FPGA_GPIO10,R_FPGA_GPIO9,R_FPGA_GPIO8} = PORT1;


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
