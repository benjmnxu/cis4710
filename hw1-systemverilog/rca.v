`default_nettype none
module halfadder (
	a,
	b,
	s,
	cout
);
	input wire a;
	input wire b;
	output wire s;
	output wire cout;
	assign s = a ^ b;
	assign cout = a & b;
endmodule
module fulladder1 (
	cin,
	a,
	b,
	s,
	cout
);
	input wire cin;
	input wire a;
	input wire b;
	output wire s;
	output wire cout;
	wire s_tmp;
	wire cout_tmp1;
	wire cout_tmp2;
	halfadder h0(
		.a(a),
		.b(b),
		.s(s_tmp),
		.cout(cout_tmp1)
	);
	halfadder h1(
		.a(s_tmp),
		.b(cin),
		.s(s),
		.cout(cout_tmp2)
	);
	assign cout = cout_tmp1 | cout_tmp2;
endmodule
module rca4 (
	a,
	b,
	sum,
	carry_out
);
	input wire [3:0] a;
	input wire [3:0] b;
	output wire [3:0] sum;
	output wire carry_out;
	wire c1;
	wire c2;
	wire c3;
	fulladder1 fa0(
		.cin(1'b0),
		.a(a[0]),
		.b(b[0]),
		.s(sum[0]),
		.cout(c1)
	);
	fulladder1 fa1(
		.cin(c1),
		.a(a[1]),
		.b(b[1]),
		.s(sum[1]),
		.cout(c2)
	);
	fulladder1 fa2(
		.cin(c2),
		.a(a[2]),
		.b(b[2]),
		.s(sum[2]),
		.cout(c3)
	);
	fulladder1 fa3(
		.cin(c3),
		.a(a[3]),
		.b(b[3]),
		.s(sum[3]),
		.cout(carry_out)
	);
endmodule
module rca4_demo (
	BUTTON,
	LED
);
	input wire [6:0] BUTTON;
	output wire [7:0] LED;
	rca4 rca(
		.a(4'd2),
		.b({BUTTON[2], BUTTON[5], BUTTON[4], BUTTON[6]}),
		.sum(LED[3:0]),
		.carry_out(LED[4])
	);
	assign LED[7:5] = 3'd0;
endmodule