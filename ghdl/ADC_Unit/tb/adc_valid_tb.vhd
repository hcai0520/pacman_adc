library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_valid_tb is
end adc_valid_tb;

architecture behaviour of adc_valid_tb is
  component adc_valid is
    port (
      ACLK             : in  std_logic;
      ARESETN          : in  std_logic;
      
      VALID_O            : out std_logic;
      ADC_VALID_CONFIG_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      RISING_EDGE_I      : in  std_logic;
      FALLING_EDGE_I     : in  std_logic;

      RISING_COUNT_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FALLING_COUNT_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;
  signal count      : integer := 0;
  signal aclk       : std_logic;
  signal aresetn    : std_logic;
  
  signal config     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal fall_e     : std_logic := '0';
  signal rise_e     : std_logic := '0';

  signal valid      : std_logic;
  signal r_cnt      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal f_cnt      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

begin
  uut: adc_valid port map (
    ACLK               => aclk,
    ARESETN            => aresetn,
    ADC_VALID_CONFIG_I => config,
    RISING_EDGE_I      => rise_e,
    FALLING_EDGE_I     => fall_e,
    VALID_O            => valid,
    RISING_COUNT_O     => r_cnt,
    FALLING_COUNT_O    => f_cnt
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
    config     <= x"FAFAFAFA";
    wait;
  end process;

  edges_in : process
  begin
    wait for 21 ns;
    rise_e  <= '1';
    wait for 10 ns;
    rise_e  <= '0';
    wait for 30 ns;
    fall_e  <= '1';
    wait for 10 ns;
    fall_e  <= '0';
    wait for 40 ns;
    fall_e  <= '1';
    wait for 10 ns;
    fall_e  <= '0';
    wait for 20 ns;
    rise_e  <= '1';
    wait for 10 ns;
    rise_e  <= '0';
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
    write (l, String'(" adc_valid_config_i: 0x"));
    hwrite (l, config);
    write (l, String'(" | rising_edge_i: 0x"));
    write (l, rise_e);
    write (l, String'(" | falling_edge_i: 0x"));
    write (l, fall_e);
    write (l, String'(" || valid_o: "));
    write (l, valid);
    write (l, String'(" | rising_count_o: 0x"));
    hwrite (l, r_cnt);
    write (l, String'(" | falling_count_o: 0x"));
    hwrite (l, f_cnt);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
