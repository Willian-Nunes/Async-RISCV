/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////// RETIRE UNIT //////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// Developed By: Willian Analdo Nunes /////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// PUCRS, Porto Alegre, 2020      /////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "pkg.sv"
import my_pkg::*;

module retire(
    input logic clk,
    input logic reset,
    input logic [31:0] result [1:0],        // Results vector(one from each unit)
    input logic jump,                       // Jump signal from branch unit
    input logic we,
    input logic [3:0] instruction_tag,      // Instruction tag to be compared with retire tag
    input logic write_in,
    input logic [1:0] size_in,
    output logic reg_we,              // Write Enable to Register Bank
    output logic [31:0] WrData,
    output logic [31:0] New_pc,
    output logic [31:0] write_address,  
    output logic [31:0] DATA_out,
    output logic write,
    output logic [1:0] size
    );

    logic [3:0] curr_tag;
    logic killed;
    logic [31:0] WrData_int;
    logic reg_we_int;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always@(posedge clk) begin
        WrData_int <= result[0];
        WrData <= WrData_int;
        reg_we <= reg_we_int;
    end

////////////////////////////////////////////////////// Killed signal generation /////////////////////////////////////////////////////////////////////
    always_comb
        if (curr_tag != instruction_tag)
            killed <= 1;
        else
            killed <= 0;

//////////////////////////////////////////////////// TAG control based on signals Jump and Killed ///////////////////////////////////////////////////
    always @(posedge clk or negedge reset) begin
        if(!reset)
            curr_tag <= 0;
        else if (jump==1 && killed==0)      // If a jump was taken and the tag is correct
            curr_tag <= curr_tag + 1;
        else  
            curr_tag <= curr_tag;
    end

/////////////////////////////////////////////////// Flow Control ////////////////////////////////////////////////////////////////////////////////////
    always@(posedge clk)
        if(killed)
          reg_we_int <= 0;
        else 
          reg_we_int <= we;

//////////////////////////////////// PC Flow control signal generation //////////////////////////////////////////////////////////////////////////////
    for (genvar i=0; i < $bits(New_pc); i++)
        discard NewPC_D (.a(result[1][i]), .q(New_pc[i]), .en(jump==1 && killed==0), .*);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    discard write_D (.a(write_in), .q(write), .en(write_in==1 && killed==0), .*);

    for (genvar i=0; i < $bits(size); i++)
        discard size_D (.a(size_in[i]), .q(size[i]), .en(write_in==1 && killed==0), .*);
    
    for (genvar i=0; i < $bits(write_address); i++) begin
        discard WrAdd_D (.a(result[1][i]), .q(write_address[i]), .en(write_in==1 && killed==0), .*);
        discard Dout_D (.a(result[0][i]), .q(DATA_out[i]), .en(write_in==1 && killed==0), .*);
    end
endmodule
