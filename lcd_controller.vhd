LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
--USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE  IEEE.NUMERIC_STD.all;
LIBRARY WORK;
USE WORK.Yakir_LCD.all;
-- SW8 (GLOBAL RESET) resets LCD
ENTITY lcd_controller IS
-- Enter number of Hex digit data values to display from hardware
-- (do not count ASCII character constants)
	GENERIC(Num_Hex_Digits: Integer:= 10); 
-------------------------- ---------------------------------------------
-- LCD Displays 16 Characters on 2 lines
-- lcd_test string is an ASCII character string entered in hex for 
-- the two lines of the  LCD Display   (See ASCII to hex table below)
-- Edit lcd_test_String entries above to modify display
-- Enter the ASCII character's 2 hex digit equivalent value
-- (see table below for ASCII hex values)
-- To display character assign ASCII value to lcd_test_string(x)
-- To skip a character use X"20" (ASCII space)
-- To dislay a "live" hex digit using values from hardware on LCD use the following: 
--   make array element for that character location X"0" & 4-bit field from Hex_Display_Data
--   state machine sees X"0" in high 4-bits & grabs the next lower 4-bits from Hex_Display_Data input
--   and performs 4-bit binary to ASCII conversion needed to print a hex digit
--   Num_Hex_Digits must be set to the count of hex data characters (ie. "00"s) in the display
--   Connect hardware bits to display to Hex_Display_Data input
-- To display less than 32 characters, terminate string with an entry of X"FE"
--  (fewer characters may slightly increase the LCD's data update rate)
------------------------------------------------------------------- 
--                        ASCII HEX TABLE
--  Hex						Low Hex Digit
-- Value  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
------\----------------------------------------------------------------
--H  2 |  SP  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
--i  3 |  0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
--g  4 |  @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
--h  5 |  P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
--   6 |  `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
--   7 |  p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~ DEL
-----------------------------------------------------------------------
-- Example "A" is row 4 column 1, so hex value is X"41"
-- *see LCD Controller's Datasheet for other graphics characters available
--
	PORT(reset, Clock			: IN	STD_LOGIC;
			index					: IN STD_LOGIC_VECTOR(1 downto 0);
			data_select			: IN STD_LOGIC_VECTOR(3 downto 0);
--			FFT_POS		:	IN STD_LOGIC_VECTOR(7 downto 0);
--			FFT_Detect		:  IN STD_LOGIC_VECTOR(1 downto 0);
--			ADB_Detect		: 	IN STD_LOGIC_VECTOR(7 downto 0);
--			ADB_PRI_Dec		:	IN STD_LOGIC_VECTOR(15 downto 0);
--			ADB_Tau_Dec		:	IN STD_LOGIC_VECTOR(15 downto 0);
			quotient,remain,Outposition_Data, Outposition_Freq			:in std_logic_vector(3 downto 0);
			 Numoffreqs,Numofdata,Mode					: in std_logic_vector(2 downto 0);
--			state_os							: in std_logic_vector(15 downto 0);
			IN_data						  	 : in std_logic_vector(95 downto 0);
			IN_freq_dec			   		 : in 	  std_logic_vector(15 downto 0);
		 LCD_RS, LCD_EN				: OUT	STD_LOGIC;
		 LCD_RW						: OUT   STD_LOGIC;
		 LCD_DATA					: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0));
		
END ENTITY lcd_controller;

ARCHITECTURE arch_lcd_controller OF lcd_controller IS
TYPE character_string IS ARRAY ( 0 TO 31 ) OF STD_LOGIC_VECTOR( 7 DOWNTO 0 );

TYPE STATE_TYPE IS (HOLD, FUNC_SET, DISPLAY_ON, MODE_SET, Print_String,
LINE2, RETURN_HOME, DROP_LCD_EN, RESET1, RESET2, 
RESET3, DISPLAY_OFF, DISPLAY_CLEAR);
SIGNAL state, next_command: STATE_TYPE;
SIGNAL lcd_test_string	: character_string;
-- Enter new ASCII hex data above for LCD Display
SIGNAL LCD_DATA_VALUE, Next_Char: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL CLK_COUNT_400HZ: STD_LOGIC_VECTOR(19 DOWNTO 0);
SIGNAL CHAR_COUNT: STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL CLK_400HZ_Enable,LCD_RW_INT : STD_LOGIC;
SIGNAL Line1_chars, Line2_chars: STD_LOGIC_VECTOR(127 DOWNTO 0);
BEGIN

		process(Clock, Reset)
		begin
				if Reset = '0' then
						lcd_test_string <=(X"57",X"61",X"69",X"74",X"69",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
											    X"6E",X"67",X"2E",X"2E",X"2E",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  --"waiting..."
				elsif rising_edge(Clock) then
					if CLK_400HZ_Enable = '1' then --Clock AND Enable pulse of 400Hz
											if (data_select="0000")then
												lcd_test_string <=(X"54",X"79",X"70",X"65",X"20",X"6E",X"75",X"6D",X"20",X"6F",X"66",X"20",X"20",X"20",X"20",X"20",
																		 X"66",X"72",X"65",X"71",X"73",X"20",X"61",X"6E",X"64",X"20",X"64",X"61",X"74",X"61",X"20",X"20");  -- "Type num of freqs and data"
											
--											elsif(data_select = "") then
--												lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",lcd_F_big,lcd_P,lcd_O,lcd_S,lcd_COLON,X"0" & Outposition_freq,X"20",X"20",X"20",X"20",
--																		 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  --"Fpos:X"
											
											elsif (data_select="0001")then
												lcd_test_string <=(X"4E",X"75",X"6D",X"20",X"6F",X"66",X"20",X"66",X"72",X"65",X"71",X"73",X"20",X"69",X"73",X"20",
																		 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"0"& ('0' & Numoffreqs),X"20",X"20",X"20",X"20",X"20",X"20",X"20");  -- "num of freqs is"
											elsif(data_select = "0010") then							 
												lcd_test_string <=(X"4E",X"75",X"6D",X"20",X"6F",X"66",X"20",X"64",X"61",X"74",X"61",X"20", X"69",X"73",lcd_COLON,X"20",
																		 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"0"& ('0' & Numofdata),X"20",X"20",X"20",X"20",X"20",X"20",X"20");  -- "num of data is"
											elsif(data_select = "0011") then							 
												lcd_test_string <=(X"20",X"20",X"20",lcd_M_big,lcd_O,lcd_D,lcd_E,lcd_COLON,X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
																		 X"20",X"20",X"20",X"20",X"20",X"0"& ('0' & Mode),X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  --Mode:
--											elsif(data_select = "0100") then							 
--												lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",lcd_F_big,lcd_P,lcd_O,lcd_S,lcd_COLON,X"0" & Outposition_freq,X"20",X"20",X"20",X"20",
--																		 X"20",X"20",X"20",X"20",X"20",X"20",X"0" & IN_freq_dec(15 downto 12),X"0" & IN_freq_dec(11 downto 8),X"0" & IN_freq_dec(7 downto 4),X"0" & IN_freq_dec(3 downto 0),lcd_K_big,lcd_H_big,lcd_Z_big,X"20",X"20",X"20");  --Fpos:/n XXX KHZ
											elsif(data_select = "0100") then							 
												lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",lcd_F_big,lcd_P,lcd_O,lcd_S,lcd_COLON,X"0" & Outposition_freq,X"20",X"20",X"20",X"20",
																		 X"20",X"20",X"20",X"20",X"20",X"20",X"0" & IN_freq_dec(3 downto 0),X"0" & IN_freq_dec(7 downto 4),X"0" & IN_freq_dec(11 downto 8),X"20",lcd_K_big,lcd_H_big,lcd_Z_big,X"20",X"20",X"20");  --Fpos:/n XXX KHZ
											elsif(data_select = "0101") then				
												lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",lcd_F_big,lcd_P,lcd_O,lcd_S,lcd_COLON,X"0" & Outposition_freq,X"20",X"20",X"20",X"20",
																		 X"20",X"20",X"20",X"20",X"20",X"20",lcd_1,lcd_M_big,lcd_H_big,lcd_Z_big,X"20",X"20",X"20",X"20",X"20",X"20");  --Fpos:X/n 1MHZ
											elsif(data_select = "0110") then							 
												lcd_test_string <=(lcd_D_big,lcd_P,lcd_O,lcd_S,lcd_COLON,X"0" & Outposition_Data,X"20",X"20",
																		 X"0" & IN_data(95 downto 92),X"0" & IN_data(91 downto 88),X"0" & IN_data(87 downto 84),X"0" & IN_data(83 downto 80),X"0" & IN_data(79 downto 76),X"0" & IN_data(75 downto 72),X"0" & IN_data(71 downto 68),X"0" & IN_data(67 downto 64),X"0" & IN_data(63 downto 60),X"0" & IN_data(59 downto 56),X"0" & IN_data(55 downto 52),X"0" & IN_data(51 downto 48),X"0" & IN_data(47 downto 44),X"0" & IN_data(43 downto 40),X"0" & IN_data(39 downto 36),X"0" & IN_data(35 downto 32),X"0" & IN_data(31 downto 28),X"0" & IN_data(27 downto 24),X"0" & IN_data(23 downto 20),X"0" & IN_data(19 downto 16),X"0" & IN_data(15 downto 12),X"0" & IN_data(11 downto 8),X"0" & IN_data(7 downto 4),X"0" & IN_data(3 downto 0));  --Dpos:X/n XXX
											elsif(data_select = "0111") then							 
												lcd_test_string <=(lcd_P_big,lcd_R,lcd_E,lcd_S,lcd_S,X"20",lcd_O_big,lcd_N,X"20",lcd_S_big,lcd_E,lcd_T,X"20",lcd_T_big,lcd_O,X"20",
																		 lcd_C_big,lcd_H,lcd_O,lcd_O,lcd_S,lcd_E,X"20",lcd_M_big,lcd_O,lcd_D,lcd_E,X"20",X"20",X"20",X"20",X"20");  --Press on Set to Choose mode
											elsif(data_select = "1010") then
												lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"44",X"6F",X"6E",X"65",X"21",X"20",X"20",X"20",X"20",X"20",  
																		 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  	--"Done!"
											
											elsif(data_select = "1001") then
												lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
																		 X"53",X"74",X"61",X"72",X"74",X"69",X"6E",X"67",X"2E",X"2E",X"2E",X"20",X"20",X"20",X"20",X"20");  -- "starting...""
											elsif(data_select = "1000") then
												lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
																		 X"53",X"74",X"6F",X"70",X"70",X"69",X"6E",X"67",X"2E",X"2E",X"2E",X"20",X"20",X"20",X"20",X"20");  --"stopping..."
											elsif(data_select = "1011") then
												lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",lcd_S_big,lcd_A,lcd_V,lcd_E,lcd_D,X"20",X"20",X"20",X"20",X"20",
																		 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  --"Saved"	
											
											
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
--						if (data_select="0000")then
--														lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"54",
--																				 X"79",X"70",X"65",X"20",X"6E",X"75",X"6D",X"20",X"6F",X"66",X"20",X"66",X"72",X"65",X"71",X"73",X"20",X"61",X"6E",X"64",X"20",X"64",X"61",X"74",X"61");  -- "Type num of freqs and data"
--						elsif (data_select = "0001") then--show num of freq
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"4E",X"75",X"6D",X"20",
--													 X"6F",X"66",X"20",X"66",X"72",X"65",X"71",X"73",X"20",X"69",X"73",X"0"& ('0' & Numoffreqs),X"20",X"20",X"20",X"20",X"20",X"20",X"20");  -- "num of freqs is"
--						elsif(data_select = "0010") then 
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"43",X"68",X"6F",X"6F",X"73",X"65",X"20",X"4D",X"6F",x"64",X"65",X"3A",  -- "Choose Mode:" 
--													 X"30",X"2D",X"53",X"74",X"72",X"20",X"31",x"2D",X"53",x"74",X"70",X"20",X"32",X"2D",X"4C",X"64");  -- "0-Str 1-Stp 2-Ld"(switches)					 
--						elsif(data_select = "0011") then						
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"54",X"79",X"70",X"65",X"20",X"6D",X"6F",X"64",X"65",X"3A",X"0"& ('0' & Numofload),X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  --"Type mode"
----						elsif(data_select = "0100") then	
----							lcd_test_string <=(X"50",X"72",X"65",X"73",X"73",X"20",X"53",X"57",X"35",X"20",X"74",X"6F",X"20",X"43",X"68",X"61", 
----													 X"6E",X"67",X"65",X"20",X"66",X"72",X"65",X"71",X"20",X"6F",X"72",X"20",X"64",X"61",X"74",X"61");  --"Press SW5 to change freq or data"				
----						elsif(data_select = "0101") then	
----							lcd_test_string <=(X"50",X"72",X"65",X"73",X"73",X"20",X"53",X"57",X"34",X"20",X"74",X"6F",X"20",X"43",X"68",X"61",  
----													 X"6E",X"67",X"65",X"20",X"69",X"6E",X"64",X"65",X"78",X"20",X"6F",X"72",X"20",X"66",X"72",X"71");  --"Press SW4 to change index or frq"
--						elsif(data_select = "0110") then	
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"69",X"6E",X"63",X"72",X"65",X"61",X"73",X"65",X"2F",X"64",X"65",  
--													 X"63",X"72",X"65",X"61",X"73",X"65",X"20",X"66",X"72",X"65",X"71",X"20",X"20",X"20",X"20",X"20");  --"increase/decrease freq"
--						elsif (data_select = "0111") then--show freq
--								lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"4E",X"65",X"77",X"20",X"76", 
--														 X"61",X"6C",X"75",X"65",X"0" & IN_freq_dec(7 downto 4),X"0" & IN_freq_dec(3 downto 0),X"30",X"30",X"4B",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  --"new value:"
----						elsif(data_select = "0101") then--show freq
----								lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"4E",X"65",X"77",X"20",X"76", 
----														 X"61",X"6C",X"75",X"65",X"0" & IN_freq_dec(15 downto 12),X"0" & IN_freq_dec(11 downto 8),X"0" & IN_freq_dec(7 downto 4),X"0" & IN_freq_dec(3 downto 0),X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  --"new value:"
--						elsif(data_select = "1000") then
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"53",X"74",X"61",X"72",X"74",
--													 X"69",X"6E",X"67",X"2E",X"2E",X"2E",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  -- "starting...""
--						elsif(data_select = "1001") then 
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"53",X"74",X"6F",X"70",X"70",
--													 X"69",X"6E",X"67",X"2E",X"2E",X"2E",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  --"stopping..."
--						elsif(data_select = "1010") then
--							lcd_test_string <=(X"20",X"4E",X"65",X"77",X"20",X"66",X"72",X"65",X"71",X"20",X"70",X"6F",X"73",X"69",X"74",X"73",X"6F",X"6E",X"3A",X"0" & Outposition_Freq,X"20",
--													 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  -- "New freq position:"
-- 						elsif(data_select = "1101") then
--							lcd_test_string <=(X"20",X"4E",X"65",X"77",X"20",X"64",X"61",X"74",X"61",X"20",X"70",X"6F",X"73",X"69",X"74",X"73",X"6F",X"6E",X"3A",X"0" & Outposition_Data,X"20",
--													 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  -- "New data position:"
----						elsif(data_select = "0101") then
----							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"3B",X"29",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",  
----													 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  	--";)"
--						elsif(data_select = "1011") then
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"44",X"6F",  
--													 X"6E",X"65",X"21",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  	--"Done!"
--						elsif(data_select = "1100") then
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"4E",X"65",X"77",X"20",X"69",X"6E",X"64",X"65",X"78",X"3A",X"0" &("00"&index), 
--													 X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20");  	--"New index:"
--						elsif (data_select = "1110") then
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"4E",X"75",X"6D",X"20",
--													 X"6F",X"66",X"20",X"64",X"61",X"74",X"61",X"20",X"20",X"69",X"73",X"0"& ('0' & Numofdata),X"20",X"20",X"20",X"20",X"20",X"20",X"20");  -- "num of data is"
--						elsif(data_select = "0100") then--show data
--							lcd_test_string <=(X"20",X"20",X"20",X"20",X"0" & IN_data(95 downto 92),X"0" & IN_data(91 downto 88),X"0" & IN_data(87 downto 84),X"0" & IN_data(83 downto 80),X"0" & IN_data(79 downto 76),X"0" & IN_data(75 downto 72),X"0" & IN_data(71 downto 68),X"0" & IN_data(67 downto 64),X"0" & IN_data(63 downto 60),X"0" & IN_data(59 downto 56),X"0" & IN_data(55 downto 52),X"0" & IN_data(51 downto 48),X"0" & IN_data(47 downto 44),X"0" & IN_data(43 downto 40),X"0" & IN_data(39 downto 36),X"0" & IN_data(35 downto 32),X"0" & IN_data(31 downto 28),X"0" & IN_data(27 downto 24),X"0" & IN_data(23 downto 20),X"0" & IN_data(19 downto 16),X"0" & IN_data(15 downto 12),X"0" & IN_data(11 downto 8),X"0" & IN_data(7 downto 4),X"0" & IN_data(3 downto 0),X"20",X"20",X"20",X"20");  --"new value:"
						end if;
					end if;
				end if;
		end process;

--lcd_test_string <=							
--	
----						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- .. "Current  Mission:"
----							X"4D",x"69",X"73",X"73",X"69",X"6F",X"6E",X"3A",  -- ..
----							X"20",X"20",X"20",X"20",X"20",X"49",X"6E",X"20",  -- 			 "In Out"
----							X"4F",X"75",X"74",X"20",X"20",X"20",X"20",X"20") when (S = "1110011111" AND data_select = '0') else   
----							
----							
----						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- .. "Current  Mission:"
----							X"4D",x"69",X"73",X"73",X"69",X"6F",X"6E",X"3A",  -- ..
----							X"20",X"20",X"4E",X"6F",X"20",X"4F",X"70",X"65",  -- 		  "No Operation"
----							X"72",X"61",X"74",X"69",X"6F",X"6E",X"20",X"20") when (S = "1111111111" AND data_select = '0') else							
----							
----							
----						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- .. "Current  Mission:"
----							X"4D",x"69",X"73",X"73",X"69",X"6F",X"6E",X"3A",  -- ..
----							X"20",X"20",X"20",X"20",X"20",X"20",X"44",X"65",  -- 		     "Delay"           
----							X"6C",X"61",X"79",X"20",X"20",X"20",X"20",X"20") when (S = "1010001101" AND data_select = '0') else
----							
----							
----						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- .. "Current  Mission:"
----							X"4D",x"69",X"73",X"73",X"69",X"6F",X"6E",X"3A",  -- ..
----							X"20",X"20",X"20",X"20",X"20",X"20",X"46",X"46",  -- 		     "FFT"           
----							X"54",X"20",X"20",X"20",X"20",X"20",X"20",X"20") when (S = "1100010110" AND data_select = '0') else							
----							
----							
----						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- .. "Current  Mission:"
----							X"4D",x"69",X"73",X"73",X"69",X"6F",X"6E",X"3A",  -- ..
----							X"20",X"20",X"20",X"46",X"46",X"54",X"20",X"2B",  -- 		     "FFT + Delay"           
----							X"20",X"44",X"65",X"6C",X"61",X"79",X"20",X"20") when (S = "1000010101" AND data_select = '0') else							
----							
----
----						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- .. "Current  Mission:"
----							X"4D",x"69",X"73",X"73",X"69",X"6F",X"6E",X"3A",  -- ..
----							X"20",X"20",X"20",X"20",X"20",X"53",X"52",X"41",  -- 		     "SRAM"           
----							X"4D",X"20",X"20",X"20",X"20",X"20",X"20",X"20") when (S = "0110000100" AND data_select = '0') else														
--							
--							
----							(X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Window:"
----							X"57",x"69",X"6E",X"64",X"69",X"6F",X"77",X"3A",  -- 																	..
----							X"46",X"46",X"54",X"3A",X"0" & LengthOfWindow_FFT(11 downto 8),  -- 		     		"[4][3][2][1]"  
----							X"0" & LengthOfWindow_FFT(7 downto 4),X"0" & LengthOfWindow_FFT(3 downto 0),X"20", X"46",X"49",X"46",X"4F",X"3A", X"0" & LengthOfWindow_Delay(11 downto 8),
----							X"0" & LengthOfWindow_Delay(7 downto 4),X"0" & LengthOfWindow_Delay(3 downto 0)) when data_select = '1' else
--
--							
--
--						 
--						
--					
--						--(X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:" -- OVERFLOW PRI AND Tau
----						  (X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",
----							X"0" & ADB_Detect(7 downto 4), X"0" & ADB_Detect(3 downto 0), X"20", X"20", X"20", X"20", X"20", X"20",-- 																	.. 
----							X"50",X"52",X"49",X"3B",			  -- 											   .. "PRI:"
----							X"09",X"09",X"09",X"09",X"2B", -- [PRI]
----							X"54",X"61",X"75",X"3B",													--		.. "Tau:"
----							X"09",X"09",X"09")   when (data_select = '1' AND ((ADB_Tau_Dec >= 999) AND (ADB_PRI_Dec >= 9999))) else		-- [Tau]				
----			
----						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:" -- OVERFLOW PRI
----							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
----							X"50",X"52",X"49",X"3B",		  -- 											   .. "PRI:"
----							X"09",X"09",X"09",X"09",X"2B", -- [PRI]
----							X"54",X"61",X"75",X"3B",													--		.. "Tau:"
----							X"0" & ADB_Tau_Dec(11 downto 8),X"0" & ADB_Tau_Dec(7 downto 4),X"0" & ADB_Tau_Dec(3 downto 0))   when (data_select = '1' AND (ADB_PRI_Dec >= 9999)) else		-- [Tau]
----
----
----
----						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:" -- OVERFLOW Tau
----							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
----							X"50",X"52",X"49",X"3B",			  -- 											   .. "PRI:"
----							X"0" & ADB_PRI_Dec(15 downto 12),X"0" & ADB_PRI_Dec(11 downto 8),X"0" & ADB_PRI_Dec(7 downto 4),X"0" & ADB_PRI_Dec(3 downto 0),X"2B", -- [PRI]
----							X"54",X"61",X"75",X"3B",													--		.. "Tau:"
----							X"09",X"09",X"09")   when (data_select = '1' AND (ADB_Tau_Dec >= 999)) else		-- [Tau]							
--							
--							
--							
--							
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:" -- NO OVERFLOW
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"50",X"52",X"49",X"3B",		  -- 											   .. "PRI:"
--							X"0" & ADB_PRI_Dec(15 downto 12),X"0" & ADB_PRI_Dec(11 downto 8),X"0" & ADB_PRI_Dec(7 downto 4),X"0" & ADB_PRI_Dec(3 downto 0),X"20", -- [PRI]
--							X"54",X"61",X"75",X"3B",													--		.. "Tau:"
--							X"0" & ADB_Tau_Dec(11 downto 8),X"0" & ADB_Tau_Dec(7 downto 4),X"0" & ADB_Tau_Dec(3 downto 0))   when (data_select = '1' AND ADB_Detect(3 downto 0) = "1111") else		-- [Tau]
--							
--							
--							
--							
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"30")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "0000")) else		
--	
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"31")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "0001")) else		
--						
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"32")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "0010")) else	
--					
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"33")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "0011")) else		
--	
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"34")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "0100")) else		
--						
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"35")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "0101")) else		
--			
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"36")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "0110")) else		
--	
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"37")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "0111")) else		
--						
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"38")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "1000")) else	
--					
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"39")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "1001")) else		
--	
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"41")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "1010")) else		
--						
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"42")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "1011")) else	
--				
--							  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"43")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "1100")) else		
--	
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"44")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "1101")) else		
--						
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"45")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "1110")) else	
--					
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"50",X"7C",X"54",X"46")    when (data_select = '1' AND (ADB_Detect(3 downto 0) = "1111")) else		
--			
--							
--							
--							
--							
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"44",X"45",X"54",X"45",X"43",X"54",X"20",  -- 											   .. "  DETECT - [POS][POS]  "
--							X"2D",X"20",X"0" & FFT_POS(7 downto 4),X"0" & FFT_POS(3 downto 0),X"20",X"20",X"20",X"20")   when FFT_Detect = "10" else
--							
--							
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Status:"
--							X"53",x"54",X"41",X"54",X"55",X"53",X"3A",X"20",  -- 																	.. 
--							X"20",X"4E",X"4F",X"54",X"20",X"44",X"45",X"54",  -- 																	.. "   NOT DETECT   "
--							X"45",X"43",X"54",X"20",X"46",X"72",X"65",X"71")    when (FFT_Detect = "01" OR FFT_Detect = "00") else							
--							
--							
--						  (X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- .. "Current  Mission:"
--							X"4D",x"69",X"73",X"73",X"69",X"6F",X"6E",X"3A",  -- ..
--							X"20",X"20",X"20",X"20",X"20",X"20",X"45",X"52",  -- 		     "ERROR"           
--							X"52",X"4F",X"52",X"20",X"20",X"20",X"20",X"20");
							



-- BIDIRECTIONAL TRI STATE LCD DATA BUS
	LCD_DATA <= LCD_DATA_VALUE WHEN LCD_RW_INT = '0' ELSE "ZZZZZZZZ";
-- get next character in display string
	Next_Char <= lcd_test_string(CONV_INTEGER(CHAR_COUNT));
	LCD_RW <= LCD_RW_INT;
PROCESS (Clock, Reset)
	BEGIN
	 IF RISING_EDGE(Clock) THEN
		IF RESET = '0' THEN
		 CLK_COUNT_400HZ <= X"00000";
		 CLK_400HZ_Enable <= '0';
		ELSE
				IF CLK_COUNT_400HZ < X"0EA60" THEN -- X"0EA60" when 125MHz, then X"05DC0" when 50MHz (/2.5)
				 CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1;
				 CLK_400HZ_Enable <= '0';
				ELSE
		    	 CLK_COUNT_400HZ <= X"00000";
				 CLK_400HZ_Enable <= '1';
				END IF;
		END IF;
	 END IF;
	END PROCESS;
	PROCESS (Clock, reset)
	BEGIN
		IF reset = '0' THEN
			state <= RESET1;
			LCD_DATA_VALUE <= X"38";
			next_command <= RESET2;
			LCD_EN <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';

		ELSIF Clock'EVENT AND Clock = '1' THEN
		  IF CLK_400Hz_Enable = '1' THEN
-- State Machine to send commands and data to LCD DISPLAY			
			CASE state IS
-- Set Function to 8-bit transfer and 2 line display with 5x8 Font size
-- see Hitachi HD44780 family data sheet for LCD command and timing details
				WHEN RESET1 =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"38";
						state <= DROP_LCD_EN;
						next_command <= RESET2;
						CHAR_COUNT <= "00000";
				WHEN RESET2 =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"38";
						state <= DROP_LCD_EN;
						next_command <= RESET3;
				WHEN RESET3 =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"38";
						state <= DROP_LCD_EN;
						next_command <= FUNC_SET;
-- EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD
				WHEN FUNC_SET =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"38";
						state <= DROP_LCD_EN;
						next_command <= DISPLAY_OFF;
-- Turn off Display and Turn off cursor
				WHEN DISPLAY_OFF =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"08";
						state <= DROP_LCD_EN;
						next_command <= DISPLAY_CLEAR;
-- Clear Display and Turn off cursor
				WHEN DISPLAY_CLEAR =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"01";
						state <= DROP_LCD_EN;
						next_command <= DISPLAY_ON;
-- Turn on Display and Turn off cursor
				WHEN DISPLAY_ON =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"0C";
						state <= DROP_LCD_EN;
						next_command <= MODE_SET;
-- Set write mode to auto increment address and move cursor to the right
				WHEN MODE_SET =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"06";
						state <= DROP_LCD_EN;
						next_command <= Print_String;
-- Write ASCII hex character in first LCD character location
				WHEN Print_String =>
						state <= DROP_LCD_EN;
						LCD_EN <= '1';
						LCD_RS <= '1';
						LCD_RW_INT <= '0';
-- ASCII character to output
						IF Next_Char(7 DOWNTO  4) /= X"0" THEN
						LCD_DATA_VALUE <= Next_Char;
						ELSE
-- Convert 4-bit value to an ASCII hex digit
							IF Next_Char(3 DOWNTO 0) >9 THEN
-- ASCII A...F
							 LCD_DATA_VALUE <= X"4" & (Next_Char(3 DOWNTO 0)-9);
							ELSE
-- ASCII 0...9
							 LCD_DATA_VALUE <= X"3" & Next_Char(3 DOWNTO 0);
							END IF;
						END IF;
						state <= DROP_LCD_EN;
-- Loop to send out 32 characters to LCD Display  (16 by 2 lines)
						IF (CHAR_COUNT < 31) AND (Next_Char /= x"FE") THEN
						 CHAR_COUNT <= CHAR_COUNT +1;
						
						ELSE 
						 CHAR_COUNT <= "00000";
						END IF;
						
-- Jump to second line?
						IF CHAR_COUNT = 15 THEN next_command <= line2;
-- Return to first line?
						ELSIF (CHAR_COUNT = 31) OR (Next_Char = X"FE") THEN 
						 next_command <= return_home; 
						ELSE next_command <= Print_String; END IF;
-- Set write address to line 2 character 1
				WHEN LINE2 =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"c0";
						state <= DROP_LCD_EN;
						next_command <= Print_String;
-- Return write address to first character postion on line 1
				WHEN RETURN_HOME =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						LCD_DATA_VALUE <= X"80";
						state <= DROP_LCD_EN;
						next_command <= Print_String;
-- The next three states occur at the end of each command or data transfer to the LCD
-- Drop LCD E line - falling edge loads inst/data to LCD controller
				WHEN DROP_LCD_EN =>
						LCD_EN <= '0';
						state <= HOLD;
-- Hold LCD inst/data valid after falling edge of E line				
				WHEN HOLD =>
						state <= next_command;
			END CASE;
		  END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE;













--
--							(X"43",X"75",X"72",X"72",X"65",X"6E",X"74",x"20",  -- 																.. "Current  Window:"
--							X"57",x"69",X"6E",X"64",X"69",X"6F",X"77",X"3A",  -- 																	..
--							X"20",X"20",X"20",X"20",X"20",X"20",LengthOfWindow_Dec(15 downto 12) + X"30",LengthOfWindow_Dec(11 downto 8) + X"30",  -- 		     		"[4][3][2][1]"  
--							LengthOfWindow_Dec(7 downto 4) + X"30",LengthOfWindow_Dec(3 downto 0) + X"30",X"20",X"20",X"20",X"20",X"20",X"20") when data_select = '1' else