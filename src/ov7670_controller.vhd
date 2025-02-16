-------------------------------------------------------------------------
-- Name: ov7670_controller
-- Description: Module that links the SCCB protocol and the configuration
-- registers
-- Author: Blanca Nadal Valle
-------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
  
entity ov7670_controller is
  port ( 
     clk50         : in    std_logic;
     clk25         : in    std_logic;
     reset         : in    std_logic;
     resend        : in    std_logic;
     config_finish : out   std_logic;
     SIOC          : out   std_logic;
     SIOD          : inout std_logic;
     pwdn          : out   std_logic;
     xclk          : out   std_logic
  );
end ov7670_controller;
  
  
architecture ov7670_controller_arch of ov7670_controller is


  constant cam_address: std_logic_vector(7 downto 0):= x"42";
  
  signal  s_command          : std_logic_vector(15 downto 0);
  signal  s_config_finished  : std_logic;
  signal  s_done             : std_logic;
  signal  s_send             : std_logic;
  signal  s_reset            : std_logic;

  
  component ov7670_registers
    port ( 
      clk             : in  std_logic;
      continue        : in  std_logic;
      resend          : in  std_logic;
      command         : out std_logic_vector(15 downto 0);
      config_finished : out std_logic
    );
  end component;
  
  component ov7670_sccb
    port(       
      Clk         :   in    std_logic;                    
      Reset       :   in    std_logic;                    
      IdAddress   :   in    std_logic_vector(7 downto 0); 
      IdRegister  :   in    std_logic_vector(7 downto 0); 
      WriteData   :   in    std_logic_vector(7 downto 0); 
      Send        :   in    std_logic;                    
      Done        :   out   std_logic;                    
      SIOD        :   inout std_logic;                    
      SIOC        :   out   std_logic                     
    );
  end component;


begin

  ov7670_registers_i: ov7670_registers
    port map (
    clk      => clk50,
    resend   => resend,
    continue => s_done,
    command  => s_command,
    config_finished => s_config_finished   
    );


  ov7670_sccb_i: ov7670_sccb
    port map (
    Clk        => clk50,
    Reset      => reset, -- bntr
    IdAddress  => cam_address,
    IdRegister => s_command(15 downto 8),
    WriteData  => s_command(7 downto 0),
    Send       => s_send, 
    Done       => s_done,
    SIOD       => SIOD,
    SIOC       => SIOC
    );
    
    s_send        <= not s_config_finished;
    config_finish <= s_config_finished;
    pwdn          <= '0';   -- Normal operation
    xclk          <= clk25;
    
    
end ov7670_controller_arch;