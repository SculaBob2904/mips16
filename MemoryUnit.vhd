
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;
 
 
entity mem_unit is
     Port (
        clk         : in std_logic;
        we          : in std_logic;
        addr        : in std_logic_vector(15 downto 0);
        di          : in std_logic_vector(15 downto 0);
        do          : out std_logic_vector(15 downto 0) 
     );
end mem_unit;

architecture Behavioral of mem_unit is
    type ram_memory is array(0 to 63) of std_logic_vector(15 downto 0);
    signal ram : ram_memory := (
        others => (others => '0')
    );
    
begin
    
    do <= ram(conv_integer(addr));
    
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(we = '1') then
                ram(conv_integer(addr)) <= di;
            end if;
        end if;
    end process;

end Behavioral;
