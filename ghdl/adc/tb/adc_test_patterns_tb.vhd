library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_test_patterns_tb is
end adc_test_patterns_tb;

architecture behaviour of adc_test_patterns_tb is
  component adc_test_patterns is
    port (
      ACLK             : in  std_logic;
      ARESETN          : in  std_logic;
      
      DATA_O       : out std_logic_vector((ADC_DATA_WIDTH +1)-1 downto 0) := (others => '0');

      
      CONFIG_A_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CONFIG_B_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;
  signal count      : integer := 0;
  signal aclk       : std_logic;
  signal aresetn    : std_logic;
  
  signal config_a     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal config_b : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal data_o     : std_logic_vector(15 downto 0) := (others => '0');
  signal diof       : std_logic := '0';

  --signal adc_en     : std_logic;
begin
  uut: adc_test_patterns port map (
    ACLK             => aclk,
    ARESETN          => aresetn,

    DATA_O       => data_o(12 downto 0),
 
    CONFIG_A_I       =>config_a,
    CONFIG_B_I       =>config_b

  );



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
    config_b     <= x"110010A0";
    config_a     <= x"0001BFF0";
    --wait for 70 ns;
    --config     <= x"00016005";
    wait;
  end process;

  
  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    if (count < 20) then
      wait for 10 ns;
    else
      wait;
    end if;
    write (l, String'("c: "));
    write (l, count, left, 4);
    write (l, String'("aclk: "));
    write (l, aclk);
    write (l, String'(" | adc_test_range_i: 0x"));
    hwrite (l, config_b);
    write (l, String'(" adc_config_i: 0x"));
    hwrite (l, config_a);
    write (l, String'(" || data_o: 0x"));
    hwrite (l, data_o);

    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
