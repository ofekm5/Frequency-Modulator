LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE  IEEE.NUMERIC_STD.all;

Entity HSMC_CONTROL is
port( Clock, Reset_n					  		: in std_logic;
		Ada_dco_A, Ada_dco_B 				: in std_logic;
		OE_A, OE_B						  		: out std_logic;
		CHIP_SELECT_A, CHIP_SELECT_B 		: out std_logic;
		Clock_out_adc_A, Clock_out_adc_B : out std_logic; 
		HSMB_RX_LED, HSMB_TX_LED 			: out std_logic);
end entity;

architecture arch_HSMC_CONTROL of HSMC_CONTROL is
begin
		OE_A <= '0';
		OE_B <= '0';
		CHIP_SELECT_A <= '0';
		CHIP_SELECT_B <= '0';
		Clock_out_adc_A <= Clock;
		Clock_out_adc_B <= Clock;
		HSMB_RX_LED <= '1' when Reset_n = '1' else
							'0';
		HSMB_TX_LED <= '1' when (Ada_dco_A = '1' OR Ada_dco_B = '1') AND Reset_n = '1' else
							'0';
end architecture;

	  