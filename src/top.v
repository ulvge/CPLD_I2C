`timescale 1ns/1ps
`include "src/io_deglitch.v"
`include "src/clk_divisor.v"

module ns213_bmu_cpld_top
(
    input FPGA_CLK_50M,
    //input CPLD_RST_N,

    output CPLD_LED0_N,
    output CPLD_LED1_N,
    output CPLD_LED2_N,

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

    output R_BMC_PCIE_RST_N, // BMC_PCIE复位
    output R_BMC_PHY_RST_N, // PHY复位
    input R_BMC_RSTN_EXT,   // BMC复位
    output R_BMC_RSTN_FPGA,
    output R_CPU_POR_N,

    output USB_SWITCH_EN,

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
    output R_RESERVE19,

    input VCORE_EN,
    output P1V8_EN,
    output P1V1_EN,
    output P3V3_EN,
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

	`define POR_BY_SOFT 1'b0
	`define DELAY_6MS	11'd6
	`define DELAY_10MS	11'd10 
	`define DELAY_50MS	11'd50 
	`define DELAY_400MS	11'd400 

	wire 	clk, rst_l;
	wire 	one_ms_pulse;
	wire 	one_s_pulse;
	wire 	one_us_pulse;
	wire 	ALL_PWRGD_w;

	wire 	timer_delay_VCORE_PWRGD;
	wire 	timer_delay_P1V8_PWRGD;
	wire 	timer_delay_P3V3_PWRGD;
	wire 	timer_delay_P1V1_PWRGD;
	wire 	timer_delay_400MS_P1V1_PWRGD;

    assign 	clk = FPGA_CLK_50M;
    assign 	rst_l = P1V8_PWRGD;
    //assign 	rst_l = CPLD_RST_N;
	assign 	cnt_en = 1'b1; 
	assign 	one_pulse = 1'b1;

    assign  QSPI_CSN0_FPGA = QSPI_CSN0;
    assign 	QSPI_CSN1_FPGA = 1'b1;
    assign 	USB_SWITCH_EN = 1'b1;
    assign 	R_BMC_RSTN_FPGA = R_BMC_RSTN_EXT;
    //assign 	R_BMC_RSTN_FPGA = 1'bz;//R_BMC_RSTN_EXT & R_CPU_POR_N;
    
    assign 	R_CPU_POR_N = timer_delay_400MS_P1V1_PWRGD;

	wire 	clk_divisor_out;

    wire [7:0] PORT0;
    assign {R_FPGA_GPIO7,R_FPGA_GPIO6,R_FPGA_GPIO5,R_FPGA_GPIO4,
            R_FPGA_GPIO3,R_FPGA_GPIO2,R_FPGA_GPIO1,R_FPGA_GPIO0} = PORT0;
    wire [7:0] PORT1;
    assign {R_FPGA_GPIO15,R_FPGA_GPIO14,R_FPGA_GPIO13,R_FPGA_GPIO12,
            R_FPGA_GPIO11,R_FPGA_GPIO10,R_FPGA_GPIO9,R_FPGA_GPIO8} = PORT1;


    wire [3:0] debug;
    // bit 3,2,1,0
    assign {R_RESERVE19, CPLD_LED2_N, CPLD_LED1_N, CPLD_LED0_N} = ~debug;
    // assign CPLD_LED0_N = !R_BMC_I2C_SCL1;
    // assign CPLD_LED1_N = !R_BMC_I2C_SDA1;
    // assign CPLD_LED2_N = !clk_divisor_out;
    
    i2c i2c_nca9555(
        .clk(clk),
        .SCL(R_BMC_I2C_SCL1),
        .SDA(R_BMC_I2C_SDA1),
        .RST(rst_l),
        .LEDG(debug),
        .PORT0(PORT0),
        .PORT1(PORT1)
    );
    

	clk_divisor clk_divisor_1s(
        .sys_clk(clk),
        .clkout(clk_divisor_out)
	);

// seqruce step
	assign	ALL_PWRGD_w = VCORE_EN;
	assign	P1V8_EN = timer_delay_VCORE_PWRGD;
	assign	P3V3_EN = timer_delay_P1V8_PWRGD;
	assign	P1V1_EN = timer_delay_P3V3_PWRGD;
`ifdef POR_BY_SOFT
	assign	R_BMC_PCIE_RST_N = timer_delay_P1V1_PWRGD;
	assign	R_BMC_PHY_RST_N = timer_delay_P1V1_PWRGD;
`else
	assign	R_BMC_PCIE_RST_N = 1'bz;
	assign	R_BMC_PHY_RST_N = 1'bz;
`endif
  
  //1 us timer
	timer_1us u_timer_1us(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(cnt_en),
	.cnt_pulse(one_pulse),
	.timeout(one_us_pulse)
	 );
//1 ms timer
	timer_1ms u_timer_1ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(cnt_en),
	.cnt_pulse(one_us_pulse),
	.timeout(one_ms_pulse)
	 );
  
//timer_delay_VCORE_PWRGD
	timer_n_ms u1_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & VCORE_PWRGD),
	.cnt_size(`DELAY_6MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_VCORE_PWRGD)
	 );	
//timer_delay_P1V8_PWRGD
	timer_n_ms u2_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P1V8_PWRGD),
	.cnt_size(`DELAY_6MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_P1V8_PWRGD)
	 );	
//timer_delay_P3V3_PWRGD
	timer_n_ms u3_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P3V3_PWRGD),
	.cnt_size(`DELAY_6MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_P3V3_PWRGD)
	 );	
//timer_delay_P1V1_PWRGD
	timer_n_ms u4_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P1V1_PWRGD),
	.cnt_size(`DELAY_10MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_P1V1_PWRGD)
	 );	

//timer_delay_400MS_P1V1_PWRGD
	timer_n_ms u41_timer_n_ms(
	.sys_clk(clk),
	.sys_rst_n(rst_l),
	.cnt_en(rst_l & P1V1_PWRGD),
	.cnt_size(`DELAY_400MS),
	.cnt_pulse(one_ms_pulse),
	.timeout(timer_delay_400MS_P1V1_PWRGD)
	 );
endmodule
