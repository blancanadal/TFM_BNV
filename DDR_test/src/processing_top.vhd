----------------------------------------------------------------
-- Name: processing_top
-- Description: Module that links foveal acquisition with OV7670 
-- sensor and VGA controller
-- Author: Blanca Nadal Valle
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity processing_top is
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

end processing_top;

architecture processing_top_arch of processing_top is

signal clk50, clk25, clk200        : std_logic;
signal s_pixel_end                 : std_logic;
signal s_reset                     : std_logic;
signal s_we_bram                   : std_logic;
signal image_we_bram               : std_logic;
signal s_vsync_delayed             : std_logic;
signal s_capture_out               : std_logic_vector(11 downto 0);
signal image_out                   : std_logic_vector(11 downto 0);
signal s_gen_level                 : std_logic_vector(11 downto 0);
signal s_pyramid_dout              : std_logic_vector(11 downto 0);
signal s_pixel_cnt, s_addr         : std_logic_vector(18 downto 0);
signal s_image_cnt                 : std_logic_vector(18 downto 0);
signal s_pixel_addr                : std_logic_vector(18 downto 0);
signal s_rgb_in                    : std_logic_vector(11 downto 0);
signal s_ddr_fovea_in              : std_logic_vector(11 downto 0);
signal s_we_fovea                  : std_logic;
signal s_we_fovea_rd               : std_logic;
signal s_start_write               : std_logic;
signal s_addr_wr_fovea             : std_logic_vector(12 downto 0);
signal s_addr_rd_fovea             : std_logic_vector(12 downto 0);
signal s_bram_fovea_out            : std_logic_vector(11 downto 0);
signal s_fovea_proc                : std_logic_vector(11 downto 0);
signal s_fovea_data_in             : std_logic_vector(11 downto 0);
signal s_fovea_data_out            : std_logic_vector(11 downto 0);
signal s_ddr_addr_wr               : std_logic_vector(12 downto 0);
signal s_ddr_addr_rd               : std_logic_vector(12 downto 0);

-- DDR SIGNALS
signal ddr_clk, ddr_reset          : std_logic;
signal s_init_calib_complete       : std_logic;
signal s_app_en                    : std_logic;
signal s_app_addr                  : std_logic_vector(26 downto 0);
signal s_app_cmd                   : std_logic_vector(2 downto 0);
signal s_app_wdf_data              : std_logic_vector(63 downto 0);
signal s_app_wdf_end               : std_logic;
signal s_app_wdf_mask              : std_logic_vector(7 downto 0);
signal s_app_wdf_wren              : std_logic;
signal s_app_rd_data               : std_logic_vector(63 downto 0);
signal s_app_rd_data_end           : std_logic;
signal s_app_rd_data_valid         : std_logic;
signal s_app_rdy                   : std_logic;
signal s_app_wdf_rdy               : std_logic;

signal s_ddr2_dq                   : std_logic_vector(15 downto 0);
signal s_ddr2_dqs_p                : std_logic_vector(1 downto 0);
signal s_ddr2_dqs_n                : std_logic_vector(1 downto 0);
signal s_ddr2_addr                 : std_logic_vector(12 downto 0);
signal s_ddr2_ba                   : std_logic_vector(2 downto 0);
signal s_ddr2_ras_n                : std_logic;
signal s_ddr2_cas_n                : std_logic;
signal s_ddr2_we_n                 : std_logic;
signal s_ddr2_ck_p                 : std_logic_vector(0 downto 0);
signal s_ddr2_ck_n                 : std_logic_vector(0 downto 0);
signal s_ddr2_cke                  : std_logic_vector(0 downto 0);
signal s_ddr2_cs_n                 : std_logic_vector(0 downto 0);
signal s_ddr2_dm                   : std_logic_vector(1 downto 0);
signal s_ddr2_odt                  : std_logic_vector(0 downto 0);
signal sync_reset1, sync_reset2    : std_logic;

component image_stream_gen 
  port (
    pclk           : in  std_logic;                  
    reset          : in  std_logic;                                            
    vsync          : in std_logic;                       
    href           : in std_logic;                       
    we_fovea       : out std_logic;    
    start_write    : out std_logic;    
    addr_wr_fovea  : out std_logic_vector(12 downto 0);    
    bram_fovea_out : out std_logic_vector(11 downto 0)     
  );
end component;


 
 component bram_to_ddr
  port (
    clka  : in std_logic;
    wea   : in std_logic;
    addra : in std_logic_vector(12 downto 0);
    dina  : in std_logic_vector(11 downto 0);
    clkb  : in std_logic;   
    addrb : in std_logic_vector(12 downto 0);    
    doutb : out std_logic_vector(11 downto 0) 
  );
 end component;
 
 component clk_wiz_0
   port (
     clk_in1  : in  std_logic;
     CLK50    : out std_logic;
     CLK25    : out std_logic;
     CLK200   : out std_logic
   );
  end component;
  
 component fovea_ddr_ctrl
  port (
    clk                   : in  std_logic;
    reset                 : in  std_logic;
    start_write           : in  std_logic;
    app_wdf_rdy           : in  std_logic;
    app_rdy               : in  std_logic;
    init_calib_complete   : in  std_logic;
    app_rd_data           : in  std_logic_vector(63 downto 0);
    app_rd_data_valid     : in  std_logic;
    fovea_data_in         : in  std_logic_vector(11 downto 0); 
    app_cmd               : out std_logic_vector(2 downto 0);
    app_addr              : out std_logic_vector(26 downto 0);
    app_wdf_data          : out std_logic_vector(63 downto 0);
    app_wdf_end           : out std_logic;
    app_wdf_wren          : out std_logic;
    app_en                : out std_logic;
    fovea_data_out        : out std_logic_vector(11 downto 0); 
    addr_ddr_wr           : out std_logic_vector(12 downto 0);
    addr_ddr_rd           : out std_logic_vector(12 downto 0);
    we_fovea_out          : out std_logic
  );
end component;
  
  component mig_7series_0
    port(
      sys_clk_i           : in    std_logic;
      sys_rst             : in    std_logic;
      app_addr            : in    std_logic_vector(26 downto 0);
      app_cmd             : in    std_logic_vector(2 downto 0);
      app_en              : in    std_logic;
      app_wdf_data        : in    std_logic_vector(63 downto 0);
      app_wdf_end         : in    std_logic;
      app_wdf_mask        : in    std_logic_vector(7 downto 0);
      app_wdf_wren        : in    std_logic;
      app_sr_req          : in    std_logic; -- 0
      app_ref_req         : in    std_logic; -- 0
      app_zq_req          : in    std_logic; --0
      ddr2_dq             : inout std_logic_vector(15 downto 0);
      ddr2_dqs_p          : inout std_logic_vector(1 downto 0);
      ddr2_dqs_n          : inout std_logic_vector(1 downto 0);
      ddr2_addr           : out   std_logic_vector(12 downto 0);
      ddr2_ba             : out   std_logic_vector(2 downto 0);
      ddr2_ras_n          : out   std_logic;
      ddr2_cas_n          : out   std_logic;
      ddr2_we_n           : out   std_logic;
      ddr2_ck_p           : out   std_logic_vector(0 downto 0);
      ddr2_ck_n           : out   std_logic_vector(0 downto 0);
      ddr2_cke            : out   std_logic_vector(0 downto 0);
      ddr2_cs_n           : out   std_logic_vector(0 downto 0);
      ddr2_dm             : out   std_logic_vector(1 downto 0);
      ddr2_odt            : out   std_logic_vector(0 downto 0);
      app_rd_data         : out   std_logic_vector(63 downto 0);
      app_rd_data_end     : out   std_logic;
      app_rd_data_valid   : out   std_logic;
      app_rdy             : out   std_logic;
      app_wdf_rdy         : out   std_logic;
      app_sr_active       : out   std_logic;
      app_ref_ack         : out   std_logic;
      app_zq_ack          : out   std_logic;
      ui_clk              : out   std_logic;
      ui_clk_sync_rst     : out   std_logic;
      init_calib_complete : out   std_logic
    );

end component mig_7series_0;
  
component ddr2_model
port (
    dq      : inout std_logic_vector(15 downto 0);
    dqs     : inout std_logic_vector(1 downto 0);
    dqs_n   : inout std_logic_vector(1 downto 0);
    addr    : in    std_logic_vector(12 downto 0);
    ba      : in    std_logic_vector(2 downto 0);
    ras_n   : in    std_logic;
    cas_n   : in    std_logic;
    we_n    : in    std_logic;
    ck      : in    std_logic_vector(0 downto 0);
    ck_n    : in    std_logic_vector(0 downto 0);
    cke     : in    std_logic_vector(0 downto 0);
    cs_n    : in    std_logic_vector(0 downto 0);
    dm_rdqs : inout std_logic_vector(1 downto 0);
    odt     : in    std_logic_vector(0 downto 0);
    rdqs_n  : out   std_logic_vector(1 downto 0)
);
end component;

begin

image_stream_i : image_stream_gen
port map (
    pclk        => pclk,                    
    reset       => btnr,                                         
    vsync       => vsync,                      
    href        => href,                     
    we_fovea    => s_we_fovea,
    start_write => s_start_write,                     
    addr_wr_fovea=> s_addr_wr_fovea,      
    bram_fovea_out  => s_bram_fovea_out      
  );


  bram_to_ddr_i: bram_to_ddr
  port map (
    clka    => pclk,
    wea     => s_we_fovea,
    addra   => s_addr_wr_fovea,
    dina    => s_bram_fovea_out,
    clkb    => ddr_clk,        
    addrb   => s_ddr_addr_wr,  
    doutb   => s_fovea_data_in   
  );
 
   

 clk_wiz_0_i: clk_wiz_0
   port map(
     clk_in1  => sysclk,
     CLK50    => clk50,
     CLK25    => clk25,
     CLK200   => clk200
   );

 fovea_ddr_ctrl_i: fovea_ddr_ctrl
  port map(
   clk                   => ddr_clk,
   reset                 => ddr_reset,
   start_write           => s_start_write,
   app_wdf_rdy           => s_app_wdf_rdy,
   app_rdy               => s_app_rdy,
   init_calib_complete   => s_init_calib_complete,
   app_rd_data           => s_app_rd_data,
   app_rd_data_valid     => s_app_rd_data_valid,
   fovea_data_in         => s_fovea_data_in,
   app_cmd               => s_app_cmd,
   app_addr              => s_app_addr,
   app_wdf_data          => s_app_wdf_data,
   app_wdf_end           => s_app_wdf_end,
   app_wdf_wren          => s_app_wdf_wren,
   app_en                => s_app_en,
   fovea_data_out        => s_fovea_data_out,
   addr_ddr_wr           => s_ddr_addr_wr,
   addr_ddr_rd           => s_ddr_addr_rd,
   we_fovea_out          => s_we_fovea_rd
 );


  DDR_i : mig_7series_0
    port map(
      sys_clk_i           => clk200,
      sys_rst             => sync_reset2,
      app_addr            => s_app_addr,
      app_cmd             => s_app_cmd,
      app_en              => s_app_en,
      app_wdf_data        => s_app_wdf_data,
      app_wdf_end         => s_app_wdf_end,
      app_wdf_mask        => (others => '0'),  -- no mask required
      app_wdf_wren        => s_app_wdf_wren,
      app_sr_req          => '0',
      app_ref_req         => '0',
      app_zq_req          => '0',
      ddr2_dq             => s_ddr2_dq,
      ddr2_dqs_p          => s_ddr2_dqs_p,
      ddr2_dqs_n          => s_ddr2_dqs_n,
      ddr2_addr           => s_ddr2_addr,
      ddr2_ba             => s_ddr2_ba,
      ddr2_ras_n          => s_ddr2_ras_n,
      ddr2_cas_n          => s_ddr2_cas_n,
      ddr2_we_n           => s_ddr2_we_n,
      ddr2_ck_p           => s_ddr2_ck_p,
      ddr2_ck_n           => s_ddr2_ck_n,
      ddr2_cke            => s_ddr2_cke,
      ddr2_cs_n           => s_ddr2_cs_n,
      ddr2_dm             => s_ddr2_dm,
      ddr2_odt            => s_ddr2_odt,
      app_rd_data         => s_app_rd_data,
      app_rd_data_end     => s_app_rd_data_end,
      app_rd_data_valid   => s_app_rd_data_valid,
      app_rdy             => s_app_rdy,
      app_wdf_rdy         => s_app_wdf_rdy,
      app_sr_active       => open,
      app_ref_ack         => open,
      app_zq_ack          => open,
      ui_clk              => ddr_clk, -- 300 MHz
      ui_clk_sync_rst     => ddr_reset,
      init_calib_complete => s_init_calib_complete
  );


model_ddr_i: ddr2_model
  port map(
    dq          => s_ddr2_dq,
    dqs         => s_ddr2_dqs_p,
    dqs_n       => s_ddr2_dqs_n,
    addr        => s_ddr2_addr,
    ba          => s_ddr2_ba,
    ras_n       => s_ddr2_ras_n,
    cas_n       => s_ddr2_cas_n,
    we_n        => s_ddr2_we_n,
    ck          => s_ddr2_ck_p,
    ck_n        => s_ddr2_ck_n,
    cke         => s_ddr2_cke,
    cs_n        => s_ddr2_cs_n,
    dm_rdqs     => s_ddr2_dm,
    odt         => s_ddr2_odt,
    rdqs_n      => open
);


process(clk200) 
begin
    if rising_edge(clk200) then
        sync_reset1 <= btnr;
        sync_reset2  <= sync_reset1;
    end if;
end process;
    
end processing_top_arch;
