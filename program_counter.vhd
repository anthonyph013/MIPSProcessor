library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity PC is
   port(
          clk     : in  STD_LOGIC;
          reset_N : in  STD_LOGIC;
	  wr_en   : in std_logic;
	  PC_in   : in	word;
          count   : out word
       );

end PC;

architecture PC_arch of PC is
-- signal declarations

 	signal num: word;

begin
-- your code goes here
	count <= num;

	counter: process(clk,reset_N)
	begin
		-- asynchronous reset
		if (reset_N = '0') then
			num <= (others => '0');
		-- assign register from input
		elsif (clk'event and clk = '1' and wr_en = '1') then
			num <= PC_in;
		end if;
	end process;
end PC_arch;

