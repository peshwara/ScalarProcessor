module top;
  bit clk;

  interfaceP inf(clk);
  testP test(inf);
  dutP dut( 
	.rst(inf.rst),
	.clk(inf.clk),
	.rd(inf.rd),
	.wrt(inf.wrt),
	.add(inf.add),
	.dat(inf.dat)
	);
  memory mem(
	.add(inf.add),
	.dat(inf.dat),
	.rd(inf.rd),
	.wrt(inf.wrt),
	.clk(inf.clk)
  );
	

  initial begin
    clk = 0;
    forever begin
      #6 clk = ~clk;
    end
  end
endmodule

interface interfaceP(input bit clk);
logic rst;
wire [7:0] dat;
logic [7:0] add;
logic rd, wrt;

clocking cb @(posedge clk); //relative to tb
input rd, wrt;
input add;
inout dat;
endclocking

modport TB(clocking cb, output rst);

endinterface
