LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity datapath_tb is
end datapath_tb;

architecture datapath_tb_arch of datapath_tb is
-- component declaration
	component datapath is
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

	end component;
-- component specification

-- signal declaration
	signal tclk, treset_N : std_logic := '0';
	signal tPCUpdate, tIorD, tMemRead, tMemWrite, tIRWrite, tRegWrite, 
		tALUSrcA, tzero : std_logic;
	signal tMemtoReg, tRegDst, tALUSrcB, tPCSource: std_logic_vector(1 downto 0);
	signal tALUControl : ALU_opcode;
	signal topcode_out, tfunc_out : opcode;
	signal half_period : time := CLK_PERIOD / 2;
begin
	datapath0 : datapath port map (tclk, treset_N, tPCUpdate, tIorD, tMemRead, tMemWrite,
			tIRWrite, tMemtoReg, tRegDst, tRegWrite, tALUSrcA, tALUSrcB, tALUControl,
			tPCSource, topcode_out, tfunc_out, tzero);
  
	clk_run : process
	begin
		if (tclk = '1') then
			tclk <= '0';
			wait for half_period;
		else 
			tclk <= '1';
			wait for half_period;
		end if;
	end process;
	
	datapath_tb_run : process
	begin
		-- TEST PC UPDATE
		-- set control signals
		tMemRead <= '0';	-- enable memory read
		tMemWrite <= '0';	-- disable memory write
		tIRWrite <= '0';	-- disable IR write
		tRegWrite <= '0';	-- disable RF write
		tPCupdate <= '1';	-- enable PC update
		-- selector signals
		tIorD <= '0'; 		-- select PC for mem addr
		tMemtoReg <= "10"; 	-- select PC for RF wr data
		tRegDst <= "01";	-- select rd as wr addr	
		tALUSrcA <= '1';	-- select ALU A src as PC out
		tALUSrcB <= "01";	-- select ALU B src as "4"
		tPCSource <= "00";	-- select PC increment
		tALUControl <= "000";	-- set ALU to addition
		-- let signals propogate through ALU
		wait for 2*CLK_PERIOD;
		-- allow incrementing
		treset_N <= '1';
		wait for 3*CLK_PERIOD;
		-- test PC doesn't override counter when not enabled
		tPCupdate <= '0';
		wait for 8 ns;

		-- TEST INSTRUCTION FETCH
		-- move MEM to IR
		-- increment PC
		tMemRead <= '1';
		tIRWrite <= '1';
		tPCupdate <= '1';
		-- set selector signals
		-- fetch instruction i.e. PC = 12, get instruction 4
		-- "00000000000000000010000000100100",	--   and r4, r0, r0   -- this block shifts right r3 by r2 times (2 times r1)
	
		-- disable signals
		wait for CLK_PERIOD;
		tPCupdate <= '0';
		-- take into account of memory read delay
		wait for CLK_PERIOD;
		tIRWrite <= '0';
		-- assert instruction 4 was fetched
		assert topcode_out = "000000" report "failed to fetch opcode INS 4";
		assert tfunc_out = "100100" report "failed to fetch func code INS 4";
		wait for 8 ns;

		-- TEST LOAD
		-- write memory into RF
		tMemtoReg <= "01";	-- write to RF from MDR
		wait for 4 ns;
		tRegWrite <= '1';	-- enable RF write
		wait for clk_period;
		tRegWrite <= '0';	-- disable RF write
		-- assert $4 = instruction 4

		-- TEST AND
		tMemtoReg <= "00";	-- write to RF from ALU
		tALUSrcA <= '0';	-- set ALU A as reg A
		tALUSrcB <= "00";	-- set ALU B as reg B
		wait for clk_period;
		
		tRegWrite <= '1';	-- write ALU result to RF
		wait for clk_period;
		tRegWrite <= '0';
		-- assert  $4 = 0	assuming $0 is forced to 0
		wait for 4 ns;

		-- TEST STORE
		-- assuming $0 is 0
		-- reg B is currently 0
		tMemWrite <= '1';	-- enable memory write
		tMemRead <= '0';	-- disable memory read
		wait for wr_latency;	-- wait for write latency of memory
		tMemWrite <= '0';
		tMemRead <= '1';
		
		wait for rd_latency + 5 ns;
		-- assert MEM[PC] = 0 where PC = 16
		tIRWrite <= '1';	-- enable IR write
		wait for clk_period;
		tIRWrite <= '0';	-- disable IR write
		assert topcode_out = "000000" report "failed to store $0=0 to MEM[4]";
		assert tfunc_out = "000000" report "failed to store $0=0 to MEM[4]";
		
		wait for 6 ns;
		-- TEST BRANCH
		-- force PC to 36
		-- must force before 545 ns
		-- MEM[9] = "00010000100000010000000000000011",	--   beq  r4, r1, 3
		tMemRead <= '0';	-- disable and reenable MEM read to get new IR
		wait for 3 ns;
		tMemRead <= '1';
		wait for rd_latency + 5 ns;
		-- fetch instruction
		tIRWrite <= '1';	
		wait for clk_period;
		tIRWrite <= '0';
		assert topcode_out = "000100" report "failed to fetch MEM[9]";
		assert tfunc_out = "000011" report "failed to fetch MEM[9]";
		wait for 4 ns;

		-- increment PC
		tPCsource <= "01";	-- set PC source to branched target addr
		tALUsrcA <= '1';	-- set ALU A to PC
		tALUsrcB <= "01";	-- set ALU B to 4
		wait for clk_period;    -- allow ALU output reg to change value
		tPCupdate <= '1';	-- enable PC write
		

		-- calculate branch address
		-- add PC to IMM
		tALUsrcB <= "11";	-- set ALU B to branching offset
		wait for clk_period;	-- allow ALU output reg to change value
		tPCupdate <= '0';	-- disable PC write

		-- perform comparison
		-- force $1 to 0
		tALUControl <= "001";	-- set ALU to subraction
		tPCsource <= "01";	-- set PC source to branched target addr
		tALUsrcA <= '0';	-- set ALU A to reg A
		tALUsrcB <= "00";	-- set ALU B to reg B

		-- branch if equal to zero
		if (tzero = '1') then		
			tPCupdate <= '1';
			wait for clk_period;
			tPCupdate <= '0';
		end if;
		
		
		
		wait;
	end process;
end datapath_tb_arch;