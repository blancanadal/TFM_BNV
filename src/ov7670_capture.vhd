------------------------------------------------------------------
-- Name: ov7670_capture
-- Description: Module that captures the image from ov7670 sensor
-- Author: Blanca Nadal Valle
------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity ov7670_capture is
  port(       
    pclk      : in  std_logic;                       -- Pixel clock   (provided by the sensor: 25MHz)
    reset     : in  std_logic;                       -- Reset
    vsync     : in  std_logic;                       -- Vertical sync
    href      : in  std_logic;                       -- Horizontal sync
    data      : in  std_logic_vector (7 downto 0);   -- 8-bit data from sensor
    addr      : out std_logic_vector (18 downto 0);  -- 307200 positions
    dout      : out std_logic_vector (11 downto 0);  -- Data to BRAM
    pixel_end : out std_logic                        
  );

end ov7670_capture;

architecture ov7670_capture_arch of ov7670_capture is

 --Signals
  signal red      : std_logic_vector(4 downto 0);
  signal blue     : std_logic_vector(4 downto 0);
  signal green    : std_logic_vector(5 downto 0);
  signal reg_dout : std_logic_vector(11 downto 0);
  signal s_dout   : std_logic_vector(11 downto 0);
  signal byte_sel : std_logic;
  signal s_pixel_end : std_logic;
  signal addr_cnt : unsigned(18 downto 0);
  
  -- ILA --
  --attribute mark_debug: string;
  --attribute mark_debug of href            : signal is "true";
  --attribute mark_debug of data          : signal is "true";
  --attribute mark_debug of vsync         : signal is "true";
  --attribute mark_debug of addr_cnt      : signal is "true";
  --attribute mark_debug of dout          : signal is "true";

begin

  pixel_capture : process(pclk, reset)
    begin      
    if rising_edge(pclk) then
        if (reset = '0') then
          s_pixel_end <= '0';
          addr_cnt  <= (others => '0');
          byte_sel  <= '0';
          red       <= (others => '0');
          green     <= (others => '0');
          blue      <= (others => '0');
        else
          if (vsync = '1') then     -- End of image --> reset control signals
            s_pixel_end <= '0';
            addr_cnt  <= (others => '0');
            byte_sel  <= '0';
            red       <= (others => '0');
            green     <= (others => '0');
            blue      <= (others => '0');
          else                    -- Transmision of image
            if (href = '1') then    -- Start of line
              if (byte_sel = '0') then  -- First byte
                red       <= data(7 downto 3);
                green     <= data(2 downto 0) & "000";
                s_pixel_end <= '0';
                byte_sel  <= '1';
              else                      -- Second byte
                green     <= green(5 downto 3) & data(7 downto 5);
                blue      <= data(4 downto 0);
                s_pixel_end <= '1';
                byte_sel  <= '0';
                addr_cnt  <= addr_cnt + 1;
              end if;
            else  -- End of line
              byte_sel  <= '0';
              s_pixel_end <= '0';
            end if;
          end if;
        end if;
      end if;
  end process;
  
  process(pclk, reset)
  begin
    if rising_edge(pclk) then
        if (reset = '0') then
            reg_dout <= (others => '0');
        else
            reg_dout <= s_dout;
        end if;
     end if;
  end process;

  s_dout <= red(4 downto 1) & green(5 downto 2) & blue(4 downto 1); 
  dout   <= s_dout when (s_pixel_end = '1') else reg_dout;
  addr <= std_logic_vector(addr_cnt);
  pixel_end <= s_pixel_end;
  
  
--   signal d_latch      : std_logic_vector(15 downto 0) := (others => '0');
--   signal address      : std_logic_vector(18 downto 0) := (others => '0');
--   signal address_next : std_logic_vector(18 downto 0) := (others => '0');
--   signal wr_hold      : std_logic_vector( 1 downto 0) := (others => '0');
--
--begin
--   addr <= address(18 downto 0);
--   process(pclk)
--   begin
--      if rising_edge(pclk) then
--         -- This is a bit tricky href starts a pixel transfer that takes 3 cycles
--         --        Input   | state after clock tick
--         --         href   | wr_hold    d_latch           d                 we address  address_next
--         -- cycle -1  x    |    xx      xxxxxxxxxxxxxxxx  xxxxxxxxxxxxxxxx  x   xxxx     xxxx
--         -- cycle 0   1    |    x1      xxxxxxxxRRRRRGGG  xxxxxxxxxxxxxxxx  x   xxxx     addr
--         -- cycle 1   0    |    10      RRRRRGGGGGGBBBBB  xxxxxxxxRRRRRGGG  x   addr     addr
--         -- cycle 2   x    |    0x      GGGBBBBBxxxxxxxx  RRRRRGGGGGGBBBBB  1   addr     addr+1
--
--         if vsync = '1' then
--            address <= (others => '0');
--            address_next <= (others => '0');
--            wr_hold <= (others => '0');
--         else
--            -- This should be a different order, but seems to be GRB!
--            dout    <= d_latch(15 downto 12) & d_latch(10 downto 7) & d_latch(4 downto 1);
--            address <= address_next;
--            pixel_end <= wr_hold(1);
--            wr_hold <= wr_hold(0) & (href and not wr_hold(0));
--            d_latch <= d_latch(7 downto  0) & data;
--
--            if wr_hold(1) = '1' then
--               address_next <= std_logic_vector(unsigned(address_next)+1);
--            end if;
--         end if;
--      end if;
--   end process;
  
end ov7670_capture_arch;