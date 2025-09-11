library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_unit is
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    -- REGBUS Ports
    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
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
end adc_unit;

architecture behavioral of adc_unit is
  component adc_registers is
    port(
      ACLK	             : in std_logic;
      ARESETN	             : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

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

  component adc_input_mux is
    port (
      ACLK             : in  std_logic;
      ARESETN          : in  std_logic;
  
      ADC_DATA_I       : in  std_logic_vector(ADC_DATA_WIDTH downto 0);
      INT_DATA_O       : out std_logic_vector(ADC_DATA_WIDTH downto 0) := (others => '0');

      --ADC_EN_O         : out std_logic;

      --regbus
      ADC_LOOK_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
      ADC_TEST_RANGE_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ADC_CONFIG_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  component adc_bram is
    port(
      ACLK           : in  std_logic;
      ARESETN        : in  std_logic;

      VALID_I        : in  std_logic;
      INT_DATA_I     : in  std_logic_vector(ADC_DATA_WIDTH downto 0);
    
      -- REGISTER
      BRAM_CONFIG_I  : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LAST_O         : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
      -- BRAM
      --BRAM_EN_O      : out std_logic; 
      BRAM_DATA_O    : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
      BRAM_WEN_O     : out std_logic_vector(3 downto 0);
      BRAM_ADDR_O    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
      BRAM_CLK_O     : out std_logic;
      BRAM_RST_O     : out std_logic
      );
  end component;

  component adc_trigger is
    port(
      ACLK              : in  std_logic;
      ARESETN           : in  std_logic;

      INT_DATA_I        : in  std_logic_vector(ADC_DATA_WIDTH downto 0);

      -- REGISTER
      ADC_TRIG_CONFIG_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      RISING_EDGE_O     : out std_logic;
      FALLING_EDGE_O    : out std_logic
      );
  end component;

  component adc_valid is
    port(
      ACLK               : in  std_logic;
      ARESETN            : in  std_logic;

      VALID_O            : out std_logic;
      ADC_VALID_CONFIG_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      RISING_EDGE_I      : in  std_logic;
      FALLING_EDGE_I     : in  std_logic;

      RISING_COUNT_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FALLING_COUNT_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  -- commands
  signal command0     : std_logic := '0';
  signal command1     : std_logic := '0';
  signal command2     : std_logic := '0';
  signal command3     : std_logic := '0';

  -- read only (from regbus) registers
  signal adc_look     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal ris_cnt      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal fal_cnt      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal status       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal last_w       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- read write registers
  signal adc_config   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal test_range   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal trig_config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal valid_config : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bram_config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- data
  signal adc_data  : std_logic_vector(ADC_DATA_WIDTH downto 0) := (others => '0');
  signal int_data  : std_logic_vector(ADC_DATA_WIDTH downto 0) := (others => '0');

  signal rise_edge : std_logic;
  signal fall_edge : std_logic;
  signal valid     : std_logic;
  



  begin

  ADC_CLK_O <= ACLK;
  adc_data(ADC_DATA_WIDTH-1 downto 0)  <= ADC_DATA_I;
  adc_data(ADC_DATA_WIDTH)             <= ADC_DOF_I;
  
  regbus: adc_registers port map (
      ACLK           => ACLK,
      ARESETN        => ARESETN,
      S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
      S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
      S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
      S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
      S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
      S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
      S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
      S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,

      ADC_EN_O            => ADC_EN_O,
      BRAM_EN_O           => BRAM_EN_O,

      COMMAND_0_O         => command0,
      COMMAND_1_O         => command1,
      COMMAND_2_O         => command2,
      COMMAND_3_O         => command3,

      ADC_LOOK_I          => adc_look,
      RISING_COUNT_I      => ris_cnt,
      FALLING_COUNT_I     => fal_cnt,
      STATUS_I            => status,
      LAST_I              => last_w,

      ADC_CONFIG_O        => adc_config,
      ADC_TEST_RANGE_O    => test_range,
      ADC_TRIG_CONFIG_O   => trig_config, 
      ADC_VALID_CONFIG_O  => valid_config,
      BRAM_CONFIG_O       => bram_config  
      
      );

  in_mux: adc_input_mux port map (
    ACLK             => ACLK,
    ARESETN          => ARESETN,
    ADC_DATA_I       => adc_data, 
    INT_DATA_O       => int_data,
    ADC_LOOK_O       => adc_look, 
    --ADC_EN_O         => ADC_EN_O,
    ADC_TEST_RANGE_I => test_range,
    ADC_CONFIG_I     => adc_config
  );

  trig: adc_trigger port map (
    ACLK              => ACLK,
    ARESETN           => ARESETN,
    INT_DATA_I        => int_data,
    ADC_TRIG_CONFIG_I => trig_config,
    RISING_EDGE_O     => rise_edge, 
    FALLING_EDGE_O    => fall_edge  
  );

  validate: adc_valid port map (
    ACLK               => ACLK,
    ARESETN            => ARESETN,
    ADC_VALID_CONFIG_I => valid_config,
    RISING_EDGE_I      => rise_edge,
    FALLING_EDGE_I     => fall_edge,
    VALID_O            => valid,
    RISING_COUNT_O     => ris_cnt,
    FALLING_COUNT_O    => fal_cnt
  );

  bram: adc_bram port map (
    ACLK           => ACLK,
    ARESETN        => ARESETN,
    VALID_I        => valid,
    INT_DATA_I     => int_data,
    BRAM_CONFIG_I  => bram_config,
    
    STATUS_O      => status,
    LAST_O        => last_w,

    --BRAM_EN_O      => BRAM_EN_O,
    BRAM_DATA_O    => BRAM_DATA_O,
    BRAM_WEN_O     => BRAM_WEN_O,
    BRAM_ADDR_O    => BRAM_ADDR_O,
    BRAM_CLK_O     => BRAM_CLK_O,
    BRAM_RST_O     => BRAM_RST_O
    );

end behavioral;
