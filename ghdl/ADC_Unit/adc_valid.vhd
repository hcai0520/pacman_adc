library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_valid is
  port (
    ACLK               : in  std_logic;
    ARESETN            : in  std_logic;

    VALID_O            : out std_logic;
    ADC_VALID_CONFIG_I : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    RISING_EDGE_I      : in  std_logic;
    FALLING_EDGE_I     : in  std_logic;

    RISING_COUNT_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    FALLING_COUNT_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
end entity adc_valid;

architecture behavioral of adc_valid is
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal valid     : std_logic;
  
  signal config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal ris_ed    : std_logic;
  signal fal_ed    : std_logic;
  signal r_cnt     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal f_cnt     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
begin
  clk             <= ACLK;
  rst             <= not ARESETN;
  VALID_O         <= valid;

  config          <= ADC_VALID_CONFIG_I;
  fal_ed          <= FALLING_EDGE_I;
  ris_ed          <= RISING_EDGE_I;

  RISING_COUNT_O  <= r_cnt;
  FALLING_COUNT_O <= f_cnt;

  process(clk,rst) --gets valid
  begin
    if (rst = '1') then
      valid  <= '0';
    elsif (rising_edge(clk)) then
      if (config = x"FFFFFFFF") then
        valid <= '0';
      else
        valid  <= '1';
      end if;
    end if;
  end process;

  process(clk,rst) --gets counts:
  begin
    if (rst = '1') then
      r_cnt <= (others => '0');
      f_cnt <= (others => '0');
    elsif (rising_edge(clk)) then
      if (ris_ed = '1') then
        r_cnt <= std_logic_vector(unsigned(r_cnt) + 1);
      end if;
      if (fal_ed = '1') then
        f_cnt <= std_logic_vector(unsigned(f_cnt) + 1);
      end if;
    end if;
  end process;

end behavioral;
