LIBRARY IEEE; 
use ieee.std_logic_1164.all;
package Glob_dcls is
-- Data types 
	constant word_size : natural := 32;			
	subtype word is std_logic_vector(word_size-1 downto 0); 
	constant half_word_size : natural := 16;			
	subtype half_word is std_logic_vector(half_word_size-1 downto 0); 
	constant Byte_size : natural := 8;
	subtype Byte is std_logic_vector(Byte_size-1 downto 0);
	constant reg_addr_size : natural := 5;
	subtype reg_addr is std_logic_vector(reg_addr_size-1 downto 0);
	constant opcode_size : natural := 6;
	subtype opcode is std_logic_vector(opcode_size-1 downto 0);
	constant offset_size : natural := 16; 
	subtype offset is std_logic_vector(offset_size-1 downto 0);
	constant target_size : natural := 26;
	subtype target is std_logic_vector(target_size-1 downto 0);

	subtype ALU_opcode is std_logic_vector(2 downto 0);
  subtype RAM_ADDR is integer range 0 to 63;

  type RAM is array (RAM_ADDR) of word;

-- Constants   

        constant One_word: word := (others=>'1');
        constant Zero_word: word := (others=>'0');
        constant Z_word: word :=    (others=>'Z');
        constant U_word: word :=    (others=>'U');
        
        constant CLK_PERIOD: time := 40 ns;
        constant RD_LATENCY: time := 35 ns;
        constant WR_LATENCY: time := 35 ns;
	constant HALF_PERIOD: time := CLK_PERIOD / 2;
        
        constant op_R 	: opcode := "000000";
	constant op_BNE : opcode := "000101";
	constant op_BE	: opcode := "000100";
	constant op_JMP	: opcode := "000010";
	constant op_LW	: opcode := "100011";
	constant op_SW	: opcode := "101011";
	-- I type instructions
	constant op_ADDI	: opcode := "001000";
	constant op_ORI		: opcode := "001101";
	constant op_ANDI	: opcode := "001100";
	-- R type instructions
	constant funct_ADD	: opcode := "100000";
	constant funct_SUB	: opcode := "100010";
	constant funct_AND	: opcode := "100100";
	constant funct_OR	: opcode := "100101";
	constant funct_SLL	: opcode := "000000";
	constant funct_SRL	: opcode := "000010";
	-- ALU opcodes
	constant alu_add	: alu_opcode := "000";
	constant alu_sub	: alu_opcode := "001";
	constant alu_sll	: alu_opcode := "010";
	constant alu_srl	: alu_opcode := "011";
	constant alu_and	: alu_opcode := "100";
	constant alu_or		: alu_opcode := "101";
	constant alu_xor	: alu_opcode := "110";
	constant alu_nor	: alu_opcode := "111";	

-- Components


end Glob_dcls;


