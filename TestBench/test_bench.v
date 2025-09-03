module final_tb();
reg [31:0]InputA,InputB;
reg clk,rst=0;
wire [31:0]AbyB;
wire DONE;
wire [1:0]Exception;
fpdivisionfinal uut(AbyB,DONE,Exception,InputA,InputB,clk,rst);

initial
begin
clk=0;
forever # 5clk=~clk;   
end

initial
begin
    InputA=32'b01001001000110001101110011111011; //A<B
    InputB=32'b01000111011100000100101110011111; 
    
end
endmodule
