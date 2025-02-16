----------------------------------------------------------------
-- Name: foveal_pyramid_gen
-- Description: Module that generates the regular foveal pyramid
-- based on foveal levels
-- Author: Blanca Nadal Valle
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity foveal_pyramid_gen is
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
    col_proc_out  : out std_logic_vector(9 downto 0);    
    col_aux1_out  : out std_logic_vector(9 downto 0);
    col_aux2_out  : out std_logic_vector(9 downto 0);
    col_aux3_out  : out std_logic_vector(9 downto 0); 
    we_bram       : out std_logic;
    addr_rd_fovea : out std_logic_vector(12 downto 0);
    start_cnt_proc: out std_logic;
    pixel_cnt_proc: out std_logic_vector(18 downto 0);
    pyramid_dout  : out std_logic_vector(11 downto 0)
    );

end foveal_pyramid_gen;

architecture foveal_pyramid_gen_arch of foveal_pyramid_gen is

constant MAX_COL : unsigned(9 downto 0) := "1010000000"; -- 640
constant MAX_ROW : unsigned(9 downto 0) := "0111100000"; -- 480

  -- Define boundaries for each level
constant fovea_width   : unsigned(9 downto 0) := "0010000000"; -- Fovea width (128)
constant fovea_height  : unsigned(9 downto 0) := "0001000000"; -- Fovea height (64)

constant level1_width  : unsigned(9 downto 0) := "0100000000"; -- Nivel 1 width (256)
constant level1_height : unsigned(9 downto 0) := "0010100000"; -- Nivel 1 height (160)

constant level2_width  : unsigned(9 downto 0) := "0111100000"; -- Nivel 2 width (480)
constant level2_height : unsigned(9 downto 0) := "0101000000"; -- Nivel 2 height (320)

constant level3_width  : unsigned(9 downto 0) := "1010000000"; -- Nivel 3 width (640)
constant level3_height : unsigned(9 downto 0) := "0111100000"; -- Nivel 3 height (480)

constant center_col : unsigned(9 downto 0) := "0101000000"; -- Center column (320)
constant center_row : unsigned(9 downto 0) := "0011110000"; -- Center row (240)

signal cnt_col_proc         : unsigned(9 downto 0); -- Count up to 680 cols
signal cnt_row_proc         : unsigned(9 downto 0); -- Count up to 460 rows


--constant center_col : unsigned(9 downto 0) := "0000101000";  -- Center column (40 for smaller image)
--constant center_row : unsigned(9 downto 0) := "0000011110";  -- Center row (30 for smaller image)
--
---- Define boundaries for each level (adjusted for smaller image 80x60 (8x times smaller than VGA)
--constant fovea_width   : unsigned(9 downto 0) := "0000001000"; -- Fovea width (8)
--constant fovea_height  : unsigned(9 downto 0) := "0000000100";  -- Fovea height (4)
--constant level1_width  : unsigned(9 downto 0) := "0000011000"; -- 2x2 Rexels width (24)
--constant level1_height : unsigned(9 downto 0) := "0000010010";  -- 2x2 Rexels height (18)
--constant level2_width  : unsigned(9 downto 0) := "0000110000"; -- 4x4 Rexels width (48)
--constant level2_height : unsigned(9 downto 0) := "0000100100";  -- 4x4 Rexels height (36)
--constant level3_width  : unsigned(9 downto 0) := "0001010000"; -- 8x8 Rexels width (80)
--constant level3_height : unsigned(9 downto 0) := "0000111100";  -- 8x8 Rexels height (60)

signal s_vsync_proc   : std_logic;
signal href_prev      : std_logic;
signal pixel_gen, pixel_sync   : std_logic;
signal r_pyramid_dout     : std_logic_vector(11 downto 0);
signal s_pyramid_dout     : std_logic_vector(11 downto 0);
signal cnt_col_aux1, cnt_col_aux2, cnt_col_aux3  : unsigned(9 downto 0); 
signal s_pixel_cnt : unsigned(18 downto 0);
signal start_data1, start_data2, start_data3 : std_logic;
signal cnt_addr_rd_fovea  :unsigned(12 downto 0);
signal reg_addr_rd_fovea  :unsigned(12 downto 0);

--attribute mark_debug: string;
--attribute mark_debug of pixel_end     : signal is "true";
--attribute mark_debug of s_vsync_proc  : signal is "true";
--attribute mark_debug of rd_capture    : signal is "true";
--attribute mark_debug of pixel_cnt_proc  : signal is "true";
--attribute mark_debug of pyramid_dout  : signal is "true";
--attribute mark_debug of cnt_row_proc  : signal is "true";
--attribute mark_debug of cnt_col_proc  : signal is "true";
--attribute mark_debug of capture_out   : signal is "true";
--attribute mark_debug of row_level_1   : signal is "true";
--attribute mark_debug of row_level_2   : signal is "true";
--attribute mark_debug of row_level_3   : signal is "true";
--attribute mark_debug of we_bram_row1  : signal is "true";
--attribute mark_debug of we_bram_row2  : signal is "true";
--attribute mark_debug of we_bram_row3  : signal is "true";
--attribute mark_debug of cnt_col_aux1  : signal is "true";
--attribute mark_debug of cnt_col_aux2  : signal is "true";
--attribute mark_debug of cnt_col_aux3  : signal is "true";
--attribute mark_debug of s_pixel_cnt   : signal is "true";
--attribute mark_debug of start_data1   : signal is "true";
--attribute mark_debug of start_data2   : signal is "true";
--attribute mark_debug of start_data3   : signal is "true";

begin

pixel_gen_proc: process(pclk, reset) 
begin 
    if rising_edge(pclk) then
      if(reset = '0') then
        pixel_sync <= '0';
        pixel_gen  <= '0';
      else
        if (pixel_gen = '1') then
            if(pixel_sync = '0') then
              pixel_sync <= '1';
            else
              pixel_sync <= '0';
            end if;
        elsif(start_proc = '1') then
            pixel_gen <= '1';
        end if;
      end if;
    end if;
 end process;
        
 aux_col_counter1: process(pclk, reset)
 begin
   if rising_edge(pclk) then
    if (reset = '0') then
        cnt_col_aux1 <= (others => '0');
    else
      if (start_data1 = '1') then
        if (pixel_sync = '1') then
          if (cnt_col_aux1 < MAX_COL - 1) then 
              cnt_col_aux1  <= cnt_col_aux1 + 1;
          else
              cnt_col_aux1  <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end if;
  end process;
  
 aux_col_counter2: process(pclk, reset)
 begin
   if rising_edge(pclk) then
    if (reset = '0') then
      cnt_col_aux2 <= (others => '0');
    else
      if (start_data2 = '1') then
        if (pixel_sync = '1') then
          if (cnt_col_aux2 < MAX_COL - 1) then -- 79
              cnt_col_aux2  <= cnt_col_aux2 + 1;
          else
              cnt_col_aux2  <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end if;
  end process;
  
 aux_col_counter3: process(pclk, reset)
 begin
  if rising_edge(pclk) then
    if (reset = '0') then
      cnt_col_aux3 <= (others => '0');
    else
      if (start_data3 = '1') then
        if (pixel_sync = '1') then
          if (cnt_col_aux3 < MAX_COL - 1) then -- 79
              cnt_col_aux3  <= cnt_col_aux3 + 1;
          else
              cnt_col_aux3  <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end if;
  end process;

 
start_cnt_gen: process(pclk, reset) 
  begin
   if rising_edge(pclk) then
     if (reset = '0') then
       s_vsync_proc <= '0';
     else
      if (start_cnt = '1') then 
        s_vsync_proc <= '1';
      elsif ((cnt_row_proc >= MAX_ROW - 1) and (cnt_col_proc >= MAX_COL - 1)) then 
        s_vsync_proc <= '0';
      end if;
    end if ;
   end if; 
  end process; 
 
  counters: process(pclk, reset)
  begin
    if rising_edge(pclk) then
      if (reset = '0') then
        cnt_row_proc <= (others => '0');
        cnt_col_proc <= (others => '0');
      else
        if (s_vsync_proc = '0') then
        cnt_row_proc <= (others => '0');
        cnt_col_proc <= (others => '0');
        else
          if (href = '1') then
            if(pixel_end = '1') then
               cnt_col_proc <= cnt_col_proc + 1;
            end if;
          elsif(href = '0' and href_prev = '1') then
            cnt_row_proc <= cnt_row_proc + 1;
            cnt_col_proc <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;
  
    href_prev_proc: process(pclk, reset)
     begin
     if rising_edge(pclk) then
       if (reset = '0') then
         href_prev <= '0';
         reg_addr_rd_fovea <= (others => '0');
       else
         href_prev <= href;
         reg_addr_rd_fovea <= cnt_addr_rd_fovea;
       end if;
     end if;
   end process;
  
process(reset, pixel_end, r_pyramid_dout, s_vsync_proc, data_row1, data_row2, data_row3, cnt_col_proc, cnt_row_proc, capture_out, cnt_addr_rd_fovea, reg_addr_rd_fovea)
  begin
  if (pixel_end = '1' and s_vsync_proc = '1') then
      -- Fovea level (green), all pixels within the fovea region
      if ((cnt_col_proc >= center_col - (fovea_width / 2) and cnt_col_proc < center_col + (fovea_width / 2)) and
          (cnt_row_proc >= center_row - (fovea_height / 2) and cnt_row_proc < center_row + (fovea_height / 2))) then
        s_pyramid_dout <= capture_out;
        we_bram <= '1';
        cnt_addr_rd_fovea <= cnt_addr_rd_fovea + 1;
      -- First ring (yellow, 2x2 Rexels), between fovea and level1 boundaries
      elsif ((cnt_col_proc >= center_col - (level1_width / 2) and cnt_col_proc < center_col + (level1_width / 2)) and
            (cnt_row_proc >= center_row - (level1_height / 2) and cnt_row_proc < center_row + (level1_height / 2))) then
            --((cnt_col_proc and "0000001") = "0000001" and (cnt_row_proc and "0000001") = "0000001")) then
          s_pyramid_dout <= data_row1; -- SALIDA DE LA FIFO
          we_bram <= '1';
          cnt_addr_rd_fovea <= reg_addr_rd_fovea;
      -- Second ring (red, 4x4 Rexels), between level1 and level2 boundaries
      elsif ((cnt_col_proc >= center_col - (level2_width / 2) and cnt_col_proc < center_col + (level2_width / 2)) and
            (cnt_row_proc >= center_row - (level2_height / 2) and cnt_row_proc < center_row + (level2_height / 2))) then
            --((cnt_col_proc and "0000011") = "0000011" and (cnt_row_proc and "0000011") = "0000011")) then
          s_pyramid_dout <= data_row2; -- SALIDA DE LA FIFO
          we_bram <= '1'; 
          cnt_addr_rd_fovea <= reg_addr_rd_fovea;     
      -- Third ring (blue, 8x8 Rexels), outside level2 boundaries
      elsif (cnt_col_proc >= (center_col - (level3_width / 2)) and cnt_col_proc < (center_col + (level3_width / 2))) and
            ((cnt_row_proc >= center_row - (level3_height / 2)) and cnt_row_proc < (center_row + (level3_height / 2))) then
            --(cnt_col_proc and "0000111") = "0000111" and (cnt_row_proc and "0000111") = "0000111" then
          s_pyramid_dout <= data_row3;
          we_bram <= '1';
          cnt_addr_rd_fovea <= reg_addr_rd_fovea;
      else
        s_pyramid_dout <= (others => '0');
        cnt_addr_rd_fovea <= reg_addr_rd_fovea;
        we_bram <= '0';
      end if;
  else
     cnt_addr_rd_fovea <= reg_addr_rd_fovea;
     s_pyramid_dout <= r_pyramid_dout;
     we_bram <= '0';
  end if;
  end process;
  

reg_pyramid: process(pclk, reset) 
begin
  if rising_edge(pclk) then
    if (reset = '0') then
        r_pyramid_dout   <= (others => '0');
    else
        r_pyramid_dout   <= s_pyramid_dout;
    end if;
  end if;
end process;


fill_fifo1: process(pclk, reset)
begin
  if rising_edge(pclk) then
    if (reset = '0') then
      row_level_1   <= (others => '0');
      we_bram_row1 <= '0';
      start_data1  <= '0';
    else
      if (start_data1 = '1') then
        if(pixel_sync = '1') then
          if(cnt_col_aux1 >= MAX_COL - 1) then
            we_bram_row1  <= '0';
            start_data1   <= '0';
          else
            row_level_1  <= gen_level_1;
            we_bram_row1 <= '1';
          end if;
        else
          we_bram_row1 <= '0';  
        end if;
      elsif (new_data1 = '1' and start_proc = '1') then     -- Esquina inferior derecha
        start_data1  <= '1';
        row_level_1  <= gen_level_1;
        we_bram_row1 <= '1';
      else
        we_bram_row1 <= '0';
      end if;
    end if;
  end if;
end process;
  
fill_fifo2: process(pclk, reset)
begin
  if rising_edge(pclk) then
    if (reset = '0') then
      row_level_2   <= (others => '0');
      we_bram_row2 <= '0';
      start_data2  <= '0';
    else
      if (start_data2 = '1') then
        if(pixel_sync = '1') then
          if(cnt_col_aux2 >= MAX_COL - 1) then
            we_bram_row2    <= '0';
            start_data2     <= '0';
          else
            row_level_2 <= gen_level_2;
            we_bram_row2 <= '1';
          end if;
        else
          we_bram_row2 <= '0';
        end if;
      elsif (new_data2 = '1' and start_proc = '1') then     -- Esquina inferior derecha
        start_data2  <= '1';
        row_level_2 <= gen_level_2;
        we_bram_row2 <= '1';
      else
        we_bram_row2 <= '0';
      end if;
    end if;
  end if;
end process; 
  
  
  
fill_fifo3: process(pclk, reset)
begin
  if rising_edge(pclk) then
    if (reset = '0') then
      row_level_3   <= (others => '0');
      we_bram_row3 <= '0';
      start_data3  <= '0';
    else
      if (start_data3 = '1') then
        if(pixel_sync = '1') then
          if(cnt_col_aux3 >= MAX_COL - 1) then
            we_bram_row3 <= '0';
            start_data3 <= '0';
          else
            row_level_3 <= gen_level_3;
            we_bram_row3 <= '1';
          end if;
        else
          we_bram_row3 <= '0';
        end if;
      elsif (new_data3 = '1' and start_proc = '1') then     -- Esquina inferior derecha
        start_data3  <= '1';
        row_level_3 <= gen_level_3;
        we_bram_row3 <= '1';
      else
        we_bram_row3 <= '0';
      end if;
    end if;
  end if;
end process;

 pixel_cnt_gen: process(pclk, reset)
 begin
   if rising_edge(pclk) then
    if (reset = '0') then
        s_pixel_cnt      <= (others => '0');
    else   
        if(s_vsync_proc = '1') then
            if (pixel_end = '1') then
                s_pixel_cnt  <= s_pixel_cnt + 1;
            end if;
        else
            s_pixel_cnt <= (others => '0');
        end if;
   end if;
  end if;
  end process;

  col_proc_out <= std_logic_vector(cnt_col_proc);
  col_aux1_out <= std_logic_vector(cnt_col_aux1);
  col_aux2_out <= std_logic_vector(cnt_col_aux2);
  col_aux3_out <= std_logic_vector(cnt_col_aux3);
  start_cnt_proc <= s_vsync_proc;
  pyramid_dout <= s_pyramid_dout;
  pixel_cnt_proc <= std_logic_vector(s_pixel_cnt);
  addr_rd_fovea <= std_logic_vector(cnt_addr_rd_fovea);
  
end foveal_pyramid_gen_arch;
