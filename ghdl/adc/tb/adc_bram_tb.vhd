library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_bram_tb is
end adc_bram_tb;
     
architecture behaviour of adc_bram_tb is
  component adc_bram is
    port (
      CLK_I          : in  std_logic;
      RST_I          : in  std_logic;

      ACQUIRE_I      : in  std_logic;
      DATA_I         : in  std_logic_vector(ADC_DATA_WIDTH downto 0);
      BRAM_EN_I      : in std_logic; 

    -- REGISTER
      CONFIG_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LAST_O         : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
      BUFFERED_O     : out std_logic;


    -- BRAM
    --bram enable out is determined by bram enable in (from time resigsters) and valid. 
      BRAM_EN_O      : out std_logic;
      BRAM_DATA_O    : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
      BRAM_WEN_O     : out std_logic_vector(3 downto 0);
      BRAM_ADDR_O    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
      BRAM_CLK_O     : out std_logic;
      BRAM_RST_O     : out std_logic
    );
  end component;
  signal count     : integer := 0;
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal bram_en_in   : std_logic;
  signal bram_en_out    : std_logic;
  signal data_i    : std_logic_vector(15 downto 0);
  signal di        : std_logic_vector(ADC_DATA_WIDTH-1 downto 0) := (others => '0');
  signal diof      : std_logic := '0';
  signal config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal stat      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal last      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wen       : std_logic_vector(3 downto 0);
  signal addr      : std_logic_vector(15 downto 0);
  signal do        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal buffered  : std_logic;
  signal acquire   : std_logic;

begin
  uut: adc_bram port map (
      CLK_I         => clk,
      RST_I         => rst,
      ACQUIRE_I     => acquire,
      BRAM_EN_O     => bram_en_out,
      DATA_I        => data_i(12 downto 0),
      BRAM_EN_I     => bram_en_in,
      CONFIG_I      => config,
      STATUS_O      => stat,
      LAST_O        => last,
      BRAM_DATA_O   => do,
      BRAM_WEN_O    => wen,
      BRAM_ADDR_O   => addr(BRAM_ADDR_WIDTH-1 downto 0),
      BUFFERED_O    => buffered
      );

  data_i(11 downto 0)  <= di;
  data_i(12)           <= diof;
  data_i(15 downto 13) <= (others => '0');
  
  rst_process : process
  begin
    rst <= '1';
    wait for 20 ns;
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

  config_in : process
  begin
    wait for 18 ns;
    config <= x"0000000F";
   -- wait for 30 ns;
   -- config <= x"00011008";
   -- wait for 100 ns;
   -- config <= x"00012004";
   -- wait for 100 ns;
   -- config <= x"00013002";
    wait;
  end process;

  data_in : process
  begin
    di     <= x"000";
    diof   <= '0';
    wait for 18 ns;
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

  acquire_process : process
  begin
    wait for 1 ns;
    acquire <= '0';
    wait for 10 ns;
    acquire <= '1'; 
    wait for 10 ns;
    acquire <= '0';   
    wait;
  end process;

  bram_enable : process
  begin
    wait for 1 ns;
    bram_en_in <= '0';
    wait for 20 ns;
    bram_en_in <= '1';   
    wait for 200 ns;
    bram_en_in <= '0';  
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    if (count < 35) then
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
    write (l, String'(" bram_en_i: "));
    write (l, bram_en_in);
    write (l, String'(" bram_en_o: "));
    write (l, bram_en_out);
    write (l, String'(" bram_config_i: 0x"));
    hwrite (l, config);
    write (l, String'(" | int_data_i: 0x"));
    hwrite (l, data_i);
    write (l, String'(" || bram_data_o: 0x"));
    hwrite (l, do);
    write (l, String'(" | bram_addr_o: 0x"));
    hwrite (l, addr);
    write (l, String'(" | bram_wen_o: 0x"));
    hwrite (l, wen);

    write (l, String'(" | buffered_o: "));
    write (l, buffered);
    --write (l, String'(" | adc_last_o: 0x"));
    --hwrite (l, last);
    if (rst = '1') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;


  
end behaviour;
