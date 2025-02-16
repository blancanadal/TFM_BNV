library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fovea_ddr_ctrl is
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
end fovea_ddr_ctrl;

architecture fovea_ddr_ctrl_arch of fovea_ddr_ctrl is
  constant MAX_DATA         : unsigned(12 downto 0)        := (others => '1');
  constant CMD_WRITE        : std_logic_vector(2 downto 0) := "100";
  constant CMD_READ         : std_logic_vector(2 downto 0) := "101";
  constant BURST_BLOCK_SIZE : integer := 8;

  -- BRAM-DDR control
  signal cnt_addr_ddr_wr: unsigned(12 downto 0);
  signal cnt_addr_ddr_rd: unsigned(12 downto 0);
  
  signal write_buffer   : std_logic_vector(511 downto 0); -- 8 words of 64 bits
  signal write_index    : integer range 0 to 40;          -- Data sent every 8-word burst
  signal read_buffer    : std_logic_vector(511 downto 0); -- 8 words of 64 bits
  signal read_index     : integer range 0 to 40;          -- Data read every 8-word burst
  signal word_index     : integer range 0 to 8;           -- Index of 64-bit word within burst
  signal bit_offset     : integer range 0 to 64;          -- Shift in every word
  signal burst_cnt      : integer range 0 to 8;           -- Counter for burst
  signal cycle_cnt      : integer range 0 to 4;         -- Counter for bursts cycles (Need 4 for 128 data)
  signal init_complete  : std_logic;
  signal s_app_wdf_wren : std_logic;
  signal s_app_addr     : unsigned(26 downto 0);
  
  type fsm is (IDLE, WRITE_BUFF, SEND_CMD_WR, WRITE_BURST, DELAY, SEND_CMD_RD, READ_BURST, READ_BUFF);
  signal state: fsm;
  
begin

  process(clk, reset) 
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        init_complete <= '0';
      else
        if (init_calib_complete = '1' and start_write = '1') then
          init_complete <= '1';
        elsif (cycle_cnt > 3) then
          init_complete <= '0';
        end if;
      end if;
    end if;
  end process;    

  -- BRAM to DDR addr
  process(clk, reset)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        cnt_addr_ddr_wr <= (others => '0');
      else
        if (state = WRITE_BUFF) then 
          if (cnt_addr_ddr_wr > MAX_DATA - 1) then
             cnt_addr_ddr_wr <= (others => '0');
          else
             cnt_addr_ddr_wr <= cnt_addr_ddr_wr + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- DDR to BRAM addr
  process(clk, reset)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        cnt_addr_ddr_rd <= (others => '0');
        we_fovea_out <= '0';
      else
        if (state = READ_BUFF) then
          if (cnt_addr_ddr_rd > MAX_DATA) then
             cnt_addr_ddr_rd <= (others => '0');
          else
             cnt_addr_ddr_rd <= cnt_addr_ddr_rd + 1;
             we_fovea_out<= '1';
          end if;
        else
          we_fovea_out <= '0';
        end if;
      end if;
    end if;
  end process;
 
  process(clk, reset)
  begin
    if rising_edge(clk)then
     if (reset = '1') then
        cycle_cnt    <= 0;
        app_en          <= '0';
        app_cmd         <= "111"; -- Inactive
        s_app_addr      <= (others => '0');
        app_wdf_data    <= (others => '0'); 
        s_app_wdf_wren  <= '0';
        app_wdf_end     <= '0';
        write_buffer    <= (others => '0');
        write_index     <= 0;        
        read_buffer     <= (others => '0');
        read_index      <= 0;
        word_index      <= 0;
        bit_offset      <= 0;
        burst_cnt       <= 0;
        fovea_data_out  <= (others => '0');
     else
      case state is
          when IDLE =>
              if (init_complete = '1') then
                  state <= WRITE_BUFF;  
              else
                  state <= IDLE;
              end if;
              
          when WRITE_BUFF =>
            
            if (write_index = 39) then
              write_index <= 0;
              bit_offset <= 0;
              word_index <= 0;
              state <= SEND_CMD_WR;
            else
              s_app_addr <= to_unsigned(BURST_BLOCK_SIZE*cycle_cnt,27);    -- Update base address depending on the number of bursts 
              bit_offset <= (write_index mod 5) * 12; -- Position of the word in buffer
            -- Buffer filled with 5 data (1 word)
              if ((write_index mod 5) = 4) then
                word_index <= word_index + 1;
              end if;
            
              write_buffer((511 - (word_index * 64) - bit_offset) downto (511 - (word_index * 64) - bit_offset - 11)) <= fovea_data_in;
              write_index <= write_index + 1;
              state <= WRITE_BUFF;
            end if;
            
         when SEND_CMD_WR =>
              if (app_rdy = '1' and app_wdf_rdy = '1') then
                app_cmd <= CMD_WRITE;
                app_en  <= '1';
                state <= WRITE_BURST;
              end if;
              
          when WRITE_BURST =>
              if (burst_cnt > 7) then
                  s_app_wdf_wren <= '0';
                  app_wdf_end <= '0';  
                  state <= SEND_CMD_RD;  
                  burst_cnt <= 0;
              else
                 app_en  <= '0';
               if (app_wdf_rdy = '1') then
                s_app_wdf_wren <= '1';
                app_wdf_data <= write_buffer(511 - (burst_cnt * 64) downto (511 - burst_cnt * 64 - 63));
                burst_cnt <= burst_cnt + 1;
                state <= WRITE_BURST; 
                if (burst_cnt = 7) then
                  app_wdf_end <= '1';
                else
                  app_wdf_end <= '0';
                end if;
               end if;
              end if;
              
          when SEND_CMD_RD =>
          
            if (app_rdy = '1') then
              app_cmd <= CMD_READ;
              app_en  <= '1'; 
              state <= READ_BURST;
            end if;
          
          when READ_BURST =>   
             app_en  <= '0';       
              if (burst_cnt > 7) then  
                  state <= READ_BUFF;
                  burst_cnt <= 0;  
              else
               if (app_rdy = '1' and app_rd_data_valid = '1') then

                    read_buffer(511 - (burst_cnt * 64) downto (511 - burst_cnt * 64 - 63)) <= app_rd_data;
                    burst_cnt <= burst_cnt + 1;
                    state <= READ_BURST; 
                end if;
              end if;
              
          when READ_BUFF =>
            if (read_index = 39) then
             read_index <= 0;
             bit_offset <= 0;
             word_index <= 0;
              if (cycle_cnt > 3) then
                cycle_cnt  <= 0;
                state <= IDLE;
              else
                state <= WRITE_BUFF;
                cycle_cnt  <= cycle_cnt + 1;
              end if;
            else
                bit_offset <= (read_index mod 5) * 12;
            
              if (read_index mod 5) = 4 then
                word_index <= word_index + 1;
              end if;
      
                fovea_data_out <= read_buffer((511 - (word_index * 64) - bit_offset) downto (511 - (word_index * 64) - bit_offset - 11));
                read_index     <= read_index + 1;
                state <= READ_BUFF;
            end if;

          when others =>
              state <= IDLE;
      end case;
     end if;
   end if;
  end process;
  

  app_wdf_wren <= s_app_wdf_wren; 
  app_addr     <= std_logic_vector(s_app_addr);
  addr_ddr_wr  <= std_logic_vector(cnt_addr_ddr_wr); 
  addr_ddr_rd  <= std_logic_vector(cnt_addr_ddr_rd); 
  
end fovea_ddr_ctrl_arch;