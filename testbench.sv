 //TEST BENCH:

`timescale 1ns/10ps



program automatic testP(interfaceP.TB in);
reg [7:0] AR, DR, GR, FR, PR, tb_res, dut_res;
reg [1:0] src, dst;
reg [3:0] opcode, pst; 

initial
begin
$dumpfile("wave_PS.vcd"); //specify the name of the VCD file
$dumpvars(0,testP); //Dump the variables 
end

initial 
begin

reset();

fork
monitor();
selfcheck();
join_none

#1000 $finish();
end
task reset();
in.rst = 1;
repeat(2)@(in.cb ) 
if(pst== 4'b0000)
	$display("%0dns: Reset successful",$time);
	else 
	$display("%0dns: Reset unsuccessful",$time);
#4 in.rst = 0;
endtask

task monitor();
top.dut.d1.m2.AR <= 8'b10000000;
top.dut.d1.m2.DR <= 8'b10001000;
top.dut.d1.m2.GR <= 8'b10001001;
top.dut.d1.m2.FR <= 8'b10001001;
forever @in.cb begin
AR= top.dut.d1.m2.AR;
DR= top.dut.d1.m2.DR;
GR= top.dut.d1.m2.GR;
FR= top.dut.d1.m2.FR;
PR= top.dut.d1.PR;

pst = top.dut.c1.pst;
opcode = top.dut.c1.opcode;
src = top.dut.c1.src;
dst = top.dut.c1.dst;

$display("%0dns: test value of pst = %h",$time, pst);

end
endtask 


task selfcheck();

forever @in.cb begin 

if(pst == 4'b0010) begin //Fetch State of CU

$display("%0dns: test value of AR = %h",$time, AR);
$display("test value of DR = %h", DR);
$display("test value of GR = %h", GR);
$display("test value of FR = %h", FR);
$display("%0dns:opcode = %h; src = %h; dst= %h;",$time,opcode, src, dst);



case (opcode)

1: begin	//JUMP
dut_res = top.mem.memory[AR];	
$display("test value of AR = %h", AR);
repeat(3)@(in.cb) 

tb_res = PR;
$display("test value of PR = %h", PR);

$display("%0dns:DUT:result==%0h", $time, dut_res);
$display("test value of mem = %h", tb_res);

 if (tb_res==dut_res) 
		 $display("JUMP operation:output matches expected result\n*****************************************\n");
 else $display("JUMP: error- mismatch:!!");
end

2: begin	//READ
dut_res = top.mem.memory[AR];	
	
repeat(3)@(in.cb) 

case(dst)
01:begin
	tb_res = DR;
	end 
10:begin
	tb_res = GR;
	end
endcase
$display("%0dns:DUT:result==%0h", $time, dut_res);
$display("test value of mem = %h", tb_res);

 if (tb_res==dut_res) 
		 $display("READ operation:output matches expected result\n*****************************************\n");
 else $display("READ: error- mismatch:!!");
end

3: begin	//WRITE
case(dst)
01:begin
	tb_res = DR;
	end 
10:begin
	tb_res = GR;
	end
endcase	 
repeat(4)@(in.cb) 
	
dut_res = top.mem.memory[AR];	

$display("%0dns:DUT:result==%0h", $time, dut_res);
$display("test value of mem = %h", tb_res);

 if (tb_res==dut_res) 
		 $display("WRITE operation:output matches expected result\n*****************************************\n");
 else $display("WRITE: error- mismatch:!!");
end

4: begin  //COPY

case(src)
2'b00: 	tb_res= AR;

2'b01: 	tb_res= DR;
		
2'b10: 	tb_res= GR;
endcase
	 
	 repeat(2)@(in.cb ) 
	 
case(dst)
	 
2'b00: 	begin
		if(src == 2'b01)
			dut_res = DR;
		if(src == 2'b10)
			dut_res = GR;
		end
2'b01: 	begin
		if(src == 2'b00)
			dut_res = AR;
		if(dst == 2'b10)
			dut_res = GR;
		end
		
2'b10: 	begin
		if(src == 2'b00)
			dut_res = AR;
		if(src == 2'b01)
			dut_res = DR;
		end

endcase		
		

 if (tb_res==dut_res) 
		$display("COPY operation: output of COPY operation matches expected result\n*****************************************\n");
	else $display("COPY: error- mismatch:!!");
 
end

5: begin	//ADD
tb_res = GR + DR;
	 $display("TB:result=%0h", tb_res);
	 $display("dest operand=", dst);
	 
repeat(4)@(in.cb) 
	 
if(dst == 2'b01) 
	dut_res = DR;
 else if (dst == 2'b10)
	dut_res = GR;
$display("%0dns:DUT:result==%0h", $time, dut_res);
$display("test value of FR = %h", FR);

 if (tb_res==dut_res) 
		 $display("ADD operation:output matches expected result\n*****************************************\n");
 else $display("ADD: error- mismatch:!!");
end

6: begin  //SUB
if(src == 2'b10)
tb_res = DR - GR;

else tb_res = GR - DR;
	 $display("TB:result=%0h", tb_res);
	 $display("dest operand=", dst);
	 
	 repeat(4)@(in.cb ) 
	 
if(dst == 2'b01) 
	dut_res = DR;
 else if (dst == 2'b10)
	dut_res = GR;

 
 $display("%0dns:DUT:result==%0h", $time, dut_res);
$display("test value of FR = %h", FR);

 if (tb_res==dut_res) 
		$display("SUB operation: output of matches expected result\n*****************************************\n");
	else $display("SUB :error- mismatch:!!");
 
 
end

7: begin // LLS: load inst's 4LSB to LSB of GR
	tb_res = {dst,src};
	$display("%0dns: LLS's LSB = %h",$time, tb_res);
	repeat(2)@(in.cb )
	dut_res = GR[3:0];
	$display("%0dns:  GR's LSB = %h",$time, dut_res);
	
	if (tb_res==dut_res) 
		$display("LLS operation: successful\n*****************************************\n");
	else $display("LLS: error- mismatch:!!");
	end

8: begin // LMS: load inst's 4LSB to MSB of GR
	tb_res = {dst,src};
	$display("%0dns: LLS's LSB = %h",$time, tb_res);
	repeat(2)@(in.cb )
	dut_res = GR[7:4];
	$display("%0dns:  GR's MSB = %h",$time, dut_res);
	
	if (tb_res==dut_res) 
		$display("LMS operation: successful\n*****************************************\n");
	else $display("LMS: error- mismatch:!!");
	end
	
9: begin // CRF: load inst's 4LSB to LSB of FR
	tb_res = FR[3:0];
	$display("%0dns: FR's LSB = %h",$time, tb_res);
	repeat(2)@(in.cb )
	dut_res = GR[3:0];
	$display("%0dns:  GR's LSB = %h",$time, dut_res);
	
	if (tb_res==dut_res) 
		$display("CFR operation: successful\n*****************************************\n");
	else $display("CRF: error- mismatch:!!");
	end
		

endcase

end
end
endtask



endprogram

//Memory module
module memory( add , dat , rd , wrt,clk );
input [7:0]add ;
input  rd , wrt ;
inout [7:0]dat ;
integer i,j,k,l;
input clk;
reg [7:0]memory[0:255];
reg [7:0]init_c = 8'd0;
wire [7:0] dat, databus_tb;

class memrand;
  
  typedef enum {NOPE=4'b0000, JUMP=4'b0001, READ=4'b0010, WRITE=4'b0011, COPY=4'b0100, ADD=4'b0101, SUB=4'b0110, LLS=4'b0111, LMS=4'b1000, CFR=4'b1001} eopcode;
  rand eopcode opcode;
  typedef enum {A=00, D=01, G=10} oprand;
  rand oprand oprand1, oprand2;
  rand bit [7:0] mdata;
  constraint c1 {//opcode inside {[0:9]};
                 if (opcode == 5 || opcode == 6)     // ADD or SUB
                   oprand1 != 00 && oprand2!= 00 && (oprand1 != oprand2);
                 else if( opcode ==2 || opcode == 3) //READ or WRITE
                   oprand1 != 00 && oprand2 == 00;
                 else if (opcode == 4)					// COPY
                   oprand1 != oprand2 ;
                 else if( opcode ==0 || opcode == 1)	// NOPE or JUMP                     
                	oprand1 == 0 && oprand2 == 0 ;
                   }
endclass
  covergroup coverage;
	opcode: coverpoint m.opcode;// m.operand1, m.operand2;
	oprand1: coverpoint m.oprand1;
	oprand2: coverpoint m.oprand2;
	
	cross opcode, oprand1{
	ignore_bins copyc = binsof(opcode) intersect {4} ;
	ignore_bins readc = binsof(opcode) intersect {2} ;
	ignore_bins wrtc = binsof(opcode) intersect {3};
	ignore_bins nopjump = binsof(opcode) intersect {[0:1]};
	ignore_bins addc  = binsof(opcode) intersect {6} &&
						binsof(oprand1) intersect {00};
	ignore_bins subc  = binsof(opcode) intersect {5} &&
						binsof(oprand1) intersect {00};
	}
	
	cross opcode, oprand2{
	ignore_bins copyc = binsof(opcode) intersect {4};
	ignore_bins readc = binsof(opcode) intersect {2} ;
	ignore_bins wrtc = binsof(opcode) intersect {3};
	ignore_bins nopjump = binsof(opcode) intersect {[0:1]};
	ignore_bins addc  = binsof(opcode) intersect {6} &&
						binsof(oprand2) intersect {00};
	ignore_bins subc  = binsof(opcode) intersect {5} &&
						binsof(oprand2) intersect {00};
	}
	

  endgroup
memrand m;
coverage cr;

initial 
begin 
m= new();
cr = new();
memory[0] =  8'b0000_0000;
memory[1] =  8'b0010_0100;
memory[2] =  8'b0101_1001; // add gr, dr Add GR(10) and DR(01) and store the result in GR(10)

i=3;
repeat(253) begin

  assert(m.randomize());
  cr.sample();
    memory[i][7:4]= m.opcode;
    memory[i][3:2]= m.oprand1;
    memory[i][1:0]= m.oprand2;
	//$display ("memory[%d]=%b", i,memory[i]);
	i++;
end 

end

always @(posedge clk)
begin
if(wrt ==1)
begin
memory[add] <= databus_tb;
$display ("memory[add] : %h, address : %h, Data after ALU operation : %h",memory[add],add,databus_tb);
end

if (rd !==0 || wrt !==0)
$display ("time = %0dns, memory[add] : %h, address : %h, Data : %h, rd : %h, wrt = %h",$time,memory[add],add,dat,rd,wrt);
end

assign databus_tb = (wrt) ? dat  : databus_tb;
assign dat = (rd) ? memory[add] : 8'hzz;

endmodule

