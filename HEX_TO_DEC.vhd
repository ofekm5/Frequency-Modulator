LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE  IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

Entity HEX_TO_DEC is
generic(NumOfBits: integer:= 4);
port( Clock, Reset : in std_logic;
		A: in std_logic_vector(NumOfBits-1 downto 0);
		Y : out std_logic_vector(15 downto 0));
end entity;

architecture arch_HEX_TO_DEC of HEX_TO_DEC is
signal Y_sig : std_logic_vector(15 downto 0);
begin         
			 process(Clock, Reset)
			 begin 
					if Reset = '0' then
						Y_sig <= (others=>'0');
					elsif rising_edge(Clock) then						
						Y_sig(3 downto 0) <= conv_std_logic_vector(conv_integer(A) mod 10,4);
						Y_sig(7 downto 4) <= conv_std_logic_vector((conv_integer(A)/10) mod 10,4);
						Y_sig(11 downto 8) <= conv_std_logic_vector((conv_integer(A)/100) mod 10,4);
						Y_sig(15 downto 12) <= conv_std_logic_vector((conv_integer(A)/1000) mod 10,4);
					end if;
			 end process;
			 Y<=Y_sig;
end architecture;




--			 process(Clock, Reset)
--			 variable Y_sig: std_logic_vector(15 downto 0);
--			 begin 
--					if Reset = '0' then
--						Y_sig:= (others=>'0');
--					elsif rising_edge(Clock) then
--						--Y_sig<=CONV_STD_LOGIC_VECTOR(((CONV_INTEGER(A(12))*4096)+(A(11)*2048)+(CONV_INTEGER(A(10))*1024)+(CONV_INTEGER(A(9))*512)+(CONV_INTEGER(A(8))*256)+(CONV_INTEGER(A(7))*128)+(CONV_INTEGER(A(6))*64)+(CONV_INTEGER(A(5))*32)+(CONV_INTEGER(A(4))*16)+(CONV_INTEGER(A(3))*8)+(CONV_INTEGER(A(2))*4)+(CONV_INTEGER(A(1))*2)+CONV_INTEGER(A(0))),16);
--						for i in 0 to NumOfBits-1 loop
--							if A(i) = '1' then
--								Y_sig:= Y_sig + 2**i;
--							end if;
--						end loop;
--						Y<=Y_sig;						
--					end if;
--			 end process;
	  