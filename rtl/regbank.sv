module regbank
  (input logic         clk, reset,
  input logic [4:0]   addra,
  input logic [4:0]   addrb,
  input logic [31:1]  addrw,
  input logic [31:0]  in,
  output logic [31:0] outa,
  output logic [31:0] outb);

  logic [31:0]        regfile [31:1];

  wire [31:0] outa_int, outb_int;

  assign outa = outa_int,
         outb = outb_int;

    for (genvar i=0; i < $bits(outa); i++) begin
        discard zero_rega_D (.a(0), .q(outa_int[i]), .en(addra == 0), .*);
        discard zero_regb_D (.a(0), .q(outb_int[i]), .en(addrb == 0), .*);
    end

    for (genvar j = 1; j < 32 ; j++)
      for (genvar i=0; i < $bits(outa); i++)
        discard outa_int_D (.a(regfile[j][i]), .q(outa_int[i]), .en(addra == j), .*);
    
    for (genvar j = 1; j < 32 ; j++)
      for (genvar i=0; i < $bits(outb); i++)
        discard outb_int_D (.a(regfile[j][i]), .q(outb_int[i]), .en(addrb == j), .*);
    
    for (genvar i = 1; i < 32 ; i++)
      always_ff @(posedge clk or negedge reset)
        if(!reset)
          regfile[i] <= '0;
        else if (addrw[i])
          regfile[i] <= in;

endmodule

