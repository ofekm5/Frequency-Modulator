LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE  IEEE.NUMERIC_STD.all;

Entity NCO_Output_Enable is
port( Clock, Reset : in std_logic;
		valid_nco	 : in std_logic;
		Data_in  	 : in std_logic_vector(17 downto 0);
		Data_out 	 : out std_logic_vector(17 downto 0));
end entity;

architecture arch_NCO_Output_Enable of NCO_Output_Enable is

begin         
		process(Clock, Reset)
		begin
				if Reset = '0' then
					Data_out <= (others=>'0');
				elsif rising_edge(Clock) then
					if valid_nco = '1' then
						Data_out <= Data_in;
					else
						Data_out <= (others=>'0');
					end if;
				end if;
		end process;
end architecture;

	  