/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ////////////////////////////////////////////////// BRANCH UNIT //////////////////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////// Developed By: Willian Analdo Nunes /////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////////// PUCRS, Porto Alegre, 2020      /////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "pkg.sv"
import my_pkg::*;

module branchUnit #(parameter  DEPTH = 3)
    (input logic clk,
    input logic [31:0]  opA,
    input logic [31:0]  opB,
    input logic [31:0]  offset,
    input logic [31:0]  NPC,
    input instruction_type i,
    output logic [31:0] result_out,
    output logic [31:0] result_jal,
    output logic        jump_out,
    output logic        we_out);

    logic [31:0]        result[DEPTH], result_int;
    logic [31:0]        result_jal_int[DEPTH];
    logic               jump[DEPTH];
    logic               we_int[DEPTH];

    assign result_int = opA + opB;                  // Generates the JALR target
  ////////////////////////////////////////////////////////////// Result assign ////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
      if(i==OP6) begin
          result[0] <= opA + opB;                   // OPA==PC e OPB==OFFSET
          result_jal_int[0] <= NPC+4;               // The return address is the instruction following the JAL
      end else if(i==OP7) begin
          result[0][31:1] <= result_int[31:1];      // JALR result recieves the target calculated and assigned to result_int
          result[0][0]<=0;                          // The lest significant digit is 0
          result_jal_int[0] <= NPC+4;               // The return address is the instruction following the JAL
      end else begin
          result[0] <= NPC + offset;                // The new PC address is PC + imediate
          result_jal_int[0] <= 32'h00000000;        // Return address is not used
      end

        if(i==OP0)                                  // Branch if equal
          jump[0] <= (opA == opB);
        else if(i==OP1)                             // Branch if not equal
          jump[0] <= (opA != opB);
        else if(i==OP2)                             // Branch if less than
          jump[0] <= ($signed(opA) < $signed(opB));
        else if(i==OP3)                             // Branch if less than unsigned
          jump[0] <= ($unsigned(opA) < $unsigned(opB));
        else if(i==OP4)                             // Branch if greather than
          jump[0] <= ($signed(opA) >= $signed(opB));
        else if(i==OP5)                             // Branch if greather than
          jump[0] <= ($unsigned(opA) >= $unsigned(opB));
        else if(i==OP6 || i==OP7)                   // Unconditional Branches
          jump[0] <= 1;
        else
          jump[0] <= 0;

      if(i==OP6 || i==OP7)
        we_int[0] <= '1;
      else 
        we_int[0] <= '0;
    end

    always @(posedge clk) begin
      for(int i = 1; i < DEPTH; i++) begin
        result[i] <= result[i-1];
        result_jal_int[i] <= result_jal_int[i-1];
        jump[i] <= jump[i-1];
        we_int[i] <= we_int[i-1];
      end
    end

    always_comb begin
          result_out <= result[DEPTH-1];
          result_jal <= result_jal_int[DEPTH-1];
          jump_out <= jump[DEPTH-1];
          we_out <= we_int[DEPTH-1];
      end

endmodule
