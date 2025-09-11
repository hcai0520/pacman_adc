library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_bram is
  port (
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
end entity adc_bram;

architecture behavioral of adc_bram is
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal valid     : std_logic;
  
  signal wen       : std_logic_vector(3 downto 0) := (others => '0');
  signal addr      : std_logic_vector(10 downto 0) := (others => '0');
  signal data      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');

  signal stat      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal last      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal buff_size : std_logic_vector(10 downto 0) := (others => '0');
  signal packing   : std_logic_vector(3  downto 0) := (others => '0');
 
begin
  clk         <= ACLK;
  rst         <= not ARESETN;
  valid       <= VALID_I;
  
  --BRAM_EN_O   <= BRAM_CONFIG_I(16);
  BRAM_RST_O  <= rst;
  BRAM_CLK_O  <= clk;

  BRAM_ADDR_O(12 downto 2) <= addr;
  BRAM_ADDR_O(1  downto 0) <= "00";
  BRAM_DATA_O <= data;
  BRAM_WEN_O  <= wen;

  buff_size   <= BRAM_CONFIG_I(10 downto  0);
  packing     <= BRAM_CONFIG_I(15 downto 12);

  STATUS_O    <= stat;
  LAST_O      <= last;

  process(clk,rst)
  begin
    if (rst = '1') then
      wen      <= (others => '0');
      data     <= (others => '0');
      addr     <= (others => '0');
    elsif (rising_edge(clk)) then
      if (packing = x"0" or valid = '0') then -- reset state
        wen      <= (others => '0');
        data     <= (others => '0');
        addr     <= (others => '0');
      elsif (packing = x"1") then
        data(12 downto 0)  <= INT_DATA_I;
        data(31 downto 13) <= (others => '0');
        wen                <= (others => '1');
        if (buff_size = x"0") then
          addr <= std_logic_vector(unsigned(addr) + 1);
        elsif (unsigned(addr) >= unsigned(buff_size)) then
          addr <= (others => '0');
        else
          addr <= std_logic_vector(unsigned(addr) + 1);
        end if;
      elsif (packing = x"2") then -- bit packing (no loss of data)
        data(12 downto 0)  <= INT_DATA_I;
        data(15 downto 13) <= (others => '0');
        data(28 downto 16) <= INT_DATA_I;
        data(31 downto 29)  <= (others => '0');
        if (wen = x"3") then
          wen <= x"C";
        else
          wen <= x"3";
          if (buff_size = x"0") then
            addr <= std_logic_vector(unsigned(addr) + 1);
          elsif (unsigned(addr) >= unsigned(buff_size)) then
            addr <= (others => '0');
          else
            addr <= std_logic_vector(unsigned(addr) + 1);
          end if;
        end if;
      elsif (packing = x"3") then --very packed (loss of 4 bits of data + overflow)
        data(7  downto  0) <= INT_DATA_I(11 downto 4);
        data(15 downto  8) <= INT_DATA_I(11 downto 4);
        data(23 downto 16) <= INT_DATA_I(11 downto 4);
        data(31 downto 24) <= INT_DATA_I(11 downto 4);
        if (wen = x"1") then
          wen <= x"2";
        elsif (wen = x"2") then
          wen <= x"4";
        elsif (wen = x"4") then
          wen <= x"8";
        else
          wen <= x"1";
          if (buff_size = x"0") then
            addr <= std_logic_vector(unsigned(addr) + 1);
          elsif (unsigned(addr) >= unsigned(buff_size)) then
            addr <= (others => '0');
          else
            addr <= std_logic_vector(unsigned(addr) + 1);
          end if;
        end if;
      else
        wen      <= (others => '0');
        data     <= (others => '0');
        addr     <= (others => '0');
      end if;
    end if;
  end process;

  process(clk,rst) -- gets status and last
  begin
    if (rst = '1') then
      last <= (others => '0');
      stat <= (others => '0');
    else
      if (rising_edge(clk)) then
        if (wen /= x"0") then
          stat(10 downto 0) <= addr;
          stat(15 downto 12) <= wen;
          last <= data;
        end if;
      end if;
    end if;
  end process;

end behavioral;
