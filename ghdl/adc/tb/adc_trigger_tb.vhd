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
      CLK_I              : in  std_logic;
      RST_I              : in  std_logic;
      TRIG_CONFIG_I   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUFFERED_I         : in  std_logic;
      ACQUIRE_I           : in  std_logic;
      RISING_EDGE_I      : in  std_logic;
      FALLING_EDGE_I     : in  std_logic;
      DEBUG_O            : out std_logic_vector(2 downto 0);
      EN_O               : out std_logic
      );
  end component;
  signal count      : integer := 0;
  signal clk        : std_logic;
  signal rst        : std_logic;
  signal en_out     : std_logic;
  signal config     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rising     : std_logic;
  signal status    : std_logic_vector(2 downto 0);
  signal acquire     : std_logic :='0';
  signal buff       : std_logic := '0';
begin
  uut: adc_trigger port map (
      CLK_I               => clk,
      RST_I               => rst,
      TRIG_CONFIG_I       => config,
      BUFFERED_I          => buff,
      ACQUIRE_I            => acquire,
      RISING_EDGE_I       => rising,
      FALLING_EDGE_I      => '0',
      DEBUG_O             =>  status,
      EN_O                => en_out
  );



  rst_process : process
  begin
    rst <= '1';
    wait for 10 ns;
    rst <= '0';    
    wait;
  end process;
  
  clk_process : process
  begin
    count <= count + 1;    
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  end process;


  acquire_process : process
  begin
    wait for 1 ns;
    acquire <= '0';
    wait for 20 ns;
    acquire <= '1'; 
    wait for 10 ns;
    acquire <= '0';   
    wait;
  end process;

  buff_process : process
  begin
    wait for 1 ns;
    buff <= '1';
    wait for 60 ns;
    buff <= '1'; 
    wait;
  end process;

  config_in : process
  begin
    config     <= x"000A0001";
    wait;
  end process;

  data_in : process
  begin
    rising   <= '0';
    wait for 120 ns;
    rising   <= '1';
    wait for 10 ns;
    rising   <= '0';
    wait;
  end process;

    output_process : process
    variable l : line;
    begin
    if (count < 30) then
      wait for 10 ns;
    else
      wait;
    end if;
    write (l, String'("c: "));
    write (l, count, left, 4);
    write (l, String'("clk: "));
    write (l, clk);
    write (l, String'(" acquire: "));
    write (l, acquire);
    write (l, String'(" buff: "));
    write (l, buff);
    write (l, String'(" config: 0x"));
    hwrite (l, config);
    write (l, String'(" | rising: "));
    write (l, rising);
    write (l, String'(" || EN_O: "));
    write (l, en_out);
    write (l, String'(" | status "));
    write (l, status);
    if (rst = '1') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
