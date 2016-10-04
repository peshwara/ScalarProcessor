//CONTROL UNIT:

`timescale 1ns/10ps
module cu_dut(inc_PR, load_IR, set_PR, ctrl_sig, WR, RD, RDM, Mode, copy_flag, res_sel, instruction, clk, rst);

// input output declarations.
input clk,rst;
input [7:0] instruction;
output inc_PR, load_IR, WR, RD, RDM, Mode, copy_flag, set_PR;
output [3:0] ctrl_sig;
output [1:0] res_sel;

// parameter declarations.
parameter s0 = 4'b0000, s1 = 4'b0001, s2 = 4'b0010, s3 = 4'b0011,s4 = 4'b0100,s5 = 4'b0101,  s6 = 4'b0110, s7 = 4'b0111, s9 = 4'b1001;

// register declarations.
reg [3:0] pst,nst;
reg inc_PR, load_IR, WR, RD, RDM, Mode, set_PR;
reg err_flag, copy_flag;
reg [3:0] ctrl_sig;
reg [1:0] res_sel;

// wire declarations.
wire [3:0] opcode; 
wire [1:0] src; 
wire [1:0] dst; 
wire [3:0] reg_sel; 
assign opcode = instruction[7:4]; 
assign src = instruction[1:0]; 
assign dst = instruction[3:2]; 
assign reg_sel = instruction[3:0];

always @(posedge clk or posedge rst)
begin
if(rst)
   begin
   pst = s0;
   end
else
   begin 
   pst = nst;
   end
end

always @(pst)
begin : output_and_next_state
RD = 0;
WR = 0;
RDM = 0;
inc_PR = 0; 
err_flag = 0; 
load_IR = 0; 
copy_flag = 0; 
ctrl_sig=0; 
res_sel=0; 
set_PR=0;
Mode = 0;
nst = s0; 

case(pst)

s0: begin
	$display("Control Unit: Time = %0dns, -----Reset State-----\n", $time);	
	nst = s1;
	end

		
s1: begin
	$display("Control Unit: Time = %0dns, -----Fetch state-----\n", $time);
	nst = s2;
	RD  = 1;	//in test bench if rd = 1, copy data pointed by addr to data_bus
	load_IR = 1;
	end

		
s2:	begin
	$display("Control Unit: Time = %0dns, -----Inc PR state-----\n", $time);	
	nst = s3;
	inc_PR = 1;  //PR should be continously copied to addr, such that for NOP nst can be s2 and it can fetch next instruction.
	end

	
s3:	begin
	$display("Control Unit: Time = %0dns, decode opcode = %h \n", $time, opcode);
	case(opcode)
	4'b0000 : begin
			  $display("Control Unit: Time = %0dns, -----NOP instruction-----\n", $time);
			  nst = s1; 
			  end
	4'b0001 : begin 
			  $display("Control Unit: Time = %0dns, -----JUMP instruction-----\n", $time);
			  set_PR = 1;
			  nst = s1;
			  end
	4'b0010 : begin
		      $display("Control Unit: Time = %0dns, -----READ instruction-----\n", $time);
			  RD = 1;
			  RDM = 1;
			  nst = s6; 
			  end
	4'b0011 : begin
			  $display("Control Unit: Time = %0dns, -----WRITE instruction-----\n", $time);
			  copy_flag = 1;
			  case (dst)
			  2'b01 : ctrl_sig = 14;//sel_DR_w
			  2'b10 : ctrl_sig = 15;//sel_GR_w
			  default : err_flag = 1;
			  endcase
			  nst = s7; 
			  end
	4'b0100 : begin
			  $display("Control Unit: Time = %0dns, -----COPY instruction-----\n", $time);
			  nst = s1;
			  copy_flag = 1;
			  case (reg_sel) 
			  4'b0001 : begin ctrl_sig = 1; end //load_AR_DR
			  4'b0100 : begin ctrl_sig = 2; end //load_DR_AR
			  4'b1000 : begin ctrl_sig = 3; end //load_GR_AR
			  4'b0010 : begin ctrl_sig = 4; end //load_AR_GR
			  4'b1001 : begin ctrl_sig = 5; end //load_GR_DR
			  4'b0110 : begin ctrl_sig = 6; end //load_DR_GR
			  default : $display("Control Unit: Time = %0dns, Error in SEL_cpr", $time);
			  endcase
			  end
	4'b0101 : begin
			  $display("Control Unit: Time = %0dns, -----ADD instruction-----\n", $time);
			  //Mode = 0;
			  nst = s4;
			  copy_flag = 1;
			  case (reg_sel)
	          4'b1001 : ctrl_sig = 10; //GR=op2_DR=op1
	          4'b0110 : ctrl_sig = 11; //DR=op2_GR=op1
	          default : $display("Control Unit: Time = %0dns, Error in SEL_ops for add", $time);
	          endcase
			  end
	4'b0110: begin 
			  $display("Control Unit: Time = %0dns, -----SUB instruction-----\n", $time);
			  //Mode = 1;
			  nst = s5;
			  copy_flag = 1;
			  case (reg_sel)
	          4'b1001 : ctrl_sig = 10; //GR=op2_DR=op1
	          4'b0110 : ctrl_sig = 11; //DR=op2_GR=op1
	          default : $display("Control Unit: Time = %0dns, Error in SEL_ops for sub", $time);
	          endcase
			  end
	4'b0111: begin 
			 $display("Control Unit: Time = %0dns, -----LLS instruction-----\n", $time);
			 nst = s1;
			 copy_flag = 1;
			 ctrl_sig = 7; //load_GR_LS
			 end
    4'b1000: begin 
			 $display("Control Unit: Time = %0dns, -----LMS instruction-----\n", $time);
	         nst = s1;
			 copy_flag = 1;
			 ctrl_sig = 8; 
			 end
	4'b1001: begin 
			 $display("Control Unit: Time = %0dns, -----CFR instruction-----\n", $time);
			 nst = s1;
			 copy_flag = 1;
	         ctrl_sig = 9;
			 end 
	endcase
	end
	
//Mode select state for addition
s4 : begin
	 $display("Control Unit: Time = %0dns, -----Mode selection for ADD-----\n", $time);
     nst = s9;
	 Mode = 0;
	 end
	
//Mode select state for subtraction
s5 : begin
	 $display("Control Unit: Time = %0dns, -----Mode selection for SUB-----\n", $time);
     nst = s9;
	 Mode = 1;
	 end

// Read elaborate
s6 : begin
	 $display("Control Unit: Time = %0dns, -----Read elaborate-----\n", $time);
	 nst = s1;
	 copy_flag = 1;
	 case(dst)
     2'b01 : ctrl_sig = 12;//load_DR_dat
	 2'b10 : ctrl_sig = 13;//load_GR_dat
	 default : err_flag = 1;
	 endcase
	 end

// Write elaborate
s7 : begin
	 $display("Control Unit: Time = %0dns, -----Write elaborate-----\n", $time);
     nst = s1;
     WR = 1; 
     RDM =1;
     end
	
//Execute state
s9 : begin
	 $display("Control Unit: Time = %0dns, -----Execute elaborate-----\n", $time); //add or sub
     nst = s1;
	 case(dst)
     2'b01 : res_sel = 1;//load_DR_dat
	 2'b10 : res_sel = 2;//load_GR_dat
	 default : err_flag = 1;
	 endcase
	 end
endcase
end
endmodule

