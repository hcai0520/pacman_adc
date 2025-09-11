library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_registers is
  generic (
    C_SCOPE                : integer  := 16#D#;

    C_REG_ENABLES          : integer  := 16#000#; -- RW
    C_REG_ADC_COMMANDS     : integer  := 16#004#; -- WO
    
    C_REG_ADC_LOOK         : integer  := 16#100#; -- RO
    C_REG_RISING_COUNT     : integer  := 16#104#; -- RO
    C_REG_FALLING_COUNT    : integer  := 16#108#; -- RO
    C_REG_STATUS           : integer  := 16#10C#; -- RO
    C_REG_LAST             : integer  := 16#110#; -- RO
    
    C_REG_ADC_CONFIG       : integer  := 16#200#; -- RW
    C_REG_ADC_TEST_RANGE   : integer  := 16#204#; -- RW
    C_REG_ADC_TRIG_CONFIG  : integer  := 16#208#; -- RW
    C_REG_ADC_VALID_CONFIG : integer  := 16#20C#; -- RW
    C_REG_BRAM_CONFIG      : integer  := 16#210#; -- RW
    
    C_REG_ADC_SCRATCH      : integer  := 16#300#; -- RW
    C_REG_ADC_ROA          : integer  := 16#304#; -- RO
    C_VAL_ADC_ROA          : integer  := 16#1234ABCD#
    );
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RACK    : out std_logic;

    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

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
end entity adc_registers;

architecture behavioral of adc_registers is
  signal clk      : std_logic;
  signal rst      : std_logic;

  -- Regbus Signals
  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rack     : std_logic := '0';

  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  -- command signals
  signal commands : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal enables  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- output registers 
  signal adc_config   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal test_range   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal trig_config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal valid_config : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bram_config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- scratch registers
  signal scratch      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

begin
  --inputs:
  clk       <= ACLK;
  rst       <= not ARESETN;

  --REGBUS--
  --outputs:
  S_REGBUS_RB_RDATA	 <= rdata;
  S_REGBUS_RB_RACK	 <= rack;
  S_REGBUS_RB_WACK	 <= wack;
  --inputs: (already registered at preceding stage)
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;

  ADC_EN_O  <= enables(0);
  BRAM_EN_O <= enables(1);

  -- Commands
  COMMAND_0_O <= commands(0);
  COMMAND_1_O <= commands(1);
  COMMAND_2_O <= commands(2);
  COMMAND_3_O <= commands(3);

  -- output registers
  ADC_CONFIG_O       <= adc_config;
  ADC_TEST_RANGE_O   <= test_range;
  ADC_TRIG_CONFIG_O  <= trig_config;
  ADC_VALID_CONFIG_O <= valid_config;
  BRAM_CONFIG_O      <= bram_config;
  

  -- Handle Read Request:
  process(clk,rst)
  variable scope   : integer;
  variable reg     : integer;
  begin
    if (rst = '1') then
      rdata <= x"00000000";
      rack <= '0';
    else
      if (rising_edge(clk)) then
        if (rupdate='0') then
          --rdata is registered until the next update or reset.
          rack <= '0';
        else
          scope := to_integer(unsigned(raddr(15 downto 12)));
          reg   := to_integer(unsigned(raddr(11 downto 0)));
          if (scope=C_SCOPE) then
            if (reg=C_REG_ENABLES) then
              rdata <= enables;
              rack <= '1';
            -- RO registers
            elsif (reg=C_REG_ADC_LOOK) then
              rdata <= ADC_LOOK_I;
              rack  <= '1';
            elsif (reg=C_REG_RISING_COUNT) then
              rdata <= RISING_COUNT_I;
              rack  <= '1';
            elsif (reg=C_REG_FALLING_COUNT) then
              rdata <= FALLING_COUNT_I;
              rack  <= '1';
            elsif (reg=C_REG_STATUS) then
              rdata <= STATUS_I;
              rack  <= '1';
            elsif (reg=C_REG_LAST) then
              rdata <= LAST_I;
              rack  <= '1';
            -- RW registers
            elsif (reg=C_REG_ADC_CONFIG) then
              rdata <= adc_config;
              rack  <= '1';
            elsif (reg=C_REG_ADC_TEST_RANGE) then
              rdata <= test_range;
              rack  <= '1';
            elsif (reg=C_REG_ADC_TRIG_CONFIG) then
              rdata <= trig_config;
              rack  <= '1';
            elsif (reg=C_REG_ADC_VALID_CONFIG) then
              rdata <= valid_config;
              rack  <= '1';
            elsif (reg=C_REG_BRAM_CONFIG) then
              rdata <= bram_config;
              rack  <= '1';
            -- scratch registers
            elsif (reg=C_REG_ADC_SCRATCH) then
              rdata <= scratch;
              rack  <= '1';
            elsif (reg=C_REG_ADC_ROA) then
              rdata <= std_logic_vector(to_unsigned(C_VAL_ADC_ROA, rdata'length));
              rack  <= '1';
            else
              -- this is an error, invalid register
              rdata <= x"EEEEEEEE";
              rack  <= '0';
            end if;
          else
            -- this is not an error, just a request outside our scope/role
            rdata <= x"00000000";
            rack  <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Handle Write Request:
  process(clk,rst)
    variable scope   : integer;
    variable reg     : integer;
  begin
    if (rst = '1') then
      adc_config   <= x"00000000";
      test_range   <= x"00000000";
      trig_config  <= x"00000000";
      valid_config <= x"00000000";
      bram_config  <= x"00000000";
      scratch      <= x"00000000";
      commands     <= x"00000000";
    else
      if (rising_edge(clk)) then
        commands   <= x"00000000";
        if (wupdate='0') then
          wack  <= '0';
        else
          scope := to_integer(unsigned(waddr(15 downto 12)));
          reg   := to_integer(unsigned(waddr(11 downto 0)));
          if (scope=C_SCOPE) then
            if (reg=C_REG_ADC_CONFIG) then
              adc_config   <= wdata;
              wack         <= '1';
            elsif (reg=C_REG_ADC_TEST_RANGE) then
              test_range   <= wdata;
              wack         <= '1';
            elsif (reg=C_REG_ADC_TRIG_CONFIG) then
              trig_config  <= wdata;
              wack         <= '1';
            elsif (reg=C_REG_ADC_VALID_CONFIG) then
              valid_config <= wdata;
              wack         <= '1';
            elsif (reg=C_REG_BRAM_CONFIG) then
              bram_config  <= wdata;
              wack         <= '1';
            elsif (reg=C_REG_ADC_COMMANDS) then
              commands     <= wdata;
              wack         <= '1';
            elsif (reg=C_REG_ENABLES) then
              enables      <= wdata;
              wack         <= '1';
            elsif (reg=C_REG_ADC_SCRATCH) then
              scratch      <= wdata;
              wack         <= '1';
            else
              -- this is an error, invalid register
              wack  <= '0';
            end if;
          else
            -- this is not an error, just a request outside our scope/role
            wack  <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
end;
