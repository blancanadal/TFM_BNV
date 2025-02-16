---------------------------------------------------
-- Name: Nexys_ov7670_VGA
-- Description: top module that links OV7670 sensor
-- to VGA controller
-- Author: Blanca Nadal Valle
---------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all ; 
use ieee.numeric_std.all ; 

entity Nexys_ov7670_VGA is 
  port( 
    CLK100MHz       : in    std_logic;
    BTNC            : in    std_logic;  -- resend
    BTNR            : in    std_logic;  -- reset
    
    D0              : in    std_logic;
    D1              : in    std_logic;
    D2              : in    std_logic;
    D3              : in    std_logic;
    D4              : in    std_logic;
    D5              : in    std_logic;
    D6              : in    std_logic;
    D7              : in    std_logic;
    JB              : in    std_logic_vector(2 downto 1); -- VSYNC & HREF
    
    SCREEN_ON       : in    std_logic; -- SCREEN ON
    
    PCLK            : in    std_logic;

    SIOD            : inout std_logic;
    SIOC            : out   std_logic;

    PWDN            : out   std_logic;
    RESET           : out   std_logic;
    XCLK            : out   std_logic;
    
    -- CONFIG_FINISHED & DONE_TRANS
    LED             : out   std_logic_vector(2 downto 0);
    
    -- VGA Connector
    VGA_HS          : out   std_logic;
    VGA_VS          : out   std_logic;
    
    VGA_RED_O       : out   std_logic_vector (3 downto 0);
    VGA_GREEN_O     : out   std_logic_vector (3 downto 0);
    VGA_BLUE_O      : out   std_logic_vector (3 downto 0)
    );
    
end Nexys_ov7670_VGA; 

architecture Nexys_ov7670_VGA_arch of Nexys_ov7670_VGA is 

signal s_data_in : std_logic_vector(7 downto 0);

component processing_top
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

signal s_reset : std_logic;

begin 

  processing_top_i: processing_top
    port map (
    sysclk           => CLK100MHz,
    btnc             => BTNC,
    btnr             => BTNR,
    pclk             => PCLK,   
    vsync            => JB(1),  
    href             => JB(2),   
    data_in          => s_data_in,
    screen_on        => SCREEN_ON,    
    config_finished  => LED(1),
    SIOD             => SIOD,
    SIOC             => SIOC,                     
    pwdn             => PWDN,
    reset            => s_reset,      
    resend           => LED(2),      
    xclk             => XCLK,
    vga_vsync        => VGA_VS,
    vga_hsync        => VGA_HS,
    vga_red          => VGA_RED_O,
    vga_green        => VGA_GREEN_O,
    vga_blue         => VGA_BLUE_O

  );

s_data_in <= D7&D6&D5&D4&D3&D2&D1&D0;
RESET     <= s_reset;
LED(0)    <= s_reset;


end Nexys_ov7670_VGA_arch; 