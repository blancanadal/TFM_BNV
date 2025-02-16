------------------------------------------------------------------
-- Name: ov7670_registers
-- Description: Module that stores the configuration parameters to
-- send to sensor through SCCB
-- Author: Blanca Nadal Valle
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
  
entity ov7670_registers is
  port ( 
    clk             : in std_logic;
    continue        : in std_logic;
    resend          : in std_logic;
    command         : out std_logic_vector(15 downto 0);
    config_finished : out std_logic
  );
end ov7670_registers;
  
  
architecture ov7670_registers_arch of ov7670_registers is
  signal addrReg      : std_logic_vector(7 downto 0);
  signal s_command    : std_logic_vector(15 downto 0);

--attribute mark_debug: string;
--attribute mark_debug of config_finished : signal is "true";
--attribute mark_debug of addrReg         : signal is "true";
--attribute mark_debug of command         : signal is "true";
--attribute mark_debug of continue        : signal is "true";


begin

process(clk)
begin
  if rising_edge(clk) then
    if (resend = '1') then
        addrReg <= (others => '0');
    elsif (continue = '1') then
        addrReg <= std_logic_vector(unsigned(addrReg) + 1);
    end if;
  end if;
end process;  
    
 
 process(addrReg)
 begin
    case addrReg is         -- from datasheet
      when x"00" => s_command <= x"1280"; -- COM7   Reset
      when x"01" => s_command <= x"1280"; -- COM7   Reset
      when x"02" => s_command <= x"1204"; -- COM7   Size & RGB output
      when x"03" => s_command <= x"1100"; -- CLKRC  Prescaler - Fin/(1+1)
      when x"04" => s_command <= x"0C00"; -- COM3   Lots of stuff, enable scaling, all others off
      when x"05" => s_command <= x"3E00"; -- COM14  PCLK scaling off
      when x"06" => s_command <= x"8C00"; -- RGB444 Set RGB format
      when x"07" => s_command <= x"0400"; -- COM1   no CCIR601
      when x"08" => s_command <= x"4010"; -- COM15  Full 0-255 output, RGB 565
      when x"09" => s_command <= x"3a04"; -- TSLB   Set UV ordering,  do not auto-reset window
      when x"0A" => s_command <= x"1438"; -- COM9  - AGC Celling
      when x"0B" => s_command <= x"4f40"; --x"4fb3"; -- MTX1  - colour conversion matrix
      when x"0C" => s_command <= x"5034"; --x"50b3"; -- MTX2  - colour conversion matrix
      when x"0D" => s_command <= x"510C"; --x"5100"; -- MTX3  - colour conversion matrix
      when x"0E" => s_command <= x"5217"; --x"523d"; -- MTX4  - colour conversion matrix
      when x"0F" => s_command <= x"5329"; --x"53a7"; -- MTX5  - colour conversion matrix
      when x"10" => s_command <= x"5440"; --x"54e4"; -- MTX6  - colour conversion matrix
      when x"11" => s_command <= x"581e"; --x"589e"; -- MTXS  - Matrix sign and auto contrast
      when x"12" => s_command <= x"3dc0"; -- COM13 - Turn on GAMMA and UV Auto adjust
      when x"13" => s_command <= x"1100"; -- CLKRC  Prescaler - Fin/(1+1)
      when x"14" => s_command <= x"1711"; -- HSTART HREF start (high 8 bits)
      when x"15" => s_command <= x"1861"; -- HSTOP  HREF stop (high 8 bits)
      when x"16" => s_command <= x"32A4"; -- HREF   Edge offset and low 3 bits of HSTART and HSTOP
      when x"17" => s_command <= x"1903"; -- VSTART VSYNC start (high 8 bits)
      when x"18" => s_command <= x"1A7b"; -- VSTOP  VSYNC stop (high 8 bits)
      when x"19" => s_command <= x"030a"; -- VREF   VSYNC low two bits
      when x"1A" => s_command <= x"0e61"; -- COM5(0x0E) 0x61
      when x"1B" => s_command <= x"0f4b"; -- COM6(0x0F) 0x4B
      when x"1C" => s_command <= x"1602"; --
      when x"1D" => s_command <= x"1e37"; -- MVFP (0x1E) 0x07  -- FLIP AND MIRROR IMAGE 0x3x
      when x"1E" => s_command <= x"2102";
      when x"1F" => s_command <= x"2291";
      when x"20" => s_command <= x"2907";
      when x"21" => s_command <= x"330b";
      when x"22" => s_command <= x"350b";
      when x"23" => s_command <= x"371d";
      when x"24" => s_command <= x"3871";
      when x"25" => s_command <= x"392a";
      when x"26" => s_command <= x"3c78"; -- COM12 (0x3C) 0x78
      when x"27" => s_command <= x"4d40";
      when x"28" => s_command <= x"4e20";
      when x"29" => s_command <= x"6900"; -- GFIX (0x69) 0x00
      when x"2A" => s_command <= x"6b4a";
      when x"2B" => s_command <= x"7410";
      when x"2C" => s_command <= x"8d4f";
      when x"2D" => s_command <= x"8e00";
      when x"2E" => s_command <= x"8f00";
      when x"2F" => s_command <= x"9000";
      when x"30" => s_command <= x"9100";
      when x"31" => s_command <= x"9600";
      when x"32" => s_command <= x"9a00";
      when x"33" => s_command <= x"b084";
      when x"34" => s_command <= x"b10c";
      when x"35" => s_command <= x"b20e";
      when x"36" => s_command <= x"b382";
      when x"37" => s_command <= x"b80a";
      when others => s_command <= x"ffff";
   end case;
  end process;
  
  
  process(clk)
  begin
    if rising_edge(clk) then
      if s_command = x"FFFF" then
        config_finished <= '1';
      elsif (resend = '0') then
        config_finished <= '0';
    end if;  
  end if;
 end process;
  
 command <= s_command;
  
end ov7670_registers_arch;