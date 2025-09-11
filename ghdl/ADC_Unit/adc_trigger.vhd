library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_trigger is
  port (
    ACLK              : in  std_logic;
    ARESETN           : in  std_logic;

    INT_DATA_I        : in  std_logic_vector(ADC_DATA_WIDTH downto 0);

    -- REGISTER
    ADC_TRIG_CONFIG_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    RISING_EDGE_O     : out std_logic;
    FALLING_EDGE_O    : out std_logic
    );
end entity adc_trigger;

architecture behavioral of adc_trigger is
  signal clk     : std_logic;
  signal rst     : std_logic;
  signal data    : std_logic_vector(11 downto 0);
  
  signal thresh  : std_logic_vector(11 downto 0) := (others => '0');
  signal swing   : std_logic_vector(11 downto 0) := (others => '0');

  signal state   : std_logic_vector(1 downto 0) := "00";

  signal rising  : std_logic := '0';
  signal falling : std_logic := '0';

begin
  clk            <= ACLK;
  rst            <= not ARESETN;
  data           <= INT_DATA_I(11 downto 0);

  thresh         <= ADC_TRIG_CONFIG_I(27 downto 16);
  swing          <= ADC_TRIG_CONFIG_I(11 downto  0);

  RISING_EDGE_O  <= rising;
  FALLING_EDGE_O <= falling;

  process(clk,rst) -- state process
    variable low     : unsigned(ADC_DATA_WIDTH-1 downto 0);
    variable high    : unsigned(ADC_DATA_WIDTH-1 downto 0);
    variable current : std_logic_vector(1 downto 0);
  begin
    -- get upper and lower thresholds
    if (unsigned(thresh) < unsigned(swing)) then -- if lowerbound is underflow
      low  := x"000";
    else
      low  := unsigned(thresh) - unsigned(swing);
    end if;
    if (unsigned(not thresh) < unsigned(swing)) then -- if upperbound is overflow
      high := x"FFF";
    else
      high := unsigned(thresh) + unsigned(swing);
    end if;
    -- state code
    if (rst = '1') then
      current := "00";
      state   <= "00";
      rising  <= '0';
      falling <= '0';
    elsif (rising_edge(clk)) then
      rising  <= '0';
      falling <= '0';
      if (unsigned(data) <= low) then
        current := "01";
      elsif (unsigned(data) >= high) then
        current := "11";
      else
        current := "10";
      end if;
      state <= current;
      if ((state = "01") and (current = "11")) then
        rising  <= '1';
      elsif ((state = "11") and (current = "01")) then
        falling <= '1';
      end if;
      
    end if;
  end process;
  
end behavioral;
