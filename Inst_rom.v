`ifndef _INST_ROM
`define _INST_ROM
//zjdsxcpy
`include "Defines.vh"

module Inst_rom (
	input wire					ce,
	input wire[`InstAddrBus]	addr,
	output	reg[`InstBus]		inst
);
//def arr size 'InstMemNum, width InstBus
reg[`InstBus]	inst_mem[0: `InstMemNum-1];

// initial with file inst_rom.data
initial	$readmemh("D:/Homework/txjg/CPU/test/instr.bin", inst_mem);
reg[`InstBus] inst_tmp;

always @ (*) begin
	if (!ce) begin
		inst = `ZeroWord;
	end else begin
		inst_tmp	=	inst_mem[addr[`InstMemNumLog2 + 1: 2]];
		inst		=	{inst_tmp[7:0], inst_tmp[15:8], inst_tmp[23:16], inst_tmp[31:24]};
	end
end

endmodule
`endif