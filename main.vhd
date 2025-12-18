library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity main is
	port(
		reset_button: in std_logic;
		clk_12mhz : in std_logic;
		vga_rgb : out std_logic_vector(5 downto 0);
		vga_HSYNC : out std_logic;
		vga_VSYNC : out std_logic;
		debug_leds : out std_logic_vector(2 downto 0);
		nes_data : in std_logic ;
		nes_clk : out std_logic;
		nes_latch : out std_logic
	);
end main;

architecture synth of main is

component ramdp is
  generic (
    WORD_SIZE : natural := 8; -- Bits per word (read/write block size)
    N_WORDS : natural := 16; -- Number of words in the memory
    ADDR_WIDTH : natural := 4 -- This should be log2 of N_WORDS; see the Big Guide to Memory for a way to eliminate this manual calculation
   );
  port (
    clk : in std_logic;
    r_addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    r_data : out std_logic_vector(WORD_SIZE - 1 downto 0);
    w_addr : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
    w_data : in std_logic_vector(WORD_SIZE - 1 downto 0);
    w_enable : in std_logic
  );
end component;
component mypll is
    port(
        ref_clk_i: in std_logic; -- input clock
        rst_n_i: in std_logic; -- reset (active low)
        outcore_o: out std_logic; -- output to pins
        outglobal_o: out std_logic -- output for clock network
    );
end component;



component vga is
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
	
	end_of_frame : out std_logic

);
end component;

component nes is
  port(
		data : in std_logic := '0';
		oscclk : in std_logic;
		clk : out std_logic;
		latch : out std_logic;
		output : out std_logic_vector(7 downto 0)
	);
end component;
  component apple_rom is
    port(
      clk : in std_logic;
      xin : in unsigned(9 downto 0); -- 64 words total
      yin : in unsigned(9 downto 0); -- 64 words total
      xshift : in unsigned(4 downto 0);
      yshift : in unsigned(4 downto 0);
      data : out std_logic_vector(5 downto 0) -- 6-bit words, RRGGBB
    );
  end component;

  component snake_head_rom is
    port(
      clk : in std_logic;
      xin : in unsigned(9 downto 0); -- 64 words total
      yin : in unsigned(9 downto 0); -- 64 words total
      xshift : in unsigned(4 downto 0);
      yshift : in unsigned(4 downto 0);
      direction : in std_logic_vector(1 downto 0);
      data : out std_logic_vector(5 downto 0) -- 6-bit words, RRGGBB
    );
  end component;
	component numbers_rom is
		port (
			x     : in  std_logic_vector(7 downto 0);
			y     : in  std_logic_vector(3 downto 0);
			pixel : out std_logic_vector(5 downto 0)
		);
	end component;

	component start_rom is
	  port (
		x     : in  std_logic_vector(7 downto 0);
		y     : in  std_logic_vector(6 downto 0);
		pixel : out std_logic_vector(5 downto 0)
	  );
	end component;
	
	component gameover_rom is
	  port (
		x     : in  std_logic_vector(7 downto 0);
		y     : in  std_logic_vector(6 downto 0);
		pixel : out std_logic_vector(5 downto 0)
	  );
end component;

component currscore_rom is
  port (
    x     : in  std_logic_vector(4 downto 0);
    y     : in  std_logic_vector(3 downto 0);
    pixel : out std_logic_vector(5 downto 0)
  );
end component;

component highscore_rom is
  port (
    x     : in  std_logic_vector(4 downto 0);
    y     : in  std_logic_vector(3 downto 0);
    pixel : out std_logic_vector(5 downto 0)
  );
end component;
signal clk_pll : std_logic;



type GAME_STATE is (START, START_RESET, RESET, PLAYING, DEAD);
signal cur_game_state : GAME_STATE;

type GAMETICK_STEP is (READ_HEAD, READ_HEAD_WAIT, HEAD_LOGIC, DECREMENT_TAIL_READ, DECREMENT_TAIL_READ_WAIT, DECREMENT_TAIL_WRITE, DECREMENT_TAIL_WRITE_WAIT, GROW_HEAD, GROW_HEAD_WAIT, PLACE_APPLE_READ, PLACE_APPLE_READ_WAIT, PLACE_APPLE_WRITE, PLACE_APPLE_WRITE_WAIT, PRE_DRAW, DRAW);
signal cur_gametick_step :  GAMETICK_STEP;
signal loop_iterator : unsigned (7 downto 0);
signal reset_loop_iterator : unsigned (7 downto 0);

signal snake_head : unsigned (7 downto 0);
signal snake_length : unsigned (7 downto 0);

type DIRECTION is (UP, DOWN, LEFT, RIGHT);
signal prev_step_dir : DIRECTION; -- 0 => up, 1 => down, 2 => left, 3 => right
signal prev_step_dir_back : DIRECTION; -- opposite of prev_step_dir, used to make sure user doesn't try to go backwards
signal user_step_dir : DIRECTION;
signal next_step_dir : DIRECTION;
signal next_snake_head : unsigned (7 downto 0);
signal next_snake_in_wall : std_logic;

signal game_board_r_addr : std_logic_vector (7 downto 0);
signal game_board_r_data : std_logic_vector (7 downto 0);
signal game_board_w_addr : std_logic_vector (7 downto 0);
signal game_board_w_data : std_logic_vector (7 downto 0);
signal game_board_w_enable : std_logic; 

signal need_to_place_apple : std_logic;
signal rng_out : unsigned (31 downto 0);

signal frame_counter : unsigned (7 downto 0);

signal debug_leds_state: std_logic_vector (2 downto 0);


signal vga_row_grid: unsigned(9 downto 0);
signal vga_row_block: unsigned(9 downto 0);
	
signal vga_col_grid: unsigned(9 downto 0);
signal vga_col_block: unsigned(9 downto 0);

signal vga_row: unsigned(9 downto 0);
signal vga_col: unsigned(9 downto 0);

signal vga_valid : std_logic;
signal vga_end_of_frame : std_logic;


signal arrow_buttons : std_logic_vector(3 downto 0); -- 0 => up, 1 => down, 2 => left, 3 => right
signal nes_output : std_logic_vector(7 downto 0);

signal apple_rom_data : std_logic_vector(5 downto 0);
signal snake_head_data : std_logic_vector(5 downto 0);
signal numbers_rom_data : std_logic_vector(5 downto 0);
signal start_rom_data : std_logic_vector(5 downto 0);
signal gameover_rom_data : std_logic_vector(5 downto 0);
signal currscore_rom_data : std_logic_vector(5 downto 0);
signal highscore_rom_data : std_logic_vector(5 downto 0);

signal snake_head_direction : std_logic_vector(1 downto 0);

signal score_tensdigit : unsigned(3 downto 0);
signal score_onesdigit : unsigned(3 downto 0);

signal highscore : unsigned (7 downto 0);

signal highscore_tensdigit : unsigned(3 downto 0);
signal highscore_onesdigit : unsigned(3 downto 0);

signal score_displaydigit : unsigned(3 downto 0);



signal in_gameboard_area : std_logic;
signal right_columns : std_logic_vector(3 downto 0);
signal right_rows : std_logic_vector(3 downto 0);

signal right_vga :  std_logic_vector(5 downto 0);
begin

	debug_leds <= arrow_buttons(2 downto 0);
	arrow_buttons(0) <= nes_output(3);
	arrow_buttons(1) <= nes_output(2);
	arrow_buttons(2) <= nes_output(1);
	arrow_buttons(3) <= nes_output(0);
	
	score_onesdigit <= resize(snake_length mod 10, 4);
	score_tensdigit <= (snake_length * 7d"52")(12 downto 9);
	highscore_onesdigit <= resize(highscore mod 10, 4);
	highscore_tensdigit <= (highscore * 7d"52")(12 downto 9);
	
	right_columns(3) <= '1' when (vga_col_grid = 16) else '0';
	right_columns(2) <= '1' when (vga_col_grid = 17) else '0';
	right_columns(1) <= '1' when (vga_col_grid = 18) else '0';
	right_columns(0) <= '1' when (vga_col_grid = 19) else '0';
	
	right_rows(3) <= '1' when (vga_row_grid = 5) else '0';
	right_rows(2) <= '1' when (vga_row_grid = 6) else '0';
	right_rows(1) <= '1' when (vga_row_grid = 7) else '0';
	right_rows(0) <= '1' when (vga_row_grid = 8) else '0';
	
	in_gameboard_area <= '1' when (vga_col_grid < 16) else '0';
	score_displaydigit <= score_tensdigit when (right_columns(2) = '1' and right_rows(2) = '1') else 
						  score_onesdigit when (right_columns(1) = '1' and right_rows(2) = '1') else 
						  highscore_tensdigit when (right_columns(2) = '1' and right_rows(0) = '1') else 
						  highscore_onesdigit;

				
	pll : mypll port map (
				  ref_clk_i => clk_12mhz,
				  rst_n_i => '1',
				  outcore_o => clk_pll,
				  outglobal_o => open);
				  
	vga_display : vga port map (
						  clk_pll => clk_pll,
						  HSYNC => vga_HSYNC,
						  VSYNC => vga_VSYNC,
						  valid => vga_valid,
						  row_grid => vga_row_grid,
						  row_block => vga_row_block,
						  col_grid => vga_col_grid,
						  col_block => vga_col_block,
						  row => vga_row,
						  col => vga_col,
						  end_of_frame => vga_end_of_frame

					  );
						  
	-- the game board stores the state of the game as well as visual information
	game_board : ramdp generic map (WORD_SIZE => 8, N_WORDS => 256, ADDR_WIDTH => 8)
					   port map (clk => clk_pll,
	 						     r_addr => game_board_r_addr, 
	 						     r_data => game_board_r_data, 
	 						     w_addr => game_board_w_addr, 
	 						     w_data => game_board_w_data, 
	 						     w_enable => game_board_w_enable);

	
	nes_1 : nes port map (data => nes_data,
						   oscclk => clk_pll,
						   clk => nes_clk,
						   latch => nes_latch,
						   output => nes_output);
						   
	snake_head_1 : snake_head_rom port map(clk => clk_pll, 
										xin => 10d"0", 
										yin => 10d"0", -- 00 down, 01 right, 10 up, 11 left;
										yshift => vga_row_block(4 downto 0), 
										xshift => vga_col_block(4 downto 0), 
										direction => snake_head_direction,
										data => snake_head_data);
										
	apple_1 : apple_rom port map(clk => clk_pll, 
							  xin => 10d"0", 
							  yin => 10d"0", 
							  yshift => vga_row_block(4 downto 0), 
							  xshift => vga_col_block(4 downto 0), 
							  data => apple_rom_data);
							  
	numbers_rom_1 : numbers_rom
					port map(
						y => std_logic_vector(vga_row_block(3 downto 0)), 
						x => std_logic_vector(score_displaydigit) & std_logic_vector(vga_col_block(3 downto 0)), 
							  
						pixel => numbers_rom_data
					);				
					
	start_rom_1 : start_rom
	  port map(
		x     => std_logic_vector(vga_col(9 downto 2)),
		y     => std_logic_vector(vga_row(8 downto 2)),
		pixel => start_rom_data
	  );

gameover_rom_1 : gameover_rom
  port map(
		x     => std_logic_vector(vga_col(9 downto 2)),
		y     => std_logic_vector(vga_row(8 downto 2)),
    pixel => gameover_rom_data
  );
  
  currscore_rom_1 : currscore_rom
  port map(
    x     => right_columns(1) & std_logic_vector(vga_col_block(3 downto 0)),
    y     => std_logic_vector(vga_row_block(3 downto 0)),
    pixel => currscore_rom_data
  );
  highscore_rom_inst : highscore_rom
  port map(
    x     => right_columns(1) & std_logic_vector(vga_col_block(3 downto 0)),
    y     => std_logic_vector(vga_row_block(3 downto 0)),
    pixel => highscore_rom_data
  );


	snake_head_direction <= "00" when (prev_step_dir = DOWN) else
							 "01" when (prev_step_dir = RIGHT) else
							 "10" when (prev_step_dir = UP) else
							 "11" when (prev_step_dir = LEFT);
							 
							 
	
	-- update user_step_dir based on arrow_buttons; this needs to be async  to detect presses between frames
	process (arrow_buttons) is
	begin 
		if (arrow_buttons(0)) then
			user_step_dir <= UP;
		end if;
		if (arrow_buttons(1)) then
			user_step_dir <= DOWN;
		end if;
		if (arrow_buttons(2)) then
			user_step_dir <= LEFT;
		end if;
		if (arrow_buttons(3)) then
			user_step_dir <= RIGHT;
		end if;
	end process;
	
	
	-- implement prev_step_dir_back
	prev_step_dir_back <= DOWN when (prev_step_dir = UP) else
						  UP when (prev_step_dir = DOWN) else
						  LEFT when (prev_step_dir = RIGHT) else
						  RIGHT;
	-- calculate next_step_dir: it is the user_step_dir, unless the user is trying to go backwards in which it is prev_step_dir
	next_step_dir <= prev_step_dir when (user_step_dir = prev_step_dir_back) else user_step_dir;
	-- calculate next_snake_head: it is snake_head stepped once in the direction of next_step_dir
	next_snake_head <= snake_head - 16 when (next_step_dir = UP) else
					   snake_head + 16 when (next_step_dir = DOWN) else
					   snake_head - 1 when (next_step_dir = LEFT) else
					   snake_head + 1;
	next_snake_in_wall <= '1' when (
							(snake_head(7 downto 4) = 4d"0" and next_step_dir = UP) or
							(snake_head(7 downto 4) = 4d"14" and next_step_dir = DOWN) or
							(snake_head(3 downto 0) = 4d"0" and next_step_dir = LEFT) or
							(snake_head(3 downto 0) = 4d"15" and next_step_dir = RIGHT)
						) else '0';
	
	
	
	
	process (clk_pll) is
	begin		
		
		if (rising_edge(clk_pll)) then
		    -- automatically reset game_board to read if wrote in previous step			
			if(reset_button) then
				cur_game_state <= START;
				
			else 
				case (cur_game_state) is 
					when START =>
						if (nes_output(4)= '1') then
							cur_game_state <= START_RESET;
						end if;
						highscore <= 8d"0";
					when PLAYING => 
						case (cur_gametick_step) is
						
							when READ_HEAD => 
								game_board_r_addr <= std_logic_vector(next_snake_head);
								cur_gametick_step <= READ_HEAD_WAIT;
							when READ_HEAD_WAIT => 
								cur_gametick_step <= HEAD_LOGIC;
							when HEAD_LOGIC =>
								prev_step_dir <= next_step_dir;
								if (next_snake_in_wall) then
									cur_game_state <= DEAD;

								elsif (game_board_r_data = 8d"0") then
									-- snake is going into empty space. decrement the tail and then write the new head
									
									cur_gametick_step <= DECREMENT_TAIL_READ;
									snake_head <= next_snake_head; 
									loop_iterator <= 8d"0";
								elsif (game_board_r_data = 8d"255") then

									snake_length <= snake_length + 1;
									cur_gametick_step <= GROW_HEAD;
									need_to_place_apple <= '1';
									snake_head <= next_snake_head; 

								else
									-- snake ran into wall or itself
									cur_game_state <= DEAD;
								end if;
								
							
							when DECREMENT_TAIL_READ =>
								cur_gametick_step <= DECREMENT_TAIL_READ_WAIT;
								game_board_r_addr <= std_logic_vector(loop_iterator);
								
							when DECREMENT_TAIL_READ_WAIT =>
								cur_gametick_step <= DECREMENT_TAIL_WRITE;
								
							when DECREMENT_TAIL_WRITE =>
								game_board_w_enable <= '1';
								game_board_w_addr <= std_logic_vector(loop_iterator);
								game_board_w_data <= 8d"255" when (game_board_r_data = 8d"255") else 
													8d"0" when(game_board_r_data = 8d"0") else 
													std_logic_vector(unsigned(game_board_r_data) - 1);
								cur_gametick_step <= DECREMENT_TAIL_WRITE_WAIT;
								
							when DECREMENT_TAIL_WRITE_WAIT =>
								if (loop_iterator = 255) then
									cur_gametick_step <= GROW_HEAD; -- we're done shrinking the tail so grow the head
								else 
									loop_iterator <= loop_iterator + 1;
									cur_gametick_step <= DECREMENT_TAIL_READ;
								end if;
								game_board_w_enable <= '0';
							when GROW_HEAD =>
								-- make the new head position the snake length
								-- next step: place an apple if necessary
								cur_gametick_step <= GROW_HEAD_WAIT;

								game_board_w_addr <= std_logic_vector(snake_head);
								game_board_w_data <= std_logic_vector(snake_length);
								game_board_w_enable <= '1';
							when GROW_HEAD_WAIT =>
								cur_gametick_step <= PLACE_APPLE_READ;
								game_board_w_enable <= '0';
								
							when PLACE_APPLE_READ =>
								if (need_to_place_apple) then
									game_board_r_addr <= std_logic_vector(rng_out(7 downto 0));
									cur_gametick_step <= PLACE_APPLE_READ_WAIT;

								else 
									cur_gametick_step <= PRE_DRAW;

									-- go to draw step since we don't need to place an apple
								end if;	
								
							when PLACE_APPLE_READ_WAIT =>
								cur_gametick_step <= PLACE_APPLE_WRITE;
		

							when PLACE_APPLE_WRITE =>
								
								if (game_board_r_data = 8d"0" and rng_out(7 downto 4) /= 15) then
									need_to_place_apple <= '0';
									game_board_w_data <= 8d"255";
									game_board_w_addr <= std_logic_vector(rng_out(7 downto 0));
									game_board_w_enable <= '1';
									cur_gametick_step <= PLACE_APPLE_WRITE_WAIT;
								else
									cur_gametick_step <= PRE_DRAW;

								end if;
								
							when PLACE_APPLE_WRITE_WAIT =>
								game_board_w_enable <= '0';

								cur_gametick_step <= PRE_DRAW;

							when PRE_DRAW =>
								cur_gametick_step <= DRAW;
								game_board_r_addr <= std_logic_vector(vga_row_grid(3 downto 0) & vga_col_grid(3 downto 0));
								game_board_w_enable <= '0';

							when DRAW =>
								

								if (vga_end_of_frame = '1') then
									if (frame_counter = 10) then
										frame_counter <= 8d"0";
										cur_gametick_step <= READ_HEAD;
									else
										frame_counter <= frame_counter + 1;
									end if;
								end if;
								
								rng_out <= resize((rng_out * 1664525 + 1013904223), 32);
								game_board_r_addr <= std_logic_vector((vga_row_grid(3 downto 0)) & (vga_col_grid(3 downto 0)));
								
								if (snake_length > highscore) then
									highscore <= snake_length;

								end if;
								
						end case; 
						
					when START_RESET =>
						debug_leds_state <= "001";

						reset_loop_iterator <= 8d"0";
						cur_game_state <= RESET;
						
					when RESET =>
						if (reset_loop_iterator = 255) then
							cur_game_state <= PLAYING;
							cur_gametick_step <= PRE_DRAW;
							snake_head <= 4d"8" & 4d"8";
							snake_length <= 8d"3"; 
							debug_leds_state <= "011";
							need_to_place_apple <= '1';
							
						else 
							reset_loop_iterator <= reset_loop_iterator + 1;
							debug_leds_state <= "010";

						end if;
						
						game_board_w_addr <= std_logic_vector(reset_loop_iterator); 
						game_board_w_data <= 8d"0";
						game_board_w_enable <= '1';
					when DEAD =>
					    if (nes_output(7)= '1') then
							cur_game_state <= START_RESET;
						end if;
				end case;
			end if;
		end if;

	end process;


	right_vga <= "111111" when (right_columns(0) = '1' or right_columns(3) = '1') else
					numbers_rom_data when (right_rows(0) = '1' or right_rows(2) = '1') else
					currscore_rom_data when (right_rows(3) = '1') else
					highscore_rom_data when (right_rows(1) = '1') else
					"111111";
	
	vga_rgb <= "000000" when (not vga_valid) else
			   start_rom_data when (cur_game_state = START) else
			   gameover_rom_data when (cur_game_state = DEAD) else
			   right_vga when (in_gameboard_area = '0') else
			   snake_head_data when (game_board_r_addr = std_logic_vector(snake_head)) else
			   "000000" when (game_board_r_data = 8d"0") else
			   apple_rom_data when (game_board_r_data = 8d"255") else
			   "001001";
			  


end;


