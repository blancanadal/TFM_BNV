------------------------------------------------------------------
-- Name: ov7670_sccb
-- Description: Module that implements the SCCB interface between
-- NEXYS 4 DDR and ov7670 sensor
-- Author: Blanca Nadal Valle
------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity ov7670_sccb is         
	port(       
    Clk         :   in      std_logic;                      --  System clock input (50MHz)
    Reset       :   in      std_logic;                      --  Reset(active low) input
    IdAddress   :   in      std_logic_vector(7 downto 0);   --  SCCB slave device's address input
    IdRegister  :   in      std_logic_vector(7 downto 0);   --  SCCB slave device's register input
    WriteData   :   in      std_logic_vector(7 downto 0);   --  Data input
    Send        :   in      std_logic;                      --  Input for determine SCCB line is ready for another operation
    Done        :   out     std_logic;                      --  Output that alerts that a new register has been sent
    SIOD        :   inout   std_logic;                      --  SCCB serial data I/O
    SIOC        :   out     std_logic                       --  SCCB clock output
	);
end ov7670_sccb;

architecture ov7670_sccb_arch of ov7670_sccb is
    
    constant CLK_PERIOD    : time    := 20 ns;     -- System clock (50Mhz)
    constant SCCB_PERIOD   : time    := 2500 ns;   -- SCCB interface clock (400kHz)
    
    constant ClockCountMax : integer :=  (SCCB_PERIOD / CLK_PERIOD);

    type   PhaseWrite is (IDLE, START, SEND_ADDR, SEND_REG, SEND_DATA, DATA_DC, STOP);
    signal Current_State, Next_State : PhaseWrite;
    

    signal CounterSCCB      : integer range 0 to 31;  -- to generate the minimum frequency signal (SIOD reference)
    signal CounterSIOC      : integer range 0 to 3 ;  -- to generate SIOC reference signal
    signal BitCounter       : integer range 0 to 8 ;
    
    signal DataClockRef     : std_logic;
    signal DataClockRefPrev : std_logic;
    signal SIOCClock        : std_logic;
    signal SIOCClockPrev    : std_logic;
    signal SIOCInit         : std_logic;
    signal SIODReg          : std_logic;
    
    signal s_Addr           : std_logic_vector(7 downto 0);       
    signal s_Reg            : std_logic_vector(7 downto 0);       
    signal s_Data           : std_logic_vector(7 downto 0);
    signal AddrReg          : std_logic_vector(7 downto 0);       
    signal RegReg           : std_logic_vector(7 downto 0);       
    signal DataReg          : std_logic_vector(7 downto 0);         
    signal s_InitTrans      : std_logic;  
    signal InitTransReg     : std_logic;
    signal s_InitStop     : std_logic;  
    signal InitStopReg     : std_logic;
    signal s_send           : std_logic; 
    
    signal startBitCounter  : std_logic;

-- ILA --
--attribute mark_debug: string;
--attribute mark_debug of s_send          : signal is "true";
--attribute mark_debug of SIOC            : signal is "true";
--attribute mark_debug of SIOD            : signal is "true";
--attribute mark_debug of Done            : signal is "true";
--attribute mark_debug of BitCounter      : signal is "true";
--attribute mark_debug of Current_State   : signal is "true";
--attribute mark_debug of IdRegister      : signal is "true";
--attribute mark_debug of WriteData       : signal is "true";



  begin

  PROC_CLKGEN : process(Clk,Reset)
    begin
      if rising_edge(Clk) then
        if (Reset = '0') then
           SIOCClock    <= '1';
           DataClockRef <= '1';
           CounterSCCB  <= 0;
           CounterSIOC  <= 0;
         else
          SIOCClockPrev      <= SIOCClock;
          DataClockRefPrev   <= DataClockRef;   
				if (CounterSCCB = 15) then --(ClockCountMax / 4) - 1/2
					DataClockRef  <= not DataClockRef;
					if (CounterSIOC = 3) then
						SIOCClock   <= not SIOCClock;
						CounterSIOC <= 0;
					else
						CounterSIOC <= CounterSIOC + 1;
					end if;
					CounterSCCB	  <= 0;
				else
					CounterSCCB   <= CounterSCCB + 1;
				end if;
	       end if;
      end if;
    end process;
    
  DATA_CAPTURE : process(clk, Reset)
    begin
       if rising_edge(clk) then
        if(Reset = '0') then
            AddrReg        <= (others => '0');
            RegReg         <= (others => '0');
            DataReg        <= (others => '0');       
        
        else
            AddrReg    <= s_Addr;
            RegReg     <= s_Reg; 
            DataReg    <= s_Data;
        end if;
        end if;
    end process;
    
    
  BIT_COUNTER : process(clk, Reset)
    begin
        if rising_edge(clk) then
          if (Reset = '0') then
              BitCounter <= 0; 
          else         
            if (startBitCounter = '1') then
              if (DataClockRef = '1' and DataClockRefPrev = '0' and SIOCClock = '0' and SIOCClockPrev = '0') then
                if (BitCounter <= 7) then
                   BitCounter <= BitCounter + 1; 
                else
                   BitCounter  <= 0;
                end if;
              else
                null;
              end if;
            else
                BitCounter <= 0;
            end if;
          end if;
        end if;
    end process;
    
    
  SIOC  <=  SIOCInit when (Current_State = IDLE or Current_State = START or Current_State = STOP ) else SIOCClock;
  
  s_send <= Send;

  SIOD_REGISTER : process(clk, Reset)
   begin
    if rising_edge(clk) then    
        if (Reset = '0') then
            SIODReg <= '0';
            InitTransReg <= '0';
            InitStopReg <= '0';
        else       
            SIODReg <= SIOD;
            InitTransReg <= s_InitTrans;          
            InitStopReg <= s_InitStop;          
        end if;
    end if;
  end process;


  PROC_REG_CURRENT_STATE:
    process(Reset, Clk)
    begin
      if rising_edge(clk) then
        if (Reset = '0') then
            Current_State <= IDLE;  
        else       
            Current_State <= Next_State;
        end if;
      end if;
    end process PROC_REG_CURRENT_STATE;


  PROC_WRITE_STATE_MACHINE:
    process(Current_State, Next_State, Reset, Send, SIOCClock, SIOCClockPrev, InitTransReg, InitStopReg, DataClockRef, DataClockRefPrev,SIODReg, AddrReg, RegReg, DataReg, BitCounter, IdAddress, IdRegister, WriteData)
    begin
      
      Next_State <= Current_State;
      SIOD <= 'Z';
      Done <= '0';
      s_Addr <= AddrReg;
      s_Reg  <= RegReg;
      s_Data <= DataReg;
      s_InitTrans <= '0';
      s_InitStop <= '0';
      SIOCInit    <= '1';
      startBitCounter <= '0';
      
        case current_state is 
          when IDLE => 
              if (SIOCClock = '1' and SIOCClockPrev = '1'and DataClockRef = '1' and DataClockRefPrev = '0') then
                if (Send = '1') then
                    Next_State <= IDLE;
                    SIOD <= '1';
                    s_InitTrans <= '1';
                    s_Addr      <= IdAddress;
                    s_Reg       <= IdRegister;
                    s_Data      <= WriteData; 
                else 
                    Next_State <= IDLE; 
                    SIOD       <= 'Z';
                end if;
              elsif (SIOCClock = '0' and SIOCClockPrev = '0' and DataClockRef = '1' and DataClockRefPrev = '0' and InitTransReg = '1') then
                SIOD          <= '0';
                s_InitTrans   <= '0';
                Next_State    <= START;
              elsif (InitTransReg = '1') then
                Next_State <= IDLE;
                SIOD       <= SIODReg;
                s_InitTrans <= '1';
              else 
                Next_State <= IDLE;
                SIOD       <= SIODReg;
              end if;   
          
          when START =>
            SIOD <= '0'; 
            if (SIOCClock = '0' and SIOCClockPrev = '1') then
              SIOCInit    <= '0';
              Next_State  <= SEND_ADDR;
            else
              SIOCInit    <= '1';
              Next_State  <= START;             
            end if;
    
          when SEND_ADDR =>
           startBitCounter <= '1';
            if (DataClockRef = '1' and DataClockRefPrev = '0' and SIOCClock = '0' and SIOCClockPrev = '0') then
              if (BitCounter <= 7) then
                  if(AddrReg(7) = '1') then
                      SIOD    <= '1';
                      s_Addr  <= std_logic_vector(shift_left(unsigned(AddrReg), 1));
                  elsif (AddrReg(7) = '0') then
                      SIOD    <= '0';
                      s_Addr   <= std_logic_vector(shift_left(unsigned(AddrReg), 1));
                  end if;
                Next_State <= SEND_ADDR;  
              else
                  SIOD       <= 'Z'; -- Don't Care Bit!
                  startBitCounter <= '0';
                  Next_State <= SEND_REG;
              end if;
            else
                Next_State  <= SEND_ADDR;
                SIOD        <= SIODReg;
            end if;

          when SEND_REG =>
           startBitCounter <= '1';
           if (DataClockRef = '1' and DataClockRefPrev = '0' and SIOCClock = '0' and SIOCClockPrev = '0') then
             if (BitCounter <= 7) then
                 if(RegReg(7) = '1') then
                     SIOD    <= '1';
                     s_Reg  <= std_logic_vector(shift_left(unsigned(RegReg), 1));
                 elsif (RegReg(7) = '0') then
                     SIOD    <= '0';
                     s_Reg   <= std_logic_vector(shift_left(unsigned(RegReg), 1));
                 end if;
               Next_State <= SEND_REG;  
             else
                 SIOD       <= 'Z'; -- Don't Care Bit!
                 startBitCounter <= '0';
                 Next_State <= SEND_DATA;
             end if;
           else
               Next_State  <= SEND_REG;
               SIOD        <= SIODReg;
           end if;
          
          when SEND_DATA =>
           startBitCounter <= '1';
           if (DataClockRef = '1' and DataClockRefPrev = '0' and SIOCClock = '0' and SIOCClockPrev = '0') then
             if (BitCounter <= 7) then
                 if(DataReg(7) = '1') then
                     SIOD    <= '1';
                     s_Data  <= std_logic_vector(shift_left(unsigned(DataReg), 1));
                 elsif (DataReg(7) = '0') then
                     SIOD    <= '0';
                     s_Data   <= std_logic_vector(shift_left(unsigned(DataReg), 1));
                 end if;
               Next_State <= SEND_DATA;  
             else
                 SIOD       <= 'Z'; -- Don't Care Bit!
                 startBitCounter <= '0';
                 Next_State <= DATA_DC;
             end if;
           else
               Next_State  <= SEND_DATA;
               SIOD        <= SIODReg;
           end if;       

          when DATA_DC =>
            if (DataClockRef = '1' and DataClockRefPrev = '0' and SIOCClock = '0' and SIOCClockPrev = '0') then
                SIOD        <= '0';
                s_Addr <= (others => '0');
                s_Reg  <= (others => '0');
                s_Data <= (others => '0');
                Next_State <= STOP;
            else
              Next_State <= DATA_DC;
              SIOD       <= SIODReg;
            end if;
            
            
          when STOP =>

              if (DataClockRef = '1' and DataClockRefPrev = '0' and SIOCClock = '0' and SIOCClockPrev = '0') then
                    Next_State  <= STOP;
                    SIOD        <= '1';
                    SIOCInit    <= '1';
                    s_InitTrans <= '1';
                    Done        <= '0';
              elsif (DataClockRef = '1' and DataClockRefPrev = '0' and SIOCClock = '1' and SIOCClockPrev = '1' and InitTransReg = '1') then 
                    Next_State  <= IDLE;
                    SIOD        <= 'Z';
                    SIOCInit    <= '1';
                    s_InitTrans <= '0';
                    Done        <= '1';
                    
              elsif (InitTransReg = '1') then
                      s_InitTrans <= '1';
                      Next_State <= STOP;
                      SIOD       <= SIODReg;
                      SIOCInit   <= '1';
                      
              elsif (InitStopReg = '1') then
                    s_InitStop <= '1';
                    SIOCInit   <= '1';
                    Next_State <= STOP;
                    SIOD       <= SIODReg; 
             elsif (SIOCClock = '1' and SIOCClockPrev = '0') then
                    s_InitStop <= '1';
                    SIOD       <= SIODReg;
                    SIOCInit   <= '1';                        
              else
                Next_State <= STOP;
                SIOD       <= SIODReg;
                SIOCInit   <= '0';
              end if;
        end case;
    end process;
  
end ov7670_sccb_arch;