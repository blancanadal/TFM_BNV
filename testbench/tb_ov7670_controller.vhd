--------------------------------------------------------------
-- Name: tb_ov7670_controller
-- Description: Module that tests the interaction between SCCB
-- interface and registers module
-- Author: Blanca Nadal Valle
--------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity tb_ov7670_controller is         

end tb_ov7670_controller;

architecture tb_ov7670_controller_arch of tb_ov7670_controller is

  constant c_CLK_PERIOD : time := 20 ns;     -- System clock (50Mhz)
  
  signal clk            : std_logic;
  signal reset          : std_logic;
  signal s_resend       : std_logic;
  signal s_doneTrans    : std_logic;
  signal s_config_finish: std_logic;
  signal s_SIOC         : std_logic;
  signal s_SIOD         : std_logic;
  signal s_pwdn         : std_logic;
  signal s_xclk         : std_logic;

  signal more_stimuli   : boolean := true;  
  
  
  component ov7670_controller
  port ( 
     clk           : in     std_logic;
     reset         : in     std_logic;
     resend        : in     std_logic;
     doneTrans     : out    std_logic;
     config_finish : out    std_logic;
     SIOC          : out    std_logic;
     SIOD          : inout  std_logic;
     pwdn          : out    std_logic;
     xclk          : out    std_logic
  );
  end component;
  
  

begin

  UUT: ov7670_controller
    port map(
      clk            => clk,            
      reset          => reset,          
      resend         => s_resend, 
      doneTrans      => s_doneTrans,      
      config_finish  => s_config_finish,
      SIOC           => s_SIOC,         
      SIOD           => s_SIOD,         
      pwdn           => s_pwdn,         
      xclk           => s_xclk            
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
  
  assert (s_SIOD  = 'Z')  report "Test 1: Wrong value of 'SIOD' signal" severity error;
  assert (s_SIOC = '1')   report "Test 1: Wrong value of 'SIOC' signal" severity error;  
  assert (s_config_finish = '0')   report "Test 1: Wrong value of 'CONFIG_FINISH' signal" severity error;  
  
  wait for (c_CLK_PERIOD); 
  reset <= '1';
  wait for (c_CLK_PERIOD);
  report "**************************END TEST 1******************************" severity note;
  -----------------
  -- END OF TEST 1
  -----------------

  -------------------------------------
  -- TEST 2: CONFIGURATION OF REGISTERS
  -------------------------------------
  report "**************************TEST 2*********************************" severity note;

  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);     
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- First register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);     
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Second register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);     
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Third register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);     
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Fourth register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);    
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Fifth register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);     
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Sixth register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);    
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Seventh register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);     
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Eighth register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);     
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Nineth register configured
  
  s_resend       <= '1'; 
  wait for (100*c_CLK_PERIOD);    
  s_resend       <= '0'; 
  
  wait until rising_edge(s_doneTrans); -- Tenth register configured

  -- config_finished must be logic-1

  report "**************************END TEST 2******************************" severity note;
  -----------------
  -- END OF TEST 2
  -----------------


  wait for (10 * c_CLK_PERIOD);
  more_stimuli <= false;
  wait;
  
  end process;
  
end tb_ov7670_controller_arch;
