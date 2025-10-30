library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;


--create rising and falling signal from adc_input_mux
--01=LOW ;11=HIGH
--rising edge when state_z "01" and state "11"
--falling edge when state_z "11" and state "01" 

entity edge_detect is
  port (
    CLK_I              : in  std_logic;
    RST_I              : in  std_logic;
    DATA_I             : in  std_logic_vector(ADC_DATA_WIDTH downto 0);
    EDGE_CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    RISING_COUNT_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    FALLING_COUNT_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    RISING_EDGE_O      : out std_logic;
    FALLING_EDGE_O     : out std_logic
    );
end entity edge_detect;

architecture behavioral of edge_detect is
  signal clk     : std_logic;
  signal rst     : std_logic;
  signal data    : std_logic_vector(11 downto 0);
  signal thresh  : std_logic_vector(11 downto 0) := (others => '0');
  signal swing   : std_logic_vector(11 downto 0) := (others => '0');
  signal state_z : std_logic_vector(1 downto 0) := "00";
  signal rising  : std_logic := '0';
  signal falling : std_logic := '0';
  constant count_max      : unsigned(31 downto 0) := to_unsigned(100000000 - 1, C_RB_DATA_WIDTH);
begin
  clk            <=  CLK_I;
  rst            <=  RST_I;
  data           <=  DATA_I(11 downto 0);
  thresh         <=  EDGE_CONFIG_I(27 downto 16);
  swing          <=  EDGE_CONFIG_I(11 downto  0);

  RISING_EDGE_O  <= rising;
  FALLING_EDGE_O <= falling; 



  -- state process
  process(clk,rst) 
    variable state   : std_logic_vector(1 downto 0);
    variable low     : unsigned(ADC_DATA_WIDTH-1 downto 0);
    variable high    : unsigned(ADC_DATA_WIDTH-1 downto 0);
  begin
    -- get upper and lower thresholds
    if (unsigned(thresh) < unsigned(swing)) then -- if lowerbound is underflow
      low  := x"000";
    else
      low  := unsigned(thresh) - unsigned(swing);
    end if;
    if (unsigned(not thresh) < unsigned(swing)) then -- if upperbound is overflow; not thresh = 2^n - 1 - thresh (n is bits)
      high := x"FFF";
    else
      high := unsigned(thresh) + unsigned(swing);
    end if;
    -- state code
    if (rst = '1') then
      state_z <= "00";
      state   := "00";
      rising  <= '0';
      falling <= '0';
     
    elsif (rising_edge(clk)) then
      rising  <= '0';
      falling <= '0';
      if (unsigned(data) <= low) then
        state := "01";
      elsif (unsigned(data) >= high) then
        state := "11";
      else
        state := "10";
      end if;
      state_z <= state;
      if ((state_z = "01") and (state = "11")) then
        rising  <= '1';
        
      elsif ((state_z = "11") and (state = "01")) then
        falling <= '1';
        
      end if;


    end if;
  end process;
  
  --count rising and falling edge
  process(clk,rst) --gets counts:
  variable r_cnt : unsigned(31 downto 0);
  variable f_cnt : unsigned(31 downto 0);
  begin
    if (rst = '1') then
      r_cnt := (others => '0');
      f_cnt := (others => '0');
    elsif (rising_edge(clk)) then
      if (rising = '1') then
        if r_cnt = count_max then
          r_cnt :=(others => '0');
        else
          r_cnt := r_cnt + 1;
        end if;
      end if;
      if (falling = '1') then
        if f_cnt = count_max then
          f_cnt :=(others => '0');
        else  
          f_cnt := f_cnt + 1;
        end if;  
      end if;
      RISING_COUNT_O <= std_logic_vector(r_cnt);
      FALLING_COUNT_O <= std_logic_vector(f_cnt);
    end if;
  end process;
  
end behavioral;
