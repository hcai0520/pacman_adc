library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_unit is
  port (
    CLK_I	               : in std_logic;
    RST_I	               : in std_logic;

    -- REGBUS Ports
    S_REGBUS_RB_RUPDATE  : in  std_logic;
    S_REGBUS_RB_RADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK     : out std_logic;
    
    S_REGBUS_RB_WUPDATE  : in  std_logic;
    S_REGBUS_RB_WADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK     : out std_logic;

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
      CLK_I         	       : in std_logic;
      RST_I	                 : in std_logic;

      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RACK       : out std_logic;

      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      ADC_EN_O                : out std_logic;
      ACQUIRE_O               : out std_logic;


      -- RO registers
      ADC_LOOK_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      RISING_COUNT_I          : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FALLING_COUNT_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_I                : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LAST_I                  : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
      -- RW registers
      TESTPATTERN_CONFIG_A_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TESTPATTERN_CONFIG_B_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TRIG_CONFIG_O              : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      EDGE_CONFIG_O              : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BRAM_CONFIG_O              : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  component adc_test_patterns is
    port (
      CLK_I                : in  std_logic;
      RST_I                : in  std_logic;  
      DATA_O               : out std_logic_vector((ADC_DATA_WIDTH +1)-1 downto 0) := (others => '0');
      CONFIG_A_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CONFIG_B_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;



  component adc_trigger is
    port (
      CLK_I              : in  std_logic;
      RST_I              : in  std_logic;
      TRIG_CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUFFERED_I         : in  std_logic;
      ACQUIRE_I          : in  std_logic;
      RISING_EDGE_I      : in  std_logic;
      FALLING_EDGE_I     : in  std_logic;
      DEBUG_O            : out std_logic_vector(2 downto 0);
      EN_O               : out std_logic
      );
  end component;

  component edge_detect is
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
  end component;


  component adc_bram is
    port(
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

  

  


  -- read only (from regbus) registers
  signal adc_look     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal ris_cnt      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal fal_cnt      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal status       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal last_w       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- config registers
  signal test_pattern_config_a   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal test_pattern_config_b   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal edge_config             : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal trig_config             : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bram_config             : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  
  -- data
  signal adc_data            : std_logic_vector(ADC_DATA_WIDTH downto 0) := (others => '0');
  signal data                : std_logic_vector(ADC_DATA_WIDTH downto 0) := (others => '0');
  signal bram_en             : std_logic;
  signal rise_edge           : std_logic;
  signal fall_edge           : std_logic;
  signal acquire             : std_logic;
  signal buffered            : std_logic;


  begin

  ADC_CLK_O <= CLK_I;
  adc_data(ADC_DATA_WIDTH-1 downto 0)  <= ADC_DATA_I;
  adc_data(ADC_DATA_WIDTH)             <= ADC_DOF_I;
  
  regbus: adc_registers port map (
      CLK_I               => CLK_I,
      RST_I               => RST_I,
      S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
      S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
      S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
      S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
      S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
      S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
      S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
      S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,

      ADC_EN_O            => ADC_EN_O,
      ACQUIRE_O           => acquire ,

      ADC_LOOK_I                => adc_look,
      RISING_COUNT_I            => ris_cnt,
      FALLING_COUNT_I           => fal_cnt,
      STATUS_I                  => status,
      LAST_I                    => last_w,

      TESTPATTERN_CONFIG_A_O    => test_pattern_config_a,
      TESTPATTERN_CONFIG_B_O    => test_pattern_config_b,
      TRIG_CONFIG_O             => trig_config, 
      EDGE_CONFIG_O             => edge_config,
      BRAM_CONFIG_O             => bram_config
      
      );

  in_mux: adc_test_patterns port map (
    CLK_I              => CLK_I,
    RST_I              => RST_I,
    DATA_O             => data,
      
    CONFIG_A_I         => test_pattern_config_a,
    CONFIG_B_I         => test_pattern_config_b

  );

  edge: edge_detect port map (
    CLK_I              => CLK_I,
    RST_I              => RST_I,
    DATA_I             => data,
    EDGE_CONFIG_I      => edge_config,
    RISING_COUNT_O     => ris_cnt,
    FALLING_COUNT_O    => fal_cnt,
    RISING_EDGE_O      => rise_edge, 
    FALLING_EDGE_O     => fall_edge 

  );

  trig: adc_trigger port map (
      CLK_I            => CLK_I,
      RST_I            => RST_I,
      TRIG_CONFIG_I    => trig_config,
      BUFFERED_I       => buffered,
      ACQUIRE_I        => acquire,
      RISING_EDGE_I    => rise_edge,
      FALLING_EDGE_I   => fall_edge,
      EN_O             => bram_en
  );

  bram: adc_bram port map (
    CLK_I            => CLK_I,
    RST_I            => RST_I,
    DATA_I           => data,
    BRAM_EN_I        => bram_en,
    CONFIG_I         => bram_config,
    BUFFERED_O       => buffered,
    STATUS_O         => status,
    LAST_O           => last_w,
    ACQUIRE_I        => acquire,
    BRAM_EN_O        => BRAM_EN_O,
    BRAM_DATA_O      => BRAM_DATA_O,
    BRAM_WEN_O       => BRAM_WEN_O,
    BRAM_ADDR_O      => BRAM_ADDR_O,
    BRAM_CLK_O       => BRAM_CLK_O,
    BRAM_RST_O       => BRAM_RST_O
    );

end behavioral;
