library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_input_mux_tb is
end adc_input_mux_tb;

architecture behaviour of adc_input_mux_tb is
  component adc_input_mux is
    port (
      ACLK             : in  std_logic;
      ARESETN          : in  std_logic;
      
      ADC_DATA_I       : in  std_logic_vector(ADC_DATA_WIDTH downto 0);
      INT_DATA_O       : out std_logic_vector(ADC_DATA_WIDTH downto 0);
      ADC_LOOK_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      --ADC_EN_O         : out std_logic;

      ADC_TEST_RANGE_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ADC_CONFIG_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;
  signal count      : integer := 0;
  signal aclk       : std_logic;
  signal aresetn    : std_logic;
  
  signal config     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal test_range : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal look       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal data_o     : std_logic_vector(15 downto 0) := (others => '0');
  signal data_i     : std_logic_vector(15 downto 0) := (others => '0');
  signal di         : std_logic_vector(11 downto 0) := (others => '0');
  signal diof       : std_logic := '0';

  --signal adc_en     : std_logic;
begin
  uut: adc_input_mux port map (
    ACLK             => aclk,
    ARESETN          => aresetn,
    ADC_DATA_I       => data_i(12 downto 0),
    INT_DATA_O       => data_o(12 downto 0),
    ADC_LOOK_O       => look,
    --ADC_EN_O         => adc_en,
    ADC_TEST_RANGE_I => test_range,
    ADC_CONFIG_I     => config
  );

  data_i(11 downto  0) <= di;
  data_i(12)           <= diof;
  data_i(15 downto 13) <= (others => '0');

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 12 ns;
    aresetn <= '1';    
    wait;
  end process;
  
  aclk_process : process
  begin
    count <= count + 1;    
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  config_in : process
  begin
    wait for 18 ns;
    test_range <= x"11000F00";
    config     <= x"00008000";
    wait for 70 ns;
    config     <= x"0001BFF0";
    --wait for 70 ns;
    --config     <= x"00016005";
    wait;
  end process;

  data_in : process
  begin
    di     <= x"000";
    diof   <= '0';
    wait for 22 ns;
    di     <= x"111";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"222";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"333";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"444";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"555";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"666";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"777";
    diof   <= '0';   
    wait for 10 ns;
    di     <= x"888";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"999";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"AAA";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"BBB";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"CCC";
    diof   <= '1';  
    wait for 10 ns;
    di     <= x"DDD";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"EEE";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"FFF";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"001";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"112";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"223";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"334";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"445";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"556";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"667";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"778";
    diof   <= '0';   
    wait for 10 ns;
    di     <= x"889";
    diof   <= '1';
    wait for 10 ns;
    di     <= x"99A";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"AAB";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"BBC";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"CCD";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"DDE";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"EEF";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"FF0";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"ACE";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"222";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"333";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"444";
    diof   <= '1';
    wait for 10 ns;
    di     <= x"555";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"666";
    diof   <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    if (count < 15) then
      wait for 10 ns;
    else
      wait;
    end if;
    write (l, String'("c: "));
    write (l, count, left, 4);
    --write (l, String'("aclk: "));
    --write (l, aclk);
    --write (l, String'(" | adc_test_range_i: 0x"));
    --hwrite (l, test_range);
    write (l, String'(" adc_config_i: 0x"));
    hwrite (l, config);
    write (l, String'(" | adc_data_i: 0x"));
    hwrite (l, data_i);
    write (l, String'(" || int_data_o: 0x"));
    hwrite (l, data_o);
    write (l, String'(" | adc_look_o: 0x"));
    hwrite (l, look);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
