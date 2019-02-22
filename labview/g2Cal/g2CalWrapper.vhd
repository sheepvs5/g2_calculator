----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2019/02/12 14:49:45
-- Design Name: 
-- Module Name: g2CalWrapper - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

Entity g2CalWrapper is
    Port ( clk : in STD_LOGIC;
       RST : in STD_LOGIC;
       a1 : in STD_LOGIC_VECTOR (31 downto 0);
       a1V : in STD_LOGIC;
       a1R : out STD_LOGIC;
       a2 : in STD_LOGIC_VECTOR (31 downto 0);
       a2V : in STD_LOGIC;
       a2R : out STD_LOGIC;
       g2Dat : out STD_LOGIC_VECTOR (31 downto 0);
       g2V : out STD_LOGIC;
       g2R : in STD_LOGIC);
End g2CalWrapper;

ARCHITECTURE Behavioral of g2CalWrapper is

component g2Cal
    Port ( clk : in STD_LOGIC;
           RST : in STD_LOGIC;
           a1 : in STD_LOGIC_VECTOR (31 downto 0);
           a1V : in STD_LOGIC;
           a1R : out STD_LOGIC;
           a2 : in STD_LOGIC_VECTOR (31 downto 0);
           a2V : in STD_LOGIC;
           a2R : out STD_LOGIC;
           g2Dat : out STD_LOGIC_VECTOR (31 downto 0);
           g2V : out STD_LOGIC;
           g2R : in STD_LOGIC);
end component;

begin

g2CalWrapped : g2Cal
    port map (
        clk => clk,
        RST => RST,
        a1 => a1,
        a1V => a1V,
        a1R => a1R,
        a2 => a2,
        a2V => a2V,
        a2R => a2R,
        g2Dat => g2Dat,
        g2V => g2V,
        g2R => g2R);

end Behavioral;
