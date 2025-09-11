library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_trigger_tb is
end adc_trigger_tb;

architecture behaviour of adc_trigger_tb is
  component adc_trigger is
    port (
      ACLK             : in  std_logic;
      ARESETN          : in  std_logic;
      
      INT_DATA_I       : in  std_logic_vector(ADC_DATA_WIDTH downto 0);

      ADC_TRIG_CONFIG_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      RISING_EDGE_O     : out std_logic;
      FALLING_EDGE_O    : out std_logic
      );
  end component;
  signal count      : integer := 0;
  signal aclk       : std_logic;
  signal aresetn    : std_logic;
  
  signal config     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal data_i     : std_logic_vector(15 downto 0) := (others => '0');
  signal di         : std_logic_vector(11 downto 0) := (others => '0');
  signal diof       : std_logic := '0';

  signal fall       : std_logic;
  signal rise       : std_logic;

  
begin
  uut: adc_trigger port map (
    ACLK              => aclk,
    ARESETN           => aresetn,
    INT_DATA_I        => data_i(12 downto 0),
    ADC_TRIG_CONFIG_I => config,
    RISING_EDGE_O     => rise,
    FALLING_EDGE_O    => fall
  );

  data_i(11 downto 0) <= di;
  data_i(12)          <= diof;
  data_i(15 downto 13)<= (others => '0');

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
    config     <= x"08000080";
    wait;
  end process;

  data_in : process
  begin
    di     <= x"000";
    diof   <= '0';
    wait for 19 ns;
    di     <= x"111";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"333";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"555";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"777";
    diof   <= '0';   
    wait for 10 ns;
    di     <= x"888";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"AAA";
    diof   <= '0';   
    wait for 10 ns;
    di     <= x"001";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"781";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"ACE";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"87F";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"0BE";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"BED";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"7A0";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"700";
    diof   <= '0';   
    wait for 10 ns;
    di     <= x"830";
    diof   <= '1';
    wait for 10 ns;
    di     <= x"DEA";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"1CE";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"880";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"780";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"AAA";
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
    write (l, String'(" adc_trig_config_i: 0x"));
    hwrite (l, config);
    write (l, String'(" | int_data_i: 0x"));
    hwrite (l, data_i);
    write (l, String'(" || rising_edge_o: "));
    write (l, rise);
    write (l, String'(" | falling_edge_o: "));
    write (l, fall);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
