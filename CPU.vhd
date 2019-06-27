LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity CPU is
  
  port (
    clk     : in std_logic;
    reset_N : in std_logic);            -- active-low signal for reset

end CPU;

architecture CPU_arch of CPU is
-- component declaration
	
	-- Datapath (from Lab 5)
	component datapath is
		port(
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
    zero       : out std_logic		-- send zero to controller (cond. branch)
		);
	end component;

	-- Controller (you just built)
	component control is
		port(
        clk   	    : IN STD_LOGIC; 
        reset_N	    : IN STD_LOGIC; 
        
	-- "000000" for R type operations
        op_code      : IN opcode;     -- declare type for the 6 most significant bits of IR
        funct       : IN opcode;     -- declare type for the 6 least significant bits of IR 
     	zero        : IN STD_LOGIC;
        
     	PCUpdate    : OUT STD_LOGIC; -- this signal controls whether PC is updated or not
     	IorD        : OUT STD_LOGIC;	-- MEM addr = PC if 0, else ALU output reg
     	MemRead     : OUT STD_LOGIC;	
     	MemWrite    : OUT STD_LOGIC;

     	IRWrite     : OUT STD_LOGIC;	
	-- RF in = 
	-- 	if 0, ALU output reg
	-- 	if 1, MDR
	-- 	if 2, PC
     	MemtoReg    : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
	-- RF addr =
	--	if 0, rt
	--	if 1, rd
	-- 	if 2, 31
     	RegDst      : OUT STD_LOGIC_VECTOR (1 downto 0); -- the extra bit is for JAL
     	RegWrite    : OUT STD_LOGIC;
     	ALUSrcA     : OUT STD_LOGIC;	--ALU A = A reg if 0, else PC
	-- ALU B =
	--	if 0, B reg
	--	if 1, 4
	-- 	if 2, IMM
	-- 	if 3, branch offset
     	ALUSrcB     : OUT STD_LOGIC_VECTOR (1 downto 0); 
     	ALUcontrol  : OUT ALU_opcode;
	-- PC = 
	--	if 0, ALU out for PC+4
	--	if 1, ALU output reg for branching
	--	if 2, jump addr
     	PCSource    : OUT STD_LOGIC_VECTOR (1 downto 0)
	);
	end component;
-- component specification

-- signal declaration
	signal ctrl_opcode, ctrl_funccode : opcode;
	signal ctrl_zero : std_logic;
	signal ctrl_PCupdate, ctrl_IorD, ctrl_MemRead, ctrl_MemWrite, ctrl_IRwrite, ctrl_RegWrite, ctrl_ALUSrcA : std_logic;
	signal ctrl_ALUcontrol : ALU_opcode;
	signal ctrl_MemtoReg, ctrl_RegDst, ctrl_ALUSrcB, ctrl_PCSource : std_logic_vector (1 downto 0);

begin
	datapath0 : datapath port map (clk, reset_N, ctrl_PCUpdate, ctrl_IorD, ctrl_MemRead, ctrl_MemWrite, ctrl_IRWrite, ctrl_MEmtoREg, ctrl_RegDst,
		ctrl_RegWrite, ctrl_ALUSrcA, ctrl_ALUSrcB, ctrl_ALUcontrol, ctrl_PCSource, ctrl_opcode, ctrl_funccode, ctrl_zero);

	control0 : control port map (clk, reset_N, ctrl_opcode, ctrl_funccode, ctrl_zero, ctrl_PCupdate, ctrl_IorD, ctrl_MemRead, ctrl_MemWrite, 
		ctrl_IRWrite, ctrl_MemtoReg, ctrl_RegDst, ctrl_RegWrite, ctrl_ALUSrcA, ctrl_ALUSrcB, ctrl_ALUcontrol, ctrl_PCSource);



end CPU_arch;
