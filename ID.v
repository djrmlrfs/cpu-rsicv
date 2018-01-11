`ifndef _ID
`define _ID
//the most changed from the book aha
//and i think it will be much long
`include "Defines.vh"

module ID (
	input wire					rst,
	input wire[`InstAddrBus]	pc_i,
	input wire[`InstBus]		inst_i,	
	// read regfile
	input wire[`RegBus]		 	r1_data_i,
	input wire[`RegBus]		 	r2_data_i,
	output reg					r1_enable_o,
	output reg					r2_enable_o,
	output reg[`RegAddrBus]	 	r1_addr_o,
	output reg[`RegAddrBus]	 	r2_addr_o,
	// to exe
	output reg[`AluOpBus]		aluop_o,
	output reg[`AluOutSelBus]	alusel_o,
	output reg[`RegBus]		 	r1_data_o,
	output reg[`RegBus]		 	r2_data_o,
	output reg					w_enable_o,
	output reg[`RegAddrBus]	 	w_addr_o,
	// ex forwarding
	input wire					ex_pre_ld,
	input wire 					ex_w_enable_i,
	input wire[`RegAddrBus]		ex_w_addr_i,
	input wire[`RegBus]			ex_w_data_i,
    // mem forwarding
    input wire					me_w_enable_i,
	input wire[`RegAddrBus]		me_w_addr_i,
	input wire[`RegBus]			me_w_data_i,
	output wire					stall_req_o,
	output reg[`RegBus]			offset_o,
	// J&B
	output reg[`InstAddrBus]	pc_o,
	output reg					b_flag_o,
	output reg[`InstAddrBus]	b_target_addr_o
);

reg r1_stall_req;
reg r2_stall_req;
assign stall_req_o = r1_stall_req|r2_stall_req;

wire[4:0]		rd;
wire[4:0]		rs1;
wire[4:0]		rs2;
wire[2:0]		funct3;
wire			funct7;
wire[6:0]		opcode;
wire[11:0]		imm_I;
wire[11:0]		imm_S;
wire[31:0]		imm_B;
wire[31:0]	 	imm_U;
wire[31:0]		imm_J;

reg instvalid;
reg[`RegBus] imm;
reg pre_ld;

assign opcode		=	inst_i[6:0];
assign rd			=	inst_i[11:7];
assign funct3		=	inst_i[14:12];
assign rs1			=	inst_i[19:15];
assign rs2			=	inst_i[24:20];
assign imm_I		=	inst_i[31:20];
assign funct7		=	inst_i[30];
assign imm_S		=	{inst_i[31:25], inst_i[11:7]};
assign imm_B		=	{{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8],1'h0};
assign imm_U		=	{inst_i[31:12], 12'h0};
assign imm_J		=	{{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21],1'h0};
//ID_BRANCHES
`ifdef ID_BRANCHES
wire				lt_res;
wire				gt_res;
wire				eq_res;
assign lt_res = ((aluop_o == `EX_BLT_OP || aluop_o == `EX_BGE_OP)? $signed(r1_data_o) < $signed(r2_data_o):	r1_data_o < r2_data_o);
assign eq_res = (r1_data_o == r2_data_o);
`endif
//ID_JALR
`ifdef ID_JALR
wire[`RegBus] sum_res;
assign sum_res = r1_data_o + {{20{imm_I[11]}}, imm_I};
`endif

wire				b_flag;
wire[`InstAddrBus]	b_target_res;
assign b_target_res = (opcode==`OP_JAL)?imm_J+pc_i:imm_B+pc_i;


always @(*) begin
	case(opcode)
		`OP_JAL: begin
			b_flag_o		<=	1'b1;
			b_target_addr_o	<=	b_target_res;
		end
`ifdef ID_JALR
		`OP_JALR: begin
			b_flag_o		<=	1'b1;
			b_target_addr_o	<=	sum_res;
		end
`endif
`ifdef ID_BRANCHES
		`OP_BRANCH: begin
			case (funct3)
				`FUNCT3_BEQ: begin
					b_flag_o		<=	eq_res;
					b_target_addr_o	<=	b_target_res;
				end
				`FUNCT3_BNE: begin
					b_flag_o		<=	~eq_res;
					b_target_addr_o	<=	b_target_res;
				end
				`FUNCT3_BLT, `FUNCT3_BLTU: begin
					b_flag_o		<=	lt_res;
					b_target_addr_o	<=	b_target_res;
				end
				`FUNCT3_BGE, `FUNCT3_BGEU: begin
					b_flag_o		<=	~lt_res;
					b_target_addr_o	<=	b_target_res;
				end
				default: begin
					b_flag_o		<=	1'b0;
					b_target_addr_o	<=	`ZeroWord;
				end
			endcase
		end
`endif
		default: begin
			b_flag_o		<=	1'b0;
			b_target_addr_o	<=	`ZeroWord;
		end
	endcase
end

always @ (*) begin
	if (rst) begin
		aluop_o			<=	`EX_NOP_OP;
		alusel_o		<=	`EX_RES_NOP;
		r1_enable_o		<=	1'b0;
		r1_addr_o		<=	`NOPRegAddr;
		r2_enable_o		<=	1'b0;
		r2_addr_o		<=	`NOPRegAddr;
		w_enable_o		<= 	`WriteDisable;
		w_addr_o		<= 	`NOPRegAddr;
		instvalid		<=	`InstValid;
		imm 			<=	`ZeroWord;
		pre_ld	   	    <=	1'b0;
	end else begin
		pc_o			<=	pc_i;
		case(opcode)
			`OP_LUI: begin
				imm				<=	imm_U;
                w_addr_o        <=   rd;
                w_enable_o      <=  `WriteEnable;
                instvalid       <=  `InstValid;
				aluop_o			<=	`EX_OR_OP;
				alusel_o		<=	`EX_RES_LOGIC;
				r1_enable_o		<=	1'b0;
				r1_addr_o		<=	rs1;
				r2_enable_o		<=	1'b0;
				r2_addr_o		<=	rs2;
				pre_ld		    <=	1'b0;
			end
			`OP_AUIPC: begin
				imm				<=	imm_U;
				pre_ld		    <=	1'b0;
				aluop_o			<=	`EX_AUIPC_OP;
				alusel_o		<=	`EX_RES_ARITH;
				w_addr_o		<=	rd;
				r1_addr_o		<=	rs1;
				r2_addr_o		<=	rs2;
				instvalid		<=	`InstValid;
				w_enable_o		<=	`WriteEnable;
				r1_enable_o		<=	1'b0;
				r2_enable_o		<=	1'b0;
			end
			`OP_JAL: begin
				imm				<=	imm_J;
                pre_ld		    <=	1'b0;
                aluop_o			<=	`EX_JAL_OP;
				w_addr_o		<=	rd;
                alusel_o		<=	`EX_RES_J_B;
				r1_addr_o		<=	rs1;
				r2_addr_o		<=	rs2;
				instvalid		<=	`InstValid;
                w_enable_o		<=	`WriteEnable;
                r1_enable_o		<=	1'b0;
                r2_enable_o     <=  1'b0;
			end
			`OP_JALR: begin
				w_enable_o		<=	`WriteEnable;
				aluop_o			<=	`EX_JALR_OP;
				alusel_o		<=	`EX_RES_J_B;
				instvalid		<=	`InstValid;
				pre_ld		    <=	1'b0;
				r1_enable_o		<=	1'b1;
				r2_enable_o		<=	1'b0;
				r1_addr_o		<=	rs1;
				r2_addr_o		<=	rs2;
				imm				<=	{{20{imm_I[11]}}, imm_I};
				w_addr_o		<=	rd;
			end
			`OP_BRANCH: begin
				case(funct3)
					`FUNCT3_BEQ: begin
						aluop_o			<=	`EX_BEQ_OP;
						alusel_o		<=	`EX_RES_NOP;
						w_enable_o		<=	`WriteDisable;
                        w_addr_o        <=   `ZeroWord;
                        instvalid       <=   `InstValid;
						pre_ld		    <=	1'b0;
                        r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b1;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	imm_B;
					end
					`FUNCT3_BNE: begin
						pre_ld    		<=	1'b0;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b1;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	imm_B;
						aluop_o			<=	`EX_BNE_OP;
                        alusel_o        <=  `EX_RES_NOP;
						w_enable_o		<=	`WriteDisable;
						w_addr_o		<=	`ZeroWord;
						instvalid		<=	`InstValid;
					end
					`FUNCT3_BLT: begin
						pre_ld		    <=	1'b0;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b1;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	imm_B;
						aluop_o			<=	`EX_BLT_OP;
                        alusel_o        <=  `EX_RES_NOP;
						w_enable_o		<=	`WriteDisable;
						w_addr_o		<=	`ZeroWord;
						instvalid		<=	`InstValid;
					end
					`FUNCT3_BGE: begin
						pre_ld    		<=	1'b0;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b1;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	imm_B;
						aluop_o			<=	`EX_BGE_OP;
                        alusel_o        <=   `EX_RES_NOP;
						w_enable_o		<=	`WriteDisable;
						w_addr_o		<=	`ZeroWord;
						instvalid		<=	`InstValid;
					end
					`FUNCT3_BLTU: begin
						pre_ld		    <=	1'b0;
                        r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b1;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	imm_B;
						aluop_o			<=	`EX_BLTU_OP;
                        alusel_o        <=  `EX_RES_NOP;
						w_enable_o		<=	`WriteDisable;
						w_addr_o		<=	`ZeroWord;
						instvalid		<=	`InstValid;
					end
					`FUNCT3_BGEU: begin
						pre_ld		    <=	1'b0;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b1;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	imm_B;
						aluop_o			<=	`EX_BGEU_OP;
                        alusel_o        <=  `EX_RES_NOP;
						w_enable_o		<=	`WriteDisable;
						w_addr_o		<=	`ZeroWord;
						instvalid		<=	`InstValid;
					end
					default: begin
						pre_ld		    <=	1'b0;
						r1_enable_o		<=	1'b0;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	`NOPRegAddr;
						r2_addr_o		<=	`NOPRegAddr;
						imm 			<=	`ZeroWord;
						aluop_o			<=	`EX_NOP_OP;
                        alusel_o        <=  `EX_RES_NOP;
						w_enable_o		<= 	`WriteDisable;
						w_addr_o		<= 	`NOPRegAddr;
						instvalid		<=	`InstValid;
					end
				endcase
			end

			`OP_LOAD: begin
				case (funct3)
					`FUNCT3_LB: begin
                        w_addr_o        <=  rd;
                        r1_addr_o       <=  rs1;
                        r2_addr_o       <=  rs2;
						pre_ld		    <=	1'b1;
						r1_enable_o		<=	1'b1;
                        r2_enable_o     <=  1'b0;
						aluop_o			<=	`EX_LB_OP;
						alusel_o		<=	`EX_RES_LD_ST;
						w_enable_o		<=	`WriteEnable;
						instvalid		<=	`InstValid;
						imm				<=	{{20{imm_I[11]}}, imm_I[11: 0]};
					end 
					
					`FUNCT3_LH: begin
						w_addr_o		<=	rd;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						pre_ld		    <=	1'b1;
						r1_enable_o		<=	1'b1;
                        r2_enable_o     <=  1'b0;
						aluop_o			<=	`EX_LH_OP;
                        alusel_o        <=  `EX_RES_LD_ST;
						w_enable_o		<=	`WriteEnable;
						instvalid		<=	`InstValid;
        				imm				<=	{{20{imm_I[11]}}, imm_I[11: 0]};
					end
					`FUNCT3_LW: begin
						w_addr_o		<=	rd;
						r1_addr_o		<=	rs1;
                        r2_addr_o       <=  rs2;
						pre_ld		    <=	1'b1;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
                        aluop_o			<=	`EX_LW_OP;
                        alusel_o        <=  `EX_RES_LD_ST;
						w_enable_o		<=	`WriteEnable;
						instvalid		<=	`InstValid;
						imm				<=	{{20{imm_I[11]}}, imm_I[11: 0]};
					end
					`FUNCT3_LBU: begin
						w_addr_o		<=	rd;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
					    pre_ld		    <=	1'b1;
						r1_enable_o		<=	1'b1;
                        r2_enable_o     <=  1'b0;
						aluop_o			<=	`EX_LBU_OP;
                        alusel_o        <=  `EX_RES_LD_ST;
						w_enable_o		<=	`WriteEnable;
						instvalid		<=	`InstValid;
						imm				<=	{{20{imm_I[11]}}, imm_I[11: 0]};
					end

					`FUNCT3_LHU: begin
						w_addr_o		<=	rd;
                        r1_addr_o       <=  rs1;
                        r2_addr_o       <=  rs2;
						pre_ld    		<=	1'b1;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
						aluop_o			<=	`EX_LHU_OP;
                        alusel_o        <=  `EX_RES_LD_ST;
						w_enable_o		<=	`WriteEnable;
						instvalid		<=	`InstValid;
						imm				<=	{{20{imm_I[11]}}, imm_I[11: 0]};

					end
					default: begin
						w_addr_o		<= 	`NOPRegAddr;
                        r1_addr_o       <=  `NOPRegAddr;
                        r2_addr_o       <=  `NOPRegAddr;
						pre_ld    		<=	1'b0;
						r1_enable_o		<=	1'b0;
						r2_enable_o		<=	1'b0;
						aluop_o			<=	`EX_NOP_OP;
                        alusel_o        <=  `EX_RES_NOP;
                        w_enable_o		<= 	`WriteDisable;
						instvalid		<=	`InstValid;
						imm 			<=	`ZeroWord;
					end 
				endcase
			end
			`OP_STORE: begin
				case (funct3)
				  	`FUNCT3_SB: begin
						w_addr_o		<=	rd;
                        r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						pre_ld		    <=	1'b0;
                        r1_enable_o     <=  1'b1;
                        r2_enable_o     <=  1'b1;
						aluop_o			<=	`EX_SB_OP;
                        alusel_o        <=  `EX_RES_LD_ST;
                        w_enable_o		<=	`WriteDisable;
						instvalid		<=	`InstValid;
						imm				<=	{{20{imm_S[11]}}, imm_S[11: 0]};
					end

					`FUNCT3_SH: begin
						w_addr_o		<=	rd;
                        r1_addr_o       <=  rs1;
                        r2_addr_o       <=  rs2;
                        pre_ld          <=  1'b0;
                        r1_enable_o     <=  1'b1;
                        r2_enable_o     <=  1'b1;
                        aluop_o         <=  `EX_SH_OP;
                        alusel_o        <=  `EX_RES_LD_ST;
                        w_enable_o      <=  `WriteDisable;
                        instvalid       <=  `InstValid;
                        imm             <=  {{20{imm_S[11]}}, imm_S[11: 0]};
					end

					`FUNCT3_SW: begin
						w_addr_o		<=	rd;
                        r1_addr_o       <=  rs1;
                        r2_addr_o       <=  rs2;
                        pre_ld          <=  1'b0;
                        r1_enable_o     <=  1'b1;
                        r2_enable_o     <=  1'b1;
                        aluop_o         <=  `EX_SW_OP;
                        alusel_o        <=  `EX_RES_LD_ST;
                        w_enable_o      <=  `WriteDisable;
                        instvalid       <=  `InstValid;
                        imm             <=  {{20{imm_S[11]}}, imm_S[11: 0]};
					end

				  	default: begin
						w_addr_o		<= 	`NOPRegAddr;
                        r1_addr_o       <=  `NOPRegAddr;
                        r2_addr_o       <=  `NOPRegAddr;
						pre_ld		    <=	1'b0;
						r1_enable_o		<=	1'b0;
                        r2_enable_o     <=  1'b0;
						aluop_o			<=	`EX_NOP_OP;
						alusel_o		<=	`EX_RES_NOP;
						w_enable_o		<= 	`WriteDisable;
						instvalid		<=	`InstValid;
						imm 			<=	`ZeroWord;
					end
				endcase
			end
			`OP_OPI: begin
				case(funct3)
					`FUNCT3_ADDI: begin
						aluop_o			<=	`EX_ADD_OP;
						alusel_o		<=	`EX_RES_ARITH;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	{{20{imm_I[11]}}, imm_I[11: 0]};
						w_enable_o		<=	`WriteEnable;
						w_addr_o		<=	rd;
						instvalid		<=	`InstValid;
						pre_ld		<=	1'b0;
					end

					`FUNCT3_SLTI: begin
						aluop_o			<=	`EX_SLT_OP;
						alusel_o		<=	`EX_RES_ARITH;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	{{20{imm_I[11]}}, imm_I[11: 0]};
						w_enable_o		<=	`WriteEnable;
						w_addr_o		<=	rd;
						instvalid		<=	`InstValid;
						pre_ld		    <=	1'b0;
					end

					`FUNCT3_SLTIU: begin
						aluop_o			<=	`EX_SLTU_OP;
						alusel_o		<=	`EX_RES_ARITH;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	{{20{imm_I[11]}}, imm_I[11: 0]};	
						w_enable_o		<=	`WriteEnable;
						w_addr_o		<=	rd;
						instvalid		<=	`InstValid;
						pre_ld		    <=	1'b0;
					end
					
					`FUNCT3_XORI: begin
						aluop_o			<=	`EX_XOR_OP;
						alusel_o		<=	`EX_RES_LOGIC;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	{20'h0, imm_I};
						w_enable_o		<=	`WriteEnable;
						w_addr_o		<=	rd;
						instvalid		<=	`InstValid;
						pre_ld		    <=	1'b0;
					end

					`FUNCT3_ORI: begin//aha 
						aluop_o			<=	`EX_OR_OP;
						alusel_o		<=	`EX_RES_LOGIC;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	{20'h0, imm_I};
						w_enable_o		<=	`WriteEnable;
						w_addr_o		<=	rd;
						instvalid		<=	`InstValid;
						pre_ld		    <=	1'b0;
					end

					`FUNCT3_ANDI: begin
						aluop_o			<=	`EX_AND_OP;
						alusel_o		<=	`EX_RES_LOGIC;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	{20'h0, imm_I};
						w_enable_o		<=	`WriteEnable;
						w_addr_o		<=	rd;
						instvalid		<=	`InstValid;
						pre_ld	        <=	1'b0;
					end
					
					`FUNCT3_SLLI: begin
						aluop_o			<=	`EX_SLL_OP;
						alusel_o		<=	`EX_RES_SHIFT;
						r1_enable_o		<=	1'b1;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	rs1;
						r2_addr_o		<=	rs2;
						imm				<=	{27'h0, rs2};
						w_enable_o		<=	`WriteEnable;
						w_addr_o		<=	rd;
						instvalid		<=	`InstValid;
						pre_ld		    <=	1'b0;
					end
					
					`FUNCT3_SRLI_SRAI: begin
						case (funct7)
							`FUNCT7_SRLI: begin
								aluop_o		<=	`EX_SRL_OP;
								alusel_o	<=	`EX_RES_SHIFT;
								r1_enable_o	<=	1'b1;
								r2_enable_o	<=	1'b0;
								r1_addr_o	<=	rs1;
								r2_addr_o	<=	rs2;
								imm			<=	{27'h0, rs2};
								w_enable_o	<=	`WriteEnable;
								w_addr_o	<=	rd;
								instvalid	<=	`InstValid;
								pre_ld	    <=	1'b0;
							end

							`FUNCT7_SRAI: begin
								aluop_o		<=	`EX_SRA_OP;
								alusel_o	<=	`EX_RES_SHIFT;
								r1_enable_o	<=	1'b1;
								r2_enable_o	<=	1'b0;
								r1_addr_o	<=	rs1;
								r2_addr_o	<=	rs2;
								imm			<=	{27'h0, rs2};
								w_enable_o	<=	`WriteEnable;
								w_addr_o	<=	rd;
								instvalid	<=	`InstValid;
								pre_ld	    <=	1'b0;
							end

						 	default: begin
								aluop_o		<=	`EX_NOP_OP;
								alusel_o	<=	`EX_RES_NOP;
								r1_enable_o	<=	1'b0;
								r2_enable_o	<=	1'b0;
								r1_addr_o	<=	`NOPRegAddr;
								r2_addr_o	<=	`NOPRegAddr;
								w_enable_o	<= 	`WriteDisable;
								w_addr_o	<= 	`NOPRegAddr;
								instvalid	<=	`InstValid;
								imm 	    <=	`ZeroWord;
								pre_ld		<=	1'b0;
							end
						endcase
					end

					default: begin
						aluop_o			<=	`EX_NOP_OP;
						alusel_o		<=	`EX_RES_NOP;
						r1_enable_o		<=	1'b0;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	`NOPRegAddr;
						r2_addr_o		<=	`NOPRegAddr;
						w_enable_o		<= 	`WriteDisable;
						w_addr_o		<= 	`NOPRegAddr;
						instvalid		<=	`InstValid;
						imm 			<=	`ZeroWord;
						pre_ld		    <=	1'b0;
					end
				endcase
			end
			
			`OP_OP: begin
				case (funct3)
					`FUNCT3_ADD_SUB: begin
						case (funct7)
							`FUNCT7_ADD: begin
								aluop_o		<=	`EX_ADD_OP;
								alusel_o	<=	`EX_RES_ARITH;
								r1_enable_o	<=	1'b1;
								r2_enable_o	<=	1'b1;
								r1_addr_o	<=	rs1;
								r2_addr_o	<=	rs2;
								imm			<=	`ZeroWord;
								w_enable_o	<=	`WriteEnable;
								w_addr_o	<=	rd;
								instvalid	<=	`InstValid;
								pre_ld	    <=	1'b0;
							end

							`FUNCT7_SUB: begin
								aluop_o		<=	`EX_SUB_OP;
								alusel_o	<=	`EX_RES_ARITH;
								r1_enable_o	<=	1'b1;
								r2_enable_o	<=	1'b1;
								r1_addr_o	<=	rs1;
								r2_addr_o	<=	rs2;
								imm			<=	`ZeroWord;
								w_enable_o	<=	`WriteEnable;
								w_addr_o	<=	rd;
								instvalid	<=	`InstValid;
								pre_ld	    <=	1'b0;
							end
							default: begin
								aluop_o			<=	`EX_NOP_OP;
								alusel_o		<=	`EX_RES_NOP;
								r1_enable_o		<=	1'b0;
								r2_enable_o		<=	1'b0;
								r1_addr_o		<=	`NOPRegAddr;
								r2_addr_o		<=	`NOPRegAddr;
								w_enable_o		<= 	`WriteDisable;
								w_addr_o		<= 	`NOPRegAddr;
								instvalid		<=	`InstValid;
								imm 			<=	`ZeroWord;
								pre_ld		    <=	1'b0;
							end
						endcase
					end

					`FUNCT3_SLL: begin
						imm			<=	`ZeroWord;
                        aluop_o		<=	`EX_SLL_OP;
						alusel_o	<=	`EX_RES_SHIFT;
						r1_enable_o	<=	1'b1;
						r2_enable_o	<=	1'b1;
						r1_addr_o	<=	rs1;
						r2_addr_o	<=	rs2;
						w_enable_o	<=	`WriteEnable;
						w_addr_o	<=	rd;
						instvalid	<=	`InstValid;
						pre_ld	<=	1'b0;
					end

					`FUNCT3_SLT: begin
						aluop_o		<=	`EX_SLT_OP;
						alusel_o	<=	`EX_RES_ARITH;
						r1_enable_o	<=	1'b1;
						r2_enable_o	<=	1'b1;
						r1_addr_o	<=	rs1;
						r2_addr_o	<=	rs2;
						imm			<=	`ZeroWord;
						w_enable_o	<=	`WriteEnable;
						w_addr_o	<=	rd;
						instvalid	<=	`InstValid;
						pre_ld	    <=	1'b0;
					end

					`FUNCT3_SLTU: begin
						imm			<=	`ZeroWord;
						pre_ld	    <=	1'b0;
						aluop_o		<=	`EX_SLTU_OP;
						w_addr_o	<=	rd;
						alusel_o	<=	`EX_RES_ARITH;
						r1_addr_o	<=	rs1;
                        r2_addr_o   <=  rs2;
						instvalid	<=	`InstValid;
                        w_enable_o  <=  `WriteEnable;
						r1_enable_o	<=	1'b1;
						r2_enable_o	<=	1'b1;
					end
					
					`FUNCT3_XOR: begin
						aluop_o		<=	`EX_XOR_OP;
						alusel_o	<=	`EX_RES_LOGIC;
						r1_addr_o	<=	rs1;
                        r2_addr_o   <=  rs2;
						r1_enable_o	<=	1'b1;
						r2_enable_o	<=	1'b1;
						imm			<=	`ZeroWord;
						pre_ld	    <=	1'b0;
						w_addr_o	<=	rd;
						w_enable_o	<=	`WriteEnable;
						instvalid	<=	`InstValid;
					end
					
					`FUNCT3_SRL_SRA: begin
					   case (funct7)
                            `FUNCT7_SRL: begin
                                imm			<=	`ZeroWord;
                                pre_ld	    <=	1'b0;
                                aluop_o		<=	`EX_SRL_OP;
                                alusel_o	<=	`EX_RES_SHIFT;
                                r1_enable_o	<=	1'b1;
                                r2_enable_o	<=	1'b1;
                                r1_addr_o	<=	rs1;
                                r2_addr_o	<=	rs2;
                                w_addr_o	<=	rd;
                                w_enable_o	<=	`WriteEnable;
                                instvalid	<=	`InstValid;
                            end
    
                            `FUNCT7_SRA: begin
                                imm			<=	`ZeroWord;
                                pre_ld	    <=	1'b0;
                                aluop_o		<=	`EX_SRA_OP;
                                alusel_o	<=	`EX_RES_SHIFT;
                                r1_enable_o	<=	1'b1;
                                r2_enable_o	<=	1'b1;
                                r1_addr_o	<=	rs1;
                                r2_addr_o	<=	rs2;
                                w_addr_o	<=	rd;
                                w_enable_o	<=	`WriteEnable;
                                instvalid	<=	`InstValid;
                            end

							default: begin
								imm 			<=	`ZeroWord;
                                pre_ld          <=  1'b0;
								aluop_o			<=	`EX_NOP_OP;
								alusel_o		<=	`EX_RES_NOP;
								r1_enable_o		<=	1'b0;
								r2_enable_o		<=	1'b0;
								r1_addr_o		<=	`NOPRegAddr;
								r2_addr_o		<=	`NOPRegAddr;
								w_addr_o		<= 	`NOPRegAddr;
								w_enable_o		<= 	`WriteDisable;
								instvalid		<=	`InstValid;
							end
                        endcase
					end
					
					`FUNCT3_OR: begin
						imm			<=	`ZeroWord;
                        pre_ld      <=  1'b0;
						aluop_o		<=	`EX_OR_OP;
						alusel_o	<=	`EX_RES_LOGIC;
						r1_enable_o	<=	1'b1;
						r2_enable_o	<=	1'b1;
						r1_addr_o	<=	rs1;
						r2_addr_o	<=	rs2;
						w_enable_o	<=	`WriteEnable;
						w_addr_o	<=	rd;
						instvalid	<=	`InstValid;
					end

					`FUNCT3_AND: begin
						imm			<=	`ZeroWord;
						pre_ld	    <=	1'b0;
						aluop_o		<=	`EX_AND_OP;
						alusel_o	<=	`EX_RES_LOGIC;
						r1_enable_o	<=	1'b1;
						r2_enable_o	<=	1'b1;
						r1_addr_o	<=	rs1;
						r2_addr_o	<=	rs2;
						w_enable_o	<=	`WriteEnable;
						w_addr_o	<=	rd;
						instvalid	<=	`InstValid;
					end
					
					default: begin
						imm 			<=	`ZeroWord;
						pre_ld		    <=	1'b0;
						aluop_o			<=	`EX_NOP_OP;
						alusel_o		<=	`EX_RES_NOP;
						r1_enable_o		<=	1'b0;
						r2_enable_o		<=	1'b0;
						r1_addr_o		<=	`NOPRegAddr;
						r2_addr_o		<=	`NOPRegAddr;
						w_enable_o		<= 	`WriteDisable;
						w_addr_o		<= 	`NOPRegAddr;
						instvalid		<=	`InstValid;
					end
				endcase
			end
			
			default: begin
				imm			<=	`ZeroWord;
                pre_ld      <=  1'b0;                
				aluop_o		<=	`EX_NOP_OP;
				alusel_o	<=	`EX_RES_NOP;
				r1_enable_o	<=	1'b0;
				r2_enable_o	<=	1'b0;
				r1_addr_o	<=	rs1;
				r2_addr_o	<=	rs2;
				w_enable_o	<= 	`WriteDisable;
				w_addr_o	<= 	rd;
				instvalid	<=	`InstInvalid;
			end
		endcase
	end
end
/*  writing cpu is so fun
    the only problem is my head feels cold
*/ 
always @ (*) begin
	if (rst) begin
		r1_data_o		<=	`ZeroWord;
		r1_stall_req	<= 1'b0;
	end else if (r1_enable_o && ex_pre_ld && ex_w_addr_i == r1_addr_o)
		r1_stall_req	<= 1'b1;
	else if (r1_enable_o && ex_w_enable_i && ex_w_addr_i == r1_addr_o) begin
		r1_data_o		<=	ex_w_data_i;
		r1_stall_req	<= 1'b0;
	end	else if (r1_enable_o && me_w_enable_i && me_w_addr_i == r1_addr_o) begin
		r1_data_o		<=	me_w_data_i;
		r1_stall_req	<= 1'b0;
	end	else if (r1_enable_o) begin
		r1_data_o		<=	r1_data_i;
		r1_stall_req	<= 1'b0;
	end else if (!r1_enable_o) begin
		r1_data_o		<=	imm;
		r1_stall_req	<= 1'b0;
	end else begin
		r1_data_o	<=	`ZeroWord;
		r1_stall_req	<= 1'b0;
	end
end

always @ (*) begin
	if (rst) begin
		r2_data_o		<=	`ZeroWord;
		r2_stall_req	<=	1'b0;
	end else if (r2_enable_o && ex_pre_ld && ex_w_addr_i == r2_addr_o) begin
		r2_stall_req	<=	1'b1;
	end	else if (r2_enable_o && ex_w_enable_i && ex_w_addr_i == r2_addr_o) begin
		r2_data_o 		<=	ex_w_data_i;
		r2_stall_req	<=	1'b0;
	end	else if (r2_enable_o && me_w_enable_i && me_w_addr_i == r2_addr_o) begin
		r2_data_o		<=	me_w_data_i;
		r2_stall_req	<=	1'b0;
	end	else if (r2_enable_o) begin
		r2_data_o		<=	r2_data_i;
		r2_stall_req	<=	1'b0;
	end	else if (!r2_enable_o) begin
		r2_data_o		<=	imm;
		r2_stall_req	<=	1'b0;
	end else begin
		r2_data_o		<=	`ZeroWord;
		r2_stall_req	<=	1'b0;
	end	
end

always @ (*) begin
	if (rst) begin
		offset_o	<=	`ZeroWord;
	end else begin
		offset_o	<=	imm;
	end
end

endmodule

`endif