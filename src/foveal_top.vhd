----------------------------------------------------------------
-- Name: foveal_acq_top
-- Description: Module that links foveal acquisition with three
-- FIFOs required
-- Author: Blanca Nadal Valle
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity foveal_top is
  port(                                          
    pclk            : in  std_logic;
    reset           : in  std_logic;
    vsync           : in  std_logic;
    href            : in  std_logic;
    pixel_end       : in  std_logic;
    ddr_fovea_in    : in  std_logic_vector(11 downto 0);
    data_in         : in  std_logic_vector (11 downto 0);
    we_bram         : out std_logic;
    pixel_cnt       : out std_logic_vector(18 downto 0);
    pyramid_dout    : out std_logic_vector(11 downto 0);
    we_fovea        : out std_logic;
    addr_wr_fovea   : out std_logic_vector(12 downto 0);
    addr_rd_fovea   : out std_logic_vector(12 downto 0);
    bram_fovea_out  : out std_logic_vector(11 downto 0);
    start_write     : out std_logic
    );

end foveal_top;

architecture foveal_top_arch of foveal_top is

constant center_col : unsigned(9 downto 0) := "0101000000"; -- Center column (320)
constant center_row : unsigned(9 downto 0) := "0011110000"; -- Center row (240)

constant fovea_width   : unsigned(9 downto 0) := "0010000000"; -- Fovea width (128)
constant fovea_height  : unsigned(9 downto 0) := "0001000000"; -- Fovea height (64)

signal we1_r, we2_r, we3_r                               : std_logic;
signal we1_g, we2_g, we3_g                               : std_logic;
signal we1_b, we2_b, we3_b                               : std_logic;
signal rd1_r, rd2_r, rd3_r                               : std_logic;
signal rd1_g, rd2_g, rd3_g                               : std_logic;
signal rd1_b, rd2_b, rd3_b                               : std_logic;
signal s_data1_r, s_data2_r, s_data3_r                   : std_logic_vector(9 downto 0);
signal s_data1_g, s_data2_g, s_data3_g                   : std_logic_vector(9 downto 0);
signal s_data1_b, s_data2_b, s_data3_b                   : std_logic_vector(9 downto 0);
signal s_out1_r, s_out2_r, s_out3_r                      : std_logic_vector(9 downto 0);
signal s_out1_g, s_out2_g, s_out3_g                      : std_logic_vector(9 downto 0);
signal s_out1_b, s_out2_b, s_out3_b                      : std_logic_vector(9 downto 0);
signal s_dout1, s_dout2, s_dout3                         : std_logic_vector(11 downto 0);
signal reg_dout1, reg_dout2, reg_dout3                   : std_logic_vector(11 downto 0);
signal s_gen_level_1, s_gen_level_2, s_gen_level_3       : std_logic_vector(11 downto 0);
signal s_dout1_r, s_dout2_r, s_dout3_r                   : std_logic_vector(3 downto 0);
signal s_dout1_g, s_dout2_g, s_dout3_g                   : std_logic_vector(3 downto 0);
signal s_dout1_b, s_dout2_b, s_dout3_b                   : std_logic_vector(3 downto 0);
signal s_new_data1, s_new_data2, s_new_data3             : std_logic;
signal s_new_data1_r, s_new_data2_r, s_new_data3_r       : std_logic;
signal s_new_data1_g, s_new_data2_g, s_new_data3_g       : std_logic;
signal s_new_data1_b, s_new_data2_b, s_new_data3_b       : std_logic;

signal addr_fovea_out                                    : unsigned(12 downto 0);
--signal s_capture_full, s_capture_empty                   : std_logic;

signal we_row1, we_row2, we_row3                      : std_logic_vector(0 downto 0);
signal s_we_bram                                      : std_logic;
signal s_start_proc, s_start_cnt, s_start_cnt_proc    : std_logic;
signal s_row_level_1, s_row_level_2, s_row_level_3    : std_logic_vector(11 downto 0);
signal s_data_row1, s_data_row2, s_data_row3          : std_logic_vector(11 downto 0);
signal cnt_col_aux1, cnt_col_aux2, cnt_col_aux3       : std_logic_vector(9 downto 0);
signal cnt_col_proc                                   : std_logic_vector(9 downto 0);
signal cnt_row_acq                                    : std_logic_vector(9 downto 0);
signal cnt_col_acq                                    : std_logic_vector(9 downto 0);
signal s_pixel_cnt                                    : unsigned(18 downto 0);
signal s_pixel_cnt_dummy                              : std_logic_vector(18 downto 0);

-- ILA
--attribute mark_debug: string;
--attribute mark_debug of cnt_row_acq   : signal is "true";
--attribute mark_debug of cnt_col_acq   : signal is "true";
--attribute mark_debug of we_capture    : signal is "true";
--attribute mark_debug of rd_capture    : signal is "true";
--attribute mark_debug of s_capture_fifo: signal is "true";
--attribute mark_debug of s_capture_proc: signal is "true";
--attribute mark_debug of pixel_cnt: signal is "true";
--attribute mark_debug of s_new_data1: signal is "true";
--attribute mark_debug of s_new_data2: signal is "true";
--attribute mark_debug of s_new_data3: signal is "true";
--attribute mark_debug of s_dout1   : signal is "true";
--attribute mark_debug of href       : signal is "true";
--attribute mark_debug of vsync      : signal is "true";
--attribute mark_debug of cnt_col    : signal is "true";

component foveal_acq
 port(                                          
    pclk       : in  std_logic;                       
    reset      : in  std_logic;                       
    vsync      : in  std_logic;                       
    href       : in  std_logic;                       
    pixel_end  : in  std_logic;                                            
    din        : in  std_logic_vector(3 downto 0);   
    data1_fifo : in  std_logic_vector(9 downto 0);
    data2_fifo : in  std_logic_vector(9 downto 0);
    data3_fifo : in  std_logic_vector(9 downto 0);
    we_fifo1   : out std_logic;
    we_fifo2   : out std_logic;
    we_fifo3   : out std_logic;    
    rd_fifo1   : out std_logic;
    rd_fifo2   : out std_logic;
    rd_fifo3   : out std_logic;      
    new_data1  : out std_logic;
    new_data2  : out std_logic;
    new_data3  : out std_logic;
    cnt_col_acq: out std_logic_vector(9 downto 0);   
    cnt_row_acq: out std_logic_vector(9 downto 0);   
    dout1      : out std_logic_vector(3 downto 0);   -- First level ring
    dout2      : out std_logic_vector(3 downto 0);   -- Second level ring
    dout3      : out std_logic_vector(3 downto 0);   -- Third level ring
    fifo_out1  : out std_logic_vector(9 downto 0);
    fifo_out2  : out std_logic_vector(9 downto 0);
    fifo_out3  : out std_logic_vector(9 downto 0)
    );
end component;

component foveal_pyramid_gen
  port(                                          
    pclk          : in  std_logic;                       
    reset         : in  std_logic;                       
    href          : in  std_logic;                       
    pixel_end     : in  std_logic;                                                
    start_proc    : in  std_logic;     
    start_cnt     : in  std_logic;     
    new_data1     : in  std_logic;                                                             
    new_data2     : in  std_logic;                                                             
    new_data3     : in  std_logic;                                                                 
    capture_out   : in  std_logic_vector(11 downto 0);                       
    gen_level_1   : in  std_logic_vector(11 downto 0);   
    gen_level_2   : in  std_logic_vector(11 downto 0);   
    gen_level_3   : in  std_logic_vector(11 downto 0);     
    data_row1     : in  std_logic_vector(11 downto 0);   
    data_row2     : in  std_logic_vector(11 downto 0);   
    data_row3     : in  std_logic_vector(11 downto 0);    
    row_level_1   : out std_logic_vector(11 downto 0);   
    row_level_2   : out std_logic_vector(11 downto 0);   
    row_level_3   : out std_logic_vector(11 downto 0);
    we_bram_row1  : out std_logic;
    we_bram_row2  : out std_logic;
    we_bram_row3  : out std_logic;    
    we_bram       : out std_logic;     
    start_cnt_proc: out std_logic;  
    col_proc_out  : out std_logic_vector(9 downto 0);     
    col_aux1_out  : out std_logic_vector(9 downto 0);
    col_aux2_out  : out std_logic_vector(9 downto 0);
    col_aux3_out  : out std_logic_vector(9 downto 0); 
    addr_rd_fovea : out std_logic_vector(12 downto 0);
    pixel_cnt_proc: out std_logic_vector(18 downto 0);
    pyramid_dout  : out std_logic_vector(11 downto 0)
    );

end component;


component fifo_level_1
    port (
      clk       : in  std_logic;
      din       : in  std_logic_vector(9 downto 0);
      wr_en     : in  std_logic;
      rd_en     : in  std_logic;
      dout      : out std_logic_vector(9 downto 0);
      full      : out std_logic;
      empty     : out std_logic
    );
end component;
  
component fifo_level_2
    port (
      clk       : in  std_logic;
      din       : in  std_logic_vector(9 downto 0);
      wr_en     : in  std_logic;
      rd_en     : in  std_logic;
      dout      : out std_logic_vector(9 downto 0);
      full      : out std_logic;
      empty     : out std_logic
      );
end component;
  
component fifo_level_3
    port (
      clk       : in  std_logic;
      din       : in  std_logic_vector(9 downto 0);
      wr_en     : in  std_logic;
      rd_en     : in  std_logic;
      dout      : out std_logic_vector(9 downto 0);
      full      : out std_logic;
      empty     : out std_logic
      );
end component;

component bram_levels 
  port (
    clka  : in std_logic;
    wea   : in std_logic_vector(0 downto 0);
    addra : in std_logic_vector(9 downto 0);
    dina  : in std_logic_vector(11 downto 0);
    clkb  : in std_logic;
    enb   : in std_logic;
    addrb : in std_logic_vector(9 downto 0);
    doutb : out std_logic_vector(11 downto 0)
  );
end component;

begin

foveal_acq_red_i: foveal_acq
  port map (
    pclk        => pclk,
    reset       => reset,
    vsync       => vsync,
    href        => href,
    pixel_end   => pixel_end, 
    din         => data_in(11 downto 8),
    data1_fifo  => s_data1_r,
    data2_fifo  => s_data2_r,
    data3_fifo  => s_data3_r,
    we_fifo1    => we1_r,
    we_fifo2    => we2_r,
    we_fifo3    => we3_r,
    rd_fifo1    => rd1_r,
    rd_fifo2    => rd2_r,
    rd_fifo3    => rd3_r,
    cnt_col_acq => cnt_col_acq,
    cnt_row_acq => cnt_row_acq,
    dout1       => s_dout1_r,
    dout2       => s_dout2_r,
    dout3       => s_dout3_r,
    new_data1   => s_new_data1_r,
    new_data2   => s_new_data2_r,
    new_data3   => s_new_data3_r,
    fifo_out1   => s_out1_r,
    fifo_out2   => s_out2_r,
    fifo_out3   => s_out3_r
  );
  
  foveal_acq_green_i: foveal_acq
  port map (
    pclk        => pclk,
    reset       => reset,
    vsync       => vsync,
    href        => href,
    pixel_end   => pixel_end, 
    din         => data_in(7 downto 4),
    data1_fifo  => s_data1_g,
    data2_fifo  => s_data2_g,
    data3_fifo  => s_data3_g,
    we_fifo1    => we1_g,
    we_fifo2    => we2_g,
    we_fifo3    => we3_g,
    rd_fifo1    => rd1_g,
    rd_fifo2    => rd2_g,
    rd_fifo3    => rd3_g,
    cnt_col_acq => open,
    cnt_row_acq => open,
    dout1       => s_dout1_g,
    dout2       => s_dout2_g,
    dout3       => s_dout3_g,
    new_data1   => s_new_data1_g,
    new_data2   => s_new_data2_g,
    new_data3   => s_new_data3_g,
    fifo_out1   => s_out1_g,
    fifo_out2   => s_out2_g,
    fifo_out3   => s_out3_g
  );
  
  foveal_acq_blue_i: foveal_acq
  port map (
    pclk        => pclk,
    reset       => reset,
    vsync       => vsync,
    href        => href,
    pixel_end   => pixel_end,  
    din         => data_in(3 downto 0),
    data1_fifo  => s_data1_b,
    data2_fifo  => s_data2_b,
    data3_fifo  => s_data3_b,
    we_fifo1    => we1_b,
    we_fifo2    => we2_b,
    we_fifo3    => we3_b,
    rd_fifo1    => rd1_b,
    rd_fifo2    => rd2_b,
    rd_fifo3    => rd3_b,
    cnt_col_acq => open,
    cnt_row_acq => open,
    dout1       => s_dout1_b,
    dout2       => s_dout2_b,
    dout3       => s_dout3_b,
    new_data1   => s_new_data1_b,
    new_data2   => s_new_data2_b,
    new_data3   => s_new_data3_b,
    fifo_out1   => s_out1_b,
    fifo_out2   => s_out2_b,
    fifo_out3   => s_out3_b
  );
  
  
foveal_pyramid_gen_i: foveal_pyramid_gen
  port map (
  pclk          => pclk,
  reset         => reset,
  href          => href,
  pixel_end     => pixel_end,
  start_proc    => s_start_proc,
  start_cnt     => s_start_cnt,
  capture_out   => ddr_fovea_in, 
  new_data1     => s_new_data1,                                                         
  new_data2     => s_new_data2,   
  new_data3     => s_new_data3,
  data_row1     => s_data_row1,  
  data_row2     => s_data_row2,   
  data_row3     => s_data_row3, 
  gen_level_1   => s_gen_level_1,
  gen_level_2   => s_gen_level_2,
  gen_level_3   => s_gen_level_3,
  row_level_1   => s_row_level_1,
  row_level_2   => s_row_level_2,
  row_level_3   => s_row_level_3,
  we_bram_row1  => we_row1(0), 
  we_bram_row2  => we_row2(0),
  we_bram_row3  => we_row3(0),
  col_proc_out  => cnt_col_proc, 
  col_aux1_out  => cnt_col_aux1,
  col_aux2_out  => cnt_col_aux2,
  col_aux3_out  => cnt_col_aux3,
  we_bram       => we_bram,
  start_cnt_proc => s_start_cnt_proc,
  pixel_cnt_proc => pixel_cnt,
  addr_rd_fovea  => addr_rd_fovea,
  pyramid_dout  => pyramid_dout
  );
  
  i_fifo1_r: fifo_level_1
    port map (
      clk       => pclk,
      din       => s_out1_r,
      wr_en     => we1_r,
      rd_en     => rd1_r,
      dout      => s_data1_r,
      full      => open,
      empty     => open
    );
    
    
  i_fifo2_r: fifo_level_2
    port map (
      clk       => pclk,
      din       => s_out2_r,
      wr_en     => we2_r,
      rd_en     => rd2_r,
      dout      => s_data2_r,
      full      => open,
      empty     => open
    );
    
  i_fifo3_r: fifo_level_3
    port map (
      clk       => pclk,
      din       => s_out3_r,
      wr_en     => we3_r,
      rd_en     => rd3_r,
      dout      => s_data3_r,
      full      => open,
      empty     => open
    );
    
    i_fifo1_g: fifo_level_1
    port map (
      clk       => pclk,
      din       => s_out1_g,
      wr_en     => we1_g,
      rd_en     => rd1_g,
      dout      => s_data1_g,
      full      => open,
      empty     => open
    );
    
    
  i_fifo2_g: fifo_level_2
    port map (
      clk       => pclk,
      din       => s_out2_g,
      wr_en     => we2_g,
      rd_en     => rd2_g,
      dout      => s_data2_g,
      full      => open,
      empty     => open
    );
    
  i_fifo3_g: fifo_level_3
    port map (
      clk       => pclk,
      din       => s_out3_g,
      wr_en     => we3_g,
      rd_en     => rd3_g,
      dout      => s_data3_g,
      full      => open,
      empty     => open
    );
    
  i_fifo1_b: fifo_level_1
    port map (
      clk       => pclk,
      din       => s_out1_b,
      wr_en     => we1_b,
      rd_en     => rd1_b,
      dout      => s_data1_b,
      full      => open,
      empty     => open
    );
    
    
  i_fifo2_b: fifo_level_2
    port map (
      clk       => pclk,
      din       => s_out2_b,
      wr_en     => we2_b,
      rd_en     => rd2_b,
      dout      => s_data2_b,
      full      => open,
      empty     => open
    );
    
  i_fifo3_b: fifo_level_3
    port map (
      clk       => pclk,
      din       => s_out3_b,
      wr_en     => we3_b,
      rd_en     => rd3_b,
      dout      => s_data3_b,
      full      => open,
      empty     => open
    );  
    
    
i_bram_level_1: bram_levels 
  port map (
    clka    => pclk,
    wea     => we_row1,
    addra   => cnt_col_aux1,
    dina    => s_row_level_1,
    clkb    => pclk,
    enb     => s_start_cnt_proc,
    addrb   => cnt_col_proc,
    doutb   => s_data_row1
  );

i_bram_level_2: bram_levels 
  port map (
    clka    => pclk,
    wea     => we_row2,
    addra   => cnt_col_aux2,
    dina    => s_row_level_2,
    clkb    => pclk,
    enb     => s_start_cnt_proc,
    addrb   => cnt_col_proc,
    doutb   => s_data_row2
  );

 i_bram_level_3: bram_levels 
  port map (
    clka    => pclk,
    wea     => we_row3,
    addra   => cnt_col_aux3,
    dina    => s_row_level_3,
    clkb    => pclk,
    enb     => s_start_cnt_proc,
    addrb   => cnt_col_proc,
    doutb   => s_data_row3
  ); 


 pixel_cnt_gen: process(pclk, reset)
 begin
   if rising_edge(pclk) then
    if (reset = '0') then
        s_pixel_cnt      <= (others => '0');
    else   
        if(vsync = '0') then
            if (pixel_end = '1') then
                s_pixel_cnt  <= s_pixel_cnt + 1;
            end if;
        else
            s_pixel_cnt <= (others => '0');
        end if;
   end if;
  end if;
  end process;
 
  
  s_new_data1 <= '1' when (s_new_data1_b = '1') else '0';
  s_new_data2 <= '1' when (s_new_data2_b = '1') else '0';
  s_new_data3 <= '1' when (s_new_data3_b = '1') else '0';
  
    process(pclk, reset)
  begin
    if rising_edge(pclk) then
        if (reset = '0') then
            reg_dout1 <= (others => '0');
            reg_dout2 <= (others => '0');
            reg_dout3 <= (others => '0');
        else
            reg_dout1 <= s_dout1;
            reg_dout2 <= s_dout2;
            reg_dout3 <= s_dout3;
        end if;
     end if;
  end process;

  s_gen_level_1  <= s_dout1 when (s_new_data1 = '1') else reg_dout1;
  s_gen_level_2  <= s_dout2 when (s_new_data2 = '1') else reg_dout2;
  s_gen_level_3  <= s_dout3 when (s_new_data3 = '1') else reg_dout3;
  
  s_dout1 <= s_dout1_r & s_dout1_g & s_dout1_b; 
  s_dout2 <= s_dout2_r & s_dout2_g & s_dout2_b; 
  s_dout3 <= s_dout3_r & s_dout3_g & s_dout3_b; 
  
  s_start_proc <= '1' when (unsigned(cnt_row_acq) >= 7 and (s_new_data1 = '1' or s_new_data2 = '1' or s_new_data3 = '1')) else '0';
  s_start_cnt  <= '1' when (unsigned(cnt_row_acq)= 8) else '0';
  
  
  process(pclk, reset)
  begin
   if rising_edge(pclk) then 
    if(reset = '0') then 
        we_fovea <= '0';
        bram_fovea_out <= (others => '0');
        addr_fovea_out <= (others => '0');
    elsif (pixel_end = '1') then
        if (unsigned(cnt_col_acq) >= center_col - (fovea_width / 2) and unsigned(cnt_col_acq) < center_col + (fovea_width / 2)) and
          (unsigned(cnt_row_acq) >= center_row - (fovea_height / 2) and unsigned(cnt_row_acq) < center_row + (fovea_height / 2)) then
          bram_fovea_out <= data_in;
          we_fovea      <= '1';
          addr_fovea_out <= addr_fovea_out + 1;
        else
            if(unsigned(cnt_col_acq) = center_col + (fovea_width / 2)) and
            (unsigned(cnt_row_acq) >= center_row - (fovea_height / 2) and (unsigned(cnt_row_acq) < center_row + (fovea_height / 2))) then
               start_write <= '1';
            else
               start_write <= '0';
            end if;
          addr_fovea_out <= (others => '0');
          we_fovea      <= '0';
        end if;
    else
      we_fovea <= '0';
    end if;
  end if;
 end process;   

addr_wr_fovea <= std_logic_vector(addr_fovea_out);
-- FOR TESTING PURPOSES
--we_bram      <= s_new_data1;
--pyramid_dout <= s_dout1;
--pixel_cnt    <= std_logic_vector(s_pixel_cnt);
-- FOR TESTING PURPOSES


end foveal_top_arch;
