/*/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////// FETCH UNIT //////////////////////////////////////////////////////////////////
//////////////////////////////////////// Developed By: Willian Analdo Nunes ///////////////////////////////////////////////////
//////////////////////////////////////////// PUCRS, Porto Alegre, 2020      ///////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

//BUG FIXED --> When a Branch occurs but there was a bubble being propagated in the pipeline the tag of the instruction leaving the fetch stage was being increased wrongly.

module fetch  #(parameter start_address = 32'h00000000)     //Generic start address
    (input logic clk,
    input logic reset,
    input logic [31:0] NewPC,                               // The new Pc addrress  
    output logic [31:0] i_address,                           // Instruction address in memory (PC) 
    output logic [31:0] NPC,                                 // The Actual PC Address
    output logic [3:0] tag_out);                          // Instruction Tag 

    reg [31:0] PC, NPC_int;
    logic [3:0] tag, tag_int;
    logic [31:0] result_reg, nextPC;
    wire selector;
    wire [31:0] PC_int;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    assign i_address = PC;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    always @(posedge clk or negedge reset)
        if(!reset)
            PC <= start_address;
        else
            PC <= PC_int;

    probe s (.a(|NewPC), .q(selector), .*);

    for (genvar i = 0; i < 32 ; i++) begin
      hold jump_h (.a(result_reg[i]), .en(selector), .q(PC_int[i]), .*);
      discard sum_d (.a(nextPC[i]), .en(!selector), .q(PC_int[i]), .*);
    end

    always@(posedge clk) begin
        result_reg <= NewPC;
        nextPC <= PC+4;
        NPC_int <= PC;
        NPC <= NPC_int;
    end

/////////////////////////////////////////////////////////// TAG ///////////////////////////////////////////////////////////////////////////

    always@(posedge clk or negedge reset) 
      if(!reset)
        tag <= '0;
      else if(selector)
        tag <= tag+1;


    always@(posedge clk) begin
      tag_int = tag;            //BUFFER
      tag_out = tag_int;
    end

endmodule