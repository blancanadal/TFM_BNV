-------------------------------------------------------
-- Name: tb_ov7670_capture
-- Description: Module that tests the capture of images
-- Author: Blanca Nadal Valle
-------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity tb_ov7670_capture is         

end tb_ov7670_capture;

architecture tb_ov7670_capture_arch of tb_ov7670_capture is

  constant SCCB_PERIOD  : time := 2500 ns;   -- SCCB interface clock (400kHz)
  
  signal s_pclk     : std_logic;       
  signal s_vsync    : std_logic;       
  signal s_href     : std_logic;       
  signal s_data     : std_logic_vector(7 downto 0);       
  signal s_addr     : std_logic_vector (18 downto 0); ;       
  signal s_dout     : std_logic_vector (11 downto 0);       
  signal s_we       : std_logic; 

  signal more_stimuli   : boolean := true;  
  
  
  component ov7670_capture
    port(       
    pclk  : in  std_logic;                      
    vsync : in  std_logic;                      
    href  : in  std_logic;                      
    data  : in  std_logic_vector (7 downto 0);  
    addr  : out std_logic_vector (18 downto 0); 
    dout  : out std_logic_vector (11 downto 0); 
    we    : out std_logic                       
    
  );
  end component;
  

begin

  UUT: ov7670_capture
    port map(
     pclk    => s_pclk,     
     vsync   => s_vsync,    
     href    => s_href,     
     data    => s_data,     
     addr    => s_addr,     
     dout    => s_dout,    
     we      => s_we          
    );
    
    
  proc_clk_generator: process
  begin
     clk <= '1';
     wait for SCCB_PERIOD/2;
     clk <= '0';
     wait for SCCB_PERIOD/2;
     if not(more_stimuli) then
        wait;
     end if;
  end process;

  proc_tb: process
  begin


  ------------------
  -- TEST 1: CAPTURE
  ------------------
  report "**************************TEST 1*********************************" severity note;
  
  -- Monitoring in sim
  wait for (c_CLK_PERIOD);
  
  wait for (1125 * c_CLK_PERIOD); -- Sends a bit every 125 clk50 periods * 9 bits 
  
  -- First phase transmission

  wait for (1125 * c_CLK_PERIOD); -- Sends a bit every 125 clk50 periods * 9 bits 
  
  -- Second phase transmission
  
  wait for (1125 * c_CLK_PERIOD); -- Sends a bit every 125 clk50 periods * 9 bits 
  
  -- Third phase transmission

  wait for (c_CLK_PERIOD);

  -- Stop transmission
  report "**************************END TEST 2******************************" severity note;
  -----------------
  -- END OF TEST 1
  -----------------


  wait for (10 * c_CLK_PERIOD);
  more_stimuli <= false;
  wait;
  
  end process;
  
end tb_ov7670_capture_arch;
