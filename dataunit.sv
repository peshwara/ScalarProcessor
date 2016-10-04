//DATA UNIT:

`timescale 1ns/10ps
module du_dut(add,instruction,inc_PR,load_IR,set_PR,Mode,WR,RD,RDM,ctrl_sig,copy_flag,res_sel,clk,rst,dat);

// input output declarations.
output [7:0] instruction,add;
input inc_PR,load_IR,set_PR,Mode,WR,RD,RDM,copy_flag;
input clk,rst;
input [3:0] ctrl_sig;
input [1:0] res_sel;
inout [7:0] dat;

//Wire declarations.
wire [7:0] dat;
wire [7:0] PR,dir_add,op1, op2, result;
wire [3:0] flag;
wire [7:0] dat_ip,dat_op,dataout;
wire carry;

//assign statements.
assign add = ((RD == 1 || WR == 1) && RDM == 1)? dir_add:PR;
assign dat_ip = (RD) ? dat :8'bz;
assign dat = (WR) ? dat_op : 8'bz;
//assign dat = (WR==0&&RD==0)?dataout:8'bz; Enable if continuous data to be seen on databus.

//module instantiations
DFF IR (.dataout(instruction),.datain(dat_ip),.load(load_IR),.clk(clk),.rst(rst));
DFF data_l (.dataout(dataout),.datain(dat_ip),.load(RD),.clk(clk),.rst(rst));
PR_reg reg2 (.PR(PR),.inc_PR(inc_PR),.AR_jmp(dir_add),.clk(clk),.rst(rst),.set_PR(set_PR));
alu m1( .y(result),.a(op2),.b(op1),.cin(cin),.flag(flag));
regunit m2(.op1(op1), .op2(op2), .dir_add(dir_add), .dat_op(dat_op),.dat_ip(dataout), .flag_ru(flag), .result(result), .cu_fg(copy_flag), .cu_op(ctrl_sig), .res_sel(res_sel),.clk(clk), .rst(rst));
Mode_in l1 (.cin(cin),.Mode(Mode),.clk(clk),.rst(rst));

always@(posedge clk)
$display("Data Unit: Time = %0dns, Instruction = %h, dat = %h, RD = %b,WR = %b, add = %0d, load_IR = %b \n", $time,instruction,dat,RD,WR,add,load_IR);
endmodule

//Instruction register module
module DFF(dataout,datain,load,clk,rst);
output [7:0] dataout;
input [7:0] datain;
input load, clk,rst;
reg [7:0] dataout;
always@(posedge clk or posedge rst) 
begin
if (rst == 1) dataout <=0;
else if (load) dataout <= datain;
end
endmodule

//Mode flip flop
module Mode_in(cin,Mode,clk,rst);
output  cin;
input  Mode;
input clk,rst;
reg cin;
always@(posedge clk or posedge rst) begin
if (rst == 1) 
cin <=0;
else if (Mode == 1) 
cin <= 1;
else 
cin <= 0;
end
endmodule

//Program counter module
module PR_reg(PR,inc_PR,set_PR,AR_jmp,clk,rst);
output [7:0]PR;
input inc_PR,set_PR;
input[7:0] AR_jmp;
input clk, rst;
reg [7:0]PR;
always@(posedge clk or posedge rst)begin
if(rst) PR <= 0; 
else if(set_PR) 
PR <=  AR_jmp;
else if(inc_PR) 
PR <= PR + 1;
//$display("Data Unit: Time = %0dns,Incremented PR = %b, PR = %h \n",$time,inc_PR, PR);
end
endmodule

//Register unit module
module regunit(op1, op2, dir_add, dat_op, dat_ip, flag_ru, result, cu_fg, cu_op,res_sel,clk,rst);
input cu_fg;
input clk,rst;
input [3:0] cu_op;
input [1:0] res_sel;
input [7:0] dat_ip;
input [7:0] result;
input [3:0] flag_ru;
output [7:0] dat_op,dir_add;
output [7:0] op1, op2;
wire [7:0] dataout;
reg [7:0] DR,GR,AR;
reg [7:0] dat_op, op1, op2;
reg [3:0] FR;

assign dir_add = AR;

always@(posedge clk or posedge rst)
begin

if(rst)
begin
DR = 8'd0; GR = 8'd0; AR = 8'd0; FR = 8'd0;
$display("Data Unit: Time = %0dns, Operand1 = %h, Operand2 = %h, DR = %h, GR = %h AR = %h FR = %h \n",$time,op1,op2,DR,GR,AR,FR);
end
else if(cu_fg)
begin

case(cu_op)
1	: AR = DR;  //load_AR_DR COPY inst
2	: DR = AR;	//load_DR_AR COPY inst
3	: GR = AR;  //load_GR_AR COPY inst
4	: AR = GR;  //load_AR_GR COPY inst
5	: GR = DR;  //load_GR_DR COPY inst
6	: DR = GR;  //load_DR_GR COPY inst
7	: GR[3:0] = dat_ip[3:0];  //load_GR_LS : LLS
8	: GR[7:4] = dat_ip[3:0];  //LMS inst
9	: GR = {4'b0,FR};		//CFR
10	: begin op1 = DR; op2 = GR;end //for adition
11	: begin op1 = GR; op2 = DR;end //for adition
12	: DR = dat_ip;  // READ load_DR_dat
13	: GR = dat_ip;  // READ load_GR_dat
14	: dat_op = DR;	// WRITE sel_DR_w
15	: dat_op = GR;  // WRITEsel_GR_w
default	:$display("Data Unit: Error in SEL_cu_op");
endcase
$display("Data Unit: after loading Time = %0dns, Operand1 = %h, Operand2 = %h, DR = %h, GR = %h AR = %h FR = %h \n",$time,op1,op2,DR,GR,AR,FR);
end

else if(!rst)
begin
if(res_sel == 1)begin //load_DR_dat
 DR = result;
 FR = flag_ru;
 end
else if(res_sel == 2)begin //load_GR_dat
GR = result;
FR = flag_ru;
end
end
end
endmodule

//Design code for Carry look Ahead adder.
module pfa(pfa_a, pfa_b, pfa_cin,pfa_sum, pfa_g, pfa_p);
input pfa_a, pfa_b, pfa_cin;
output pfa_sum, pfa_g, pfa_p;
and (pfa_g, pfa_a, pfa_b);
xor (pfa_p, pfa_a, pfa_b);
xor (pfa_sum, pfa_cin, pfa_p);
endmodule

// 4 bit intermediate block
module fourbit(four_a, four_b, four_c0, four_sum, p0_3, g0_3);
input [3:0] four_a, four_b;
input four_c0;
output p0_3, g0_3;
output [3:0] four_sum;
wire four_g0,four_g1,four_g2,four_g3,four_p0,four_p1,four_p2,four_p3;
wire four_c1,four_c2,four_c3;

pfa bit0(.pfa_a(four_a[0]), 
	.pfa_b(four_b[0]), 
	.pfa_cin(four_c0),
	.pfa_sum(four_sum[0]), 
	.pfa_g(four_g0), 
	.pfa_p(four_p0)
	);

pfa bit1(.pfa_a(four_a[1]), 
	.pfa_b(four_b[1]), 
	.pfa_cin(four_c1),
	.pfa_sum(four_sum[1]), 
	.pfa_g(four_g1), 
	.pfa_p(four_p1)
	);

pfa bit2(.pfa_a(four_a[2]), 
	.pfa_b(four_b[2]), 
	.pfa_cin(four_c2),
	.pfa_sum(four_sum[2]), 
	.pfa_g(four_g2), 
	.pfa_p(four_p2)
	);

pfa bit3(.pfa_a(four_a[3]), 
	.pfa_b(four_b[3]), 
	.pfa_cin(four_c3),
	.pfa_sum(four_sum[3]), 
	.pfa_g(four_g3), 
	.pfa_p(four_p3)
	);

assign four_c1 = four_g0 | (four_c0 &four_p0);
assign four_c2 = four_g1 | (four_c0 & four_p0 & four_p1) | (four_g0 & four_p1);
assign four_c3 = four_g2 | (four_c0 & four_p0 & four_p1 & four_p2) |  (four_g0 & four_p1 & four_p2) | (four_g1 & four_p2);
assign p0_3 = four_p0 & four_p1 & four_p2 & four_p3;
assign g0_3 = four_g3|(four_g2 & four_p3)|(four_g1 & four_p2 &four_p3)| (four_g0 & four_p1 & four_p2 & four_p3); 
endmodule

// 8 bit complete cla
module adder_8(a,b,c0,sum,cout);
input [7:0] a,b;
input c0;
output [7:0] sum;
//output [3:0] flag;
output cout;
wire g1,g0;
wire p0,p1;
wire c4;  // these are cin to resp blocks
// c16= cout, c0=cin

fourbit mod0(.four_a(a[3:0]),
	     .four_b(b[3:0]),	
	     .four_c0(c0), 
	     .four_sum(sum[3:0]), 
	     .p0_3(p0), 
	     .g0_3(g0)
	     );
fourbit mod1(.four_a(a[7:4]),
	     .four_b(b[7:4]),	
	     .four_c0(c4), 
	     .four_sum(sum[7:4]), 
	     .p0_3(p1), 
	     .g0_3(g1)
	     );
assign c4 = g0 | (c0 & p0);
assign cout = g1 | (c0 & p0 & p1) | (g0 & p1);
endmodule

//Design Module for ALU
module alu( y, flag, a, b, cin);
input [7:0]a,b;
input cin;
output [7:0] y;
output [3:0] flag;
wire [7:0]sum,b1 ;
wire  zf, sf, ov, cf;
wire [7:0]y;
wire [3:0] flag;
wire  cout, cin;
assign b1 = (cin)? ~b : b;

adder_8 t1(.sum(y), .cout(cout), .a(a), .b(b1), .c0(cin));

assign ov = ((a[7] ==1 && b[7] ==1 && y[7]==0)||(a[7] ==0 && b[7] ==0 && y[7]==1)) ? 1 : 0;
assign zf = (y)?0:1;
assign cf = cout;
assign sf = y[7];
assign flag = {zf,sf,cf,ov};
assign y = sum ;
endmodule

