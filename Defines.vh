`ifndef _Def
`define _Def
`define ID_BRANCHES
`define ID_JALR
//seldom used in fact
`define ZeroWord		32'h00000000
`define WriteEnable	1'b1
`define WriteDisable	1'b0
`define ReadEnable		1'b1
`define ReadDisable	1'b0
`define InstValid		1'b1 
`define InstInvalid	1'b0
`define InstAddrBus	31: 0
`define InstBus		31: 0
`define InstAddrWidth	32
`define InstMemNum		131071
`define InstMemNumLog2	17
`define ChipEnable		1'b1
`define ChipDisable	1'b0
// regfile
`define RegAddrBus		4: 0
`define RegAddrWidth	5
`define RegBus			31: 0
`define RegWidth		32
`define NOPRegAddr		5'b00000
// ram
`define DataAddrBus     31:0
`define DataBus         31:0
`define DataMemNum      131071
`define DataMemNumLog2  17
`define ByteWidth       7:0
//aluex
`define AluOpBus		10:0
`define AluOutSelBus	2:0

`define EX_ADD_OP		11'b00100110000
`define EX_SUB_OP 		11'b00100110001
`define EX_SLT_OP		11'b00100110100
`define EX_SLTU_OP		11'b00100110110
`define EX_XOR_OP		11'b00100111000
`define EX_OR_OP 		11'b00100111100
`define EX_AND_OP		11'b00100111110
`define EX_SLL_OP		11'b00100110010
`define EX_SRL_OP		11'b00100111010
`define EX_SRA_OP		11'b00100111011
`define EX_AUIPC_OP	11'b00101110000

`define EX_JAL_OP 		11'b11011110000
`define EX_JALR_OP		11'b11001110000
`define EX_BEQ_OP 		11'b11000110000
`define EX_BNE_OP 		11'b11000110010
`define EX_BLT_OP 		11'b11000111000
`define EX_BGE_OP 		11'b11000111010
`define EX_BLTU_OP		11'b11000111100
`define EX_BGEU_OP		11'b11000111110

`define EX_LB_OP 		11'b00000110000
`define EX_LH_OP 		11'b00000110010
`define EX_LW_OP 		11'b00000110100
`define EX_LBU_OP		11'b00000111000
`define EX_LHU_OP		11'b00000111010

`define EX_SB_OP		11'b01000110000
`define EX_SH_OP		11'b01000110010
`define EX_SW_OP		11'b01000110100

`define EX_NOP_OP		11'b00000000000

`define EX_RES_LOGIC	3'b001
`define EX_RES_SHIFT	3'b010
`define EX_RES_ARITH	3'b011
`define EX_RES_J_B  	3'b100
`define EX_RES_LD_ST	3'b101
`define EX_RES_NOP		3'b000
//id
`define PC_addr     5'h20

`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_JAL      7'b1101111
`define OP_JALR     7'b1100111
`define OP_BRANCH   7'b1100011
`define OP_LOAD     7'b0000011
`define OP_STORE    7'b0100011
`define OP_OPI		 7'b0010011
`define OP_OP       7'b0110011
`define OP_MISC_MEM 7'b0001111

`define FUNCT3_JALR 3'b000
`define FUNCT3_BEQ  3'b000
`define FUNCT3_BNE  3'b001
`define FUNCT3_BLT  3'b100
`define FUNCT3_BGE  3'b101
`define FUNCT3_BLTU 3'b110
`define FUNCT3_BGEU 3'b111
`define FUNCT3_LB   3'b000
`define FUNCT3_LH   3'b001
`define FUNCT3_LW   3'b010
`define FUNCT3_LBU  3'b100
`define FUNCT3_LHU  3'b101
`define FUNCT3_SB   3'b000
`define FUNCT3_SH   3'b001
`define FUNCT3_SW   3'b010

`define FUNCT3_ADDI      3'b000
`define FUNCT3_SLTI      3'b010
`define FUNCT3_SLTIU     3'b011
`define FUNCT3_XORI      3'b100
`define FUNCT3_ORI       3'b110
`define FUNCT3_ANDI      3'b111
`define FUNCT3_SLLI      3'b001
`define FUNCT3_SRLI_SRAI 3'b101

`define FUNCT3_ADD_SUB 3'b000
`define FUNCT3_SLL     3'b001
`define FUNCT3_SLT     3'b010
`define FUNCT3_SLTU    3'b011
`define FUNCT3_XOR     3'b100
`define FUNCT3_SRL_SRA 3'b101
`define FUNCT3_OR      3'b110
`define FUNCT3_AND     3'b111

`define FUNCT3_FENCE  3'b000
`define FUNCT3_FENCEI 3'b001

`define FUNCT7_SLLI 1'b0
`define FUNCT7_SRLI 1'b0
`define FUNCT7_SRAI 1'b1
`define FUNCT7_ADD  1'b0
`define FUNCT7_SUB  1'b1
`define FUNCT7_SLL  1'b0
`define FUNCT7_SLT  1'b0
`define FUNCT7_SLTU 1'b0
`define FUNCT7_XOR  1'b0

`define FUNCT7_SRL 1'b0
`define FUNCT7_SRA 1'b1
`define FUNCT7_OR  1'b0
`define FUNCT7_AND 1'b0

`endif