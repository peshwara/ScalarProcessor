//Top level module:

`timescale 1ns/10ps
module dutP(rst, clk, rd, wrt, add, dat);
input rst, clk;
output rd, wrt;
output [7:0]add;
inout [7:0] dat;

wire [3:0] cu_op;
wire [1:0] result_sel;
wire [7:0] instruction;

cu_dut c1(.res_sel(result_sel), .load_IR(load_IR), .set_PR(set_PR), .RD(rd), .WR(wrt), .RDM(RDM), .Mode(Mode), .copy_flag(cu_fg), .ctrl_sig(cu_op), .inc_PR(inc_PR), .clk(clk), .rst(rst), .instruction(instruction));


du_dut d1(.instruction(instruction), .add(add), .dat(dat), .RD(rd), .WR(wrt), .RDM(RDM), .inc_PR(inc_PR), .clk(clk), .rst(rst), .Mode(Mode), .set_PR(set_PR), .copy_flag(cu_fg), .ctrl_sig(cu_op), .load_IR(load_IR), .res_sel(result_sel));

endmodule 

