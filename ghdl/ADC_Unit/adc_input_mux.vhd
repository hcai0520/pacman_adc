library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_input_mux is
  port(
    ACLK             : in  std_logic;
    ARESETN          : in  std_logic;
  
    ADC_DATA_I       : in  std_logic_vector(ADC_DATA_WIDTH downto 0);
    INT_DATA_O       : out std_logic_vector(ADC_DATA_WIDTH downto 0) := (others => '0');

    --ADC_EN_O         : out std_logic;

    --regbus
    ADC_LOOK_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
    ADC_TEST_RANGE_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    ADC_CONFIG_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
end entity adc_input_mux;

architecture behavioral of adc_input_mux is
  signal clk      : std_logic;
  signal rst      : std_logic;
  --signal adc_en   : std_logic := '0';
  signal adc_data : std_logic_vector(12 downto 0) := (others => '0');
  signal wait_t   : std_logic_vector(15 downto 0) := (others => '0');
  signal mode     : std_logic_vector(1  downto 0) := (others => '0');
  signal step     : std_logic_vector(12 downto 0) := (others => '0');
  signal higher   : std_logic_vector(12 downto 0) := (others => '0');
  signal lower    : std_logic_vector(12 downto 0) := (others => '0');
  signal int_data : std_logic_vector(12 downto 0) := (others => '0');    
begin
  clk      <= ACLK;
  rst      <= not ARESETN;
  
  higher   <= ADC_TEST_RANGE_I(28 downto 16);
  lower    <= ADC_TEST_RANGE_I(12 downto  0);

  wait_t   <= ADC_CONFIG_I(31 downto 16);
  --ADC_EN_O <= ADC_CONFIG_I(15);
  mode     <= ADC_CONFIG_I(14 downto 13);
  step     <= ADC_CONFIG_I(12 downto  0);

  INT_DATA_O <= int_data;

  process(clk)
    begin
    if (falling_edge(clk)) then
      adc_data <= ADC_DATA_I;
    elsif (rising_edge(clk)) then
      ADC_LOOK_O(ADC_DATA_WIDTH downto 0) <= adc_data;      
    end if;
  end process;

  process(clk,rst)
    variable counter : integer := 0;
    variable value   : unsigned(12 downto 0) := (others => '0');
    begin
    if (rst = '1') then
      int_data <= (others => '0');
      value    := unsigned(lower);
      counter  := 0;
    elsif (rising_edge(clk)) then
      if (mode = "00") then
        int_data <= adc_data;
      elsif (mode = "01") then
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
          if ((value(12) = '1') and (value(11) = '1')) then
            int_data  <= "1111111111111";
          elsif ((value(12)='0') and(value(11) = '0')) then
            int_data  <= "1000000000000";
          else
            int_data(12)          <= '0';
            int_data(11)          <= not value(11);
            int_data(10 downto 0) <= std_logic_vector(value(10 downto 0));
          end if;
        end if;
      else
        int_data <= (others => '0');
      end if;
    end if;
  end process;
      
end behavioral;
