------------------------------------------------------
-- Name: vga_display
-- Description: Module that controls the color of the 
-- VGA display signals for the VGA controller
-- Author: Blanca Nadal Valle
-------------------------------------------------------

library ieee; 
use ieee.std_logic_1164. all ; 
use ieee.numeric_std. all ; 

entity vga_display is 
  port( 
    clk25       : in  std_logic;
    rgb_in      : in  std_logic_vector(11 downto 0); 
    display_on  : in  std_logic;
    rgb_out     : out std_logic_vector(11 downto 0)
  );
    
end vga_display; 

architecture vga_display_arch of vga_display is 


begin 

  vga_rgb: process(clk25)
  begin
    if rising_edge(clk25) then
      if (display_on = '1') then
        rgb_out <= rgb_in;
      else
        rgb_out <= (others => '0');
      end if;
    end if;
  end process;
  

end vga_display_arch; 