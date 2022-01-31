/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 /////////////////////////////////////////////////// ADDER UNIT ////////////////////////////////////////////////////////////////
 //////////////////////////////////////// Developed By: Willian Analdo Nunes ///////////////////////////////////////////////////
 //////////////////////////////////////////// PUCRS, Porto Alegre, 2020      ///////////////////////////////////////////////////
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "pkg.sv"
import my_pkg::*;

module adder #(parameter  DEPTH = 3)
    (input logic clk,
    input logic [31:0]  opA,
    input logic [31:0]  opB,
    input instruction_type i,
    output logic [31:0] result_out);

    logic [31:0]        result[DEPTH];

    assign result_out = result[DEPTH-1];

    always @(posedge clk) begin
        for(int i = 1; i < DEPTH; i++)
          result[i] <= result[i-1];

        if(i==OP3)                        // Set if opA is less than opB
          if($signed(opA) < $signed(opB))
            result[0] <= 32'b1;
          else
            result[0] <= 32'b0;

        else if(i==OP2)                 // Set if opA is less than opB UNSIGNED
          if($unsigned(opA) < $unsigned(opB))
            result[0] <= 32'b1;
          else
            result[0] <= 32'b0;

        else if(i==OP1)                             // SUBTRACT
          result[0] <= opA - opB;

        else                                         // ADD (ADD,ADDI and AUIPC)
          result[0] <= opA + opB;
    end



  endmodule
