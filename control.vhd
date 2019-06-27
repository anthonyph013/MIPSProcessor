LIBRARY IEEE; 
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
USE work.Glob_dcls.all;

entity control is 
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
end control;

architecture control_arch of control is
-- component declaration
	
-- component specification


-- signal declaration
	-- enumerate control states
	type ctrl_state is (InstFetch, InstDecode, BranchInstCmp, BranchInstUpdate, JumpInst, ItypeInst, RtypeInst, RegWriteResult, IRegWriteResult, 
		MemRefInst, StoreWord, MemtoMDR, LoadWord, Invalid);

	-- set initial state to InstFetch state
	signal curr_state : ctrl_state := InstFetch;

	-- signal for PCwrite condition
	signal PCWriteCond : std_logic;

	-- signal for ALU control
	-- (00, add), (01, xor), (10, funct Rtype), (11, opcode Itype)
	signal ALUop : std_logic_vector(1 downto 0);

begin
	-- set control signals based on current state
--	with curr_state select
--		PCUpdate <=	'1' when InstFetch | BranchInstUpdate | JumpInst,
--				'0' when others;

	with curr_state select
		IorD <=		'1' when StoreWord | MemtoMDR,
				'0' when others;

	with curr_state select
		-- add delay for mem read/write since LW only works after ALU output register
		-- has correct value which only occurs on rising clock edge
		-- mem read/write only occur on rising edge of its control signal
		-- 1 ns after rising clock edge
		MemRead <=	'1' after 1 ns when InstFetch | MemtoMDR,
				'0' when others;

	with curr_state select
		-- see MemRead above
		MemWrite <=	'1' after 1 ns when StoreWord,
				'0' when others;

	with curr_state select
		IRWrite <=	'1' when InstFetch,
				'0' when others;
	
	with curr_state select
		RegWrite <=	'1' when RegWriteResult | IRegWriteResult | LoadWord,
				'0' when others;

	with curr_state select
		ALUSrcA <=	'1' when InstFetch | InstDecode,
				'0' when others;

	-- RF input data: (0. ALU output), (1, MDR), (2, PC output)
	with curr_state select
		MemtoReg <=	"00" when RegWriteResult | IRegWriteResult,
				"01" when LoadWord,
				"XX" when others;	-- no state corresponding to "10"

	-- RF write addr: (0, rt), (1, rd), (2, $31)
	with curr_state select
		RegDst <=	"00" when LoadWord | IRegWriteResult,
				"01" when RegWriteResult,
				"XX" when others;	-- no state corresponding to "10"
	
	-- ALU source B: (0, reg B), (1, int 4), (2, IMM), (3, branch offset)
	with curr_state select
		ALUSrcB <=	"00" when BranchInstCmp | RtypeInst,
				"01" when InstFetch,
				"10" when ItypeInst | MemRefInst,
				"11" when InstDecode,
				"XX" when others;	-- set value as X for unspecified states. should have no effects on instructions

	-- PC source: (0, ALU output), (1, branch addr aka ALU output register), (2, jump addr)
	with curr_state select
		PCSource <=	"00" when InstFetch,
				"01" when BranchInstCmp,
				"10" when JumpInst,
				"XX" when others;	-- set value as X for unspecified states. should have no effects on instructions
	
	-- Set ALU OP
	with curr_state select
		ALUop <=	"00" when InstFetch | InstDecode | MemRefInst,	-- ADDITION
				"01" when BranchInstCmp,			-- XOR
				"10" when RtypeInst,				-- take funct
				"11" when ItypeInst,				-- take opcode
				"XX" when others;

	-- handle state transitions
	process(clk, reset_N, op_code, funct, zero, curr_state, PCWriteCond, ALUop)
	begin
		-- set control signals sequentially
		-- set PC write signal
		if curr_state = InstFetch or (curr_State = BranchInstCmp and PCWriteCond = '1') or curr_state = JumpInst then
			PCupdate <= '1';
		else
			PCupdate <= '0';
		end if;

		-- set ALU control signal
		case ALUop is
		when "00" =>	-- ADDITION
			ALUcontrol <= alu_add;

		when "01" => -- XOR
			ALUcontrol <= alu_xor;	

		when "10" =>
			case funct is
			when funct_add =>	-- addition
				ALUcontrol <= alu_add;

			when funct_sub =>	-- subtraction
				ALUcontrol <= alu_sub;
		
			when funct_and =>	-- and
				ALUcontrol <= alu_and;
		
			when funct_or =>	-- or
				ALUcontrol <= alu_or;
	
			when funct_sll =>	-- shift left logical
				ALUcontrol <= alu_sll;

			when funct_srl =>	-- shift right logical
				ALUcontrol <= alu_srl;
			
			when others =>
			end case;
		
		when "11" =>
			case op_code is
			when op_addi =>		-- add IMM
				ALUcontrol <= alu_add;

			when op_ori =>		-- or IMM
				ALUcontrol <= alu_or;
			
			when op_andi =>		-- and IMM
				ALUcontrol <= alu_and;

			when others =>
			end case;

		when others =>
		end case;

		-- set PC write conditional signal for branching
		-- op_code = 000100 for BE, 000101 for BNE
		-- branch when equal for BE or nonequal for BNE
		if (zero = '1' and op_code = op_BE) or (zero = '0' and op_code = op_BNE) then
			--curr_state <= BranchInstUpdate;
			--PCSource <= "01";
			PCWriteCond <= '1';

		elsif not (zero = '1' and op_code = op_BE) or (zero = '0' and op_code = op_BNE) then
			--curr_state <= InstFetch;
			--PCSource <= "00";
			PcWriteCond <= '0';
		end if;

		if (clk'EVENT and clk = '1' and not (reset_N = '0')) then
			case curr_state is
			when InstFetch =>	-- instruction fetch
				curr_state <= InstDecode;
	
			when InstDecode =>	-- instruction decode
				-- select which instruction state to transition to based on op_code
				case op_code is
				when op_R => 	-- R-type opcode
					curr_state <= RtypeInst;
	
				when op_BE | op_BNE =>	-- branch opcode
					curr_state <= BranchInstCmp;
	
				when op_JMP =>	-- jump opcode
					curr_state <= JumpInst;
	
				when op_SW | op_LW =>	-- store/load word opcode
					curr_state <= MemRefInst;
	
				when op_ADDI | op_ANDI | op_ORI =>	-- I-type opcode
					curr_state <= ItypeInst;
	
				-- send unspecified opcodes to invalid state
				when others =>
					curr_state <= Invalid;
				end case;
				--curr_state <= 
	
			when BranchInstCmp =>	-- branch instruction for comparing equality/nonequality
				curr_state <= InstFetch;
	
			when ItypeInst =>	-- I type instructions
				curr_state <= IRegWriteResult;
			
			when RtypeInst =>	-- R type instructions
				curr_state <= RegWriteResult;
	
			when MemRefInst =>	-- Memory Reference Instructions
				case op_code is
				when op_SW =>	-- store word opcode
					curr_state <= StoreWord;
	
				when op_LW =>	-- load word opcode
					curr_state <= MemtoMDR;
	
				-- send unspecified opcodes to invalid state
				when others =>
					curr_state <= Invalid;
				end case;
	
			when MemtoMDR =>	-- write to MDR register from memory
				curr_state <= LoadWord;
	
			-- states that have nonconditional transition to Instruction Fetch state
			when BranchInstUpdate | JumpInst | StoreWord | LoadWord =>
				curr_state <= InstFetch;

			when RegWriteResult | IRegWriteResult =>
				curr_state <= InstFetch;

			when others =>
			end case;
		end if;
	end process;

end control_arch;



