library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity RegFile is 
  port(
        clk, wr_en                    : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in REG_addr;
        d_in                          : in word; 
        d_out_1, d_out_2              : out word
  );
end RegFile;

architecture RF_arch of RegFile is
-- component declaration
-- signal declaration
	-- Reg_addr is 32 bits so 32 registers
	subtype RegF_Addr is integer range 0 to 31;
	type RegF is array (RegF_Addr) of word;

	-- conversion from REG_addr to integer
	-- std_logic_vector -> unsigned -> integer
	signal R : RegF;
	signal zaddr : REG_ADDR := (others => '0');
begin

	process (clk)
	begin
		-- register 0 reserved for value 0
		-- for some reason, $0 will not be assigned outside of process statements
		R(0) <= zero_word;

		-- write synchronously
		if (clk'event and clk = '1' and wr_en = '1' and not (unsigned(wr_addr) = 0)) then
			

			-- convert wr_addr to integer for indexing
			R(to_integer(unsigned(wr_addr))) <= d_in;

		end if;
		
	end process;

	-- read asynchronously
	-- convert rd_addr to integer
	d_out_1 <= R(to_integer(unsigned(rd_addr_1)));
	d_out_2 <= R(to_integer(unsigned(rd_addr_2)));

end RF_arch;
