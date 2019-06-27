LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU_tb is
end CPU_tb;

architecture CPU_test of CPU_tb is
-- component declaration
	-- CPU (you just built)
	component CPU is
	port (
		clk, reset_N : in std_logic
	);
	end component;

-- component specification
-- signal declaration
	-- You'll need clock and reset.
	signal clk, reset_N : std_logic := '0';
begin
	cpu0 : CPU port map (clk, reset_N);
	clk <= not clk after HALF_PERIOD;

	process
	begin
		reset_N <= '1' after CLK_PERIOD;
		wait for 10 * CLK_PERIOD;
		wait;
	end process;

end CPU_test;
