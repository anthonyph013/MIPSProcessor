LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use work.Glob_dcls.all;

entity ALU is 
  PORT( op_code  : in ALU_opcode;
        in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount	
        ALUout   : out word;
        Zero     : out std_logic
  );
end ALU;

architecture ALU_arch of ALU is
-- signal declaration
	signal ALUresult : word;
begin
	
	process(op_code, in0, in1)
	begin
		case op_code is
			when "000" =>
				-- addition
				ALUresult <= std_logic_vector(unsigned(in0) + unsigned(in1));
			when "001" =>
				-- subtraction
				ALUresult <= std_logic_vector(unsigned(in0) - unsigned(in1));
			when "010" =>
				-- shift logical left
				-- shift_left(unsigned, natural) logical shift
				-- shift_left(signed, natural) arithmetic shift
				-- convert std_logic_vector to unsigned and natural number
				-- shift in1 by C
				-- C is 5 bits
				ALUresult <= std_logic_vector(shift_left(unsigned(in1), to_integer(unsigned(C))));
			when "011" =>
				-- shift logical right
				ALUresult <= std_logic_vector(shift_right(unsigned(in1), to_integer(unsigned(C))));
			when "100" =>
				-- and
				ALUresult <= in0 AND in1;
			when "101" =>
				-- or
				ALUresult <= in0 OR in1;
			when "110" =>
				-- xor
				ALUresult <= in0 XOR in1;
			when "111" =>
				-- nor
				ALUresult <= in0 NOR in1;				
			when others =>
		end case;

	
	end process;
	-- compute zero outside of process statement since ALUresult is modified concurently
	-- with zero calculation. process only occurs according to sensitivity list
	-- return 0 if ALUresult=0
	Zero <= '1' when (signed(ALUresult) = 0) else '0';
	ALUout <= ALUresult;
	

end ALU_arch;
