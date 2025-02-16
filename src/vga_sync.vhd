---------------------------------------------------------
-- Name: vga_sync
-- Description: Module that generates the synchronization 
-- signals for the VGA controller
-- Author: Blanca Nadal Valle
---------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all ; 
use ieee.numeric_std.all ; 

entity vga_sync is 
  port( 
    clk50         : in  std_logic;
    clk25         : in  std_logic;
    reset         : in  std_logic;
    reset50       : in  std_logic;
    hsync         : out std_logic;
    vsync         : out std_logic; 
    display_on    : out std_logic;
    pixel_addr    : out std_logic_vector (18 downto 0)
    );
    
end vga_sync; 

architecture vga_sync_arch of vga_sync is 


-- VGA 640-by-480 SYNC PARAMETERS
constant HD: integer  := 640; -- Horizontal display area 
constant RB: integer  := 16;  -- Right border
constant LB: integer  := 48;  -- Left border
constant HR: integer  := 96;  -- Horizontal retrace 
constant VD: integer  := 480; -- Vertical display area 
constant BB: integer  := 10;  -- Bottom border 
constant TB: integer  := 33;  -- Top border 
constant VR: integer  := 2;   -- Vertical retrace

-- SYNC COUNTERS
signal v_cnt : unsigned(9 downto 0);  -- Counts up to 800
signal h_cnt : unsigned(9 downto 0);  -- Counts up to 525
signal v_cnt_reg : unsigned(9 downto 0); 
signal h_cnt_reg : unsigned(9 downto 0);
signal vsync_reg : std_logic; 
signal hsync_reg : std_logic;
signal s_vsync : std_logic; 
signal s_hsync : std_logic;     

-- PIXEL COUNTER
signal cnt_pixel_addr : unsigned(18 downto 0);
signal pixel_addr_reg : unsigned(18 downto 0);

--attribute mark_debug: string;
--attribute mark_debug of cnt_pixel_addr: signal is "true";
--attribute mark_debug of v_cnt         : signal is "true";
--attribute mark_debug of h_cnt         : signal is "true";
--attribute mark_debug of hsync         : signal is "true";
--attribute mark_debug of vsync         : signal is "true";
--attribute mark_debug of display_on    : signal is "true";




begin 


  register_proc: process(clk50, reset50) 
  begin
   if rising_edge(clk50) then
     if (reset50 = '0') then
      v_cnt_reg <= (others => '0');
      h_cnt_reg <= (others => '0');
      vsync_reg <= '0';
      hsync_reg <= '0';
       
     else
      v_cnt_reg <= v_cnt;
      h_cnt_reg <= h_cnt;
      vsync_reg <= s_vsync;
      hsync_reg <= s_hsync;
    end if;
  end if;
  end process; 


  h_sync_counter: process(clk25, reset) 
  begin
   if rising_edge(clk25) then
     if (reset = '0') then
       h_cnt <= (others => '0');
     else
          if (h_cnt >= (HD + RB + LB + HR - 1)) then 
              h_cnt <= (others =>'0');
          else
              h_cnt <= h_cnt_reg + 1; 
          end if;
     end if;
    end if ; 
  end process; 
  

  v_sync_counter: process(clk25, reset) 
  begin
    if rising_edge(clk25) then
      if (reset = '0') then
        v_cnt <= (others => '0');
      else
            if (h_cnt >= (HD + RB + LB + HR - 1)) then 
                if (v_cnt >= (VD + BB + TB + VR - 1)) then
                    v_cnt <= (others =>'0');
                else
                    v_cnt <= v_cnt_reg + 1;
                end if;
            else
                v_cnt <= v_cnt_reg; 
            end if; 
     end if;
    end if ; 
  end process; 
  
  pixel_address: process(clk25, reset)
  begin
    if rising_edge(clk25) then
      if (reset = '0') then
          cnt_pixel_addr <= (others => '0');
      else
            if(h_cnt_reg >= VD) then
                cnt_pixel_addr <= (others => '0');
            else
                if(v_cnt_reg < HD) then
                    cnt_pixel_addr <= cnt_pixel_addr + 1;
                end if;
            end if;
      end if;
    end if;
  end process;
 
  
  s_hsync <= '0' when (h_cnt_reg >= (HD + RB)) and (h_cnt_reg <=(HD + RB + HR - 1)) else '1';
  s_vsync <= '0' when (v_cnt_reg >= (VD + BB)) and (v_cnt_reg <=(VD + BB + VR - 1)) else '1';
  display_on <= '1' when (h_cnt_reg < HD) and (v_cnt_reg < VD) else '1';

hsync  <= hsync_reg;
vsync  <= vsync_reg;
pixel_addr <= std_logic_vector(pixel_addr_reg); 

end vga_sync_arch; 