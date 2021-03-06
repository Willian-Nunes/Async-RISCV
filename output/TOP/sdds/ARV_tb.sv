`timescale 1ns/1ps
`include "/home/williannunes/ARV/rtl/pkg.sv"
`include "./RAM.sv"
`include "./freepdk45/8.00/logical.v"
//`include "/soft64/async/ferramentas/pulsar/v2.0/tech/freepdk45/sdds.sv"
//`include "/soft64/async/ferramentas/pulsar/v2.0/tech/freepdk45/ASCEND_FREEPDK45.v"
`include "/home/williannunes/ARV/ASCEND_FREEPDK45.v"
//`define debug 1

import my_pkg::*;

module  ARV_tb ();

    logic clk, reset;

    logic ackout;
    logic [31:0] i_address_t, i_address_f, i_address_ack;
    logic [31:0] instruction_t, instruction_f, instruction_ack;
    logic read_i;
    logic [31:0] i_address, instruction_int;

    `ifdef debug
        logic [31:0] New_pc_t, New_pc_f, New_pc_ack, New_pc;
        logic reg_we_t, reg_we_f, reg_we_ack;
        logic [31:0] WrData_t, WrData_f, WrData_ack;
    `endif

    logic read_t, read_f, read_ack;
    logic [31:0] read_address_t, read_address_f, read_address_ack, DATA_in_t, DATA_in_f, DATA_in_ack;

    logic [3:0] write_t, write_f, write_ack;
    logic [31:0] write_address_t, write_address_f, write_address_ack, DATA_out_t, DATA_out_f, DATA_out_ack;

    `ifdef debug
        logic [31:0] NPC_decoder_t, NPC_decoder_f, NPC_decoder_ack;
        logic [3:0] tag_decoder_t, tag_decoder_f, tag_decoder_ack;
    ///////////////////////////////////////////////////////////////////////////////
        logic [2:0] i_RLL_t, i_RLL_f, i_RLL_ack, xu_RLL_t, xu_RLL_f, xu_RLL_ack;
        logic [4:0] regA_t, regA_f, regA_ack, regB_t, regB_f, regB_ack, regD_t, regD_f, regD_ack;
        logic [31:0] NPC_RLL_t, NPC_RLL_f, NPC_RLL_ack, instruction_RLL_t, instruction_RLL_f, instruction_RLL_ack;
        logic [2:0] fmt_RLL_t, fmt_RLL_f, fmt_RLL_ack;
        logic [3:0] tag_RLL_t, tag_RLL_f, tag_RLL_ack;
    ///////////////////////////////////////////////////////////////////////////////
        logic [2:0] i_exec_t, i_exec_f, i_exec_ack, xu_exec_t, xu_exec_f, xu_exec_ack;
        logic [3:0] tag_exec_t, tag_exec_f, tag_exec_ack;
        logic [31:0] opA_t, opA_f, opA_ack, opB_t, opB_f, opB_ack, opC_t, opC_f, opC_ack, NPC_t, NPC_f, NPC_ack;
    ///////////////////////////////////////////////////////////////////////////////
        logic [31:0] result_ret_0__t, result_ret_0__f, result_ret_0__ack, result_ret_1__t, result_ret_1__f, result_ret_1__ack;
        logic we_ret_t, we_ret_f, we_ret_ack;
        logic jump_ret_t, jump_ret_f, jump_ret_ack;
        logic [3:0] tag_ret_t, tag_ret_f, tag_ret_ack;
        logic [3:0] write_ret_t, write_ret_f, write_ret_ack;
        ///////////////////////////////////////////////////////////////////////////
        logic [31:1] addrW_t, addrW_f, addrW_ack;

        instruction_type i_RLL, i_exec;
        xu xu_RLL, xu_exec;
        
    `endif

    logic [31:0] NPC, instruction;
    logic [31:0] read_address;
    logic read;
    logic [3:0] write;
    logic [31:0] write_address, data_write;

    int fd, fd1, fd2, fd3, fd4, fd5;
    logic [31:0]  Waddress, Ddata,  data_read;
    byte char;

    int               log_file;

    real              last_recv_time;

    mailbox               gmRes = new();
    mailbox               gmWe = new();
    mailbox               gmNewPC = new();
    mailbox               gmI = new();
    mailbox               gmIdebug = new();
    mailbox               gmInst = new();
    mailbox               gmDin = new();

    assign clk = 1;

    TOP dut (.*);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////// INSCTRUCTION ////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    always @(i_address_t or i_address_f)
      if (~|(i_address_t|i_address_f)) begin
        read_i = 0;
        i_address_ack = '0;

     end else if (&(i_address_t|i_address_f)) begin
        automatic logic tmp;
        tmp=1;
        NPC = i_address_t;
        i_address = i_address_t;
        read_i = 1;
        
        gmI.put(tmp);
        i_address_ack = '1;

        
        $fdisplay(log_file, "%g,", $realtime-last_recv_time);
        last_recv_time = $realtime;
     end


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(*)
      if ((~|instruction_ack))
        ackout <= '0;
      else if((&instruction_ack))
        ackout <= '1;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(ackout or reset)
      if (!reset || ackout) begin
        instruction_t = '0;
        instruction_f = '0;

    end else if (!ackout) begin
        automatic logic received;

        gmI.get(received);

        gmInst.get(instruction_t);
        
        if((instruction_t==32'h00000093 || instruction_t==32'h00004517 || instruction_t==32'h00001517) && ($time<300))
            gmInst.get(instruction_t);

        instruction_f = ~instruction_t;

        instruction = instruction_t;

        gmIdebug.put(instruction_t);
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////// MEMORY SIGNALS ///////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(DATA_in_ack or read_address_t or read_address_f or reset)
        if(~|(read_address_t|read_address_f)) begin
            read = 0;

            DATA_in_t = '0;
            DATA_in_f = '0;
            read_ack = '0;
            read_address_ack='0;
        end else if (&(read_address_t|read_address_f) && DATA_in_ack=='0) begin
            if(read_address_f=='1)
                read_address = $urandom_range(0,5000);
            else 
                read_address = read_address_t;

            read = 1;

            gmDin.get(DATA_in_t);

            DATA_in_f = ~DATA_in_t;
            read_ack = '1;
            read_address_ack = '1;
            $fdisplay(fd4,"[%0d] Read: %h from address %d(%h)",
                        $time, DATA_in_t, read_address_t, read_address_t);
        end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(write_address_t or write_address_f or DATA_out_t or DATA_out_f or write_t or write_f)
        if( (~|(write_address_t|write_address_f)) && (~|(DATA_out_t|DATA_out_f)) && (~|(write_t|write_f)) )begin
            write = '0;

            write_address_ack = '0;
            DATA_out_ack = 0;
            write_ack = '0;
        
        end else if( (&(write_address_t|write_address_f)) && (&(DATA_out_t|DATA_out_f)) && (&(write_t|write_f)) )begin

            $fdisplay(fd4,"[%0d] Write: %h in address %d(%h) write %04b",
                         $time, DATA_out_t, write_address_t, write_address_t, write_t);
                   
            write = write_t;
            write_address = write_address_t;
            data_write = DATA_out_t;

            write_address_ack = '1;
            DATA_out_ack = '1;
            write_ack = '1;
        end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////// DEBUG ////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    `ifdef debug
    always @(WrData_t or WrData_f or reg_we_t or reg_we_f)
        if( (~|(WrData_t|WrData_f)) && (~|(reg_we_t|reg_we_f)))begin
            WrData_ack = '0;
            reg_we_ack = '0;
        end else if( (&(WrData_t | WrData_f)) && (&(reg_we_t|reg_we_f)) )begin
            automatic logic [31:0] received;
            automatic instruction_type i_received;

            gmRes.put(WrData_t);
            gmWe.put(reg_we_t);

            $fdisplay(fd5,"[%0d] Retire: We=%0d  %0h(%0d) ",
                        $time, reg_we_t, WrData_t, WrData_t);

            WrData_ack = '1;
            reg_we_ack = '1;
        end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(addrW_t or addrW_f)
        if (~|(addrW_t|addrW_f)) begin
            addrW_ack = '0;
        end else if (&(addrW_t|addrW_f)) begin
            automatic int pos;

            for (pos=1; pos<32; pos++)
                if(addrW_t[pos]==1)
                    break;

            $fdisplay(fd5,"[%0d] addrw: %d \t %0h",
                     $time, pos, addrW_t);

            addrW_ack = '1;
        end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(New_pc_t or New_pc_f)
        if (~|(New_pc_t|New_pc_f)) begin
            New_pc_ack = '0;
        end else if (&(New_pc_t|New_pc_f)) begin

            New_pc=New_pc_t;
            gmNewPC.put(New_pc_t);
        
            $fdisplay(fd5,"[%0d] New_PC: %d \t %h",
                     $time, New_pc_t, New_pc_t);

            New_pc_ack = '1;
        end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(NPC_decoder_t or NPC_decoder_f or tag_decoder_t or tag_decoder_f)
        if( (~|(NPC_decoder_t|NPC_decoder_f)) && (~|(tag_decoder_t|tag_decoder_f))) begin
            NPC_decoder_ack = '0;
            tag_decoder_ack = '0;
        end else if( (&(NPC_decoder_t|NPC_decoder_f)) && (&(tag_decoder_t|tag_decoder_f))  )begin
            automatic logic [31:0] received;
            gmIdebug.get(received);
            NPC_decoder_ack = '1;
            tag_decoder_ack = '1;
            $fdisplay(fd3,"[%0d] Decoder received: %h \t PC - %0d \t tag - %0d \t",
                     $time, received, NPC_decoder_t, tag_decoder_t);
        end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(NPC_RLL_t or NPC_RLL_f or tag_RLL_t or tag_RLL_f or i_RLL_t or i_RLL_f or xu_RLL_t or xu_RLL_f or instruction_RLL_t or instruction_RLL_f or fmt_RLL_t or fmt_RLL_f or regA_t or regA_f or regB_t or regB_f or regD_t or regD_f)
        if( (~|(NPC_RLL_t|NPC_RLL_f)) && (~|(tag_RLL_t|tag_RLL_f)) && (~|(i_RLL_t|i_RLL_f)) && (~|(xu_RLL_t|xu_RLL_f)) && (~|(instruction_RLL_t|instruction_RLL_f)) && (~|(fmt_RLL_t|fmt_RLL_f)) && (~|(regA_t|regA_f)) && (~|(regB_t|regB_f)) && (~|(regD_t|regD_f))) begin
            NPC_RLL_ack = '0;
            tag_RLL_ack = '0;
            i_RLL_ack = '0;
            xu_RLL_ack = '0;
            instruction_RLL_ack = '0;
            fmt_RLL_ack = '0;
            regA_ack = '0;
            regB_ack = '0;
            regD_ack = '0;
        end else if( (&(NPC_RLL_t|NPC_RLL_f)) && (&(tag_RLL_t|tag_RLL_f)) && (&(i_RLL_t|i_RLL_f)) && (&(xu_RLL_t|xu_RLL_f)) && (&(instruction_RLL_t|instruction_RLL_f)) && (&(fmt_RLL_t|fmt_RLL_f)) && (&(regA_t|regA_f)) && (&(regB_t|regB_f)) && (&(regD_t|regD_f))) begin
            NPC_RLL_ack = '1;
            tag_RLL_ack = '1;
            i_RLL_ack = '1;
            xu_RLL_ack = '1;
            instruction_RLL_ack = '1;
            fmt_RLL_ack = '1;
            regA_ack = '1;
            regB_ack = '1;
            regD_ack = '1;
            i_RLL = instruction_type'(i_RLL_t);
            xu_RLL = xu'(xu_RLL_t);
            $fdisplay(fd3,"[%0d] RLL received: %s - %s - %s  PC=%0d  tag=%0d  inst=%0h  rA=%0d  rB=%0d  rD=%0d",
                     $time, xu'(xu_RLL_t), instruction_type'(i_RLL_t), fmts'(fmt_RLL_t), NPC_RLL_t, tag_RLL_t, instruction_RLL_t, regA_t, regB_t, regD_t);
        end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(i_exec_t or i_exec_f or xu_exec_t or xu_exec_f or tag_exec_t or tag_exec_f or opA_t or opA_f or opB_t or opB_f or opC_t or opC_f or NPC_t or NPC_f)
        if( (~|(i_exec_t|i_exec_f)) && (~|(xu_exec_t|xu_exec_f)) && (~|(tag_exec_t|tag_exec_f)) && (~|(opA_t|opA_f)) && (~|(opB_t|opB_f)) && (~|(opC_t|opC_f)) && (~|(NPC_t|NPC_f)) ) begin
            i_exec_ack = '0;
            xu_exec_ack = '0;
            tag_exec_ack = '0;
            opA_ack = '0;
            opB_ack = '0;
            opC_ack = '0;
            NPC_ack = '0;
        end else if( (&(i_exec_t|i_exec_f)) && (&(xu_exec_t|xu_exec_f)) && (&(tag_exec_t|tag_exec_f)) && (&(opA_t|opA_f)) && (&(opB_t|opB_f)) && (&(opC_t|opC_f)) && (&(NPC_t|NPC_f)) ) begin
            i_exec_ack = '1;
            xu_exec_ack = '1;
            tag_exec_ack = '1;
            opA_ack = '1;
            opB_ack = '1;
            opC_ack = '1;
            NPC_ack = '1;
            i_exec = instruction_type'(i_exec_t);
            xu_exec = xu'(xu_exec_t);
            $fdisplay(fd3,"[%0d] Execute received:  %s - %s  Tag=%0d  opA=%0d  opB=%0d  opC=%0d  NPC=%0d",
                     $time, xu'(xu_exec_t), instruction_type'(i_exec_t), tag_exec_t, opA_t, opB_t, opC_t, NPC_t);
        end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    always@(tag_ret_t or tag_ret_f or result_ret_0__t or result_ret_0__f or result_ret_1__t or result_ret_1__f or jump_ret_t or jump_ret_f or we_ret_t or we_ret_f or write_ret_t or write_ret_f)
        if( (~|(tag_ret_t|tag_ret_f)) && (~|(result_ret_0__t|result_ret_0__f)) && (~|(result_ret_1__t|result_ret_1__f)) && (~|(jump_ret_t|jump_ret_f)) && (~|(we_ret_t|we_ret_f)) && (~|(write_ret_t|write_ret_f)) ) begin
            tag_ret_ack = '0;
            result_ret_0__ack = '0;
            result_ret_1__ack = '0;
            jump_ret_ack = 0;
            we_ret_ack = '0;
            write_ret_ack = '0;
        end else if( (&(tag_ret_t|tag_ret_f)) && (&(result_ret_0__t|result_ret_0__f)) && (&(result_ret_1__t|result_ret_1__f)) && (&(jump_ret_t|jump_ret_f)) && (&(we_ret_t|we_ret_f)) && (&(write_ret_t|write_ret_f)) ) begin
            tag_ret_ack = '1;
            result_ret_0__ack = '1;
            result_ret_1__ack = '1;
            jump_ret_ack = 1;
            we_ret_ack = '1;
            write_ret_ack = '1;
            $fdisplay(fd3,"[%0d] Retire received:  Res0=%0h  Res1=%0h  We=%0d  Tag=%0d   Jump=%0d  Write=%04b",
                     $time, result_ret_0__t, result_ret_1__t, we_ret_t, tag_ret_t, jump_ret_t, write_ret_t);
        end
    `endif 

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////// RAM INSTANTIATION ///////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	RAM_mem #(32'h00000000) RAM_MEM( .write_enable(write), .write_address(Waddress), .data_in(Ddata),
                                     .rst(reset), .inst_address(i_address), .instruction_out(instruction_int),
                                     .read_enable(read), .read_address(read_address), .data_out(data_read));

    always_comb begin
        if(write!=0)   Waddress<=write_address;	 else Waddress<=32'h00000000;  // Daddress - write_address
        if(write!=0)  Ddata <= data_write; else Ddata <= 32'h00000000;
    end

    always@(posedge read_i)
        gmInst.put(instruction_int);

    always@(posedge read) begin
        automatic logic [31:0] auxTime;
        #1
        if(read_address==32'h80006000)begin
            auxTime = $time/1000;
            gmDin.put(auxTime);
        end else if(read_address>32'h0000FFFF)
            gmDin.put(32'h00000000);
        else
            gmDin.put(data_read);
    end

    always @(write) begin
        if((write_address == 32'h80004000 | write_address == 32'h80001000) & write!=0) begin
            char <= data_write[7:0];
            $write("%c",char);
            $fwrite(fd,"%c",char);
        end
        ////////////////////////////////////////////
        if(write_address==32'h80000000) begin
            $display("# %t END OF SIMULATION",$time);
            $fdisplay(fd,"\n# %t END OF SIMULATION",$time);
            $fdisplay(fd2,"%0t", $realtime);
            $finish;
        end
    end

    always #1000000000
            $display("%d elapsed", $time);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////// READ ARCHIVE ///////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    initial begin
      $sdf_annotate("./freepdk45/8.00/worst.sdf", dut, , , "maximum");
      //$dumpfile("worst.vcd");
      //$dumpvars;

      fd = $fopen ("output.txt", "w");
      fd2 = $fopen ("simTime.txt", "w");
      fd3 = $fopen ("debugCORE.txt", "w");
      fd4 = $fopen ("debugMEM.txt", "w");
      fd5 = $fopen ("debugLOOPS.txt", "w");

      log_file = $fopen ("ct.csv", "w");
      $fdisplay(log_file, "ct,");

      reset = 0;

      #50 reset = 1;

      last_recv_time = $realtime;
   end
endmodule