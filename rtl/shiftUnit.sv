/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 /////////////////////////////////////////////////// SHIFT UNIT ////////////////////////////////////////////////////////////////
 //////////////////////////////////////// Developed By: Willian Analdo Nunes ///////////////////////////////////////////////////
 //////////////////////////////////////////// PUCRS, Porto Alegre, 2020      ///////////////////////////////////////////////////
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

// BUG FIXED --> Arithmetic Shift was identified as an error in Berkeley Suite because the rtl operand used was ">>" what is logic shift, and arithmetic shift is ">>>"

`include "pkg.sv"
import my_pkg::*;

module shiftUnit #(parameter  DEPTH = 3)
    (input logic clk,
    input logic [31:0]  opA,
    input logic [4:0]  opB,
    input               instruction_type i,
    output logic [31:0] result_out);

    logic [31:0]        result[DEPTH];

    assign result_out = result[DEPTH-1];

    always @(posedge clk) begin
        for(int i = 1; i < DEPTH; i++)
            result[i] <= result[i-1];

        if(i==OP0)                // Shift logic left
            result[0] <= opA << opB;
        else if(i==OP1)
            result[0] <= opA >> opB;  // Shift logic right
        else
            result[0] <= $signed(opA) >>> opB; // Shift arithmetic right
    end

endmodule
