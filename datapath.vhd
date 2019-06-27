LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity datapath is
  
  port (
    clk        : in  std_logic;
    reset_N    : in  std_logic;
    
    PCUpdate   : in  std_logic;         -- write_enable of PC

    IorD       : in  std_logic;         -- Address selection for memory (PC vs. store address)
    MemRead    : in  std_logic;		-- read_enable for memory
    MemWrite   : in  std_logic;		-- write_enable for memory

    IRWrite    : in  std_logic;         -- write_enable for Instruction Register
    MemtoReg   : in  std_logic_vector(1 downto 0);  -- selects ALU or MEMORY or PC to write to register file.
    RegDst     : in  std_logic_vector(1 downto 0);  -- selects rt, rd, or "31" as destination of operation
    RegWrite   : in  std_logic;         -- Register File write-enable
    ALUSrcA    : in  std_logic;         -- selects source of A port of ALU
    ALUSrcB    : in  std_logic_vector(1 downto 0);  -- selects source of B port of ALU
    
    ALUControl : in  ALU_opcode;	-- receives ALU opcode from the controller
    PCSource   : in  std_logic_vector(1 downto 0);  -- selects source of PC

    opcode_out : out opcode;		-- send opcode to controller
    func_out   : out opcode;		-- send func field to controller
    zero       : out std_logic);	-- send zero to controller (cond. branch)

end datapath;


architecture datapath_arch of datapath is
-- component declaration
	component mem is 
		PORT (MemRead	: IN std_logic;
		MemWrite	: IN std_logic;
	 	d_in		: IN   word;		 
	 	address	: IN   word;
	 	d_out		: OUT  word 
	 	);
	end component;

	component PC is 
		port(
          clk     : in  STD_LOGIC;
          reset_N : in  STD_LOGIC;
	  wr_en   : in std_logic;
	  PC_in   : in	word;
          count   : out word
       		);
	end component;

	component ALU is
	port(
	op_code  : in ALU_opcode;
       	in0, in1 : in word;	
        C	 : in std_logic_vector(4 downto 0);  -- shift amount	
        ALUout   : out word;
        Zero     : out std_logic
  	);
	end component;
	
	component RegFile is
	port(
        clk, wr_en                    : in STD_LOGIC;
        rd_addr_1, rd_addr_2, wr_addr : in REG_addr;
        d_in                          : in word; 
        d_out_1, d_out_2              : out word
	);
	end component;
-- component specification
-- signal declaration

	signal td_in, taddress, td_out : word;
	signal target_addr : std_logic_vector(27 downto 0);
	signal sign_extended_val : word;
	signal tC : std_logic_vector(4 downto 0);

	-- PC signals
	signal tPC_in : word;
	signal tPCout : word;

	-- RF signals
	signal treg_d_in : word;
	signal treg_wr_addr : reg_addr;
	signal rs, rt: reg_addr;
	signal d_outR_1, d_outR_2 : word;

	-- ALU signals
	signal tALU_A, tALU_B : word;
	signal tALUout : word;

	-- registers
	signal MDR : word;
	signal ALUoutreg, Areg, Breg : word;
	-- instruction register
	signal IR : word;
begin
	mem0 : mem port map (Memread, MemWrite, td_in, taddress, td_out);
	pc0 : PC port map (clk, reset_N, PCUpdate, tPC_in, tPCout);
	ALU_0 : ALU port map (ALUControl, tALU_A, tALU_B, tC, tALUout, zero);

	RegFile_0 : RegFile port map (clk, RegWrite, rs, rt, treg_wr_addr, treg_d_in, d_outR_1, d_outR_2);

	-- WIRE CONNECTIONS
	-- connect memory write in from reg B
	td_in <= Breg;
	-- resizing keeps sign bit
	sign_extended_val <= std_logic_vector(resize(signed(IR(15 downto 0)), sign_extended_val'length));

	-- set shift amount
	tC <= IR(10 downto 6);

	-- multiple address by 4 to make it byte addressable
	-- shift left target address by 2
	-- concatenate bit 25 and 24 since shift_left only applies within 26 bits
	target_addr <= IR(25 downto 24) & std_logic_vector(shift_left(unsigned(IR(25 downto 0)), 2));
	-- END WIRE CONNECTIONS

	-- PARSE INSTRUCTIONS
	-- take highest 6 bits for opcode
	opcode_out <= IR(31 downto 26);

	-- lowest 6 bits for funct
	func_out <= IR(5 downto 0);
	
	-- get rs
	rs <= IR(25 downto 21);
	-- get rt
	rt <= IR(20 downto 16);
	-- END PARSE INSTRUCTIONS


	process (clk, IRWrite, IorD, RegDst, MemtoReg,
		ALUSrcA, ALUSrcB, PCSource, 
		tALUout, tPCout, MDR, rt, IR, Areg, Breg, 
		sign_extended_val, ALUoutreg, target_addr, 
		d_outR_1, d_outR_2, td_out)
	begin
		

		--START SELECTOR SIGNALS
		--select MEM address from ALU or PC
		if (IorD = '1') then
			-- select ALU output as address
			taddress <= ALUoutreg;
		else
			-- select PC output
			taddress <= tPCout;
		end if;

		-- select data to write to RF from ALU, MDR, or PC
		case MemtoReg is
			when "00" =>
				-- write ALU output to RF
				treg_d_in <= ALUoutreg;
			when "01" =>
				-- write MDR output to RF
				treg_d_in <= MDR;
			when "10" =>
				-- write PC output to RF
				treg_d_in <= tPCout;
			when others =>
		end case;

		-- select write address for RF from rt, rd, or "31"
		case RegDst is
			when "00" =>
				-- addr is rt
				treg_wr_addr <= rt;
			when "01" => 
				-- addr is rd
				treg_wr_addr <= IR(15 downto 11);
			when "10" => 
				-- addr is 31
				treg_wr_addr <= std_logic_vector(to_unsigned(31, treg_wr_addr'length));
			when others =>
		end case;

		-- select ALU source A from PC or regA
		if (ALUSrcA = '1') then
			-- select PC out as ALU A
			tALU_A <= tPCout;
		else
			-- select regA as ALU A
			tALU_A <= Areg;
		end if;

		-- select ALU source B from regB, "4", IR
		case ALUSrcB is
			when "00" =>
				-- ALU B is regB
				tALU_B <= Breg;			

			when "01" =>
				-- ALU B is "4"
				-- used for incrementing the PC
				tALU_B <= std_logic_vector(to_unsigned(4, tALU_B'length));

			when "10" =>
				-- ALU B is IMM
				-- sign extend IMM
				tALU_B <= sign_extended_val;

			when "11" =>
				-- ALU B is branching offset
				-- multiply offset by 4 to be byte addressable
				tALU_B <= std_logic_vector(shift_left(unsigned(sign_extended_val), 2));
			when others =>
		end case;

		-- select PC source from ALU, ALUout reg, IR
		case PCSource is
			when "00" =>
				-- PC source is ALU output i.e. PC increment
				tPC_in <= tALUout;

			when "01" =>
				-- PC source is ALUout reg
				-- branching
				tPC_in <= ALUoutreg;
			when "10" =>
				-- PC source is jump addr
				-- concatenate highest 3 PC out bits with target addr shifted left by 2
				-- target addr is relative to current PC
				tPC_in <=  tPCout(31 downto 28) & target_addr;

			when others =>
		end case;
		-- END SELECTOR SIGNALS
		

		if (clk'event and clk = '1') then
			-- write to registers
			-- write to instruction register
			if (IRWrite = '1') then
				IR <= td_out;
			end if;

			-- move ALU output to reg ALUout
			ALUoutreg <= tALUout;

			-- move regfile output into reg A and B
			Areg <= d_outR_1;
			Breg <= d_outR_2;

			-- move MEM data to MDR
			MDR <= td_out;
		end if;
	end process;
  
end datapath_arch;
