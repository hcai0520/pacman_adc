library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_registers_tb is
end adc_registers_tb;
     
architecture behaviour of adc_registers_tb is
  component adc_registers is
    port (
      ACLK	           : in std_logic;
      ARESETN	           : in std_logic;

      S_REGBUS_RB_RADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE  : in  std_logic;
      S_REGBUS_RB_RACK     : out std_logic;
      
      S_REGBUS_RB_WUPDATE  : in  std_logic;
      S_REGBUS_RB_WADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK     : out std_logic;

      -- Enables
      BRAM_EN_O           : out std_logic;
      ADC_EN_O            : out std_logic;

      -- Commands
      COMMAND_0_O         : out std_logic;
      COMMAND_1_O         : out std_logic;
      COMMAND_2_O         : out std_logic;
      COMMAND_3_O         : out std_logic;
    
      -- RO registers
      ADC_LOOK_I          : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      RISING_COUNT_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FALLING_COUNT_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LAST_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
      -- RW registers
      ADC_CONFIG_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ADC_TEST_RANGE_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ADC_TRIG_CONFIG_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ADC_VALID_CONFIG_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BRAM_CONFIG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;
  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  -- registers
  signal adc_config   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal test_range   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal trig_config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal valid_config : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bram_config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- enables
  signal bram_en      : std_logic := '0';
  signal adc_en       : std_logic := '0';
  -- commands
  signal command0     : std_logic := '0';
  signal command1     : std_logic := '0';
  signal command2     : std_logic := '0';
  signal command3     : std_logic := '0';

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
begin
  uut: adc_registers port map (
      ACLK                => aclk,
      ARESETN             => aresetn,
      
      S_REGBUS_RB_RUPDATE => rupdate,
      S_REGBUS_RB_RADDR   => raddr,
      S_REGBUS_RB_RDATA   => rdata,
      S_REGBUS_RB_RACK    => rack,
      S_REGBUS_RB_WUPDATE => wupdate,
      S_REGBUS_RB_WADDR   => waddr,
      S_REGBUS_RB_WDATA   => wdata,
      S_REGBUS_RB_WACK    => wack,

      BRAM_EN_O           => bram_en,
      ADC_EN_O            => adc_en,

      COMMAND_0_O         => command0,
      COMMAND_1_O         => command1,
      COMMAND_2_O         => command2,
      COMMAND_3_O         => command3,

      ADC_LOOK_I          => x"ABCD1248",
      RISING_COUNT_I      => x"00000010",
      FALLING_COUNT_I     => x"00000008",
      STATUS_I            => x"000F0100",
      LAST_I              => x"0ADC0ADC",

      ADC_CONFIG_O        => adc_config,
      ADC_TEST_RANGE_O    => test_range,
      ADC_TRIG_CONFIG_O   => trig_config,
      ADC_VALID_CONFIG_O  => valid_config,
      BRAM_CONFIG_O       => bram_config
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

  read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 1 ns;
    wait for 20 ns;
    raddr   <= x"D100";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D104";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D108";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D10C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D110";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D200";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D204";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D208";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D20C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D210";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D300";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D304";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait;
  end process;

  write_process : process
  begin
    wait for 18 ns;
    waddr   <= x"D000";
    wdata   <= x"0000000C";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D200";
    wdata   <= x"DEADBEEF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D204";
    wdata   <= x"000000EF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D208";
    wdata   <= x"ABBAABBA";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D20C";
    wdata   <= x"FEED0000";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D210";
    wdata   <= x"BAA0FEE0";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D300";
    wdata   <= x"124836C7";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000"; 
    wdata   <= x"00000000";
    wupdate <= '0';
    wait;
  end process;

output_process : process
    variable l : line;
  begin
    if (count < 15) then
      wait for 10 ns;
    else
      wait;
    end if;
    write (l, String'("c: "));
    write (l, count, left, 4);
    --write (l, String'("aclk: "));
    --write (l, aclk);
    write (l, String'(" || ra: 0x"));
    hwrite (l, raddr);
    write (l, String'(" ru:"));
    write (l, rupdate);
    write (l, String'(" rd: 0x"));
    hwrite (l, rdata);
    write (l, String'(" rk:"));
    write (l, rack);
    write (l, String'(" || wa: 0x"));
    hwrite (l, waddr);
    write (l, String'(" wu:"));
    write (l, wupdate);
    write (l, String'(" wd: 0x"));
    hwrite (l, wdata);
    write (l, String'(" wk:"));
    write (l, wack);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
