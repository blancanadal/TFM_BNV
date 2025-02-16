---------------------------------------------------
-- Name: ov7670_VGA
-- Description: top module that links OV7670 sensor
-- to VGA controller
-- Author: Blanca Nadal Valle
---------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all ; 
use ieee.numeric_std.all ; 

entity ov7670_VGA is 
  port( 
    clk50           : in    std_logic;
    clk25           : in    std_logic;
    btnc            : in    std_logic;
    btnr            : in    std_logic;
    pclk            : in    std_logic;
    vsync           : in    std_logic;
    href            : in    std_logic;
    data_in         : in    std_logic_vector (7 downto 0);
    screen_on       : in    std_logic;
    vga_in          : in    std_logic_vector(11 downto 0);
    config_finished : out   std_logic;
    pixel_end       : out   std_logic;
    capture_out     : out   std_logic_vector(11 downto 0);
    SIOD            : inout std_logic;
    SIOC            : out   std_logic;
    pwdn            : out   std_logic;
    reset           : out   std_logic;
    resend          : out   std_logic;
    xclk            : out   std_logic;
    vga_vsync       : out   std_logic;
    vga_hsync       : out   std_logic;
    vga_red         : out   std_logic_vector(3 downto 0);
    vga_green       : out   std_logic_vector(3 downto 0);
    vga_blue        : out   std_logic_vector(3 downto 0);
    pixel_addr      : out   std_logic_vector(18 downto 0)
    );
    
end ov7670_VGA; 

architecture ov7670_VGA_arch of ov7670_VGA is 

  signal s_rgb_in                   : std_logic_vector(11 downto 0);
  signal s_reset                    : std_logic;
  signal s_resend                   : std_logic;
  signal s_pixel_end                : std_logic;
  signal s_pixel_cnt                : std_logic_vector(18 downto 0);
  signal sync_pclk_1, sync_pclk_2   : std_logic;
  signal sync_clk50_1, sync_clk50_2 : std_logic;

  signal s_we                       : std_logic;
  signal s_addra                    : std_logic_vector(18 downto 0);
  signal s_dout                     : std_logic_vector(11 downto 0);
  
  
  --attribute mark_debug : string;
  --attribute mark_debug of cnt_pclk: signal is "true";
  --attribute mark_debug of vga_red: signal is "true";
  --attribute mark_debug of vga_green: signal is "true";
  --attribute mark_debug of vga_blue: signal is "true";
  --attribute mark_debug of vga_vsync: signal is "true";
  --attribute mark_debug of vga_hsync: signal is "true";
  --attribute mark_debug of SIOC: signal is "true";
  --attribute mark_debug of SIOD: signal is "true";
  
  
  
  component ov7670_controller
    port ( 
     clk50         : in    std_logic;
     clk25         : in    std_logic;
     reset         : in    std_logic;
     resend        : in    std_logic;
     config_finish : out   std_logic;
     SIOC          : out   std_logic;
     SIOD          : inout std_logic;
     pwdn          : out   std_logic;
     xclk          : out   std_logic
  );
  end component;
  
  component ov7670_capture
    port(       
      pclk  : in  std_logic;                      
      reset : in  std_logic;                      
      vsync : in  std_logic;                      
      href  : in  std_logic;                      
      data  : in  std_logic_vector (7 downto 0);  
      addr  : out std_logic_vector (18 downto 0); 
      dout  : out std_logic_vector (11 downto 0); 
      pixel_end : out std_logic                    
    );   
  end component;
  
  component ov7670_debounce
    port ( 
      clk25   : in  std_logic; -- clk25
      bntc    : in  std_logic; -- connected to bntc
      bntr    : in  std_logic; -- connected to bntr
      resend  : out std_logic;
      reset   : out std_logic
    );
  end component;
  
  
  component vga_controller 
  port( 
    clk50       : in  std_logic;
    clk25       : in  std_logic;
    reset       : in  std_logic;
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
    
  end component; 


begin 

  ov7670_controller_i: ov7670_controller
    port map (
    clk50         => clk50,
    clk25         => clk25,
    reset         => sync_clk50_2,
    resend        => s_resend,
    config_finish => config_finished,
    SIOC          => SIOC,
    SIOD          => SIOD,
    pwdn          => pwdn,
    xclk          => xclk
    );


  ov7670_capture_i: ov7670_capture
    port map (
    pclk       => pclk,
    reset      => sync_pclk_2,
    vsync      => vsync, 
    href       => href,
    data       => data_in,
    addr       => s_pixel_cnt,
    dout       => capture_out,
    pixel_end  => s_pixel_end
    );
    
    
  ov7670_debounce_i: ov7670_debounce
    port map (
    clk25   => clk25,
    bntc    => btnc,
    bntr    => btnr,
    resend  => s_resend,
    reset   => s_reset
    );

  vga_controller_i: vga_controller
    port map (
    clk50           => clk50,
    clk25           => clk25,
    reset           => s_reset,
    reset50         => sync_clk50_2,
    rgb_in          => vga_in,
    screen_on       => screen_on,
    vga_vsync       => vga_vsync,
    vga_hsync       => vga_hsync,
    vga_red         => vga_red,
    vga_green       => vga_green,
    vga_blue        => vga_blue,
    pixel_addr      => pixel_addr
    );

  sync_clk50_proc: process(clk50)
  begin
     if rising_edge(clk50) then
        sync_clk50_1 <= s_reset;
        sync_clk50_2 <= sync_clk50_1;
     end if;
   end process;
   
  sync_clk50_proc: process(clk50)
  begin
     if rising_edge(clk50) then
        sync_pclk_1 <= s_reset;
        sync_pclk_2 <= sync_pclk_1;
     end if;
   end process;
   
  reset     <= sync_pclk_2; 
  resend    <= s_resend;
  pixel_end <= s_pixel_end;
    


end ov7670_VGA_arch; 