library IEEE;
use IEEE.std_logic_1164.all;
use std.textio.all;
use IEEE.numeric_std.all;

entity pattern_gen is
port(
    valid : in std_logic;
	row : in unsigned(9 downto 0);
	col	: in unsigned(9 downto 0);
    rgb : out std_logic_vector(5 downto 0)
);
end;

architecture synth of pattern_gen is
begin
process (all) begin
	rgb <= "000000" when (row < 160 and col < 160 and valid = '1') else
	       "010000" when (row < 160 and col < 320 and valid = '1') else
	       "100000" when (row < 160 and col < 480 and valid = '1') else
	       "110000" when (row < 160 and col < 640 and valid = '1') else
	       "000000" when (row < 320 and col < 160 and valid = '1') else
	       "000100" when (row < 320 and col < 320 and valid = '1') else
	       "001000" when (row < 320 and col < 480 and valid = '1') else
	       "001100" when (row < 320 and col < 640 and valid = '1') else
	       "000000" when (row < 480 and col < 160 and valid = '1') else
	       "000001" when (row < 480 and col < 320 and valid = '1') else
	       "000010" when (row < 480 and col < 480 and valid = '1') else
	       "000011" when (row < 480 and col < 640 and valid = '1') else
		   "000000";
end process;
end;
