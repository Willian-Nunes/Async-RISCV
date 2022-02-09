`include "pkg.sv"
import my_pkg::*;

module OPF #(parameter TOKENS = 4)
    (input logic clk, reset,
    input logic we,
    input logic [4:0] regA,
    input logic [4:0] regB,
    input logic [4:0] regD,
    input logic [31:0] NPC_in,
    input logic [31:0] instruction,
    input instruction_type i,
    input xu xu_sel_in,
    input fmts fmt,
    input logic [3:0] tag_in,
    output logic [4:0] addrA,
    output logic [4:0] addrB,
    output logic [31:1] addrW,
    output logic [31:0] locked,
    output instruction_type i_out,
    output xu xu_sel,
    output logic [3:0] tag_out,
    input logic [31:0] dataA,
    input logic [31:0] dataB,
    output logic [31:0] opA,
    output logic [31:0] opB,
    output logic [31:0] opC,
    output logic [31:0] NPC
    );

    typedef enum bit {LOCK, UNLOCK} state_t;
    logic [4:0] aa, bb, dd;
    logic [31:0] NPC_r, instruction_r, NPC_next, NPC_int, instruction_next;
    logic [3:0] tag_r, tag_next, tag_int;
    logic [2:0] fmt_r, fmt_next;
    state_t             ps, ns;
    logic               accept_input;
    instruction_type i_r, i_next;
    xu xu_next, xu_r;
    logic [31:0] locked_r, target_int;
    logic [31:0] dataA_int, dataB_int, opA_int, opB_int, opC_int, imed;

    wor [31:0] locked;
    logic [31:0] lock_queue[TOKENS];

    assign aa = instruction_r[19:15];
    assign bb = instruction_r[24:20];
    assign dd = instruction_r[11:7];


    // Control FSM
    always_ff @(posedge clk or negedge reset)
      if (!reset)
        ps <= UNLOCK;
      else
        ps <= ns;

    always_comb
      if((locked_r[aa]==1 || locked_r[bb]==1) || (locked_r[0]==1 &&  (xu_r==memory && (i_r==OP0 | i_r==OP1 | i_r==OP2 | i_r==OP3 | i_r==OP4)))) 
        ns <= LOCK;
      else 
        ns <= UNLOCK;
 
    always_comb
      accept_input <= ps == UNLOCK ? 1'b1 : 1'b0;


    for (genvar i = 0 ; i < 32 ; i++) begin
        discard discard_NPC (.a(NPC_next[i]), .en(!accept_input), .q(NPC_r[i]), .*);
        hold hold_NPC (.a(NPC_in[i]), .en(accept_input), .q(NPC_r[i]), .*);

        discard discard_inst (.a(instruction_next[i]), .en(!accept_input), .q(instruction_r[i]), .*);
        hold hold_inst (.a(instruction[i]), .en(accept_input), .q(instruction_r[i]), .*);
    end

    for (genvar j = 0 ; j < 3 ; j++) begin
        discard discard_i (.a(i_next[j]), .en(!accept_input), .q(i_r[j]), .*);
        hold hold_i (.a(i[j]), .en(accept_input), .q(i_r[j]), .*);
    end

    for (genvar j = 0 ; j < 3 ; j++) begin
        discard discard_xu (.a(xu_next[j]), .en(!accept_input), .q(xu_r[j]), .*);
        hold hold_xu (.a(xu_sel_in[j]), .en(accept_input), .q(xu_r[j]), .*);
    end

    for (genvar j = 0 ; j < 3 ; j++) begin
        discard discard_fmt (.a(fmt_next[j]), .en(!accept_input), .q(fmt_r[j]), .*);
        hold hold_fmt (.a(fmt[j]), .en(accept_input), .q(fmt_r[j]), .*);
    end

    for (genvar j = 0 ; j < 4 ; j++) begin
        discard discard_tag (.a(tag_next[j]), .en(!accept_input), .q(tag_r[j]), .*);
        hold hold_tag (.a(tag_in[j]), .en(accept_input), .q(tag_r[j]), .*);
    end


    always_ff @(posedge clk or negedge reset)
        if (!reset) begin
            NPC_next <= '0;
            instruction_next <= '0;
            i_next <= '0;
            xu_next <= '0;
            fmt_next <= '0;
            tag_next <= '0;
        end else begin
            NPC_next <= NPC_r;
            instruction_next <= instruction_r;
            i_next <= i_r;
            xu_next <= xu_r;
            fmt_next <= fmt_r;
            tag_next <= tag_r;
        end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////// Conversion to one-hot codification ///////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always_comb begin
        target_int <= 1 << dd;

        if(xu_r==memory && (i_r==OP5 | i_r==OP6 | i_r==OP7))
            target_int[0] <= 1;
        else
            target_int[0] <= 0;
    end

///////////////////////////////////////////////////// Implement the queue //////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge reset)  
        if(!reset)                                      // At reset clear the queue
            for (int i = 0; i < TOKENS; i++)
                lock_queue[i] <= '0;
        else begin
            for (int j = 0; j < TOKENS-1; j++)
                lock_queue[j+1] <= lock_queue[j];       // Move the queue forward
            
            if(ns==LOCK)
                lock_queue[0] <= '0;
            else
                lock_queue[0] <= target_int;
        end

    generate
    for(genvar w = 0; w < TOKENS; w++) 
        assign locked = lock_queue[w];
    endgenerate

    always@(posedge clk) begin
        locked_r <= locked;
        addrW <= lock_queue[TOKENS-2][31:1] & {32{we}};
    end

////////////////////////////////////////////////////////// regbank input ////////////////////////////////////////////////////////////////////////////
    always@(posedge clk) begin
      dataA_int <= dataA;
      dataB_int <= dataB;
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// Extracts the immediate based on instruction type. //////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always_comb
        case(fmt_r)
            I_type: begin
                        imed[31:11] <= (instruction_r[31]==0) ? '0 : '1;
                        imed[10:0] <= instruction_r[30:20];
                    end

            S_type: begin
                        imed[31:11] <= (instruction_r[31]==0) ? '0 : '1;
                        imed[10:5] <= instruction_r[30:25];
                        imed[4:0]  <= instruction_r[11:7];
                    end

            B_type: begin
                        imed[31:12] <= (instruction_r[31]==0) ? '0 : '1;
                        imed[11] <= instruction_r[7];
                        imed[10:5] <= instruction_r[30:25];
                        imed[4:1] <= instruction_r[11:8];
                        imed[0] <= 0;
                    end

            U_type: begin
                        imed[31:12] <= instruction_r[31:12];
                        imed[11:0] <= '0;
                    end

            J_type: begin
                        imed[31:20] <= (instruction_r[31]==0) ? '0 : '1;
                        imed[19:12] <= instruction_r[19:12];
                        imed[11] <= instruction_r[20];
                        imed[10:5] <= instruction_r[30:25];
                        imed[4:1] <= instruction_r[24:21];
                        imed[0] <= 0;
                    end

            default:      imed[31:0] <= '0;
        endcase

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////// Control of the exits based on format //////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always_comb begin
        opA_int <= (fmt_r==U_type | fmt_r==J_type) ? NPC_r     : dataA_int;
        opB_int <= (fmt_r==R_type | fmt_r==B_type) ? dataB_int : imed;
        opC_int <= (fmt_r==S_type)                 ? dataB_int : imed;
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////// OUTPUTS ////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always@(posedge clk) begin
        if(ns==LOCK) begin
            i_out <= '0;
            xu_sel <= '0;
            tag_out<='0;
            opA <= '0;
            opB <= '0;
            opC <= '0;
            NPC <= '0;
        end else begin
            i_out <= i_r;
            xu_sel <= xu_r;
            tag_out <= tag_int;
            opA <= opA_int;
            opB <= opB_int;
            opC <= opC_int;
            NPC <= NPC_int;
        end
    end

    always@(posedge clk) begin
        NPC_int <= NPC_r;
        tag_int <= tag_r;
        addrA <= aa;
        addrB <= bb;
    end
endmodule