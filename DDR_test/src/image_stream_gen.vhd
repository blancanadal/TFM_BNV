---------------------------------------------------------
-- Name: image_stream_gen
-- Description: Module that generates a synthetic image
-- for testing and analysis purposes
-- Author: Blanca Nadal Valle
---------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity image_stream_gen is
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
end entity;

architecture image_stream_gen_arch of image_stream_gen is

constant center_col : unsigned(9 downto 0) := "0000101000";  -- Center column (40 for smaller image)
constant center_row : unsigned(9 downto 0) := "0000011110";  -- Center row (30 for smaller image)

-- Define boundaries for each level (adjusted for smaller image 80x60 (8x times smaller than VGA)
constant fovea_width   : unsigned(9 downto 0) := "0000001000"; -- Fovea width (8)
constant fovea_height  : unsigned(9 downto 0) := "0000000100";  -- Fovea height (4)
constant level1_width  : unsigned(9 downto 0) := "0000011000"; -- 2x2 Rexels width (24)
constant level1_height : unsigned(9 downto 0) := "0000010010";  -- 2x2 Rexels height (18)
constant level2_width  : unsigned(9 downto 0) := "0000110000"; -- 4x4 Rexels width (48)
constant level2_height : unsigned(9 downto 0) := "0000100100";  -- 4x4 Rexels height (36)
constant level3_width  : unsigned(9 downto 0) := "0001010000"; -- 8x8 Rexels width (80)
constant level3_height : unsigned(9 downto 0) := "0000111100";  -- 8x8 Rexels height (60)

--constant fovea_width   : unsigned(9 downto 0) := "0010000000"; -- Fovea width (128)
--constant fovea_height  : unsigned(9 downto 0) := "0001000000"; -- Fovea height (64)
--
--constant level1_width  : unsigned(9 downto 0) := "0100000000"; -- Nivel 1 width (256)
--constant level1_height : unsigned(9 downto 0) := "0010100000"; -- Nivel 1 height (160)
--
--constant level2_width  : unsigned(9 downto 0) := "0111100000"; -- Nivel 2 width (480)
--constant level2_height : unsigned(9 downto 0) := "0101000000"; -- Nivel 2 height (320)
--
--constant level3_width  : unsigned(9 downto 0) := "1010000000"; -- Nivel 3 width (640)
--constant level3_height : unsigned(9 downto 0) := "0111100000"; -- Nivel 3 height (480)
--
--constant center_col : unsigned(9 downto 0) := "0101000000"; -- Center column (320)
--constant center_row : unsigned(9 downto 0) := "0011110000"; -- Center row (240)

  -- Contadores horizontales y verticales
  signal cnt_row : unsigned(9 downto 0);  
  signal cnt_col : unsigned(9 downto 0); 
  signal s_vsync : std_logic; 
  signal s_href  : std_logic; 
  signal href_prev  : std_logic; 
  signal s_pixel_data : std_logic_vector(11 downto 0);
  signal reg_pixel_data : std_logic_vector(11 downto 0);
  signal s_pixel_end : std_logic;
  signal byte_sel : std_logic;
  signal addr_fovea_out : unsigned(12 downto 0);
  
  --attribute mark_debug: string;
  --attribute mark_debug of s_pixel_cnt      : signal is "true";
  --attribute mark_debug of vsync           : signal is "true";


begin

  href_prev_proc: process(pclk, reset)
     begin
     if rising_edge(pclk) then
       if (reset = '0') then
         href_prev <= '0';
         reg_pixel_data <= (others => '0');
       else
         href_prev <= href;
         reg_pixel_data <= s_pixel_data; 
       end if;
     end if;
   end process;
  
  pixel_capture : process(pclk, reset)
    begin      
    if rising_edge(pclk) then
        if (reset = '0') then
          s_pixel_end <= '0';
          byte_sel  <= '0';
        else
          if (vsync = '1') then     -- End of image --> reset control signals
            s_pixel_end <= '0';
            byte_sel  <= '0';
          else                    -- Transmision of image
            if (href = '1') then    -- Start of line
              if (byte_sel = '0') then  -- First byte
                s_pixel_end <= '0';
                byte_sel  <= '1';
              else                      -- Second byte
                s_pixel_end <= '1';
                byte_sel  <= '0';
              end if;
            else  -- End of line
              byte_sel  <= '0';
              s_pixel_end <= '0';
            end if;
          end if;
        end if;
      end if;
  end process;
  
  
  
  counters: process(pclk, reset)
  begin
    if rising_edge(pclk) then
      if (reset = '0') then
        cnt_row <= (others => '0');
        cnt_col <= (others => '0');
      else
        if (vsync = '1') then
          cnt_row <= (others => '0');
          cnt_col <= (others => '0');
        else
          if (href = '1') then
            if(s_pixel_end = '1') then
              cnt_col <= cnt_col + 1;
            end if;
          elsif(href = '0' and href_prev = '1') then
            cnt_row <= cnt_row + 1;
            cnt_col <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;



  process(reset, cnt_col, cnt_row, s_pixel_end, reg_pixel_data)
  begin
        if (reset = '0') then
            s_pixel_data <= (others => '0');
            --we_bram <= '0';
        else
            if(s_pixel_end = '1') then
              --we_bram <= '1';
                if ((cnt_col >= center_col - (fovea_width / 2) and cnt_col < center_col + (fovea_width / 2)) and
                     (cnt_row >= center_row - (fovea_height / 2) and cnt_row < center_row + (fovea_height / 2))) then
                    s_pixel_data <= x"FF0";
                 -- First ring (yellow, 2x2 Rexels), between fovea and level1 boundaries
                 elsif ((cnt_col >= center_col - (level1_width / 2) and cnt_col < center_col + (level1_width / 2)) and
                       (cnt_row >= center_row - (level1_height / 2) and cnt_row < center_row + (level1_height / 2))) then
                    s_pixel_data <= x"20F";
                 -- Second ring (red, 4x4 Rexels), between level1 and level2 boundaries
                 elsif ((cnt_col >= center_col - (level2_width / 2) and cnt_col < center_col + (level2_width / 2)) and
                       (cnt_row >= center_row - (level2_height / 2) and cnt_row < center_row + (level2_height / 2))) then
                       --((cnt_col_proc and "0000011") = "0000011" and (cnt_row_proc and "0000011") = "0000011")) then
                    s_pixel_data <= x"4F0";
                 -- Third ring (blue, 8x8 Rexels), outside level2 boundaries
                 elsif (cnt_col >= (center_col - (level3_width / 2)) and cnt_col < (center_col + (level3_width / 2))) and
                       ((cnt_row >= center_row - (level3_height / 2)) and cnt_row < (center_row + (level3_height / 2))) then
                       --(cnt_col_proc and "0000111") = "0000111" and (cnt_row_proc and "0000111") = "0000111" then
                    s_pixel_data <= x"1FF";
                 else
                    s_pixel_data <= (others => '0');
                 end if;
            else
               --we_bram <= '0';
               s_pixel_data <= reg_pixel_data;
            end if;
        end if;
  end process;


  process(pclk, reset)
  begin
   if rising_edge(pclk) then 
    if(reset = '0') then 
        we_fovea <= '0';
        bram_fovea_out <= (others => '0');
        addr_fovea_out <= (others => '0');
    elsif (s_pixel_end = '1') then
        if ((cnt_col >= center_col - (fovea_width / 2) and cnt_col < center_col + (fovea_width / 2)) and
          (cnt_row >= center_row - (fovea_height / 2) and cnt_row < center_row + (fovea_height / 2))) then
          bram_fovea_out <= s_pixel_data;
          we_fovea      <= '1';
          addr_fovea_out <= addr_fovea_out + 1;
        else
            if(cnt_col = center_col + (fovea_width / 2)) and
            (cnt_row >= center_row - (fovea_height / 2) and (cnt_row < center_row + (fovea_height / 2))) then
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


   --pixel_cnt <= std_logic_vector(s_pixel_cnt);
   --pixel_data <= s_pixel_data;

end image_stream_gen_arch;