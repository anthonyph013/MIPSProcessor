-- Student name: Tony Pham
-- Student ID number: 91467123

LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE IEEE.numeric_std.all;
USE work.Glob_dcls.all;

entity ALU_tb is
end ALU_tb;

architecture ALU_tb_arch of ALU_tb is
-- component declaration
	component ALU is
	port(
	op_code  : in ALU_opcode;
       	in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount	
        ALUout   : out word;
        Zero     : out std_logic
  	);
	end component;
-- component specification
	
-- signal declaration
	signal top_code  : ALU_opcode;
       	signal tin0, tin1 : word;	
        signal tC	: std_logic_vector(4 downto 0);  -- shift amount	
        signal tALUout   : word;
        signal tZero     : std_logic;
begin
	ALU_0: ALU port map (top_code, tin0, tin1, tC, tALUout, tZero);
	test_ALU : process
	begin
		-- test ADD 000
		top_code <= "000";
		-- convert integer 0 to std_logic_vector
		-- 0+0=0
		tin0 <= std_logic_vector(to_signed(0,tin0'length));
		tin1 <= (others => '0');
		tC <= (others => '0');
		-- check ZERO
		-- wait for 10 ns to let values propogate in ALU
		wait for 10 ns;
		assert tZero = '1' report "0+0=0 Zero!=1";
		assert tALUout = std_logic_vector(to_signed(0,tALUout'length)) report "0+0!=0";

		-- 1+0=1
		-- check not zero
		wait for 20 ns;
		tin0 <= std_logic_vector(to_signed(1, tin0'length));
		wait for 10 ns;
		assert tZero = '0' report "1+0=1 Zero!=0";
		assert tALUout = std_logic_vector(to_signed(1,tALUout'length)) report "1+0!=1";

		-- 1+105=106
		wait for 20 ns;
		tin1 <= std_logic_vector(to_signed(105, tin1'length));
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(106,tALUout'length)) report "1+105=106";
		
		-- test negative addition
		-- -106+105=-1
		wait for 20 ns;
		tin0 <= std_logic_vector(to_signed(-106, tin0'length));
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(-1,tALUout'length)) report "-106+105=-1";

		
		wait for 10 ns;

		-- test SUB 001
		top_code <= "001";
		-- convert integer 0 to std_logic_vector
		-- 0-0=0
		tin0 <= std_logic_vector(to_signed(0,tin0'length));
		tin1 <= (others => '0');
		tC <= (others => '0');
		-- check ZERO
		-- wait for 10 ns to let values propogate in ALU
		wait for 10 ns;
		assert tZero = '1' report "0-0=0 Zero!=1";
		assert tALUout = std_logic_vector(to_signed(0,tALUout'length)) report "0-0!=0";

		-- 1064-1024=40
		tin0 <= std_logic_vector(to_signed(1064,tin0'length));
		tin1 <= std_logic_vector(to_signed(1024,tin1'length));
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(40,tALUout'length)) report "1064-1024=40";

		-- 1064-5000=-3936;
		tin1 <= std_logic_vector(to_signed(5000,tin1'length));
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(-3936,tALUout'length)) report "1064-5000=-3936";
		wait for 10 ns;

		-- test SLL 010
		top_code <= "010";
		-- convert integer 0 to std_logic_vector
		-- 0 SLL 0=0
		tin0 <= std_logic_vector(to_signed(0,tin0'length));
		tin1 <= (others => '0');
		tC <= (others => '0');
		-- check ZERO
		-- wait for 10 ns to let values propogate in ALU
		wait for 10 ns;
		assert tZero = '1' report "0 SLL 0=0 Zero!=1";
		assert tALUout = std_logic_vector(to_signed(0,tALUout'length)) report "0 SLL 0!=0";

		-- 2 SLL 4 = 2^5
		tin0 <= std_logic_vector(to_signed(2,tin0'length));
		tC <= std_logic_vector(to_signed(4,tC'length));
		-- tin1 = 2 SLL 4
		tin1 <= std_logic_vector(shift_left(to_unsigned(2,tin1'length),4));
		wait for 10 ns;
		assert tALUout = tin1 report "2 SLL 4!=32";
		wait for 10 ns;

		-- test SRL 011
		top_code <= "011";
		-- convert integer 0 to std_logic_vector
		-- 0 SRL 0=0
		tin0 <= std_logic_vector(to_signed(0,tin0'length));
		tin1 <= (others => '0');
		tC <= (others => '0');
		-- check ZERO
		-- wait for 10 ns to let values propogate in ALU
		wait for 10 ns;
		assert tZero = '1' report "0 SRL 0=0 Zero!=1";
		assert tALUout = std_logic_vector(to_signed(0,tALUout'length)) report "0 SRL 0!=0";

		-- 32 SRL 4 = 2
		tin0 <= std_logic_vector(to_signed(32,tin0'length));
		tC <= std_logic_vector(to_signed(4,tC'length));
		-- tin1 = 32 SRL 4
		tin1 <= std_logic_vector(shift_right(to_unsigned(32,tin1'length),4));
		wait for 10 ns;
		assert tALUout = tin1 report "32 SRL 4!=2";

		-- 32 SRL 10 = 0
		tC <= std_logic_vector(to_signed(10,tC'length));
		tin1 <= std_logic_vector(shift_right(to_unsigned(32,tin1'length),10));
		wait for 10 ns;
		assert tALUout = tin1 report "32 SRL 10!=0";

		wait for 10 ns;

		-- test AND 100
		top_code <= "100";
		-- convert integer 0 to std_logic_vector
		-- 0 AND 0=0
		tin0 <= std_logic_vector(to_signed(0,tin0'length));
		tin1 <= (others => '0');
		tC <= (others => '0');
		-- check ZERO
		-- wait for 10 ns to let values propogate in ALU
		wait for 10 ns;
		assert tZero = '1' report "0 AND 0=0 Zero!=1";
		assert tALUout = std_logic_vector(to_signed(0,tALUout'length)) report "0 AND 0!=0";

		-- 255 AND 255 = 255
		tin0 <= std_logic_vector(to_signed(255,tin0'length));
		tin1 <= std_logic_vector(to_signed(255,tin0'length));
	
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(255,tALUout'length)) report "255 AND 255!=255";

		-- 255 AND 10 = 10
		tin1 <= std_logic_vector(to_signed(10,tin0'length));
	
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(10,tALUout'length)) report "255 AND 10!=10";
		wait for 10 ns;

		-- test OR 101
		top_code <= "101";
		-- convert integer 0 to std_logic_vector
		-- 0 OR 0=0
		tin0 <= std_logic_vector(to_signed(0,tin0'length));
		tin1 <= (others => '0');
		tC <= (others => '0');
		-- check ZERO
		-- wait for 10 ns to let values propogate in ALU
		wait for 10 ns;
		assert tZero = '1' report "0 OR 0=0 Zero!=1";
		assert tALUout = std_logic_vector(to_signed(0,tALUout'length)) report "0 OR 0!=0";

		-- 255 OR 255 = 255
		tin0 <= std_logic_vector(to_signed(255,tin0'length));
		tin1 <= std_logic_vector(to_signed(255,tin0'length));
	
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(255,tALUout'length)) report "255 OR 255!=255";

		-- 10 OR 4 = 14
		tin0 <= std_logic_vector(to_signed(10,tin0'length));
		tin1 <= std_logic_vector(to_signed(4,tin0'length));
	
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(14,tALUout'length)) report "10 OR 4 != 14";
		wait for 10 ns;

		-- test XOR 110
		top_code <= "110";
		-- convert integer 0 to std_logic_vector
		-- 0 XOR 0=0
		tin0 <= std_logic_vector(to_signed(0,tin0'length));
		tin1 <= (others => '0');
		tC <= (others => '0');
		-- check ZERO
		-- wait for 10 ns to let values propogate in ALU
		wait for 10 ns;
		assert tZero = '1' report "0 XOR 0=0 Zero!=1";
		assert tALUout = std_logic_vector(to_signed(0,tALUout'length)) report "0 XOR 0!=0";

		-- 255 XOR 255 = 0
		tin0 <= std_logic_vector(to_signed(255,tin0'length));
		tin1 <= std_logic_vector(to_signed(255,tin0'length));
	
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(0,tALUout'length)) report "255 XOR 255!=0";

		-- 10 XOR 4 = 14
		tin0 <= std_logic_vector(to_signed(10,tin0'length));
		tin1 <= std_logic_vector(to_signed(4,tin0'length));
	
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(14,tALUout'length)) report "10 XOR 4 != 14";
		wait for 10 ns;

		-- test NOR 111
		top_code <= "111";
		-- convert integer 0 to std_logic_vector
		-- 0 NOR 0 = ffff_ffff = -1
		tin0 <= std_logic_vector(to_signed(0,tin0'length));
		tin1 <= (others => '0');
		tC <= (others => '0');
		-- check ZERO
		-- wait for 10 ns to let values propogate in ALU
		wait for 10 ns;
		assert tZero = '0' report "0 NOR 0= -1 Zero!=0";
		assert tALUout = std_logic_vector(to_signed(-1,tALUout'length)) report "0 NOR 0!= -1";

		-- 255 NOR 255 = 2^32 - 1 - 255 = -256
		tin0 <= std_logic_vector(to_signed(255,tin0'length));
		tin1 <= std_logic_vector(to_signed(255,tin0'length));
	
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(-256,tALUout'length)) report "255 NOR 255!=-256";

		-- 10 NOR 4 = 2^32 - 1 - 14 = -15
		tin0 <= std_logic_vector(to_signed(10,tin0'length));
		tin1 <= std_logic_vector(to_signed(4,tin0'length));
	
		wait for 10 ns;
		assert tALUout = std_logic_vector(to_signed(-15,tALUout'length)) report "10 NOR 4 != -15";
		wait;
	end process;
	
end ALU_tb_arch;

