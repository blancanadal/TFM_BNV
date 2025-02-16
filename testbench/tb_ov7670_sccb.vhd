------------------------------------------------------------------
-- Name: tb_ov7670_sccb
-- Description: Module that tests the SCCB interface between
-- NEXYS 4 DDR and ov7670 sensor
-- Author: Blanca Nadal Valle
------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity tb_ov7670_sccb is         

end tb_ov7670_sccb;

architecture tb_ov7670_sccb_arch of tb_ov7670_sccb is

  constant c_CLK_PERIOD : time := 20 ns;     -- System clock (50Mhz)
  constant SCCB_PERIOD  : time := 2500 ns;   -- SCCB interface clock (400kHz)
  
  
  signal clk		        : std_logic;
  signal reset          : std_logic;   
  signal s_Address      : std_logic_vector(7 downto 0);       
  signal s_IdRegister   : std_logic_vector(7 downto 0);       
  signal s_WriteData    : std_logic_vector(7 downto 0);       
  signal s_send         : std_logic;       
  signal s_done         : std_logic;       
  signal s_SIOD         : std_logic;       
  signal s_SIOC         : std_logic; 

  signal more_stimuli   : boolean := true;  
  
  
  component ov7670_sccb
    port(       
      Clk         :   in      std_logic;                   
      Reset       :   in      std_logic;                   
      IdAddress   :   in      std_logic_vector(7 downto 0);
      IdRegister  :   in      std_logic_vector(7 downto 0);
      WriteData   :   in      std_logic_vector(7 downto 0);
      Send        :   in      std_logic;                   
      Done        :   out     std_logic;                   
      SIOD        :   inout   std_logic;                   
      SIOC        :   out     std_logic                    
    );
  end component;
  

begin

  UUT: ov7670_sccb
    port map(
      Clk         => clk,		      
      Reset       => reset,        
      IdAddress   => s_Address,    
      IdRegister  => s_IdRegister, 
      WriteData   => s_WriteData,  
      Send        => s_send,      
      Done        => s_done,       
      SIOD        => s_SIOD,       
      SIOC        => s_SIOC       
    );
    
    
  proc_clk_generator: process
  begin
     clk <= '1';
     wait for c_CLK_PERIOD/2;
     clk <= '0';
     wait for c_CLK_PERIOD/2;
     if not(more_stimuli) then
        wait;
     end if;
  end process;

  proc_tb: process
  begin

  ----------------
  -- TEST 1: RESET
  ----------------
  report "**************************TEST 1*********************************" severity note;
  wait until rising_edge(clk);
  wait for (c_CLK_PERIOD); 
  reset <= '1';
  wait for (c_CLK_PERIOD);
  
  reset <= '0';
  wait for (c_CLK_PERIOD);
  
  assert (s_done = '0')   report "Test 1: Wrong value of 'DONE' signal" severity error;
  assert (s_SIOD  = 'Z')  report "Test 1: Wrong value of 'SIOD' signal" severity error;
  assert (s_SIOC = '1')   report "Test 1: Wrong value of 'SIOC' signal" severity error;  
  
  wait for (c_CLK_PERIOD); 
  reset <= '1';
  wait for (c_CLK_PERIOD);
  report "**************************END TEST 1******************************" severity note;
  -----------------
  -- END OF TEST 1
  -----------------

  -----------------------
  -- TEST 2: TRANSMISSION
  -----------------------
  report "**************************TEST 2*********************************" severity note;

  s_send       <= '1'; 
  s_Address    <= x"42";
  s_IdRegister <= x"12";
  s_WriteData  <= x"80";
  
  -- Monitoring in sim
  wait for (50*c_CLK_PERIOD);    -- Start of transmission
  
  s_send       <= '0'; 
  
  wait for (1125 * c_CLK_PERIOD); -- Sends a bit every 125 clk50 periods * 9 bits 
  
  -- First phase transmission

  wait for (1125 * c_CLK_PERIOD); -- Sends a bit every 125 clk50 periods * 9 bits 
  
  -- Second phase transmission
  
  wait for (1125 * c_CLK_PERIOD); -- Sends a bit every 125 clk50 periods * 9 bits 
  
  -- Third phase transmission

  wait for (1125 * c_CLK_PERIOD); -- Stop of transmission

  wait for (c_CLK_PERIOD);

  -- Stop transmission
  report "**************************END TEST 2******************************" severity note;
  -----------------
  -- END OF TEST 2
  -----------------


  wait for (10 * c_CLK_PERIOD);
  more_stimuli <= false;
  wait;
  
  end process;
  
end tb_ov7670_sccb_arch;
