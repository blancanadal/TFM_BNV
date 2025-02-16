library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_foveal_acq is
end tb_foveal_acq;

architecture tb_foveal_acq_arch of tb_foveal_acq is

  
component foveal_top is
  port(                                          
  pclk            : in  std_logic;
  reset           : in  std_logic;
  vsync           : in  std_logic;
  href            : in  std_logic;
  pixel_end       : in  std_logic;
  data_in         : in  std_logic_vector (11 downto 0);
  we_bram         : out std_logic;
  pixel_cnt       : out std_logic_vector(18 downto 0);
  pyramid_dout    : out std_logic_vector(11 downto 0)
  );
end component;

    -- Señales internas para conectar al DUT
    signal s_pclk        : std_logic;
    signal s_reset       : std_logic;
    signal s_vsync       : std_logic;
    signal s_href        : std_logic;
    signal s_data_in     : std_logic_vector(11 downto 0) := (others => '0');
    signal s_pyramid_dout: std_logic_vector(11 downto 0) := (others => '0');
    signal s_pixel_end   : std_logic;
    signal s_we_bram     : std_logic;
    signal s_pixel_cnt   : std_logic_vector(18 downto 0);
    constant c_PCLK          : time := 40 ns;     -- 25Mhz
    constant c_PIXEL_CLK     : time := 80 ns;     -- Generation of pixel_end

    -- Pixel counters
    signal pixel_counter : integer := 0;
    
    signal more_stimuli : boolean := true;

begin

DUT: foveal_top
  port map (
    pclk            => s_pclk,
    reset           => s_reset,
    vsync           => s_vsync,
    href            => s_href, 
    pixel_end       => s_pixel_end,
    data_in         => s_data_in,
    we_bram         => s_we_bram,
    pixel_cnt       => s_pixel_cnt,
    pyramid_dout    => s_pyramid_dout
  );

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
  
  proc_pixel_clk_generator: process
  begin
      s_pixel_end <= '0';
      wait for c_PIXEL_CLK/2;
      s_pixel_end <= '1';
      wait for c_PIXEL_CLK/2;
  end process;
  
  
  stimulus: process
  begin
  ----------------------------------
  -- TEST 1: RESET
  ----------------------------------
  report "**************************TEST 1*********************************" severity note;
  s_reset <= '1';
  wait for c_PCLK;
  s_reset <= '0';
  wait for 4*c_PCLK;  
  s_reset <= '1';
  wait for 4*c_PCLK;  
  
  report "**************************END TEST 1******************************" severity note;
  -----------------
  -- END OF TEST 1
  -----------------
  
  ----------------------------------
  -- TEST 2: GENERATION OF VGA IMAGE
  ----------------------------------
  report "**************************TEST 2*********************************" severity note;
  
  s_data_in <= x"003";
  -- Inicialización
  s_vsync <= '1';
  s_href  <= '1';
 wait for (c_PCLK);

 wait until rising_edge(s_pclk);
 wait until rising_edge(s_pixel_end);
  s_vsync   <= '0';
  wait for (c_PCLK);
  
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"002";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"006";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"008";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"010";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"011";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"005";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"100";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"890";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"009";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"019";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"022";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);   -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"077";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"016";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);   -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"027";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"360";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
    s_href    <= '0';
  s_data_in <= x"002";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"006";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);   -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"008";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"010";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"011";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"005";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"100";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"890";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);   -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"009";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"019";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"022";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"077";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"016";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"027";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"360";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row

  s_href    <= '0';
  s_data_in <= x"002";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"006";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"008";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"010";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"011";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"005";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"100";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"890";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"009";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"019";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"022";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);   -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"077";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"016";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);   -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"027";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"360";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
    s_href    <= '0';
  s_data_in <= x"002";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"006";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);   -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"008";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"010";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"011";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"005";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"100";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"890";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);   -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"009";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"019";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"022";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
    s_href    <= '0';
  s_data_in <= x"027";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"360";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row
  
  s_href    <= '0';
  s_data_in <= x"002";
  wait for (c_PCLK);
  
  s_href    <= '1';
  wait for(80 * c_PIXEL_CLK);    -- 80 pixels per row

  -- 60 rows
  
  s_vsync <= '1';
  
  wait for(650 * c_PIXEL_CLK);   -- 8 rows + tolerance

  report "**************************END TEST 2******************************" severity note;
  -----------------
  -- END OF TEST 2
  -----------------
  
  wait for 10 us;
  more_stimuli <= false;
  wait;
  
  end process;

end tb_foveal_acq_arch;