LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
--USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
--USE  IEEE.NUMERIC_STD.all;

Entity TwoComplementToDec is
port(--Clock, Reset : in std_logic;
	  Data_in	:	in	std_logic_vector(13 downto 0);
	  Data_out	:	out std_logic_vector(13 downto 0));
End Entity;

architecture arch_TwoComplementToDec of TwoComplementToDec is
signal temp: std_logic_vector(13 downto 0);
begin
--		temp <= ('1' & Data_in(12 downto 0)) when (Data_in(13)='0') else 
--		((13 => '1',12 downto 0=>'0') - std_logic_vector((not Data_in) + 1 ));
--		Data_out <= temp;

--		process(Clock, Reset)
--		begin
--				if Reset = '0' then
--					Data_out <= (others=>'0');
--				elsif rising_edge(Clock) then
----					if Data_in(13) = '0' then
----						Data_out <= Data_in + "10000000000000";
----					else
----						Data_out <= Data_in - "10000000000000";
----					end if;
--				end if;
--		end process;

		Data_out(13) <= (not Data_in(13));
		Data_out(12 downto 0) <= Data_in(12 downto 0);
end architecture;










--LIBRARY IEEE;
--USE  IEEE.STD_LOGIC_1164.all;
--USE  IEEE.STD_LOGIC_ARITH.all;
--USE  IEEE.STD_LOGIC_UNSIGNED.all;
--USE  IEEE.NUMERIC_STD.all;
--
--Entity TwoComplementToDec is
--port(Data_in	:	in	std_logic_vector(13 downto 0);
--	  Data_out	:	out std_logic_vector(13 downto 0));
--End Entity;
--
--architecture arch_TwoComplementToDec of TwoComplementToDec is
--signal temp: std_logic_vector(13 downto 0);
--begin
--		temp <= Data_in when (Data_in(13)='0') else std_logic_vector((not Data_in) + 1 );
--		Data_out <= temp(13 downto 0) & "00";
--end architecture;