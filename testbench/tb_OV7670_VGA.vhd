-----------------------------------------------------
-- Name: tb_ov7670_VGA
-- Description: testbench of OV7670 sensor top module
-- Author: Blanca Nadal Valle
-----------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
  
entity tb_ov7670_VGA is
end tb_ov7670_VGA;
  
  
architecture tb_ov7670_VGA_arch of tb_ov7670_VGA is

constant c_SYSCLK        : time := 10 ns;
constant c_PCLK          : time := 40 ns;     -- 25Mhz
constant c_0164          : time := 165 us;
constant c_20ms          : time := 20 ms;

signal s_sysclk            : std_logic;
signal s_btnc              : std_logic;
signal s_btnr              : std_logic;
signal s_pclk              : std_logic;
signal s_vsync             : std_logic;
signal s_href              : std_logic;
signal s_screen_on         : std_logic;
signal s_data_in           : std_logic_vector (7 downto 0);
signal s_config_finished   : std_logic;
signal s_SIOD              : std_logic;
signal s_SIOC              : std_logic;
signal s_pwdn              : std_logic;
signal s_reset             : std_logic;
signal s_xclk              : std_logic;
signal s_vga_vsync         : std_logic;
signal s_vga_hsync         : std_logic;
signal s_vga_red           : std_logic_vector (3 downto 0);
signal s_vga_green         : std_logic_vector (3 downto 0);
signal s_vga_blue          : std_logic_vector (3 downto 0);


signal more_stimuli       : boolean := true;


  component ov7670_VGA
    port( 
      sysclk          : in    std_logic;
      btnc            : in    std_logic;
      btnr            : in    std_logic;
      pclk            : in    std_logic;
      vsync           : in    std_logic;
      href            : in    std_logic;
      data_in         : in    std_logic_vector (7 downto 0);
      screen_on       : in    std_logic;
      config_finished : out   std_logic;
      SIOD            : inout std_logic;
      SIOC            : out   std_logic;
      pwdn            : out   std_logic;
      reset           : out   std_logic;
      xclk            : out   std_logic;
      vga_vsync       : out   std_logic;
      vga_hsync       : out   std_logic;
      vga_red         : out   std_logic_vector (3 downto 0);
      vga_green       : out   std_logic_vector (3 downto 0);
      vga_blue        : out   std_logic_vector (3 downto 0)
    );
  end component;
  
 

begin

  ov7670_VGA_i: ov7670_VGA
    port map (
    sysclk           => s_sysclk,           
    btnc             => s_btnc,             
    btnr             => s_btnr,             
    pclk             => s_pclk,            
    vsync            => s_vsync,            
    href             => s_href,             
    data_in          => s_data_in,
    screen_on        => s_screen_on,              
    config_finished  => s_config_finished,  
    SIOD             => s_SIOD,             
    SIOC             => s_SIOC,             
    pwdn             => s_pwdn,             
    reset            => s_reset,            
    xclk             => s_xclk,             
    vga_vsync        => s_vga_vsync,        
    vga_hsync        => s_vga_hsync,       
    vga_red          => s_vga_red,         
    vga_green        => s_vga_green,       
    vga_blue         => s_vga_blue        

    );

proc_sysclk_generator: process
  begin
     s_sysclk <= '1';
     wait for c_SYSCLK/2;
     s_sysclk <= '0';
     wait for c_SYSCLK/2;
     if not(more_stimuli) then
        wait;
     end if;
  end process;

proc_pclk_generator: process
  begin
     s_pclk <= '1';
     wait for c_PCLK/2;
     s_pclk <= '0';
     wait for c_PCLK/2;
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
  wait until rising_edge(s_sysclk);
  wait for (c_SYSCLK); 
  s_btnr <= '1';
  wait for c_0164; -- Debounce 0,67s
  
  
  s_btnr <= '0';
  wait for (c_SYSCLK); 
  assert (s_reset  = '1')  report "Test 1: Wrong value of 'RESET' signal" severity error;
  
  report "**************************END TEST 1******************************" severity note;
  -----------------
  -- END OF TEST 1
  -----------------

  -------------------------------------
  -- TEST 2: CONFIGURATION OF REGISTERS
  -------------------------------------
  report "**************************TEST 2*********************************" severity note;
  s_screen_on <= '1';
  s_data_in <= "01101010";
  s_vsync <= '1';
  s_href  <= '0';
  s_btnc  <= '1'; 
  wait for c_0164;     
  s_btnc       <= '0'; 
  wait for c_SYSCLK; 
  
  wait until rising_edge(s_config_finished);

  -- config_finished must be logic-1
  
  -- DATA CAPTURE
  
  wait until rising_edge(s_pclk);
  s_vsync   <= '0'; 
  s_href    <= '1';
  
  wait for(1280 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(1280 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(1280 * c_PCLK);    -- 640 pixels per row
  
  -- 3 rows
  
  s_vsync <= '1';   

  report "**************************END TEST 2******************************" severity note;
  -----------------
  -- END OF TEST 2
  -----------------

  wait for c_20ms;
  more_stimuli <= false;
  wait;
  
  end process;

end tb_ov7670_VGA_arch;