module MyClockGen (
	input_clk_25MHz,
	clk_proc,
	clk_mem,
	locked
);
	input input_clk_25MHz;
	output wire clk_proc;
	output wire clk_mem;
	output wire locked;
	wire clkfb;
	(* FREQUENCY_PIN_CLKI = "25" *) (* FREQUENCY_PIN_CLKOP = "4.16667" *) (* FREQUENCY_PIN_CLKOS = "4.01003" *) (* ICP_CURRENT = "12" *) (* LPF_RESISTOR = "8" *) (* MFG_ENABLE_FILTEROPAMP = "1" *) (* MFG_GMCREF_SEL = "2" *) EHXPLLL #(
		.PLLRST_ENA("DISABLED"),
		.INTFB_WAKE("DISABLED"),
		.STDBY_ENABLE("DISABLED"),
		.DPHASE_SOURCE("DISABLED"),
		.OUTDIVIDER_MUXA("DIVA"),
		.OUTDIVIDER_MUXB("DIVB"),
		.OUTDIVIDER_MUXC("DIVC"),
		.OUTDIVIDER_MUXD("DIVD"),
		.CLKI_DIV(6),
		.CLKOP_ENABLE("ENABLED"),
		.CLKOP_DIV(128),
		.CLKOP_CPHASE(64),
		.CLKOP_FPHASE(0),
		.CLKOS_ENABLE("ENABLED"),
		.CLKOS_DIV(133),
		.CLKOS_CPHASE(97),
		.CLKOS_FPHASE(2),
		.FEEDBK_PATH("INT_OP"),
		.CLKFB_DIV(1)
	) pll_i(
		.RST(1'b0),
		.STDBY(1'b0),
		.CLKI(input_clk_25MHz),
		.CLKOP(clk_proc),
		.CLKOS(clk_mem),
		.CLKFB(clkfb),
		.CLKINTFB(clkfb),
		.PHASESEL0(1'b0),
		.PHASESEL1(1'b0),
		.PHASEDIR(1'b1),
		.PHASESTEP(1'b1),
		.PHASELOADREG(1'b1),
		.PLLWAKESYNC(1'b0),
		.ENCLKOP(1'b0),
		.LOCK(locked)
	);
endmodule
module DividerUnsigned (
	i_dividend,
	i_divisor,
	o_remainder,
	o_quotient
);
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	wire [31:0] dividend_stage [0:32];
	wire [31:0] remainder_stage [0:32];
	wire [31:0] quotient_stage [0:32];
	assign dividend_stage[0] = i_dividend;
	assign remainder_stage[0] = 32'd0;
	assign quotient_stage[0] = 32'd0;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 32; _gv_i_1 = _gv_i_1 + 1) begin : GEN_DIV
			localparam i = _gv_i_1;
			DividerOneIter iter(
				.i_dividend(dividend_stage[i]),
				.i_divisor(i_divisor),
				.i_remainder(remainder_stage[i]),
				.i_quotient(quotient_stage[i]),
				.o_dividend(dividend_stage[i + 1]),
				.o_remainder(remainder_stage[i + 1]),
				.o_quotient(quotient_stage[i + 1])
			);
		end
	endgenerate
	assign o_quotient = quotient_stage[32];
	assign o_remainder = remainder_stage[32];
endmodule
module DividerOneIter (
	i_dividend,
	i_divisor,
	i_remainder,
	i_quotient,
	o_dividend,
	o_remainder,
	o_quotient
);
	input wire [31:0] i_dividend;
	input wire [31:0] i_divisor;
	input wire [31:0] i_remainder;
	input wire [31:0] i_quotient;
	output wire [31:0] o_dividend;
	output wire [31:0] o_remainder;
	output wire [31:0] o_quotient;
	wire [31:0] next_remainder;
	assign next_remainder = (i_remainder << 1) | ((i_dividend >> 31) & 32'd1);
	wire lt;
	assign lt = next_remainder < i_divisor;
	assign o_quotient = (lt ? i_quotient << 1 : (i_quotient << 1) | 32'd1);
	assign o_remainder = (lt ? next_remainder : next_remainder - i_divisor);
	assign o_dividend = i_dividend << 1;
endmodule
module gp4 (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	input wire [3:0] gin;
	input wire [3:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [2:0] cout;
	assign cout[0] = gin[0] | (pin[0] & cin);
	assign cout[1] = gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)));
	assign cout[2] = gin[2] | (pin[2] & (gin[1] | (pin[1] & (gin[0] | (pin[0] & cin)))));
	assign pout = ((pin[0] & pin[1]) & pin[2]) & pin[3];
	assign gout = ((gin[3] | (pin[3] & gin[2])) | ((pin[3] & pin[2]) & gin[1])) | (((pin[3] & pin[2]) & pin[1]) & gin[0]);
endmodule
module gp8 (
	gin,
	pin,
	cin,
	gout,
	pout,
	cout
);
	input wire [7:0] gin;
	input wire [7:0] pin;
	input wire cin;
	output wire gout;
	output wire pout;
	output wire [6:0] cout;
	wire g_lo;
	wire p_lo;
	wire g_hi;
	wire p_hi;
	wire [2:0] c_lo;
	wire [2:0] c_hi;
	wire c_temp;
	gp4 lo(
		.gin(gin[3:0]),
		.pin(pin[3:0]),
		.cin(cin),
		.gout(g_lo),
		.pout(p_lo),
		.cout(c_lo)
	);
	assign c_temp = g_lo | (p_lo & cin);
	gp4 hi(
		.gin(gin[7:4]),
		.pin(pin[7:4]),
		.cin(c_temp),
		.gout(g_hi),
		.pout(p_hi),
		.cout(c_hi)
	);
	assign cout[2:0] = c_lo;
	assign cout[6:4] = c_hi;
	assign cout[3] = c_temp;
	assign pout = p_hi & p_lo;
	assign gout = g_hi | (p_hi & g_lo);
endmodule
module CarryLookaheadAdder (
	a,
	b,
	cin,
	sum
);
	input wire [31:0] a;
	input wire [31:0] b;
	input wire cin;
	output wire [31:0] sum;
	wire [31:0] g;
	wire [31:0] p;
	genvar _gv_i_2;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < 32; _gv_i_2 = _gv_i_2 + 1) begin : GP_BITS
			localparam i = _gv_i_2;
			assign g[i] = a[i] & b[i];
			assign p[i] = a[i] ^ b[i];
		end
	endgenerate
	wire g0;
	wire p0;
	wire g1;
	wire p1;
	wire g2;
	wire p2;
	wire g3;
	wire p3;
	wire [6:0] c0;
	wire [6:0] c1;
	wire [6:0] c2;
	wire [6:0] c3;
	wire c8;
	wire c16;
	wire c24;
	gp8 B0(
		.gin(g[7:0]),
		.pin(p[7:0]),
		.cin(cin),
		.gout(g0),
		.pout(p0),
		.cout(c0)
	);
	assign c8 = g0 | (p0 & cin);
	gp8 B1(
		.gin(g[15:8]),
		.pin(p[15:8]),
		.cin(c8),
		.gout(g1),
		.pout(p1),
		.cout(c1)
	);
	assign c16 = g1 | (p1 & c8);
	gp8 B2(
		.gin(g[23:16]),
		.pin(p[23:16]),
		.cin(c16),
		.gout(g2),
		.pout(p2),
		.cout(c2)
	);
	assign c24 = g2 | (p2 & c16);
	gp8 B3(
		.gin(g[31:24]),
		.pin(p[31:24]),
		.cin(c24),
		.gout(g3),
		.pout(p3),
		.cout(c3)
	);
	wire [31:0] c_in;
	assign c_in[0] = cin;
	assign c_in[7:1] = c0[6:0];
	assign c_in[8] = c8;
	assign c_in[15:9] = c1[6:0];
	assign c_in[16] = c16;
	assign c_in[23:17] = c2[6:0];
	assign c_in[24] = c24;
	assign c_in[31:25] = c3[6:0];
	assign sum = p ^ c_in;
endmodule
module RegFile (
	rd,
	rd_data,
	rs1,
	rs1_data,
	rs2,
	rs2_data,
	clk,
	we,
	rst
);
	input wire [4:0] rd;
	input wire [31:0] rd_data;
	input wire [4:0] rs1;
	output wire [31:0] rs1_data;
	input wire [4:0] rs2;
	output wire [31:0] rs2_data;
	input wire clk;
	input wire we;
	input wire rst;
	localparam signed [31:0] NumRegs = 32;
	reg [31:0] regs [0:31];
	assign rs1_data = (rs1 == 0 ? {32 {1'sb0}} : regs[rs1]);
	assign rs2_data = (rs2 == 0 ? {32 {1'sb0}} : regs[rs2]);
	always @(posedge clk)
		if (rst) begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < NumRegs; i = i + 1)
				regs[i] <= 1'sb0;
		end
		else if (we && (rd != 5'd0))
			regs[rd] <= rd_data;
endmodule
module DatapathSingleCycle (
	clk,
	rst,
	halt,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem,
	trace_completed_pc,
	trace_completed_insn,
	trace_completed_cycle_status
);
	reg _sv2v_0;
	input wire clk;
	input wire rst;
	output reg halt;
	output wire [31:0] pc_to_imem;
	input wire [31:0] insn_from_imem;
	output reg [31:0] addr_to_dmem;
	input wire [31:0] load_data_from_dmem;
	output reg [31:0] store_data_to_dmem;
	output reg [3:0] store_we_to_dmem;
	output wire [31:0] trace_completed_pc;
	output wire [31:0] trace_completed_insn;
	output wire [31:0] trace_completed_cycle_status;
	wire [6:0] insn_funct7;
	wire [4:0] insn_rs2;
	wire [4:0] insn_rs1;
	wire [2:0] insn_funct3;
	wire [4:0] insn_rd;
	wire [6:0] insn_opcode;
	assign {insn_funct7, insn_rs2, insn_rs1, insn_funct3, insn_rd, insn_opcode} = insn_from_imem;
	wire [11:0] imm_i;
	assign imm_i = insn_from_imem[31:20];
	wire [4:0] imm_shamt = insn_from_imem[24:20];
	wire [11:0] imm_s;
	assign imm_s = {insn_from_imem[31:25], insn_from_imem[11:7]};
	wire [12:0] imm_b;
	assign imm_b = {insn_from_imem[31], insn_from_imem[7], insn_from_imem[30:25], insn_from_imem[11:8], 1'b0};
	wire [20:0] imm_j;
	assign imm_j = {insn_from_imem[31], insn_from_imem[19:12], insn_from_imem[20], insn_from_imem[30:21], 1'b0};
	wire [31:0] imm_i_sext = {{20 {imm_i[11]}}, imm_i[11:0]};
	wire [31:0] imm_s_sext = {{20 {imm_s[11]}}, imm_s[11:0]};
	wire [31:0] imm_b_sext = {{19 {imm_b[12]}}, imm_b[12:0]};
	wire [31:0] imm_j_sext = {{11 {imm_j[20]}}, imm_j[20:0]};
	wire [31:0] imm_u = {insn_from_imem[31:12], 12'b000000000000};
	localparam [6:0] OpLoad = 7'b0000011;
	localparam [6:0] OpStore = 7'b0100011;
	localparam [6:0] OpBranch = 7'b1100011;
	localparam [6:0] OpJalr = 7'b1100111;
	localparam [6:0] OpMiscMem = 7'b0001111;
	localparam [6:0] OpJal = 7'b1101111;
	localparam [6:0] OpRegImm = 7'b0010011;
	localparam [6:0] OpRegReg = 7'b0110011;
	localparam [6:0] OpEnviron = 7'b1110011;
	localparam [6:0] OpAuipc = 7'b0010111;
	localparam [6:0] OpLui = 7'b0110111;
	wire insn_lui = insn_opcode == OpLui;
	wire insn_auipc = insn_opcode == OpAuipc;
	wire insn_jal = insn_opcode == OpJal;
	wire insn_jalr = insn_opcode == OpJalr;
	wire insn_beq = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b000);
	wire insn_bne = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b001);
	wire insn_blt = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b100);
	wire insn_bge = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b101);
	wire insn_bltu = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b110);
	wire insn_bgeu = (insn_opcode == OpBranch) && (insn_from_imem[14:12] == 3'b111);
	wire insn_lb = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b000);
	wire insn_lh = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b001);
	wire insn_lw = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b010);
	wire insn_lbu = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b100);
	wire insn_lhu = (insn_opcode == OpLoad) && (insn_from_imem[14:12] == 3'b101);
	wire insn_sb = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b000);
	wire insn_sh = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b001);
	wire insn_sw = (insn_opcode == OpStore) && (insn_from_imem[14:12] == 3'b010);
	wire insn_addi = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b000);
	wire insn_slti = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b010);
	wire insn_sltiu = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b011);
	wire insn_xori = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b100);
	wire insn_ori = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b110);
	wire insn_andi = (insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b111);
	wire insn_slli = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b001)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srli = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srai = ((insn_opcode == OpRegImm) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_add = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b000)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sub = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b000)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_sll = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b001)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_slt = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b010)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sltu = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b011)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_xor = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b100)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_srl = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_sra = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b101)) && (insn_from_imem[31:25] == 7'b0100000);
	wire insn_or = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b110)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_and = ((insn_opcode == OpRegReg) && (insn_from_imem[14:12] == 3'b111)) && (insn_from_imem[31:25] == 7'd0);
	wire insn_mul = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b000);
	wire insn_mulh = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b001);
	wire insn_mulhsu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b010);
	wire insn_mulhu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b011);
	wire insn_div = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b100);
	wire insn_divu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b101);
	wire insn_rem = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b110);
	wire insn_remu = ((insn_opcode == OpRegReg) && (insn_from_imem[31:25] == 7'd1)) && (insn_from_imem[14:12] == 3'b111);
	wire insn_ecall = (insn_opcode == OpEnviron) && (insn_from_imem[31:7] == 25'd0);
	wire insn_fence = insn_opcode == OpMiscMem;
	reg [31:0] pcNext;
	reg [31:0] pcCurrent;
	always @(posedge clk)
		if (rst)
			pcCurrent <= 32'd0;
		else
			pcCurrent <= pcNext;
	assign pc_to_imem = pcCurrent;
	assign trace_completed_pc = pcCurrent;
	assign trace_completed_insn = insn_from_imem;
	assign trace_completed_cycle_status = 32'd1;
	reg [31:0] cycles_current;
	reg [31:0] num_insns_current;
	always @(posedge clk)
		if (rst) begin
			cycles_current <= 0;
			num_insns_current <= 0;
		end
		else begin
			cycles_current <= cycles_current + 1;
			if (!rst)
				num_insns_current <= num_insns_current + 1;
		end
	reg rf_we;
	reg [4:0] rf_rd;
	reg [4:0] rf_rs1;
	reg [4:0] rf_rs2;
	reg [31:0] rf_wdata;
	wire [31:0] rs1_data;
	wire [31:0] rs2_data;
	RegFile rf(
		.clk(clk),
		.rst(rst),
		.we(rf_we),
		.rd(rf_rd),
		.rd_data(rf_wdata),
		.rs1(rf_rs1),
		.rs2(rf_rs2),
		.rs1_data(rs1_data),
		.rs2_data(rs2_data)
	);
	reg [31:0] cla_a;
	reg [31:0] cla_b;
	reg cla_cin;
	wire [31:0] cla_sum;
	CarryLookaheadAdder cla(
		.a(cla_a),
		.b(cla_b),
		.cin(cla_cin),
		.sum(cla_sum)
	);
	wire rs1_neg = rs1_data[31];
	wire rs2_neg = rs2_data[31];
	wire div_result_neg = rs1_neg ^ rs2_neg;
	wire [31:0] rs1_abs = (rs1_neg ? ~rs1_data + 32'd1 : rs1_data);
	wire [31:0] rs2_abs = (rs2_neg ? ~rs2_data + 32'd1 : rs2_data);
	wire [63:0] mul_unsigned_full = {32'd0, rs1_data} * {32'd0, rs2_data};
	wire [63:0] mul_signed_abs_full = {32'd0, rs1_abs} * {32'd0, rs2_abs};
	wire [63:0] mulhsu_abs_full = {32'd0, rs1_abs} * {32'd0, rs2_data};
	wire [63:0] mul_signed_full = (div_result_neg ? ~mul_signed_abs_full + 64'd1 : mul_signed_abs_full);
	wire [63:0] mulhsu_full = (rs1_neg ? ~mulhsu_abs_full + 64'd1 : mulhsu_abs_full);
	wire do_signed_divrem = insn_div || insn_rem;
	wire [31:0] div_dividend = (do_signed_divrem ? rs1_abs : rs1_data);
	wire [31:0] div_divisor = (do_signed_divrem ? rs2_abs : rs2_data);
	wire [31:0] div_remainder_raw;
	wire [31:0] div_quotient_raw;
	DividerUnsigned divider(
		.i_dividend(div_dividend),
		.i_divisor(div_divisor),
		.o_remainder(div_remainder_raw),
		.o_quotient(div_quotient_raw)
	);
	wire signed_div_overflow = (rs1_data == 32'h80000000) && (rs2_data == 32'hffffffff);
	wire [31:0] load_addr = rs1_data + imm_i_sext;
	wire [31:0] store_addr = rs1_data + imm_s_sext;
	wire [1:0] load_byte_offset = load_addr[1:0];
	wire [1:0] store_byte_offset = store_addr[1:0];
	wire [31:0] load_word_shifted = load_data_from_dmem >> ({27'd0, load_byte_offset} << 3);
	reg illegal_insn;
	reg taken;
	always @(*) begin
		if (_sv2v_0)
			;
		illegal_insn = 1'b0;
		halt = 1'b0;
		rf_we = 1'b0;
		rf_rd = 5'd0;
		rf_rs1 = insn_rs1;
		rf_rs2 = insn_rs2;
		rf_wdata = 1'sb0;
		cla_a = 1'sb0;
		cla_b = 1'sb0;
		cla_cin = 1'b0;
		addr_to_dmem = 1'sb0;
		store_data_to_dmem = 1'sb0;
		store_we_to_dmem = 4'b0000;
		taken = 1'b0;
		if (rst)
			pcNext = pcCurrent;
		else begin
			pcNext = pcCurrent + 32'd4;
			if (insn_ecall)
				halt = 1'b1;
			else if (insn_fence)
				;
			else
				case (insn_opcode)
					OpLui: begin
						rf_we = 1'b1;
						rf_rd = insn_rd;
						rf_wdata = imm_u;
					end
					OpAuipc: begin
						rf_we = 1'b1;
						rf_rd = insn_rd;
						rf_wdata = pcCurrent + imm_u;
					end
					OpJal: begin
						rf_we = 1'b1;
						rf_rd = insn_rd;
						rf_wdata = pcCurrent + 32'd4;
						pcNext = pcCurrent + imm_j_sext;
					end
					OpJalr: begin
						rf_we = 1'b1;
						rf_rd = insn_rd;
						rf_wdata = pcCurrent + 32'd4;
						pcNext = (rs1_data + imm_i_sext) & 32'hfffffffe;
					end
					OpLoad: begin
						rf_we = 1'b1;
						rf_rd = insn_rd;
						addr_to_dmem = {load_addr[31:2], 2'b00};
						if (insn_lb)
							rf_wdata = {{24 {load_word_shifted[7]}}, load_word_shifted[7:0]};
						else if (insn_lbu)
							rf_wdata = {24'd0, load_word_shifted[7:0]};
						else if (insn_lh)
							rf_wdata = {{16 {load_word_shifted[15]}}, load_word_shifted[15:0]};
						else if (insn_lhu)
							rf_wdata = {16'd0, load_word_shifted[15:0]};
						else if (insn_lw)
							rf_wdata = load_data_from_dmem;
						else
							illegal_insn = 1'b1;
					end
					OpStore: begin
						addr_to_dmem = {store_addr[31:2], 2'b00};
						if (insn_sb) begin
							store_data_to_dmem = {4 {rs2_data[7:0]}};
							store_we_to_dmem = 4'b0001 << store_byte_offset;
						end
						else if (insn_sh) begin
							store_data_to_dmem = {2 {rs2_data[15:0]}};
							store_we_to_dmem = (store_byte_offset[1] ? 4'b1100 : 4'b0011);
						end
						else if (insn_sw) begin
							store_data_to_dmem = rs2_data;
							store_we_to_dmem = 4'b1111;
						end
						else
							illegal_insn = 1'b1;
					end
					OpRegImm: begin
						rf_rd = insn_rd;
						if (insn_addi) begin
							rf_we = 1'b1;
							cla_a = rs1_data;
							cla_b = imm_i_sext;
							cla_cin = 1'b0;
							rf_wdata = cla_sum;
						end
						else if (insn_slti) begin
							rf_we = 1'b1;
							rf_wdata = ($signed(rs1_data) < $signed(imm_i_sext) ? 32'd1 : 32'd0);
						end
						else if (insn_sltiu) begin
							rf_we = 1'b1;
							rf_wdata = (rs1_data < imm_i_sext ? 32'd1 : 32'd0);
						end
						else if (insn_xori) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data ^ imm_i_sext;
						end
						else if (insn_ori) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data | imm_i_sext;
						end
						else if (insn_andi) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data & imm_i_sext;
						end
						else if (insn_slli) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data << imm_shamt;
						end
						else if (insn_srli) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data >> imm_shamt;
						end
						else if (insn_srai) begin
							rf_we = 1'b1;
							rf_wdata = $signed(rs1_data) >>> imm_shamt;
						end
						else
							illegal_insn = 1'b1;
					end
					OpRegReg: begin
						rf_rd = insn_rd;
						if (insn_add) begin
							rf_we = 1'b1;
							cla_a = rs1_data;
							cla_b = rs2_data;
							cla_cin = 1'b0;
							rf_wdata = cla_sum;
						end
						else if (insn_sub) begin
							rf_we = 1'b1;
							cla_a = rs1_data;
							cla_b = ~rs2_data;
							cla_cin = 1'b1;
							rf_wdata = cla_sum;
						end
						else if (insn_sll) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data << rs2_data[4:0];
						end
						else if (insn_slt) begin
							rf_we = 1'b1;
							rf_wdata = ($signed(rs1_data) < $signed(rs2_data) ? 32'd1 : 32'd0);
						end
						else if (insn_sltu) begin
							rf_we = 1'b1;
							rf_wdata = (rs1_data < rs2_data ? 32'd1 : 32'd0);
						end
						else if (insn_xor) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data ^ rs2_data;
						end
						else if (insn_srl) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data >> rs2_data[4:0];
						end
						else if (insn_sra) begin
							rf_we = 1'b1;
							rf_wdata = $signed(rs1_data) >>> rs2_data[4:0];
						end
						else if (insn_or) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data | rs2_data;
						end
						else if (insn_and) begin
							rf_we = 1'b1;
							rf_wdata = rs1_data & rs2_data;
						end
						else if (insn_mul) begin
							rf_we = 1'b1;
							rf_wdata = mul_unsigned_full[31:0];
						end
						else if (insn_mulh) begin
							rf_we = 1'b1;
							rf_wdata = mul_signed_full[63:32];
						end
						else if (insn_mulhsu) begin
							rf_we = 1'b1;
							rf_wdata = mulhsu_full[63:32];
						end
						else if (insn_mulhu) begin
							rf_we = 1'b1;
							rf_wdata = mul_unsigned_full[63:32];
						end
						else if (insn_div) begin
							rf_we = 1'b1;
							if (rs2_data == 32'd0)
								rf_wdata = 32'hffffffff;
							else if (signed_div_overflow)
								rf_wdata = 32'h80000000;
							else
								rf_wdata = (div_result_neg ? ~div_quotient_raw + 32'd1 : div_quotient_raw);
						end
						else if (insn_divu) begin
							rf_we = 1'b1;
							if (rs2_data == 32'd0)
								rf_wdata = 32'hffffffff;
							else
								rf_wdata = div_quotient_raw;
						end
						else if (insn_rem) begin
							rf_we = 1'b1;
							if (rs2_data == 32'd0)
								rf_wdata = rs1_data;
							else if (signed_div_overflow)
								rf_wdata = 32'd0;
							else
								rf_wdata = (rs1_neg ? ~div_remainder_raw + 32'd1 : div_remainder_raw);
						end
						else if (insn_remu) begin
							rf_we = 1'b1;
							if (rs2_data == 32'd0)
								rf_wdata = rs1_data;
							else
								rf_wdata = div_remainder_raw;
						end
						else
							illegal_insn = 1'b1;
					end
					OpBranch: begin
						if (insn_beq)
							taken = rs1_data == rs2_data;
						else if (insn_bne)
							taken = rs1_data != rs2_data;
						else if (insn_blt)
							taken = $signed(rs1_data) < $signed(rs2_data);
						else if (insn_bge)
							taken = $signed(rs1_data) >= $signed(rs2_data);
						else if (insn_bltu)
							taken = rs1_data < rs2_data;
						else if (insn_bgeu)
							taken = rs1_data >= rs2_data;
						else
							illegal_insn = 1'b1;
						if (taken)
							pcNext = pcCurrent + imm_b_sext;
					end
					default: illegal_insn = 1'b1;
				endcase
		end
	end
	initial _sv2v_0 = 0;
endmodule
module MemorySingleCycle (
	rst,
	clock_mem,
	pc_to_imem,
	insn_from_imem,
	addr_to_dmem,
	load_data_from_dmem,
	store_data_to_dmem,
	store_we_to_dmem
);
	reg _sv2v_0;
	parameter signed [31:0] NUM_WORDS = 512;
	input wire rst;
	input wire clock_mem;
	input wire [31:0] pc_to_imem;
	output reg [31:0] insn_from_imem;
	input wire [31:0] addr_to_dmem;
	output reg [31:0] load_data_from_dmem;
	input wire [31:0] store_data_to_dmem;
	input wire [3:0] store_we_to_dmem;
	reg [31:0] mem_array [0:NUM_WORDS - 1];
	initial $readmemh("mem_initial_contents.hex", mem_array);
	always @(*)
		if (_sv2v_0)
			;
	localparam signed [31:0] AddrMsb = $clog2(NUM_WORDS) + 1;
	localparam signed [31:0] AddrLsb = 2;
	always @(posedge clock_mem)
		if (rst)
			;
		else
			insn_from_imem <= mem_array[{pc_to_imem[AddrMsb:AddrLsb]}];
	always @(negedge clock_mem)
		if (rst)
			;
		else begin
			if (store_we_to_dmem[0])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][7:0] <= store_data_to_dmem[7:0];
			if (store_we_to_dmem[1])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][15:8] <= store_data_to_dmem[15:8];
			if (store_we_to_dmem[2])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][23:16] <= store_data_to_dmem[23:16];
			if (store_we_to_dmem[3])
				mem_array[addr_to_dmem[AddrMsb:AddrLsb]][31:24] <= store_data_to_dmem[31:24];
			load_data_from_dmem <= mem_array[{addr_to_dmem[AddrMsb:AddrLsb]}];
		end
	initial _sv2v_0 = 0;
endmodule
`default_nettype none
module SystemResourceCheck (
	external_clk_25MHz,
	btn,
	led
);
	input wire external_clk_25MHz;
	input wire [6:0] btn;
	output wire [7:0] led;
	wire clk_proc;
	wire clk_mem;
	wire clk_locked;
	MyClockGen clock_gen(
		.input_clk_25MHz(external_clk_25MHz),
		.clk_proc(clk_proc),
		.clk_mem(clk_mem),
		.locked(clk_locked)
	);
	wire [31:0] pc_to_imem;
	wire [31:0] insn_from_imem;
	wire [31:0] mem_data_addr;
	wire [31:0] mem_data_loaded_value;
	wire [31:0] mem_data_to_write;
	wire [3:0] mem_data_we;
	MemorySingleCycle #(.NUM_WORDS(128)) memory(
		.rst(!clk_locked),
		.clock_mem(clk_mem),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.load_data_from_dmem(mem_data_loaded_value),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we)
	);
	DatapathSingleCycle datapath(
		.clk(clk_proc),
		.rst(!clk_locked),
		.pc_to_imem(pc_to_imem),
		.insn_from_imem(insn_from_imem),
		.addr_to_dmem(mem_data_addr),
		.store_data_to_dmem(mem_data_to_write),
		.store_we_to_dmem(mem_data_we),
		.load_data_from_dmem(mem_data_loaded_value),
		.halt(led[0])
	);
endmodule