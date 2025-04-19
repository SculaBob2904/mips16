library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mainCU is
    Port (
        -- inputs
        op_code    : in  std_logic_vector(2 downto 0);
        -- outputs
        reg_dst    : out std_logic;
        ext_op     : out std_logic;
        alu_src    : out std_logic;
        branch     : out std_logic;
        jump       : out std_logic;
        alu_op     : out std_logic_vector(2 downto 0);
        mem_write  : out std_logic;
        mem_to_reg : out std_logic;
        reg_write  : out std_logic
    );
end mainCU;

architecture Behavioral of mainCU is
begin

    process(op_code)
    begin
        -- 1) Default values for every control signal
        reg_dst    <= '0';
        ext_op     <= '0';
        alu_src    <= '0';
        branch     <= '0';
        jump       <= '0';
        alu_op     <= "000";
        mem_write  <= '0';
        mem_to_reg <= '0';
        reg_write  <= '0';

        -- 2) Override based on opcode
        case op_code is
            when "000" =>  -- R-type instructions
                reg_dst   <= '1';
                alu_src   <= '0';
                alu_op    <= "111";  -- use function_bits in execute stage
                reg_write <= '1';

            when "001" =>  -- ADDI (sign-extend immediate)
                ext_op    <= '1';
                alu_src   <= '1';
                alu_op    <= "000";  -- ADD
                reg_write <= '1';

            when "010" =>  -- LW (sign-extend offset, load from memory)
                ext_op     <= '1';
                alu_src    <= '1';
                alu_op     <= "000";  -- ADD to compute address
                mem_to_reg <= '1';
                reg_write  <= '1';

            when "011" =>  -- SW (sign-extend offset, store to memory)
                ext_op    <= '1';
                alu_src   <= '1';
                alu_op    <= "000";  -- ADD to compute address
                mem_write <= '1';

            when "100" =>  -- BEQ (sign-extend offset, branch on equal)
                ext_op    <= '1';
                branch    <= '1';
                alu_op    <= "001";  -- SUB to compare

            when "101" =>  -- ANDI (zero-extend immediate)
                ext_op    <= '0';
                alu_src   <= '1';
                alu_op    <= "010";  -- AND
                reg_write <= '1';

            when "110" =>  -- LUI (load upper immediate)
                ext_op    <= '1';   -- route immediate to upper bits in decode
                alu_src   <= '1';
                alu_op    <= "000"; -- treat as ADD of (imm<<8)
                reg_write <= '1';

            when "111" =>  -- J (jump)
                jump      <= '1';

            when others =>
                -- leave defaults (NOP)
                null;
        end case;
    end process;

end Behavioral;
