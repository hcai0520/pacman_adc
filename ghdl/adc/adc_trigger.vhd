library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_trigger is
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
end entity adc_trigger;

architecture behavioral of adc_trigger is

  type state_t is (S_IDLE, S_BUFFERING, S_ARMED, S_TRIGGERED);
  signal state, next_state : state_t := S_IDLE;

  signal clk        : std_logic;
  signal rst        : std_logic;

  
  signal hold_cnt   : unsigned(15 downto 0):=(others => '0');

  signal hold       : unsigned(15 downto 0):=(others => '0');
  signal trig_on    : std_logic :='0';
  signal mode       : std_logic_vector(2 downto 0):= "000";

  signal trig_off  : std_logic := '0';
  signal en_out    : std_logic := '0';
  signal status    : std_logic_vector(2 downto 0);
  begin
    
    clk              <=  CLK_I;
    rst              <=  RST_I;
    mode             <= TRIG_CONFIG_I(2 downto 0);
    hold             <= unsigned(TRIG_CONFIG_I(31 downto 16));


    trig_on <= '1' when (state = S_ARMED) and 
                        ((RISING_EDGE_I = '1' and mode(0)= '1') or 
                        (FALLING_EDGE_I = '1' and mode(1)= '1')or 
                         mode(2) = '1' ) 
                else '0' ; 
    

    status <= "000" when state = S_IDLE else
              "001" when state = S_BUFFERING else
              "010" when state = S_ARMED else
              "011" when state = S_TRIGGERED else
              "111";
    DEBUG_O <= status;
    process(state, ACQUIRE_I,BUFFERED_I,trig_on,trig_off)
    begin
      next_state    <= state;
      case state is
        when S_IDLE =>
          if(ACQUIRE_I = '1') then           
            next_state    <= S_BUFFERING;
          end if;
        when S_BUFFERING =>
          if BUFFERED_I = '1' then
            next_state   <= S_ARMED;
          end if;
        when S_ARMED =>
          if trig_on = '1' then
            next_state <= S_TRIGGERED;
          end if;
        when S_TRIGGERED =>              
          if trig_off = '1' then
            next_state <= S_IDLE;          
          end if;
      end case;
    end process;

  process(clk,rst)
  begin
    if (rst = '1') then 
      state    <= S_IDLE;     
    elsif (rising_edge(clk)) then
      state    <= next_state;   
    end if;  
  end process;

  process(clk,rst)
  begin
    if (rst = '1') then     
      hold_cnt <= (others => '0');
      trig_off <= '0';
    elsif (rising_edge(clk)) then
      trig_off <= '0';
      if (state = S_ARMED) then
        hold_cnt <= (others => '0');
      elsif(state = S_TRIGGERED) then
        if hold = 0 then
          trig_off <= '1';               
          hold_cnt <= (others => '0');
      elsif hold_cnt = hold -1 then
          trig_off <= '1';               
          hold_cnt <= (others => '0');
        else
          hold_cnt <= hold_cnt + 1;
    end if;
      end if;     
    end if;  
  end process;

  process(clk, rst)
  begin
    if rst = '1' then
      en_out <= '0';
    elsif rising_edge(clk) then
      if (state = S_BUFFERING) or (state = S_ARMED) or (state = S_TRIGGERED) then
        en_out <= '1';
      else
        en_out <= '0';
      end if;
    end if;
  end process;

  EN_O <= en_out;
end behavioral;