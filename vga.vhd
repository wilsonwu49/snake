library IEEE;
use IEEE.std_logic_1164.all;
use std.textio.all;
use IEEE.numeric_std.all;

entity vga is
port(
	clk_pll : in std_logic;
	HSYNC : out std_logic;
	VSYNC : out std_logic;
	valid : out std_logic;
	
	row_grid: out unsigned(9 downto 0);
	row_block: out unsigned(9 downto 0);
	
	col_grid: out unsigned(9 downto 0);
	col_block: out unsigned(9 downto 0);
	
	row : out unsigned(9 downto 0);
	col : out unsigned(9 downto 0);
	
	end_of_frame: out std_logic
);
end;

architecture synth of vga is

	signal row_next : unsigned(9 downto 0);
	signal col_next : unsigned(9 downto 0);

	
begin


		
	end_of_frame <= '1' when (col = 0 and row = 480) else '0';
				
	row_grid <= 5d"0" & row(9 downto 5);
	row_block <= 6d"0" & row(4 downto 1);
	col_grid <= 5d"0" & col(9 downto 5);
	col_block <= 6d"0" & col(4 downto 1);
					
	process (clk_pll) begin
		if rising_edge(clk_pll) then
			
			if (col_next < 800 - 1) then
				col_next <= col_next + 1;
				
			else
				col_next <= 10d"0";
				
				if (row_next < 525 - 1) then
					row_next <= row_next + 1;
					
				else
					row_next <= 10d"0";
	
				end if;
			end if;
			
			col <= col_next;
			row <= row_next;
			

			
			
		end if;
	end process;
	
	HSYNC <= '0' when (col >= 656 and col <= 656 + 96) else '1';
	VSYNC <= '0' when (row >= 490 and row <= 490 + 2) else '1';
	valid <= '1' when (col < 640 and row < 480) else '0';
end;
