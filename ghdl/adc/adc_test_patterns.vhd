library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;




entity adc_test_patterns is
  port(
    CLK_I             : in  std_logic;
    RST_I          : in  std_logic;
  
    --Test patterns (13 bits)
    DATA_O       : out std_logic_vector((ADC_DATA_WIDTH +1)-1 downto 0) := (others => '0');

    --Config_A determines the wait time and step of the test pattern
    --Config_B determines the rang eof test pattern.   
    CONFIG_A_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    CONFIG_B_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)

    );
end entity adc_test_patterns;

architecture behavioral of adc_test_patterns is
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal wait_t   : std_logic_vector(15 downto 0) := (others => '0');
  signal step     : std_logic_vector(12 downto 0) := (others => '0');
  signal higher   : std_logic_vector(12 downto 0) := (others => '0');
  signal lower    : std_logic_vector(12 downto 0) := (others => '0');
  signal int_data : std_logic_vector(12 downto 0) := (others => '0');  


begin
  clk      <= CLK_I;
  rst      <= RST_I;
  wait_t   <= CONFIG_A_I(31 downto 16);
  step     <= CONFIG_A_I(12 downto  0);
  higher   <= CONFIG_B_I(28 downto 16);
  lower    <= CONFIG_B_I(12 downto  0);
  DATA_O   <= int_data;



  process(clk,rst)
    variable counter : integer := 0;
    variable value   : unsigned(12 downto 0) := (others => '0');
    begin
    if (rst = '1') then
      int_data <= (others => '0');
      value    := unsigned(lower);
      counter  := 0;
    elsif (rising_edge(clk)) then
        if (counter < unsigned(wait_t)) then
          counter := counter + 1;
        else
          counter := 0;
          if  ((step(12) = '0') and ((value<unsigned(lower)) or (value>=unsigned(higher)))) then
            value := unsigned(lower);
          elsif ((step(12)='1') and ((value<=unsigned(lower)) or (value>unsigned(higher)))) then
            value := unsigned(higher);
          else
            value   := value + unsigned(step);
          end if;
          if ((value(12) = '1') and (value(11) = '1')) then --avoid overflow 11 is forbidden since it is not allowed for 12 bits  
            int_data  <= "1111111111111";
          elsif ((value(12)='0') and(value(11) = '0')) then --underflow
            int_data  <= "1000000000000";
          else
            int_data(12)          <= '0';
            int_data(11)          <= not value(11);
            int_data(10 downto 0) <= std_logic_vector(value(10 downto 0));
          end if;
        end if;
    end if;
  end process;
      
end behavioral;
