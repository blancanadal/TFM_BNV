------------------------------------------------------------------
-- Name: ov7670_debounce
-- Description: TEST DECREASING DEBOUNCE TIME
-- Author: Blanca Nadal Valle
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ov7670_debounce is
  port ( 
  clk25   : in  std_logic; -- clk25
  bntc    : in  std_logic; -- connected to bntc
  bntr    : in  std_logic; -- connected to bntr
  resend  : out std_logic;
  reset   : out std_logic
  );
end ov7670_debounce;


architecture ov7670_debounce_arch of ov7670_debounce is

signal cntc_debounce: unsigned(23 downto 0); -- counts up to 4096 (0,164 ms)
signal cntr_debounce: unsigned(23 downto 0); 
-- clk25 --> period = 40ns


begin

-------------------------
-- DEBOUNCE FOR RESEND --
-------------------------
  process(clk25)
  begin
    if rising_edge(clk25) then
      if (bntc = '1') then
        if (cntc_debounce >= x"FFFF") then
          resend      <= '1';
        else
          cntc_debounce <= cntc_debounce + 1;
          resend        <= '0';
        end if;
      else
        cntc_debounce <= (others => '0');
        resend        <= '0';
      end if;
    end if;
  end process;
  
------------------------
-- DEBOUNCE FOR RESET --
------------------------ 
  process(clk25)
  begin
    if rising_edge(clk25) then
      if (bntr = '1') then
        if (cntr_debounce >= x"FFFF") then
          reset      <= '0';
        else
          cntr_debounce <= cntr_debounce + 1;
          reset        <= '1';
        end if;
      else
        cntr_debounce <= (others => '0');
        reset        <= '1';
      end if;
    end if;
  end process;
  

end ov7670_debounce_arch;
