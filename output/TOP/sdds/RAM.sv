//`include "pkg.sv"
`timescale 1ns/1ps
import my_pkg::*;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////// ASSYNC RAM MEMORY IMPLEMENTATION ////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RAM_mem #(parameter startaddress = 32'h00000000)(
    input logic [3:0] write_enable, 
    input logic read_enable,
    input logic rst,  
    input wires32 inst_address, 
    input wires32 write_address,
    input wires32 read_address,
    input wires32 data_in,
    output wires32 instruction_out,
    output wires32 data_out
    );

bit [7:0] RAM [0:4194303];
wires32 W_tmp_address, R_tmp_address, INST_tmp_address;
wires16 W_low_address, R_low_address, INST_low_address;
int W_low_address_int, R_low_address_int, INST_low_address_int;
int fd, r;
int i;

    assign W_tmp_address = write_address - startaddress;            //  Address offset 
    assign W_low_address = W_tmp_address[15:0];                 // Considers only the less significant half
    assign W_low_address_int = W_low_address;                   // convert to integer

    assign R_tmp_address = read_address - startaddress;            //  Address offset 
    assign R_low_address = R_tmp_address[15:0];                 // Considers only the less significant half
    assign R_low_address_int = R_low_address;                   // convert to integer

    assign INST_tmp_address = inst_address - startaddress;            //  Address offset 
    assign INST_low_address = INST_tmp_address[15:0];                 // Considers only the less significant half
    assign INST_low_address_int = INST_low_address;   


    initial begin
        fd = $fopen ("/home/williannunes/test.bin", "r");
        //fd = $fopen ("/home/williannunes/test_hanoi.bin", "r");
        //fd = $fopen ("/home/williannunes/coremarkDebug.bin", "r");

        r = $fread(RAM, fd);
        $display("read %d elements \n", r);
    end

////////////////////////////////////////////////////////////// Writes in memory ASYNCHRONOUSLY //////////////////////////////////////////////////////
    always @(write_enable or W_low_address) begin               // Sensitivity list 
        if(write_enable!=0 && W_low_address_int>=0 && W_low_address_int<=(MEMORY_SIZE-3)) begin // Check address range and write signals
                if(write_address==32'h80001000)
                    //$display("[%0d] write %0d(%h) in add: %0d(%h) \n", $time, data_in,data_in,W_low_address_int,W_low_address_int);
                    ;
                else if(write_enable==4'b1111) begin                                    // Store Word(4 bytes)
                    RAM[W_low_address_int+3] <= data_in[31:24];
                    RAM[W_low_address_int+2] <= data_in[23:16];
                    RAM[W_low_address_int+1] <= data_in[15:8];
                    RAM[W_low_address_int] <= data_in[7:0];
                end else if(write_enable==4'b0011) begin                                // Store Half(2 bytes)
                    RAM[W_low_address_int+1] <= data_in[15:8];
                    RAM[W_low_address_int] <= data_in[7:0];
                end else                                                                // Store Byte(1 byte)
                    RAM[W_low_address_int] <= data_in[7:0];
        end
    end

////////////////////////////////////////////////////////////// Read DATA from memory /////////////////////////////////////////////////////////////////////
    always @(read_enable or R_low_address or INST_low_address) begin
        if(read_enable==1 && R_low_address_int>=0 && R_low_address_int<=(MEMORY_SIZE-3)) begin // Check address range and read signals
            data_out[31:24] <= RAM[R_low_address_int+3];
            data_out[23:16] <= RAM[R_low_address_int+2];
            data_out[15:8] <= RAM[R_low_address_int+1];
            data_out[7:0] <= RAM[R_low_address_int];
        end
    end

////////////////////////////////////////////////////////////// Read INSTRUCTION from memory /////////////////////////////////////////////////////////////////////
    always @(rst or INST_low_address) begin
        if(rst==1 && INST_low_address_int>=0 && INST_low_address_int<=(MEMORY_SIZE-3)) begin // Check address range and read signals
            instruction_out[31:24] <= RAM[INST_low_address_int+3];
            instruction_out[23:16] <= RAM[INST_low_address_int+2];
            instruction_out[15:8] <= RAM[INST_low_address_int+1];
            instruction_out[7:0] <= RAM[INST_low_address_int];
        end
    end
endmodule