library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity instr_execute is
    Port (
        -- inputs
        operand_1     : in  std_logic_vector(15 downto 0);
        operand_2     : in  std_logic_vector(15 downto 0);
        ext_imm       : in  std_logic_vector(15 downto 0);
        pc_plus_one   : in  std_logic_vector(15 downto 0);
        function_bits : in  std_logic_vector(2 downto 0);
        shift_amount  : in  std_logic;
        -- control signals
        aluSrc        : in  std_logic;
        aluOp         : in  std_logic_vector(2 downto 0);
        -- outputs
        branch_addr   : out std_logic_vector(15 downto 0);
        result        : out std_logic_vector(15 downto 0);
        zero_flag     : out std_logic;
        mul_flag      : out std_logic;
        HI_reg        : out std_logic_vector(15 downto 0);
        LO_reg        : out std_logic_vector(15 downto 0)
    );
end instr_execute;

architecture Behavioral of instr_execute is

    -- internal signals
    signal aluOpFinal     : std_logic_vector(2 downto 0);
    signal sig_operand_2  : std_logic_vector(15 downto 0);
    signal sig_mul_flag   : std_logic;

    signal s_operand_1    : signed(15 downto 0);
    signal s_operand_2    : signed(15 downto 0);
    signal s_result       : signed(15 downto 0);
    signal l_result       : std_logic_vector(15 downto 0);

    signal s_mul_result   : signed(31 downto 0);
    signal slv_mul_result : std_logic_vector(31 downto 0);

begin
    -- widen inputs to signed/unsigned as needed
    s_operand_1   <= signed(operand_1);
    s_operand_2   <= signed(operand_2)     when aluSrc = '0'
                   else signed(ext_imm);
    sig_operand_2 <= operand_2              when aluSrc = '0'
                   else ext_imm;

    -- detect multiply instruction (R-type opcode "111" + funct "110")
    sig_mul_flag  <= '1' when aluOp = "111" and function_bits = "110"
                   else '0';
    mul_flag      <= sig_mul_flag;

    -- compute branch target as (PC + 1) + signed(offset)
    branch_addr   <= std_logic_vector( signed(pc_plus_one) 
                                     + signed(ext_imm) );

    -- decode to final ALU operation code (no latches)
    process(aluOp, function_bits)
    begin
        -- default = ADD
        aluOpFinal <= "000";

        if aluOp = "111" then
            -- R-type: use function_bits to select
            case function_bits is
                when "000" => aluOpFinal <= "000";  -- ADD
                when "001" => aluOpFinal <= "001";  -- SUB
                when "010" => aluOpFinal <= "101";  -- SLL
                when "011" => aluOpFinal <= "110";  -- SRL
                when "100" => aluOpFinal <= "010";  -- AND
                when "101" => aluOpFinal <= "011";  -- OR
                when "110" => aluOpFinal <= "100";  -- XOR
                when others => aluOpFinal <= "000";
            end case;
        elsif aluOp = "010" or aluOp = "011" then
            -- LW/SW use ADD for address calculation
            aluOpFinal <= "000";
        elsif aluOp = "001" then
            -- ADDI
            aluOpFinal <= "000";
        elsif aluOp = "101" then
            -- ANDI
            aluOpFinal <= "010";
        end if;
    end process;

    -- main ALU and shift logic, fully combinational
    process(aluOpFinal, s_operand_1, s_operand_2, sig_operand_2, shift_amount)
    begin
        -- defaults
        s_result  <= (others => '0');
        l_result  <= (others => '0');

        case aluOpFinal is
            when "000" =>
                -- ADD
                s_result <= s_operand_1 + s_operand_2;
            when "001" =>
                -- SUB
                s_result <= s_operand_1 - s_operand_2;
            when "010" =>
                -- AND
                l_result <= operand_1 and sig_operand_2;
            when "011" =>
                -- OR
                l_result <= operand_1 or sig_operand_2;
            when "100" =>
                -- XOR
                l_result <= operand_1 xor sig_operand_2;
            when "101" =>
                -- SLL by 1 if shift_amount='1'
                if shift_amount = '1' then
                    s_result <= s_operand_2(14 downto 0) & '0';
                end if;
            when "110" =>
                -- SRL by 1 if shift_amount='1'
                if shift_amount = '1' then
                    s_result <= '0' & s_operand_2(15 downto 1);
                end if;
            when others =>
                -- no-op / default
                null;
        end case;
    end process;

    -- multiplier: produce 32-bit product when requested
    process(sig_mul_flag, s_operand_1, s_operand_2)
    begin
        if sig_mul_flag = '1' then
            s_mul_result <= s_operand_1 * s_operand_2;
        else
            s_mul_result <= (others => '0');
        end if;
    end process;

    -- zero flag from signed result
    zero_flag <= '1' when s_result = 0 else '0';

    -- select between logic result and arithmetic result
    result <= l_result
              when aluOpFinal = "010"  -- AND
                or aluOpFinal = "011"  -- OR
                or aluOpFinal = "100"  -- XOR
              else std_logic_vector(s_result);

    -- split 32-bit multiply result into HI/LO
    slv_mul_result <= std_logic_vector(s_mul_result);
    HI_reg         <= slv_mul_result(31 downto 16);
    LO_reg         <= slv_mul_result(15 downto 0);

end Behavioral;
