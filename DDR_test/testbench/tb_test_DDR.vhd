----------------------------------------------------------------
-- Name: tb_test_DDR
-- Description: Testbench that tests the correct writing and 
-- reading of DDR memory
-- Author: Blanca Nadal Valle
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_test_DDR is
end tb_test_DDR;

architecture tb_test_DDR_arch of tb_test_DDR is

  
component processing_top is
 port(                                          
    sysclk          : in    std_logic;
    btnc            : in    std_logic;
    btnr            : in    std_logic;
    pclk            : in    std_logic;
    vsync           : in    std_logic;
    href            : in    std_logic;
    screen_on       : in    std_logic;
    data_in         : in    std_logic_vector (7 downto 0); 
    config_finished : out   std_logic;
    SIOD            : inout std_logic;
    SIOC            : out   std_logic;
    pwdn            : out   std_logic;
    xclk            : out   std_logic;
    reset           : out   std_logic;
    resend          : out   std_logic;
    vga_vsync       : out   std_logic;
    vga_hsync       : out   std_logic;
    vga_red         : out   std_logic_vector (3 downto 0);
    vga_green       : out   std_logic_vector (3 downto 0);
    vga_blue        : out   std_logic_vector (3 downto 0)
    );
end component;

    -- Señales internas para conectar al DUT
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
signal s_resend             : std_logic;
signal s_xclk              : std_logic;
signal s_vga_vsync         : std_logic;
signal s_vga_hsync         : std_logic;
signal s_vga_red           : std_logic_vector (3 downto 0);
signal s_vga_green         : std_logic_vector (3 downto 0);
signal s_vga_blue          : std_logic_vector (3 downto 0);

 constant c_PIXEL_CLK     : time := 80 ns;     -- Generation of pixel_end
 constant c_SYSCLK        : time := 10 ns;
 constant c_PCLK          : time := 40 ns;     -- 25Mhz
 constant c_0164          : time := 165 us;
    -- Pixel counters
    signal pixel_counter : integer := 0;
    
    signal more_stimuli : boolean := true;

begin

DUT: processing_top
  port map(                                          
    sysclk          => s_sysclk,          
    btnc            => s_btnc,            
    btnr            => s_btnr,            
    pclk            => s_pclk,            
    vsync           => s_vsync,           
    href            => s_href,           
    screen_on       => s_screen_on,       
    data_in         => s_data_in,         
    config_finished => s_config_finished, 
    SIOD            => s_SIOD,            
    SIOC            => s_SIOC,            
    pwdn            => s_pwdn,            
    xclk            => s_xclk,           
    reset           => s_reset,            
    resend          => s_resend,       
    vga_vsync       => s_vga_vsync,       
    vga_hsync       => s_vga_hsync,       
    vga_red         => s_vga_red,         
    vga_green       => s_vga_green,      
    vga_blue        => s_vga_blue  
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
s_btnr <= '1';
wait for 100 us;
-- wait for the DDR clock to be stable

s_btnr <= '0';
wait for 400 ns;
s_btnr <= '1';

wait for c_PCLK;
  report "**************************END TEST 1******************************" severity note;
  -----------------
  -- END OF TEST 1
  -----------------
wait for 100 ns;
  -------------------------------------
  -- TEST 2: TEST IMAGE OUTPUT
  -------------------------------------
  report "**************************TEST 2*********************************" severity note;
  
  wait until rising_edge(s_pclk);
  s_vsync   <= '0'; 
  s_href    <= '1';
  
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01111110";
  wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "10011010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00111010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01001010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01011010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01011100";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000000";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01001100";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01110000";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000100";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00000010";
 wait for (4*c_PCLK);
  
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00011010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00001010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00001010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01011010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010000";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000000";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01001100";
  wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01110000";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000100";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row

  s_href    <= '0';
  s_data_in <= "00000010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00011010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00001010";
  wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00001010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01011010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01010000";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000000";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01001100";
  wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01110000";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000111";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000100";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "01000101";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00000010";
 wait for (4*c_PCLK);

  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00011010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00001010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_data_in <= "00001010";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row

  s_href    <= '0';
  s_data_in <= "01000100";
 wait for (4*c_PCLK);
  
  s_href    <= '1';
  wait for(160 * c_PCLK);    -- 640 pixels per row
  
  s_href    <= '0';
  s_vsync <= '1'; 
  
wait for 10 us;

  report "**************************END TEST 2******************************" severity note;
  -----------------
  -- END OF TEST 2
  -----------------
  
  wait for 10 us;
  more_stimuli <= false;
  wait;
  
  end process;

end tb_test_DDR_arch;