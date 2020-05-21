
`timescale 1ns/10ps 

module aes_tb();

  reg           dut_sys_clk;
  reg           dut_sys_rst_n;
  reg  [127:0]  dut_text_in;
  reg  [127:0]  dut_key;
  reg           dut_ld;

  wire [127:0]  dut_text_out;
  wire          dut_ready;

  aes dut ( 
    .sys_clk  ( dut_sys_clk  ),
    .sys_rst_n( dut_sys_rst_n),
    .ld       ( dut_ld       ),
    .key      ( dut_key      ),
    .text_in  ( dut_text_in  ),
    .ready    ( dut_ready    ),
    .text_out ( dut_text_out )
  );

  task delay;
    input [31:0] num;
  begin
    repeat(num) @(posedge dut_sys_clk);
    #1;
  end
  endtask

  initial begin
    dut_sys_clk   = 1'b0;
    dut_sys_rst_n = 1'b1;
    repeat(1) @(negedge dut_sys_clk);
    dut_sys_rst_n = 1'b0;
    repeat(1) @(posedge dut_sys_clk);
    #1;
    dut_sys_rst_n = 1'b1;
  end

  always #5 dut_sys_clk = ~dut_sys_clk; 

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end

  integer   seed;
  reg[31:0] num1;
  reg[31:0] num2;
  reg[31:0] num3;
  reg[31:0] num4;
  reg[31:0] num5;

  initial begin
    if ( !$value$plusargs("seed+%d", seed) ) begin
      seed = 0;
    end
    @(posedge dut_sys_clk);
    #1;
    num1 = $random(seed);
    num2 = $random(seed);
    num3 = $random(seed);
    num4 = $random(seed);
    num5 = $random(seed);
  end

  integer PLOGFILE;
  integer CLOGFILE;

  initial begin
    PLOGFILE=$fopen("plain.txt", "a"); 
    CLOGFILE=$fopen("cipher.txt", "a"); 
    $display("");
    $display("**************************************");
    $display("* AES Test started ...               *");
    $display("**************************************");
    $display("");
    dut_ld = 1'b0;
    dut_key     = 128'h00000000000000000000000000000000;
    dut_text_in = 128'h00000000000000000000000000000000;
    @(posedge dut_sys_rst_n);
    //
    // key        : 128'h000102030405060708090a0b0c0d0e0f;
    // plaintext  : 128'h00112233445566778899aabbccddeeff;
    // ciphertext : 128'h69c4e0d86a7b0430d8cdb78070b4c55a
    //
    dut_key = 128'h000102030405060708090a0b0c0d0e0f;
    dut_text_in = 128'h00112233445566778899aabbccddeeff;
    //dut_text_in = {num2,num3,num4,num5};
    $fdisplay(PLOGFILE, "plaintext = %h", dut_text_in); 
    delay(3);  // Dont change this delay
    dut_ld = 1'b1;
    delay(1);
    dut_ld = 1'b0;
  end
    
  // 
  // Print the cipher text to cipher.txt
  //
  reg      dut_ready_dly;
  wire     dut_ready_pulse;

  initial begin 
    dut_ready_dly = 1;
  end

  always @(posedge dut_sys_clk) begin
    dut_ready_dly <= #1 dut_ready;
  end

  assign dut_ready_pulse = ~dut_ready_dly & dut_ready;

  always @(posedge dut_sys_clk) begin
    if ( dut_ready_pulse ) begin
      $fdisplay(CLOGFILE, "ciphertext = %h", dut_text_out); 
      @(posedge dut_sys_clk);
      #1;
      $display("");
      $display("**************************************");
      $display("* AES Test done ...                  *");
      $display("**************************************");
      $display("");
      $fclose(PLOGFILE);
      $fclose(CLOGFILE);
      $finish;
    end
  end

endmodule

