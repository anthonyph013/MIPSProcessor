-- Student name: Tony Pham
-- Student ID number: 91467123
-- 
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity PC_tb is
end PC_tb;

architecture PC_tb_arch of PC_tb is
-- component declaration	
-- component specification
	component PC is
		port(
			clk: in STD_LOGIC;
			reset_N: in STD_LOGIC;
			wr_en: in STD_LOGIC;
			PC_in: in word;
			count: out word 
		);
	end component;
-- signal declaration
	signal in_clk, in_reset_N: STD_LOGIC := '1';
	signal in_wr_en: STD_LOGIC := '1';
	signal in_PC_in: in word := std_logic_vector(to_signed(5,in_PC_in'length));
	signal out_count: word;

begin
-- your code goes here
	counter: PC port map (clk=>in_clk, reset_N=>in_reset_N, wr_en=>in_wr_en, PC_in=>in_PC_in, count=>out_count);

	clk_run: process
	begin
		-- for some reason the line below results in an infinite loop
		-- period = 10 ns
		--in_clk <= not in_clk after 5 ns;
		-- running the clock
		if (in_clk = '1') then
			in_clk <='0';
			wait for 5 ns;
		else
			in_clk <= '1';
			wait for 5 ns;
		end if;
		
	end process;

	test_PC: process
	begin
		-- test reset
		wait for 3 ns;
		in_reset_N <= '0';
		wait for 20 ns;
		in_reset_N <= '1';
		-- test counting
		wait for 150 ns;
		-- test reset
		in_reset_N <= '0';
		wait for 20 ns;
		wait;
	end process;

end lab2_tb_arch;

