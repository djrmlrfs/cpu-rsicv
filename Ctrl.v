//zjdsxcpy
module Ctrl(
	input wire 			rst,
	input wire			if_req,
	input wire			id_req,
	input wire			ex_req,
	input wire			me_req,
	output reg[5:0]		stall
);

	always @ (*) begin
		if (rst) begin
			stall	<=	6'b000000;
		end else if (me_req)
			stall	<=	6'b011111;
		else if (ex_req)
			stall	<=	6'b001111;
		else if (id_req)
			stall	<=	6'b000111;
		else if (if_req)
			stall	<=	6'b000011;
		else 
			stall	<=	6'b000000;
	end

endmodule