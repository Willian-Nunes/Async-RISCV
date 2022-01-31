`include "fetch.sv"
`include "decoder.sv"
`include "RLL.sv"
`include "execute.sv"
`include "retire.sv"

//`define debug 1
//`include "pkg.sv"
import my_pkg::*;

module ARV(
    input logic clk,
    input logic reset,
    input logic [31:0] instruction,
    output logic [31:0] i_address,
    /////////////////////////////////
    output logic [31:0] read_address,
    output logic read,
    input logic [31:0] DATA_in,
    /////////////////////////////////
    output logic [31:0] write_address, 
    output logic [31:0] DATA_out,
    output logic write,
    output logic [1:0] size,
    /////////////////////////////////
    `ifdef debug
    output logic reg_we,
    output logic [31:0] WrData,
    output logic [31:0] New_pc,
    /////////////////////////////////
    output logic [31:0] NPC_decoder,
    output logic [3:0] tag_decoder,
    /////////////////////////////////
    output logic [4:0] regA,
    output logic [4:0] regB,
    output logic [4:0] regD,
    output logic [31:0] NPC_RLL,
    output fmts fmt_RLL,
    output logic [31:0] instruction_RLL,
    output instruction_type i_RLL,
    output xu xu_RLL,
    output logic [3:0] tag_RLL,
    ///////////////////////////
    output logic [31:1] addrW,
    output logic [31:0] locked,
    ///////////////////////////////
    output instruction_type i_exec,
    output xu xu_exec,
    output logic [3:0] tag_exec,
    output logic [31:0] opA,
    output logic [31:0] opB,
    output logic [31:0] opC,
    output logic [31:0] NPC,
    /////////////////////////////////////
    output logic [31:0] result_ret [1:0],
    output logic we_ret,
    output logic jump_ret,
    output logic [3:0] tag_ret,
    output logic write_ret,
    output logic [1:0] size_ret
    `endif
    );
/******************************/
    parameter TOKENS = 3;
    parameter DEPTH = 3;
/******************************/

    logic [4:0] regA, regB, regD;
    logic [31:0] NPC_decoder, NPC_RLL, instruction_RLL; 
    fmts fmt_RLL;
    instruction_type i_RLL, i_exec, i_ret, i_int;
    xu xu_RLL, xu_exec, xu_int;
    logic [3:0] tag_decoder, tag_RLL, tag_exec, tag_ret, tag_int;
    

    logic [31:0] result_ret [1:0];
    logic jump_ret, write_ret;
    logic [1:0] size_ret;
    logic we_ret;

    logic we_int, we_int2, we_int3, reg_we;
    logic [31:0] WrData_int, WrData_int2, WrData, New_pc;
    logic [31:0] New_pc_int, New_pc_int2;
    logic [31:0] NPC_decoder_int;

    logic [31:1] addrW;
    logic [31:0] locked;

    logic [31:0] opA, opB, opC, NPC, opA_int, opB_int, opC_int, NPC_int;
    logic [31:0] opA_queue[TOKENS];
    logic [31:0] opB_queue[TOKENS];
    logic [31:0] opC_queue[TOKENS];
    logic [31:0] NPC_queue[TOKENS];
    logic [3:0] tag_queue[TOKENS];
    instruction_type i_queue[TOKENS];
    xu xu_queue[TOKENS];

    assign  opA = opA_queue[TOKENS-1],
            opB = opB_queue[TOKENS-1],
            opC = opC_queue[TOKENS-1],
            NPC = NPC_queue[TOKENS-1],
            i_exec = i_queue[TOKENS-1],
            xu_exec = xu_queue[TOKENS-1],
            tag_exec = tag_queue[TOKENS-1];

    always@(posedge clk or negedge reset) begin
      if(!reset) begin
          for(int i = 0; i < TOKENS; i++) begin
            i_queue[i] <= OP0;
            xu_queue[i] <= bypass;
            tag_queue[i] <= '0;
            opA_queue[i] <= '0;
            opB_queue[i] <= '0;
            opC_queue[i] <= '0;
            NPC_queue[i] <= '0;
          end

      end else begin
        i_queue[0] <= i_int;
        xu_queue[0] <= xu_int;
        tag_queue[0] <= tag_int;
        opA_queue[0] <= opA_int;
        opB_queue[0] <= opB_int;
        opC_queue[0] <= opC_int;
        NPC_queue[0] <= NPC_int;
        for(int i = 1; i < TOKENS; i++) begin
            i_queue[i] <= i_queue[i-1];
            xu_queue[i] <= xu_queue[i-1];
            tag_queue[i] <= tag_queue[i-1];
            opA_queue[i] <= opA_queue[i-1];
            opB_queue[i] <= opB_queue[i-1];
            opC_queue[i] <= opC_queue[i-1];
            NPC_queue[i] <= NPC_queue[i-1];
        end
      end
    end

    always@(posedge clk) begin
        New_pc_int2 <= New_pc_int;
        New_pc <= New_pc_int2;
    end


    fetch Ifetch (  .NewPC(New_pc),
                    .NPC(NPC_decoder), .tag_out(tag_decoder), .*);

    decoder decode ( .NPC_IN(NPC_decoder), .tag_in(tag_decoder),
                    .i_out(i_RLL), .tag_out(tag_RLL), .NPC_out(NPC_RLL), .instruction_out(instruction_RLL), .fmt_out(fmt_RLL), .xu_sel(xu_RLL), .*);

    RLL #(TOKENS) RLL1( .NPC_in(NPC_RLL), .instruction(instruction_RLL), .i(i_RLL), .xu_sel_in(xu_RLL), .fmt(fmt_RLL), .tag_in(tag_RLL), .we(reg_we), .in(WrData),
                .opA(opA_int), .opB(opB_int), .opC(opC_int), .NPC(NPC_int),
                .i_out(i_int), .xu_sel(xu_int), .tag_out(tag_int), .*);

    execute #(DEPTH) Exec ( .i(i_exec), .xu_sel(xu_exec), .tag_in(tag_exec),
                   .result_out(result_ret), .jump_out(jump_ret), .stream_tag_out(tag_ret), .write(write_ret), .size(size_ret), .we_out(we_ret), .*);

    retire Retire (.result(result_ret), .jump(jump_ret), .instruction_tag(tag_ret), .write_in(write_ret), .size_in(size_ret), .we(we_ret), 
                    .reg_we(reg_we), .WrData(WrData), .New_pc(New_pc_int), .*);

endmodule
