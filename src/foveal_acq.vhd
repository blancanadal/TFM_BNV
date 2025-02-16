----------------------------------------------------------------
-- Name: foveal_acq
-- Description: Module that generates multirresolution rings for
-- foveal mapping
-- Author: Blanca Nadal Valle
----------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity foveal_acq is
  port(                                          
    pclk       : in  std_logic;                       
    reset      : in  std_logic;                       
    vsync      : in  std_logic;                       
    href       : in  std_logic;                       
    pixel_end  : in  std_logic;                       -- New pixel available - we from BRAM                     
    din        : in  std_logic_vector(3 downto 0);   -- Dout signal from capture block
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
    cnt_row_acq: out std_logic_vector(9 downto 0);   
    cnt_col_acq: out std_logic_vector(9 downto 0);   
    dout1      : out std_logic_vector(3 downto 0);   -- First level ring
    dout2      : out std_logic_vector(3 downto 0);   -- Second level ring
    dout3      : out std_logic_vector(3 downto 0);   -- Third level ring
    fifo_out1  : out std_logic_vector(9 downto 0);
    fifo_out2  : out std_logic_vector(9 downto 0);
    fifo_out3  : out std_logic_vector(9 downto 0)
    );

end foveal_acq;

architecture foveal_acq_arch of foveal_acq is

-- Signals
signal reg1          : unsigned(9 downto 0);    
signal reg2          : unsigned(9 downto 0);
signal reg3          : unsigned(9 downto 0);
signal data1         : unsigned(9 downto 0);
signal data2         : unsigned(9 downto 0);
signal data3         : unsigned(9 downto 0);
signal reg_data1     : unsigned(9 downto 0);
signal reg_data2     : unsigned(9 downto 0);
signal reg_data3     : unsigned(9 downto 0);
signal reg_fifo1     : unsigned(9 downto 0);
signal reg_fifo2     : unsigned(9 downto 0);
signal reg_fifo3     : unsigned(9 downto 0);
signal reg_dout1     : unsigned(9 downto 0);
signal reg_dout2     : unsigned(9 downto 0);
signal reg_dout3     : unsigned(9 downto 0);
signal buff_dout1    : unsigned(9 downto 0);
signal buff_dout2    : unsigned(9 downto 0);
signal buff_dout3    : unsigned(9 downto 0);
signal out1          : unsigned(9 downto 0);
signal out2          : unsigned(9 downto 0);
signal out3          : unsigned(9 downto 0);
signal s_new_data1   : std_logic;
signal s_new_data2   : std_logic;
signal s_new_data3   : std_logic;
signal href_prev     : std_logic;
signal cnt_col       : unsigned(9 downto 0);
signal cnt_row       : unsigned(9 downto 0);

begin

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
            if(pixel_end = '1') then
              cnt_col <= cnt_col+ 1;
            end if;
          elsif(href = '0' and href_prev = '1') then
            cnt_row <= cnt_row+ 1;
            cnt_col <= (others => '0');
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
       else
         href_prev <= href;
       end if;
     end if;
   end process;
 
 
  even_registers: process(pclk, reset)
  begin
    if rising_edge(pclk) then
      if (reset = '0') then
        reg1 <= (others => '0');
        reg2 <= (others => '0');
        reg3 <= (others => '0');
      else
        if (cnt_col and "0000000001") = "0000000000" then
          reg1 <= unsigned("000000"&din);
        elsif (cnt_col and "0000000011") = "0000000001" then
          reg2 <= data1;
        elsif (cnt_col and "0000000111") = "0000000011" then
          reg3 <= data2;
        end if;
      end if;
    end if;
  end process;
  
  
  registers: process(pclk, reset)
    begin
    if rising_edge(pclk) then
      if (reset = '0') then
        reg_data1 <= (others => '0');
        reg_data2 <= (others => '0');
        reg_data3 <= (others => '0');
        reg_fifo1 <= (others => '0');
        reg_fifo2 <= (others => '0');
        reg_fifo3 <= (others => '0');
        reg_dout1 <= (others => '0');
        reg_dout2 <= (others => '0');
        reg_dout3 <= (others => '0');
      else
        reg_data1 <= data1;
        reg_data2 <= data2;
        reg_data3 <= data3;
        reg_fifo1 <= out1;
        reg_fifo2 <= out2;
        reg_fifo3 <= out3;
        reg_dout1 <= buff_dout1;
        reg_dout2 <= buff_dout2;
        reg_dout3 <= buff_dout3;
      end if;
    end if;
  end process;
 

  datapath_level_1: process(pixel_end, reset, cnt_col, cnt_row, reg1, din, data1, data1_fifo, reg_fifo1, reg_data1, reg_dout1)
  begin
    if(reset = '0') then
      out1      <= (others => '0');
      we_fifo1  <= '0';
      rd_fifo1  <= '0';
      data1     <= (others => '0');
      buff_dout1 <= (others => '0');
      s_new_data1  <= '0';    
    
     -- Ubicación de píxeles en un bloque 2x2
    elsif(pixel_end = '1') then
      if (cnt_row and "0000000001") = "0000000000" then                     -- Primera fila del bloque 2x2 (múltiplo de 2)
        if (cnt_col and "0000000001") = "0000000000" then                   -- Primera columna del bloque 2x2 (múltiplo de 2)
             -- ld0: esquina superior izquierda
             out1      <= reg_fifo1;
             we_fifo1  <= '0';
             rd_fifo1  <= '0';
             data1     <= reg_data1;
             buff_dout1 <= reg_dout1;
             s_new_data1  <= '0';
         else  -- Segunda columna 
             -- u1: esquina superior derecha
             out1      <= reg1 + unsigned("000000"&din);
             we_fifo1  <= '1';
             rd_fifo1  <= '0';
             data1     <= reg_data1;
             buff_dout1 <= reg_dout1;
             s_new_data1  <= '0';
         end if;
     else  -- Segunda fila del bloque 2x2 (fila impar)
         if (cnt_col and "0000000001") = "0000000000" then  -- Primera columna 
             -- p1: esquina inferior izquierda
             out1      <= reg_fifo1;
             we_fifo1  <= '0';
             rd_fifo1  <= '1';
             data1     <= reg_data1;
             buff_dout1 <= reg_dout1;
             s_new_data1  <= '0';
         else  -- Segunda columna (múltiplo de 2 + 1)
             -- rd1: esquina inferior derecha
             out1      <= reg_fifo1;
             we_fifo1  <= '0';
             rd_fifo1  <= '0';
             data1     <= unsigned(data1_fifo) + reg1 + unsigned("000000"&din);
             buff_dout1 <= "00" & data1(9 downto 2); -- 4 division
             s_new_data1  <= '1';
         end if;
     end if;
    else
      out1        <= reg_fifo1;
      we_fifo1    <= '0';
      rd_fifo1    <= '0';
      data1       <= reg_data1;
      buff_dout1  <= reg_dout1;
      s_new_data1 <= '0';
    end if;
   end process;
  
  
  datapath_level_2: process(reset, pixel_end, cnt_col, cnt_row, reg2, data1, data2, data2_fifo, reg_fifo2, reg_data2, reg_dout2)
  begin
    if (reset = '0') then
      out2      <= (others => '0'); 
      we_fifo2  <= '0';
      rd_fifo2  <= '0';
      data2     <= (others => '0');
      buff_dout2 <= (others => '0');
      s_new_data2  <= '0';
    elsif (pixel_end = '1') then
      if (cnt_row < "0000000001") then
        out2      <= reg_fifo2; 
        we_fifo2  <= '0';
        rd_fifo2  <= '0';
        data2     <= reg_data2;
        buff_dout2 <= reg_dout2;
        s_new_data2  <= '0';
      elsif (cnt_row and "0000000011") = "0000000001" then    -- Primera fila del bloque 4x4
          if (cnt_col and "0000000011") = "0000000001" then
            --reg2 <= data1;                      -- Posición ld1: esquina superior izquierda
            out2      <= reg_fifo2; 
            we_fifo2  <= '0';
            rd_fifo2  <= '0';
            data2     <= reg_data2;
            buff_dout2 <= reg_dout2;
            s_new_data2  <= '0';
          elsif (cnt_col and "0000000011") = "0000000011" then
              -- Posición u2: esquina superior derecha
            out2      <= reg2 + data1;  
            we_fifo2  <= '1';  
            rd_fifo2  <= '0';  
            data2     <= reg_data2;  
            buff_dout2<= reg_dout2;
            s_new_data2  <= '0';
          else
            out2      <= reg_fifo2;
            we_fifo2  <= '0';
            rd_fifo2  <= '0';
            data2     <= reg_data2;
            buff_dout2<= reg_dout2;
            s_new_data2  <= '0';
          end if;
      elsif (cnt_row and "0000000011") = "0000000011" then  -- Múltiplo de 4 en fila
          if (cnt_col and "0000000011") = "0000000001" then  -- Múltiplo de 4 en columna 
              -- Posición p2: esquina inferior izquierda
            --reg2 <= data1;        
            out2      <= reg_fifo2; 
            we_fifo2  <= '0';
            rd_fifo2  <= '1';
            data2     <= reg_data2;
            buff_dout2 <= reg_dout2;
            s_new_data2  <= '0';
          elsif (cnt_col and "0000000011") = "0000000011" then
              -- Posición rd2: esquina inferior derecha
            out2      <= reg_fifo2; 
            we_fifo2  <= '0';
            rd_fifo2  <= '0';
            data2     <= unsigned(data2_fifo) + reg2 + data1;
            buff_dout2<= "0000" & data2(9 downto 4); -- 16 division
            s_new_data2  <= '1';
          else
            out2      <= reg_fifo2;
            we_fifo2  <= '0';
            rd_fifo2  <= '0';
            data2     <= reg_data2;
            buff_dout2<= reg_dout2;  
            s_new_data2  <= '0';          
          end if;
      else
        out2      <= reg_fifo2;
        we_fifo2  <= '0';
        rd_fifo2  <= '0';
        data2     <= reg_data2; 
        buff_dout2<= reg_dout2;
        s_new_data2  <= '0';
      end if;
    else
      out2        <= reg_fifo2;
      we_fifo2    <= '0';
      rd_fifo2    <= '0';
      data2       <= reg_data2; 
      buff_dout2  <= reg_dout2;
      s_new_data2 <= '0';
    end if;
  end process;  
  
  
  datapath_level_3: process(pixel_end, reset, cnt_col, cnt_row, reg3, data2, data3, data3_fifo, reg_fifo3, reg_data3, reg_dout3)
  begin
    if (reset = '0') then 
      out3      <= (others => '0');
      we_fifo3  <= '0';
      rd_fifo3  <= '0';
      data3     <= (others => '0');
      buff_dout3<= (others => '0');
      s_new_data3  <= '0';
    elsif(pixel_end = '1') then
      if (cnt_row < "0000000011") then
          out3      <= reg_fifo3;
          we_fifo3  <= '0';
          rd_fifo3  <= '0';
          data3     <= reg_data3;
          buff_dout3<= reg_dout3;
          s_new_data3  <= '0';
      elsif (cnt_row and "0000000111") = "0000000011" then 
        if (cnt_col and "0000000111") = "0000000011" then
          -- ld2: esquina superior izquierda
          --reg3 <= data2;
          out3      <= reg_fifo3;
          we_fifo3  <= '0';
          rd_fifo3  <= '0';
          data3     <= reg_data3;
          buff_dout3<= reg_dout3;
          s_new_data3  <= '0';
        elsif (cnt_col and "0000000111") = "0000000111" then
          -- u3: esquina superior derecha
          out3      <= reg3 + data2;  
          we_fifo3  <= '1';  
          rd_fifo3  <= '0';  
          data3     <= reg_data3; 
          buff_dout3<= reg_dout3;
          s_new_data3  <= '0';        
        else
          out3      <= reg_fifo3;
          we_fifo3  <= '0';
          rd_fifo3  <= '0';
          data3     <= reg_data3;
          buff_dout3<= reg_dout3;
          s_new_data3  <= '0';
        end if;
      elsif (cnt_row and "0000000111") = "0000000111" then  -- Fila impar dentro del bloque 8x8 (fila 7)
        if (cnt_col and "0000000111") = "0000000011" then  -- Columna impar dentro del bloque 8x8 (columna 3)
          -- p3: esquina inferior izquierda
          --reg3 <= data2;
          out3      <= reg_fifo3;
          we_fifo3  <= '0';
          rd_fifo3  <= '1';
          data3     <= reg_data3;
          buff_dout3<= reg_dout3;
          s_new_data3  <= '0';
        elsif (cnt_col and "0000000111") = "0000000111" then   -- Última columna del bloque 8x8 (múltiplo de 8 + 7)
          -- rd3: esquina inferior derecha
          out3      <= reg_fifo3; 
          we_fifo3  <= '0';
          rd_fifo3  <= '0';
          data3     <= unsigned(data3_fifo) + reg3 + data2;
          buff_dout3<= "000000" & data3(9 downto 6); -- 64 division
          s_new_data3  <= '1';        
        else
          out3      <= reg_fifo3;
          we_fifo3  <= '0';
          rd_fifo3  <= '0';
          data3     <= reg_data3;
          buff_dout3<= reg_dout3;
          s_new_data3  <= '0';        
        end if;
      else
        out3      <= reg_fifo3;
        we_fifo3  <= '0';
        rd_fifo3  <= '0';
        data3     <= reg_data3;
        buff_dout3<= reg_dout3;
        s_new_data3  <= '0';
      end if;
    else
      out3      <= reg_fifo3;
      we_fifo3  <= '0';
      rd_fifo3  <= '0';
      data3     <= reg_data3;
      buff_dout3<= reg_dout3;
      s_new_data3  <= '0';
    end if;
  end process;
  
  
  fifo_out1 <= std_logic_vector(out1);
  fifo_out2 <= std_logic_vector(out2);
  fifo_out3 <= std_logic_vector(out3);
  dout1     <= std_logic_vector(buff_dout1(3 downto 0));
  dout2     <= std_logic_vector(buff_dout2(3 downto 0));
  dout3     <= std_logic_vector(buff_dout3(3 downto 0));
  new_data1 <= s_new_data1;
  new_data2 <= s_new_data2;
  new_data3 <= s_new_data3;
  cnt_col_acq <= std_logic_vector(cnt_col);
  cnt_row_acq <= std_logic_vector(cnt_row);
  
  
end foveal_acq_arch;
