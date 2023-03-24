library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_arith.all;

entity CPU is
generic(size : natural := 3);
port(Clk,rst,Enable,increase,Decrease,Set_state,Valid,EN_save,EN_Page,EN_changeupdown,EN_Done	  			  : in  std_logic; --set is for switch states
	  freq,fromfreq																			 							 			  : in  std_logic_vector(size downto 0);
	  data,Fromdata	   																	  										  : in  std_logic_vector(95 downto 0);																									 
	  My_state																												           : in  std_logic_vector(2 downto 0);
	  Reset_data,RWfreq,RWdata,NCO_WAIT																			  	           : out std_logic;
	  Outposition_Data,Outposition_Freq																			 			  	  : out std_logic_vector(3 downto 0);																	  							
	  Out_index																	  						  								  : out std_logic_vector(size downto 0);
	  Sel																	  	  										 			 		  : out std_logic_vector(2 downto 0);--Enable spreading to all
	  Out_memory																	  										  			  : out std_logic_vector(95 downto 0);
	  Numoffreqs,Numofdata,Statemode																			  	  				  : out std_logic_vector(2 downto 0); 
	  data_select																										  				  : out std_logic_vector(3 downto 0));
end entity;			

architecture arc of CPU is
type TState is (Resetting,Done,Start,Stop,Load,Setnumoffreqs,Setnumofdata,Default,Choosemode,delay);
type TStateL is (Freqpage,Datapage);
type TPage2 is (Delay,Setdatapos,Reading,Update,Setdata,Savetodataram,default);
type TPage1 is (Delay,Setfreqpos,Reading,Update,Setfreq,Savetofreqram,default);
signal Numofload_sig						 		    : std_logic_vector(2 downto 0);
signal Page1							    			 :	TPage1;
signal State							    			 : TState;
signal StateL								 			 : TStateL;
signal Page2							    			 : TPage2;
signal Out_memory_sig 		 			 			 : std_logic_vector(95 downto 0);
signal Out_index_sig  		 			 			 : std_logic_vector(size downto 0);
signal Sel_sig							    			 : std_logic_vector(2 downto 0);						
signal RWfreq_sig,RWdata_sig			 			 : std_logic;
signal Outposition_Freq_sig			 			 : std_logic_vector(3 downto 0);
signal Outposition_Data_sig			 			 : std_logic_vector(3 downto 0);
signal Numoffreqs_sig,Numofdata_sig	 			 : std_logic_vector(2 downto 0);
signal data_select_sig					 			 : std_logic_vector(3 downto 0);
signal Counter_inc,Counter_dec,CounterSetState: std_logic_vector(25 downto 0);
signal Reset_data_sig					 			 : std_logic;
signal Nmode								 			 : std_logic_vector(2 downto 0);
signal Counterfreq						 			 : std_logic_vector(2 downto 0);
signal Counterdly							 			 : std_logic_vector(25 downto 0);
signal CounterD										 : std_logic_vector(2 downto 0);
signal Counter_NCO									 : std_logic_vector(1 downto 0);
signal CounterDone									 : std_logic_vector(28 downto 0);
begin
		process(Clk,rst)
		begin
			if rst = '0' then
					 RWfreq_sig<='1';
					 RWdata_sig<='1';
					 Numofload_sig<=(others=>'0');
					 Numoffreqs_sig<=(others=>'0');
					 Counter_inc<=(others=>'0');
					 Counter_dec<=(others=>'0');
					 data_select_sig<=(others=>'0');
					 Numofdata_sig<=(others=>'0'); 
					 State<=Setnumoffreqs;
					 StateL<=Freqpage;
					 Page1<=Setfreqpos;
					 Page2<=Setdatapos;
					 Nmode<=(others=>'0');
					 Counterfreq<=(others=>'0');
					 Counterdly<=(others=>'0');
					 Sel_sig<=(others=>'0');
					 Out_memory_sig<=(others=>'0');
					 Out_index_sig <=(others=>'0');
					 Reset_data_sig<='0';
					 Outposition_Data_sig <= (others=>'0');
					 Outposition_Freq_sig <= (others=>'0');	
					 CounterD <= (others=>'0');
					 Counter_NCO <= (others=>'0');
					 CounterDone <= (others=>'0');
					 NCO_WAIT <= '0';
			elsif rising_edge(Clk) then
				if(EN_Done='1')then
					State<=Choosemode;
				end if;
				if(Enable='1')then
						case State is	
							when Setnumoffreqs=>
								if(increase='0')then
									Counter_inc<=Counter_inc+1;
									if(CONV_INTEGER(Counter_inc)=25000000)then	
										Counter_inc<=(others=>'0');
										Numoffreqs_sig<=Numoffreqs_sig+1;
									end if;
								elsif(Decrease='0')then
										Counter_dec<=Counter_dec+1;
										if(CONV_INTEGER(Counter_dec)=25000000)then
											Counter_dec<=(others=>'0');
											Numoffreqs_sig<=Numoffreqs_sig-1;
										end if;
								else
											Counter_inc<=(others=>'0');
											Counter_dec<=(others=>'0');
								end if;
								data_select_sig<="0001";
								if(Set_state='0')then
									CounterSetState<=CounterSetState+1;
									if(CONV_INTEGER(CounterSetState)=25000000)then	
										CounterSetState<=(others=>'0');
										State<=Setnumofdata;
									end if;
								end if;
							when Setnumofdata=>
								if(increase='0')then
									Counter_inc<=Counter_inc+1;
									if(CONV_INTEGER(Counter_inc)=25000000)then	
										Counter_inc<=(others=>'0');
										Numofdata_sig<=Numofdata_sig+1;
									end if;
								elsif(Decrease='0')then
										Counter_dec<=Counter_dec+1;
										if(CONV_INTEGER(Counter_dec)=25000000)then
											Counter_dec<=(others=>'0');
											Numofdata_sig<=Numofdata_sig-1;
										end if;
								else
										Counter_inc<=(others=>'0');
										Counter_dec<=(others=>'0');
								end if;
								data_select_sig<= "0010";
								if(Set_state='0')then
									CounterSetState<=CounterSetState+1;
									if(CONV_INTEGER(CounterSetState)=25000000)then	
										CounterSetState<=(others=>'0');
										State<=Choosemode;
									end if;
								end if;
							when Choosemode=>--choose between start,stop and load
								if(increase='0')then
										Counter_inc<=Counter_inc+1;
										if(CONV_INTEGER(Counter_inc)=25000000)then	
											Counter_inc<=(others=>'0');
											Nmode<=Nmode+1;
										end if;
								elsif(Decrease='0')then
										Counter_dec<=Counter_dec+1;
										if(CONV_INTEGER(Counter_dec)=25000000)then
											Counter_dec<=(others=>'0');
											Nmode<=Nmode-1;
										end if;
								else
										Counter_inc<=(others=>'0');
										Counter_dec<=(others=>'0');
								end if;
								data_select_sig<= "0011";
								if(Set_state='0')then
									CounterSetState<=CounterSetState+1;
									if(CONV_INTEGER(CounterSetState)=25000000)then	
										CounterSetState<=(others=>'0');
										case Nmode is
											when "000"=>	State<=Resetting;
											
											when "001"=>	State<=Start;
																Sel_sig(2 downto 1)<=(others=>'1');
																
										
											when "010"=>	State<=Stop;
																Sel_sig<=(others=>'0');
																
											when "011"=>	State<=Load;
																Sel_sig<="110";
											when others=>	
										end case;
									end if;
								end if;
							when Resetting=>
												NCO_WAIT <= '0';
												data_select_sig<= "1010";
												RWfreq_sig<='0';
												RWdata_sig<='0';
												Sel_sig(0)<='0'; -- Needs to be zero, During Resetting no transmiting!
												if(Valid='1')then
													if(Outposition_Freq_sig/=numoffreqs_sig)then
														Out_index_sig<=(others=>'0');
														Out_memory_sig<=(others=>'0');
														Outposition_Freq_sig<=Outposition_Freq_sig+1;
													else
														if Outposition_Data_sig/=numofdata_sig then
															Out_memory_sig <= (others=>'0');
															Outposition_Data_sig <= Outposition_Data_sig + 1;
														else
															--Sel_sig(0)<='0';--done!
															Reset_data_sig<='1';
															Outposition_Freq_sig<=(others=>'0');
															Outposition_Data_sig <= (others=>'0');
															State<=default;
														end if;
													end if;
												end if;	
							
							when Start=>
												Sel_sig(0)<='1';
												data_select_sig<= "1001";
												RWfreq_sig<='1';
												RWdata_sig<='1';																							
												if Counter_NCO = 1 then												-- Needs delay until memory is ready: Data goes from CPU to memory.
													NCO_WAIT <= '0'; 													-- Memory needs 2 clocks to output data to NCO, 1 clock is already delayed by the state, so needs 1 more.									
												else																		-- timeline: 			1clk					2clk					3clk
													Counter_NCO <= Counter_NCO + 1;								-- 						===============================================
												end if;				  													--				 			DATA = CONTROL		DATA = MEMORY		DATA = NCO
												if(Valid='1')then														--				 			EN = --				EN = WAIT			EN = NCO
													if(Outposition_Freq_sig/=numoffreqs_sig)then				-- *VALID IS A _PULSE_ OF FINISHED FULL VECTOR TRANSMITING!*
														Outposition_Freq_sig<=Outposition_Freq_sig+1;
													else
														Outposition_Freq_sig<=(others=>'0');
														if Outposition_Data_sig/=numofdata_sig then															
															Outposition_Data_sig <= Outposition_Data_sig + 1;
														else
															Outposition_Freq_sig<=(others=>'0');
															Outposition_Data_sig <= (others=>'0');
															State <= Done;
															NCO_WAIT <= '1';
															Counter_NCO <= (others=>'0');
														end if;
													end if;
												end if;
							when Done=>		-- Finished all transmiting, waiting 1s until rebroadcast to all frequencies
												CounterDone <= CounterDone + 1;
												if CounterDone = 5000 then
													State <= Start;
													CounterDone <= (others=>'0');
												end if;
							when delay=>
									Counterdly<=Counterdly+1;
									if(counterdly=25000000)then
										State<=Start;
										Counterdly <= (others=>'0');
									end if;
							when Stop=>
									Sel_sig<=(others=>'0');
									Reset_data_sig<='1';
									data_select_sig<= "1000";
							when Load=>
								if(EN_Page='0')then
									StateL<=Freqpage;
								else
									StateL<=Datapage;
								end if;
								case StateL is
											when Freqpage=>
															case Page1 is
																	when default=>
																	when Setfreqpos=>
																		if(increase='0')then
																			Counter_inc<=Counter_inc+1;
																				if(CONV_INTEGER(Counter_inc)=12500000)then
																					Outposition_Freq_sig<=Outposition_Freq_sig+1;
																					Counter_inc<=(others=>'0');
																					Page1<=Reading;
																				end if;
																		elsif(Decrease='0')then
																			Counter_dec<=Counter_dec+1;
																				if(CONV_INTEGER(Counter_dec)=12500000)then
																					Outposition_Freq_sig<=Outposition_Freq_sig-1;
																					Counter_dec<=(others=>'0');
																					Page1<=Reading;
																				end if;
																		else
																			Counter_inc<=(others=>'0');
																			Counter_dec<=(others=>'0');
																		end if;
																		if(Out_index_sig="1010")then
																			data_select_sig<= "0101";
																		else
																			data_select_sig<= "0100";
																		end if;
																		--Page1<=Reading;	
																		if(EN_changeupdown='1')then 
																			Page1<=Setfreq;
																		end if;
																	when Reading=>
																		RWfreq_sig<='1';
																		Page1<=Delay;
																	when Delay=>
																		CounterD<=CounterD+1;
																		if(CounterD=5)then
																			Page1<=Update;
																			CounterD<=(others=>'0');
																		end if;
																	when Update=>
																		Out_index_sig<=fromfreq;
																		Page1<=Setfreq;
																	when Setfreq=>
																		if(increase='0')then
																			Counter_inc<=Counter_inc+1;
																			if(CONV_INTEGER(Counter_inc)=12500000)then
																				Out_index_sig<=Out_index_sig+(freq+(1+(CONV_INTEGER(My_state))));
																				counter_inc<=(others=>'0');
																			end if;
																		elsif(Decrease='0')then
																			Counter_dec<=Counter_dec+1;
																			if(CONV_INTEGER(Counter_dec)=12500000)then
																				Out_index_sig<=Out_index_sig+(freq-(1+(4*CONV_INTEGER(My_state))));
																				counter_dec<=(others=>'0');
																			end if;
																		else
																			counter_inc<=(others=>'0');
																			counter_dec<=(others=>'0');
																		end if; 
																		if(Out_index_sig="1010")then
																			data_select_sig<= "0101";
																		else
																			data_select_sig<= "0100";
																		end if;
																		if(EN_changeupdown='0')then 
																			Page1<=Setfreqpos;
																		end if;
																		if(Set_state='0')then
																			CounterSetState<=CounterSetState+1;
																			if(CONV_INTEGER(CounterSetState)=12500000)then	
																				CounterSetState<=(others=>'0');
																				Page1<=Savetofreqram;
																				RWfreq_sig <= '0';
																			end if;
																		end if;
																	when others=> --Savetofreqram
																			RWfreq_sig<='1';
																			Page1<=Setfreqpos;		
															end case;		
											when others=> --Datapage
															case Page2 is
																when default=>
																when Setdatapos=>
																	if(increase='0')then
																		Counter_inc<=Counter_inc+1;
																		if(CONV_INTEGER(Counter_inc)=12500000)then
																			Outposition_data_sig<=Outposition_data_sig+1;
																			Counter_inc<=(others=>'0');
																			Page2<=Reading;
																		end if;
																	elsif(Decrease='0')then
																		Counter_dec<=Counter_dec+1;
																		if(CONV_INTEGER(Counter_dec)=12500000)then
																			Outposition_data_sig<=Outposition_data_sig-1;
																			Counter_dec<=(others=>'0');
																			Page2<=Reading;
																		end if;
																	else
																		Counter_inc<=(others=>'0');
																		Counter_dec<=(others=>'0');
																	end if;
																	data_select_sig <= "0110"; 
																	--Page2<=Reading;
																when Reading=>
																	RWdata_sig<='1';
																	Page2<=Delay;
																when Delay=>
																		CounterD<=CounterD+1;
																		if(CounterD=5)then
																			Page2<=Update;
																			CounterD<=(others=>'0');
																		end if;
																when Update=>
																	Out_memory_sig<=fromdata;
																	Page2<=Setdata;
																when Setdata=>
																	if(increase='0')then
																		Counter_inc<=Counter_inc+1;
																		if(CONV_INTEGER(Counter_inc)=12500000)then
																			Out_memory_sig<=Out_memory_sig+(data+2**(1+(4*CONV_INTEGER(My_state))));
																			counter_inc<=(others=>'0');
																		end if;
																	elsif(Decrease='0')then
																		Counter_dec<=Counter_dec+1;
																		if(CONV_INTEGER(Counter_dec)=12500000)then
																			Out_memory_sig<=Out_memory_sig+(data-2**(1+(4*CONV_INTEGER(My_state))));
																			counter_dec<=(others=>'0');
																		end if;
																	else
																		counter_inc<=(others=>'0');
																		counter_dec<=(others=>'0');
																	end if; 
																	data_select_sig<= "0110";
																	if(EN_changeupdown='0')then 
																		Page2<=Setdatapos;
																	end if;
																	if(Set_state='0')then
																			CounterSetState<=CounterSetState+1;
																			if(CONV_INTEGER(CounterSetState)=12500000)then	
																				CounterSetState<=(others=>'0');
																				Page2<=Savetodataram;
																				RWdata_sig <= '0';
																			end if;
																	end if;
																when others=>--Savetodataram
																		RWdata_sig<='1';
																		Page2<=Setdatapos;	
															end case;
													end case;
							when default =>
							when others=>data_select_sig<= "1010";
						end case;
				end if;
			end if;
		end process;
		Statemode<=Nmode;
		RWfreq<=RWfreq_sig;
		RWdata<=RWdata_sig;
		Outposition_Data<=Outposition_Data_sig;
		Outposition_Freq<=Outposition_Freq_sig;
		Reset_data<=Reset_data_sig;
		data_select<=data_select_sig;
		Numofdata<=Numofdata_sig;
		Numoffreqs<=Numoffreqs_sig;
		Sel<=Sel_sig;
		Out_index<=Out_index_sig;
		Out_memory<=Out_memory_sig;
end arc;