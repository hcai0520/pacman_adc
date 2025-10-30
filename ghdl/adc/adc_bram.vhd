library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_bram is
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
end entity adc_bram;

architecture behavioral of adc_bram is
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal wen       : std_logic_vector(3 downto 0) := (others => '0');
  signal addr      : std_logic_vector(10 downto 0) := (others => '0');
  signal last_addr : std_logic_vector(10 downto 0) := (others => '0');
  signal addr_z    : std_logic_vector(10 downto 0) := (others => '0');
  signal data      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');

  signal stat      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal last      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal buff_size : std_logic_vector(10 downto 0) := (others => '0');
  signal packing   : std_logic_vector(3  downto 0) := (others => '0');

  signal data_in   : std_logic_vector(ADC_DATA_WIDTH downto 0) := (others => '0');
  signal buffered  : std_logic := '0';
  signal bram_en   : std_logic;
begin
  clk         <= CLK_I;
  rst         <= RST_I;
  
  
  BRAM_RST_O   <= rst;
  BRAM_CLK_O   <= clk;
  BRAM_EN_O    <= bram_en;
  BRAM_ADDR_O(12 downto 2) <= addr;
  BRAM_ADDR_O(1  downto 0) <= "00";
  BRAM_DATA_O <= data;
  BRAM_WEN_O  <= wen;

  buff_size   <= CONFIG_I(10 downto 0);
  
  STATUS_O    <= stat;
  LAST_O      <= last;
  BUFFERED_O  <= buffered;

  process(clk,rst)
  begin
    if (rst = '1') then
      wen       <= (others => '0');
      data      <= (others => '0');
      addr      <= (others => '0');
      last_addr <= (others => '0');
      addr_z    <= (others => '0');
    elsif (rising_edge(clk)) then
      if ACQUIRE_I = '1' then
        buffered <= '0';
        if (unsigned(buff_size) > 0) then
          last_addr <= std_logic_vector(
                            to_unsigned(
                            (to_integer(unsigned(addr)) + to_integer(unsigned(buff_size)) - 1)
                            mod to_integer(unsigned(buff_size)),11));
        end if;                    
      end if;


      if BRAM_EN_I = '1' then

        data(12 downto 0)  <=   DATA_I;
        data(31 downto 13) <=   (others => '0');
        wen                <=   x"F";        
        if (unsigned(buff_size) = 0) then
          addr <= std_logic_vector(unsigned(addr) + 1);
        elsif (unsigned(addr) >= unsigned(buff_size)-1) then
          addr <= (others => '0');
        else
          addr <= std_logic_vector(unsigned(addr) + 1);
        end if;

        if addr = last_addr then
          buffered <= '1';
        end if;  
      else                                
        wen  <= (others => '0');
      end if;

    end if;  
  end process;


  process(clk,rst) -- gets status and latest data
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


process(clk,rst) -- enable bram
begin
  if (rst = '1') then
    bram_en     <= '0'; 
  else
    bram_en    <= BRAM_EN_I  ;
  end if;  
end process;



end behavioral;