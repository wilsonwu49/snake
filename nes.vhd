library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity nes is
  port(
		data : in std_logic := '0';
		oscclk : in std_logic;
		clk : out std_logic;
		latch : out std_logic;
		output : out std_logic_vector(7 downto 0) := "00000000"
	);
end nes;
 
architecture synth of nes is

component HSOSC is
generic (
	CLKHF_DIV : String := "0b00"); -- Divide 48MHz clock by 2ˆN (0-3)
port(
	CLKHFPU : in std_logic := 'X'; 
 	CLKHFEN : in std_logic := 'X'; 
	CLKHF : out std_logic := 'X');
end component;

	signal NESclk : std_logic;
    signal NEScounter : unsigned(7 downto 0) := 8b"0";
	signal counter : unsigned(25 downto 0) := 26b"0";
	signal copy_reg : std_logic_vector(7 downto 0) := "00000000";
	
begin

				  
	process(oscclk) begin
		if rising_edge(oscclk) then
			counter <= counter + 1;
			
			if (NEScounter > d"8") then
				output <= not copy_reg;
			end if;
		end if;
		
		
	end process;
	
	NESclk <= counter(8);
	NEScounter <= counter(16 downto 9);
	
	latch <= '1' when NEScounter = X"FF" else '0';
	clk <= NESclk when NEScounter < d"8" else '0';
	
	
	process(clk)begin
		if rising_edge(clk) then
			copy_reg(0) <= data;
			copy_reg(1) <= copy_reg(0);
			copy_reg(2) <= copy_reg(1);
			copy_reg(3) <= copy_reg(2);
			copy_reg(4) <= copy_reg(3);
			copy_reg(5) <= copy_reg(4);
			copy_reg(6) <= copy_reg(5);
			copy_reg(7) <= copy_reg(6);
		end if;
	end process;
	
			
end;


