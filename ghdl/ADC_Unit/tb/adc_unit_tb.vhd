library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

entity adc_unit_tb is
end adc_unit_tb;

architecture behaviour of adc_unit_tb is
  component adc_unit is
    port (
      ACLK	          : in std_logic;
      ARESETN	          : in std_logic;

      -- REGBUS Ports
      S_REGBUS_RB_RUPDATE : in  std_logic;
      S_REGBUS_RB_RADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      S_REGBUS_RB_RACK    : out std_logic;
    
      S_REGBUS_RB_WUPDATE : in  std_logic;
      S_REGBUS_RB_WADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK    : out std_logic;

      -- BRAM
      BRAM_EN_O           : out std_logic; 
      BRAM_DATA_O         : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
      BRAM_WEN_O          : out std_logic_vector(3 downto 0);
      BRAM_ADDR_O         : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
      BRAM_CLK_O          : out std_logic;
      BRAM_RST_O          : out std_logic;
    
      -- ADC
      ADC_EN_O            : out std_logic;
      ADC_CLK_O           : out std_logic;
      ADC_DATA_I          : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
      ADC_DOF_I           : in  std_logic
    );
  end component;
  
  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;

  -- regbus 
  -- read signals:
  signal raddr   : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rupdate : std_logic := '0';
  signal rdata   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rack    : std_logic := '0';
  -- write signals:
  signal waddr   : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wupdate : std_logic := '0';
  signal wdata   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal wack    : std_logic := '0';

  -- bram
  signal wen       : std_logic_vector(3 downto 0);
  signal addr      : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal do        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal b_clk     : std_logic;
  signal b_rst     : std_logic;
  signal b_en      : std_logic;
  
  signal di        : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
  signal diof      : std_logic;

 

  -- adc
  signal adc_en    : std_logic;
  signal adc_clk   : std_logic;

begin
  uut: adc_unit port map (
    ADC_EN_O       => adc_en,
    ADC_CLK_O      => adc_clk,
    ACLK           => aclk,
    ARESETN        => aresetn,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack, 
    ADC_DATA_I          => di,
    ADC_DOF_I           => diof,
    BRAM_EN_O           => b_en,
    BRAM_CLK_O          => b_clk,
    BRAM_RST_O          => b_rst,
    BRAM_DATA_O         => do,
    BRAM_ADDR_O         => addr,
    BRAM_WEN_O          => wen
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


write_process : process
  begin
    wait for 1 ns;
    wait for 20 ns; -- Turn BRAM and ADC on
    waddr   <= x"D000";
    wdata   <= x"00000003";
    wupdate <= '1';
    wait for 10 ns; 
    waddr   <= x"D210"; --tells BRAM to use 8 addresses
    wdata   <= x"00001008"; -- with 1 ADC word per address
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D208"; -- gives trigger conditions
    wdata   <= x"08000080"; --thresh 0x800 swing 0x80
    wupdate <= '1';
    wait for 10 ns;  
    waddr   <= x"D204"; --sets the bounds on the test patterns(doesn't use them yet)
    wdata   <= x"11000F00"; -- lower of 0x700 higher of 0x900
    wupdate <= '1';
    wait for 80 ns; 
    waddr   <= x"D200"; -- starts using test patterns
    wdata   <= x"00012020"; -- wait of 1 clockcycle and step of 0x20
    wupdate <= '1';
    wait for 50 ns;
    waddr   <= x"D210"; -- tells bram to use 4 addresses
    wdata   <= x"00002004"; -- with 2 ADC words per address
    wupdate <= '1';
    wait;
  end process;
  
  rapid_read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 42 ns;
    raddr   <= x"D100"; --reads look
    rupdate <= '1';     --should be one clockcycle ahead of output data
    wait for 30 ns;
    raddr   <= x"D104"; --reads  rising edge count
    rupdate <= '1';     --should see a rising edge
    wait for 60 ns;
    raddr   <= x"D108"; -- reads falling edge counts 
    rupdate <= '1';     --should see a falling edge
    wait for 40 ns;
    raddr   <= x"D110"; -- what are we write out
    rupdate <= '1';     -- should be one clockcycle behind output data
    wait for 100 ns;
    raddr   <= x"D108";  --should see regularly increasing
    rupdate <= '1';
    wait;
  end process;

  data_in : process
  begin
    di     <= x"000";
    diof   <= '0';
    wait for 23 ns;
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
    diof   <= '1';
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
    diof   <= '1';
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


end behaviour;
