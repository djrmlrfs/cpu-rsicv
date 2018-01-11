`ifndef _RESICV_MIN_SOPC
`define _RESICV_MIN_SOPC
`timescale 1ns/1ps
//zjdsxcpy

`include "Defines.vh"
`include "cpu.v"
`include "Inst_rom.v"
`include "Data_ram.v"

module Riscv_min_sopc(
	input wire clk,
	input wire rst
);

wire[`InstAddrBus]	instaddr;
wire[`InstBus]		inst;
wire				romce;
wire				ramwe;
wire[`RegBus]		ramrdata;
wire[`RegBus]		ramaddr;
wire[`RegBus]		ramwdata;
wire[3:0] 			ramsel;   
wire 				ramce; 

cpu cpu0(
	.clk(clk),
	.rst(rst),

	.rom_data_i(inst),
	.rom_ce_o(romce),
	.rom_addr_o(instaddr),

	.ram_r_data_i(ramrdata),
	.ram_addr_o(ramaddr),
	.ram_w_data_o(ramwdata),
	.ram_w_enable_o(ramwe),
	.ram_sel_o(ramsel),
	.ram_ce_o(ramce)
);

Inst_rom inst_rom0 (
	.ce(romce),
	.addr(instaddr),
	.inst(inst)
);

Data_ram data_ram0 (
	.clk(clk),
	.ce(ramce),
	.we(ramwe),
	.addr(ramaddr),
	.sel(ramsel),
	.data_i(ramwdata),
	.data_o(ramrdata)
);

endmodule

`endif