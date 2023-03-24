library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_arith.all;

entity Modulator is
port(Clk,rst,EN,myrst: in  std_logic;
	  CPU_WAIT			: in  std_logic;
	  Freq_ch	    	: in  std_logic_vector(3 downto 0);
	  inXYR	 	  	   : in  std_logic_vector(95 downto 0);
	  Valid,NCO_EN    : out std_logic; -- NCO_EN SHOULD NOT GO DOWN
	  valid_nco			: out std_logic; -- USE VALID_NCO TO STOP TRANSMITING
	  Phase		      : out std_logic_vector(31 downto 0));
end entity;	


architecture arc of Modulator is
type my_state is (Resetting, Start, Get_Input, Modulate, Done);
signal Phase_sig: std_logic_vector(31 downto 0);
signal State : my_state;
signal CH: integer range 0 to 15;
signal N: integer range 0 to 96;
signal Data_vector : std_logic_vector(95 downto 0);
signal Serial_sig: std_logic;
signal Counter: integer range 0 to 100000001;
begin
		process(Clk,rst,myrst)
		begin
				if (rst = '0' or myrst='1') then
					Serial_sig<='0';
					Counter<=0;
					NCO_EN<='0'; --0
					State<=Resetting;
					Valid<='0';
					Phase_sig <=(others=>'0');
					N <= 0;
					valid_nco <= '0';
				elsif rising_edge(Clk) then
					if(EN='1')then
						case State is
								when Resetting =>
										valid_nco <= '0'; --Phase_sig <=(others=>'0');
										NCO_EN <= '1'; --0										
										if CPU_WAIT = '0' then
											State <= Get_Input;
										end if;
								when Get_Input =>
										CH <= conv_integer(Freq_ch);
										Data_vector <= inXYR;
										Serial_sig <= inXYR(0);
										N <= 0;
										State <= Modulate;
								when Modulate =>
										valid_nco <= '1';
										NCO_EN <= '1';
										if(Serial_sig='0')then
											Phase_sig<= CONV_STD_LOGIC_VECTOR(((CH*8589935)+ 2147484),32); --add 25k
										elsif(Serial_sig='1')then
											Phase_sig<= CONV_STD_LOGIC_VECTOR(((CH*8589935)+ 4294968),32); --add 50k
										end if;
										Counter <= Counter + 1;
										if Counter = 5000 then
											if N /= 95 then
												Serial_sig <= Data_vector(N+1);
												N <= N+1;
											else
												State <= Done;
												valid_nco <= '0'; --Phase_sig <= (others=>'0');
												NCO_EN <= '1'; --0
												Valid <= '1';
												N <= 0;
												Counter <= 0;
											end if;
											Counter <= 0;
										end if;
								when Done =>
										Valid <= '0'; 
										Counter <= Counter + 1;
										if Counter = 25000 then
											State <= Resetting;
											Counter <= 0;
										end if;
								when others =>
						end case;
					else
						valid_nco <= '0'; --Phase_sig <= (others=>'0');
					end if;
				end if;
		end process;
		Phase<=Phase_sig;
end arc;








--
--						Case State is
--							when default =>
--							When Resetting=>State<=Shift;
--												 CH<=CONV_INTEGER(Freq_ch);
--												 Valid<='0';
--												 NCO_EN <= '0';
--							when Shift=>
--								Y<=Load;
--							when Modulate=>
--								NCO_EN <= '1';
--								if(Serial_sig='0')then
--									Phase_sig<= CONV_STD_LOGIC_VECTOR(((CH*8589935)+ 2147484),32); --add 25k
--								elsif(Serial_sig='1')then
--									Phase_sig<= CONV_STD_LOGIC_VECTOR(((CH*8589935)+ 4294968),32); --add 50k
--								end if;
--								--Phase_sig<=CONV_STD_LOGIC_VECTOR(X,32);
--								State<=Done;
--							when others=>
--						end case;
--						case Y is
--							when Resetting=>
--							
--							when Load=>		
--												Z<=inXYR;
--												Y<=Rotate;
--												state <= default;
--							when Rotate=>
--												NCO_EN<='1';
--												Serial_sig<=Z(N);
--												N<=N-1;
--												if(N/=0)then
--													Y<=Delay;
--													State<=Modulate;
--												else
--													Y<=Done;
--													State<=default;
--												end if;
--							when Delay=>
--												if(Counter/=5000)then
--													Counter<=Counter+1;
--												else
--													Counter<=0;
--													Y<=Rotate;
--												end if;
--							when others=>
--												N<=95;
--												NCO_EN<='0';
--												Valid<='1';
--												if(Counter/=25000)then
--													Counter<=Counter+1;
--													State <= default;
--												else
--													Counter<=0;
--													Y<=Resetting;
--													State<=Resetting;
--												end if;
--						 end case;
--					else
--						Phase_sig <= (others=>'0');
--					end if;