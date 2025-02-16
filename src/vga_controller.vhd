---------------------------------------------------
-- Name: vga_controller
-- Description: top module for VGA controller block
-- Author: Blanca Nadal Valle
---------------------------------------------------
library ieee; 
use ieee.std_logic_1164. all ; 
use ieee.numeric_std. all ; 

entity vga_controller is 
  port( 
    clk50       : in  std_logic;
    clk25       : in  std_logic;
    reset       : in  std_logic;
    reset50     : in  std_logic;
    reset50     : in  std_logic;
    screen_on   : in  std_logic;
    rgb_in      : in  std_logic_vector(11 downto 0); 
    vga_vsync   : out std_logic;
    vga_hsync   : out std_logic;
    vga_red     : out std_logic_vector(3 downto 0);
    vga_green   : out std_logic_vector(3 downto 0);
    vga_blue    : out std_logic_vector(3 downto 0);
    pixel_addr  : out std_logic_vector(18 downto 0)
    );
    
end vga_controller; 

architecture vga_controller_arch of vga_controller is 

signal s_display_on         : std_logic;
signal s_rgb_out            : std_logic_vector(11 downto 0);

  component vga_sync
    port( 
      clk25       : in  std_logic;
      clk50       : in  std_logic;
      reset       : in  std_logic;
      reset50     : in  std_logic;
      hsync       : out std_logic;
      vsync       : out std_logic; 
      display_on  : out std_logic;
      pixel_addr  : out std_logic_vector(18 downto 0)
    );
  end component;
  
  component vga_display
    port( 
      clk25       : in  std_logic;
      rgb_in      : in  std_logic_vector(11 downto 0); 
      display_on  : in  std_logic;
      rgb_out     : out std_logic_vector(11 downto 0)
    );
  end component;

begin 

  vga_sync_i: vga_sync
    port map (
    clk50         => clk50,
    clk25         => clk25,
    reset         => reset,
    reset50       => reset50,
    hsync         => vga_hsync,
    vsync         => vga_vsync,
    display_on    => s_display_on,
    pixel_addr    => pixel_addr
    );
    
    
  vga_display_i: vga_display
    port map (
    clk25       => clk25,
    rgb_in      => rgb_in,
    display_on  => s_display_on,
    rgb_out     => s_rgb_out
    );


  susp_mode: process(clk25)
  begin
    if rising_edge(clk25) then
        if(screen_on = '1') then
            vga_red   <= s_rgb_out(11 downto 8);
            vga_green <= s_rgb_out(7 downto 4);
            vga_blue  <= s_rgb_out(3 downto 0); 
        else
            vga_red   <= (others => '0');
            vga_green <= (others => '0');
            vga_blue  <= (others => '0');             
        end if;
    end if;
  end process;

end vga_controller_arch; 