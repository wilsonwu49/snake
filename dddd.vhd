library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dddd is
  port(
    value : in unsigned(5 downto 0);    
    tensdigit : out std_logic_vector(6 downto 0);    
    onesdigit : out std_logic_vector(6 downto 0)
  );
end dddd;

architecture sim of dddd is

component sevenseg is
  port(
	  S : in unsigned(3 downto 0);
	  segments : out std_logic_vector(6 downto 0)
  );
end component;

signal lowBCD : unsigned(3 downto 0);
signal tensplace : unsigned(12 downto 0);
signal highBCD : unsigned(3 downto 0);

begin

lowBCD <= value mod 4d"10";
tensplace <= value * 7d"52";
highBCD <= tensplace(12 downto 9);

sevenseg_1 : sevenseg port map(S => lowBCD, segments => onesdigit);
sevenseg_2 : sevenseg port map(S => highBCD, segments => tensdigit);
end;


