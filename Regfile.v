`include "Defines.vh"
//zjdsxcpy
module Regfile(
	input wire clk,
	input wire rst,
	//w
	input wire				we,
	input wire[`RegAddrBus] waddr, 
	input wire[`RegBus]	 	wdata,
	//r1
	input wire				re1,
	input wire[`RegAddrBus] raddr1,
	output reg[`RegBus]		rdata1,
	//r2
	input wire				re2,
	input wire[`RegAddrBus] raddr2,
	output reg[`RegBus]	 	rdata2
);
//def 32 32reg
reg [`RegBus] regs[(1 << `RegAddrWidth) - 1 : 0];
initial begin
	regs[0] = `RegWidth'h0;
end

//w
always @ (posedge clk) begin
	if (!rst) begin
		if (we && waddr != `RegAddrWidth'h0)
			regs[waddr] <= wdata;
	end
end
//r1
always @ (*) begin
	if (rst) begin
		rdata1 <= `ZeroWord;
	end else if (re1 && raddr1 == waddr && we)
	   rdata1 <= wdata;
	else if (re1)
		rdata1 <= regs[raddr1];
	else
		rdata1 <= `ZeroWord;
end
//r2
always @ (*) begin
	if (rst) begin
		rdata2 <= `ZeroWord;
	end else if (re2 && raddr2 == waddr && we)
		rdata2 <= wdata;
	else if (re2)
		rdata2 <= regs[raddr2];
	else
		rdata2 <= `ZeroWord;
end

endmodule