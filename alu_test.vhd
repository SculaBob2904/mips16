
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity alu_test is
    Port (
        clk : in std_logic;
        btn : in std_logic_vector(4 downto 0);
        sw  : in std_logic_vector(15 downto 0);
        an  : out std_logic_vector(3 downto 0);
        cat : out std_logic_vector(6 downto 0);
        led : out std_logic_vector(15 downto 0)
     );
end alu_test;

architecture Behavioral of alu_test is

    component  ALU is
    Port ( 
       --inputs
       operand_1     : in std_logic_vector(15 downto 0);
       operand_2     : in std_logic_vector(15 downto 0);
       --ext_imm       : in std_logic_vector(15 downto 0);
       --function_bits : in std_logic_vector(2 downto 0);
       --shift_amount  : in std_logic;
       --control signals
       --aluSrc        : in std_logic;
       aluOp         : in std_logic_vector(2 downto 0);
       --outputs
       --branch_addr   : out std_logic_vector(15 downto 0);
       result        : out std_logic_vector(15 downto 0);
       zero_flag     : out std_logic;
       HI_reg        : out std_logic_vector(15 downto 0);
       LO_reg        : out std_logic_vector(15 downto 0)
    );
end component;

component seven_seg_disp is
  port (
    clk    : in  std_logic;
    digits : in  std_logic_vector(15 downto 0);   
    an     : out std_logic_vector(3  downto 0);
    cat    : out std_logic_vector(6  downto 0)
  );
end component;

signal operand_1      : std_logic_vector(15 downto 0) := x"1111";
signal operand_2      : std_logic_vector(15 downto 0) := x"1010";
signal result_for_ssd : std_logic_vector(15 downto 0) := x"0000";
signal result_alu     : std_logic_vector(15 downto 0);
signal result_HI      : std_logic_vector(15 downto 0);   
signal result_LO      : std_logic_vector(15 downto 0);   

begin

process(sw(2 downto 0))
begin 
    if sw(2 downto 0) = "111" then
        if sw(15) = '1' then
            result_for_ssd <= result_HI;
        else 
            result_for_ssd <= result_LO;
        end if;
    else 
        result_for_ssd <= result_alu;
    end if;
end process;

ssd : seven_seg_disp port map(
    clk    => clk,
    digits => result_for_ssd,
    an     => an,
    cat    => cat
);

calculator : ALU port map(
    operand_1 => operand_1,
    operand_2 => operand_2,
    aluOp     => sw(2 downto 0),
    result    => result_alu,
    zero_flag => led(15),
    HI_reg    => result_HI,
    LO_reg    => result_LO
);
    
end Behavioral;
