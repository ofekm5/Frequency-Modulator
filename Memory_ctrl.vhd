library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_arith.all;

entity Memory_ctrl is
generic(size : natural := 32;
		  ADDR_WIDTH : natural := 2);
port (clk,rst,EN,RW									: in  std_logic;
		IN_Data											: in  std_logic_vector(31 downto 0); --data from CPU
		Data_read										: in  std_logic_vector(size-1 downto 0); --data from RAM
		position											: in  std_logic_vector(3 downto 0);
		Q													: out std_logic_vector((size-1) downto (size-32));
		addr												: out std_logic_vector(2**ADDR_WIDTH - 1 downto 0);
		Data_write										: out std_logic_vector((size-1) downto 0);
		WE													: out std_logic);		
end Memory_ctrl;

architecture rtl of Memory_ctrl is
signal addr_sig				: std_logic_vector(2**ADDR_WIDTH - 1 downto 0);
signal q_sig					: std_logic_vector(size-1 downto 0);
signal Data_write_sig		: std_logic_vector(size-1 downto 0);
begin
	process(clk,rst,en)
	begin
		if(rst='0') then 
			addr_sig<=(others=>'0');
			q_sig<=(others=>'0');
			Data_write_sig<=(others=>'0');
			WE<='1';
		elsif(rising_edge(clk) and EN='1') then
			if(RW='1')then--send data back
				q_sig<=Data_read;
				WE<='1';
				addr_sig <=position;
			elsif(RW='0')then--write data back
				Data_write_sig<=IN_Data;
				WE<='0';
				addr_sig <=position;
			end if;
		end if;
	end process;
	Data_write<=Data_write_sig;
	Q<=q_sig;
	addr<=addr_sig;
end rtl;
