`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

module fpdivisionfinal(AbyB,DONE,Exception,InputA,InputB,CLOCK,RESET);
input CLOCK,RESET ; // Active High Synchronous Reset
input [31:0] InputA,InputB ;
output reg[31:0] AbyB;
output reg DONE ; // '0' while calculating, '1' when the result is ready
output reg [1:0]Exception; // Used to output exceptions

//Mantissa and Exponent related Variables
wire [22:0] L_Mantissa_A,L_Mantissa_B;
reg [22:0] L_Mantissa_UnNormalized,L_Mantissa_Normalized;
wire [7:0] L_Exponent_A,L_Exponent_B;
reg [7:0] L_Exponent_unbiased,L_Exponent_unbiased_underflow,L_Exponent_biased;
reg [7:0]L_Exponent_normalized;
wire L_Sign_A,L_Sign_B;
reg L_Sign;

//Output Variables
reg L_Done;
reg [1:0] L_Exception;
reg [31:0] L_AbyB;

// divider related Variables
reg [23:0] a,b;  //M1 and M2
reg [24:0] p=0; //Reminder
integer i,y;

Mantissa_Exponent_Extractor MEE(.InputA(InputA),
                            .InputB(InputB),
                            .Exponent_A(L_Exponent_A),
                            .Exponent_B(L_Exponent_B),
                            .Mantissa_A(L_Mantissa_A),
                            .Mantissa_B(L_Mantissa_B),
                            .Sign_A(L_Sign_A),
                            .Sign_B(L_Sign_B));                                
                            
always@(posedge CLOCK)
begin
if(RESET)
    begin
    L_AbyB=32'bx;
    L_Done=1'b1;
    L_Exception=2'bxx;
    end
else
    begin   
    y=0;
    L_Done=1'b0;    
    L_Exponent_unbiased=L_Exponent_A-L_Exponent_B;//Subtraction of Exponents
    L_Exponent_biased=L_Exponent_unbiased+127;    //adding Bias 
    L_Exponent_unbiased_underflow=L_Exponent_B-L_Exponent_A;
    if(L_Mantissa_B==0 & L_Exponent_B==0)
        begin   
        L_Exception=2'b00;
        L_AbyB=32'bx;  //Divide by  Zero exception
        L_Done=1'b1; 
        end
    else if((L_Exponent_B==8'b1111_1111 & L_Mantissa_B!=0)|(L_Exponent_A==8'b1111_1111 & L_Mantissa_A!=0))
        begin
        L_Exception=2'b11;
        L_AbyB=32'bx;  // NaN exception
        L_Done=1'b1; 
        end
    else if(L_Mantissa_A==0 & L_Exponent_A==0)
        begin
        L_AbyB=32'b0; //Dividend Zero
        L_Done=1'b1; 
        L_Exception=2'bxx; 
        end    
    else if ((L_Exponent_unbiased>127 & L_Exponent_A>L_Exponent_B))
        begin
        L_Exception=2'b10;
        L_AbyB=32'bx; //Overflow exception
        L_Done=1'b1; 
        end
    else if (L_Exponent_unbiased_underflow>127 & L_Exponent_B>L_Exponent_A)
        begin
        L_Exception=2'b01; 
        L_AbyB=32'bx;//Underflow  exception   
        L_Done=1'b1; 
        end
    else
        begin
        a={1'b1,L_Mantissa_A}; ///// appending 1 at the MsB to Mantisssa_A to make it 24 bits.
        b={1'b1,L_Mantissa_B}; ///// appending 1 at the MsB to Mantisssa_B to make it 24 bits.
        p=0;
        /*NON-restoring algorithm Start*/  
        for(i=47;i>0;i=i-1)
        begin
        if (p[24])
            begin
            p={p[23:0],a[23]};
            a=a<<1;	
            p=p+b;
            end
        else
            begin
            p={p[23:0],a[23]};
            a=a<<1;
            p=p-b;
            end

        if (p[24])  
            a[0]=0;  
        else
            a[0]=1;  
        end

        if (p[24])
            p=p+b;   
        /*NON-restoring algorithm End*/ 
        if (a[23]==0)
            y=1;        
        L_Mantissa_UnNormalized=a;
        //Normalizing Exponent and mantissa
        L_Mantissa_Normalized=L_Mantissa_UnNormalized<<y;
        L_Exponent_normalized=L_Exponent_biased-y;
        L_Sign=L_Sign_A^L_Sign_B;
        L_AbyB={L_Sign,L_Exponent_normalized,L_Mantissa_Normalized};
        L_Exception=2'bxx;
        L_Done=1'b1;         
        end
    end
//assigning local variables into output variables     
AbyB<=L_AbyB;
Exception<=L_Exception;
DONE<=L_Done;
end
endmodule

//Getting Exponent,Mantissa and Sign from given 32 bit IEEE inputs
module Mantissa_Exponent_Extractor(
    input [31:0] InputA,
    input [31:0] InputB,
    output [7:0] Exponent_A,
    output [7:0] Exponent_B,
    output [22:0] Mantissa_A,
    output [22:0] Mantissa_B,
    output Sign_A,
    output Sign_B
    );

    assign Sign_A=InputA[31];
    assign Sign_B=InputB[31];
    assign Mantissa_A=InputA[22:0];
    assign Mantissa_B=InputB[22:0];
    assign Exponent_A=InputA[30:23];
    assign Exponent_B=InputB[30:23];
    
endmodule
