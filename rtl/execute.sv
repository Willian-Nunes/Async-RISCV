/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////// EXECUTE UNIT //////////////////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////// Developed By: Willian Analdo Nunes /////////////////////////////////////////////////////////////////////////
 //////////////////////////////////////////// PUCRS, Porto Alegre, 2020      /////////////////////////////////////////////////////////////////////////
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "adder.sv"
`include "logicUnit.sv"
`include "shiftUnit.sv"
`include "branchUnit.sv"
`include "bypassUnit.sv"
`include "memoryUnit.sv"

//`include "pkg.sv"
import my_pkg::*;

  module execute #(parameter  DEPTH = 3)
   (input logic         clk,
    input logic         reset,
    input logic [31:0]  NPC, // Operands from Operand Fetch stage
    input logic [31:0]  opA, //              ||
    input logic [31:0]  opB, //              ||
    input logic [31:0]  opC, //              ||
    input instruction_type i,
    input xu xu_sel,
    input logic [3:0] tag_in,
    output logic [31:0] result_out [1:0], // Results
    output logic jump_out,                       // Signal that indicates a branch taken
    output logic [3:0] stream_tag_out,
    output logic we_out,
    output logic [31:0] read_address,
    output logic read,                            // Ce to memory read
    input logic [31:0] DATA_in,                 // Data coming from memory
    output logic [3:0] write);                            // Signal that indicates the write memory operation

    logic jump_int, we_branchUnit, we_memoryUnit;
    logic [3:0] write_int;
    logic [4:0] shiftB;
    logic [31:0] adderA, adderB, logicA, logicB, shiftA, branchA, branchB, branchC, memoryA, memoryB, memoryC, bypassB, NPCbranch, result [7:0];
    instruction_type adder_i, logic_i, shift_i, branch_i, memory_i, queue_i;

    logic [3:0] stream_tag_queue[DEPTH];
    xu xu_int[DEPTH];

    ////////////////////////////////////////////////////// Instantiation of execution units  /////////////////////////////////////////////////////////////
    adder      #(DEPTH)  adder1   (.clk(clk), .opA(adderA), .opB(adderB), .i(adder_i), .result_out(result[0]));
    logicUnit  #(DEPTH) logical1 (.clk(clk), .opA(logicA), .opB(logicB), .i(logic_i), .result_out(result[1]));
    shiftUnit  #(DEPTH) shift1   (.clk(clk), .opA(shiftA), .opB(shiftB), .i(shift_i), .result_out(result[2]));
    branchUnit #(DEPTH) branch1  (.clk(clk), .opA(branchA), .opB(branchB), .offset(branchC), .NPC(NPCbranch), .i(branch_i), .result_out(result[4]), .result_jal(result[3]), .jump_out(jump_int), .we_out(we_branchUnit));
    bypassUnit #(DEPTH) bypass1  (.clk(clk), .opA(bypassB), .result_out(result[5]));
    memoryUnit #(DEPTH) memory1  (.clk(clk), .opA(memoryA), .opB(memoryB), .data(memoryC), .i(memory_i), .read_address(read_address), .read(read), .DATA_in(DATA_in), .write_address(result[7]), .DATA_wb(result[6]),  .write(write_int), .we_out(we_memoryUnit));
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    always@(posedge clk) begin
      xu_int[0] <= xu_sel;
      stream_tag_queue[0] <= tag_in;

      for(int i = 1 ; i < DEPTH ; i++) begin
        xu_int[i] <= xu_int[i-1];
        stream_tag_queue[i] <= stream_tag_queue[i-1];
      end
      stream_tag_out <= stream_tag_queue[DEPTH-1];
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////// MUX /////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    for (genvar i=0; i < $bits(opA); i++) begin
      discard bypass_B (.a(opB[i]), .q(bypassB[i]), .en(xu_sel==bypass), .*);

      discard adder_A (.a(opA[i]), .q(adderA[i]), .en(xu_sel==adder), .*);
      discard adder_B (.a(opB[i]), .q(adderB[i]), .en(xu_sel==adder), .*);

      discard logic_A (.a(opA[i]), .q(logicA[i]), .en(xu_sel==logical), .*);
      discard logic_B (.a(opB[i]), .q(logicB[i]), .en(xu_sel==logical), .*);

      discard shift_A (.a(opA[i]), .q(shiftA[i]), .en(xu_sel==shifter), .*);

      discard branch_A (.a(opA[i]), .q(branchA[i]), .en(xu_sel==branch), .*);
      discard branch_B (.a(opB[i]), .q(branchB[i]), .en(xu_sel==branch), .*);
      discard branch_C (.a(opC[i]), .q(branchC[i]), .en(xu_sel==branch), .*);
      discard branch_NPC (.a(NPC[i]), .q(NPCbranch[i]), .en(xu_sel==branch), .*);

      discard memory_A (.a(opA[i]), .q(memoryA[i]), .en(xu_sel==memory), .*);
      discard memory_B (.a(opB[i]), .q(memoryB[i]), .en(xu_sel==memory), .*);
      discard memory_C (.a(opC[i]), .q(memoryC[i]), .en(xu_sel==memory), .*);
  end

  for (genvar k=0; k < 5; k++)
      discard shift_B (.a(opB[k]), .q(shiftB[k]), .en(xu_sel==shifter), .*);

  for (genvar j=0; j < $bits(i); j++) begin
      discard adder_i (.a(i[j]), .q(adder_i[j]), .en(xu_sel==adder), .*);
      discard logic_i (.a(i[j]), .q(logic_i[j]), .en(xu_sel==logical), .*);
      discard shift_i (.a(i[j]), .q(shift_i[j]), .en(xu_sel==shifter), .*);
      discard branch_i (.a(i[j]), .q(branch_i[j]), .en(xu_sel==branch), .*);
      discard memory_i (.a(i[j]), .q(memory_i[j]), .en(xu_sel==memory), .*);
  end
 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////// DEMUX ////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    for (genvar i = 0; i < 32 ; i++) begin
      hold adder_h (.a(result[0][i]), .en(xu_int[DEPTH-1]==adder), .q(result_out[0][i]), .*);
      hold logic_h (.a(result[1][i]), .en(xu_int[DEPTH-1]==logical), .q(result_out[0][i]), .*);
      hold shift_h (.a(result[2][i]), .en(xu_int[DEPTH-1]==shifter), .q(result_out[0][i]), .*);
      hold branch_h (.a(result[3][i]), .en(xu_int[DEPTH-1]==branch), .q(result_out[0][i]), .*);
      hold bypass_h (.a(result[5][i]), .en(xu_int[DEPTH-1]==bypass), .q(result_out[0][i]), .*);
      hold dataWB_h (.a(result[6][i]), .en(xu_int[DEPTH-1]==memory), .q(result_out[0][i]), .*);
    end

    for (genvar i = 0; i < 32 ; i++) begin
      hold branchjal_h (.a(result[4][i]), .en(xu_int[DEPTH-1]==branch), .q(result_out[1][i]), .*);
      hold WriteADD_h (.a(result[7][i]), .en(xu_int[DEPTH-1]==memory), .q(result_out[1][i]), .*);
      discard zero1_d (.a(0), .en(xu_int[DEPTH-1]!=branch && xu_int[DEPTH-1]!=memory), .q(result_out[1][i]), .*);
    end

    hold jump_h (.a(jump_int), .en(xu_int[DEPTH-1]==branch), .q(jump_out), .*);
    discard zeroJ_d (.a(0), .en(xu_int[DEPTH-1]!=branch), .q(jump_out), .*);
    
    for (genvar i = 0; i < 4 ; i++) begin
      hold write_h (.a(write_int[i]), .en(xu_int[DEPTH-1]==memory), .q(write[i]), .*);
      discard zeroW_d (.a(0), .en(xu_int[DEPTH-1]!=memory), .q(write[i]), .*);
    end
    
    hold WeBrUn_h (.a(we_branchUnit), .en(xu_int[DEPTH-1]==branch), .q(we_out), .*);
    hold WeMemUn_h (.a(we_memoryUnit), .en(xu_int[DEPTH-1]==memory), .q(we_out), .*);
    discard Weone_d (.a(1), .en(xu_int[DEPTH-1]!=branch && xu_int[DEPTH-1]!=memory), .q(we_out), .*);


endmodule
