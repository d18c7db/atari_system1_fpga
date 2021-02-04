----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    22:38:01 1/11/2007
-- Design Name:
-- Module Name:    LETA_REP - Behavioral
-- Project Name: 	 LETA on a CPLD
-- Target Devices: XC95108
-- Tool versions:  webpack ise 9.1.03i
-- Description: 	 Atari Leta replacement *Freeware* !!
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - initial public release
--
-- Additional Comments:
-- 	another fun project from JROK
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity LETA_REP is
	Port (
			db   	: out  STD_LOGIC_VECTOR (7 downto 0);
			cs 		: in   STD_LOGIC;
			ck 		: in   STD_LOGIC;
			test 	: in   STD_LOGIC;
			ad 		: in   STD_LOGIC_VECTOR (1 downto 0);
			clks 	: in   STD_LOGIC_VECTOR (3 downto 0);
			dirs	: in   STD_LOGIC_VECTOR (3 downto 0);
			resoln : in   STD_LOGIC);
end LETA_REP;

architecture Behavioral of LETA_REP is

-- 8 bit counter register
type   cnt_reg is  array( 0 to 3 ) of   std_logic_vector( 7 downto 0 );
signal count_register : cnt_reg ;

-- 3 bit temp storage
type tmp_inputs is array( 0 to 3 ) of std_logic_vector( 2 downto 0 );
signal clks_tmp: tmp_inputs;
signal dirs_tmp: tmp_inputs;


signal clks_last_bit: std_logic_vector( 3 downto 0 );
signal dirs_last_bit: std_logic_vector( 3 downto 0 );




begin

-- ----------------------------------------------------------

process( clks, dirs, ck )
begin

if ( rising_edge( ck ) ) then

	for cntr in 3 downto 0 loop

		if ( test = '1' ) then

			-- test mode clear the states of DIR and CLK
			clks_tmp( cntr ) <= "000";
			dirs_tmp( cntr ) <= "000";

		else

			-- shift the bits left and store the current state in bit '0'

			clks_tmp( cntr ) ( 2 downto 1 ) <= clks_tmp( cntr )( 1 downto 0 );
			clks_tmp( cntr ) ( 0 ) <= clks( cntr );

			dirs_tmp( cntr ) ( 2 downto 1 ) <= dirs_tmp( cntr )( 1 downto 0 );
			dirs_tmp( cntr ) ( 0 ) <= dirs( cntr );

		end if;

	end loop;

end if; -- ck rising edge clock

end process;

-- ----------------------------------------------------------

process( ck, dirs_tmp, clks_tmp, test )
begin

if ( rising_edge( ck ) ) then


	for cntr in 3 downto 0 loop

		if ( test = '1' ) then

		-- test mode clear ALL the counts

			count_register(cntr) <= "00000000";
			clks_last_bit( cntr ) <= '0';
			dirs_last_bit( cntr ) <= '0';

		else

		-- test mode = '0' so normal counting operation

		-- 3 bits of CLK or DIR have to be the same
		-- before a

		 if ( clks_tmp( cntr ) = "000" ) then
				clks_last_bit( cntr ) <= '0';
		 end if;

		 if ( clks_tmp( cntr ) = "111" ) then
			clks_last_bit( cntr ) <= '1';
		 end if;

		 if ( dirs_tmp( cntr ) = "000" ) then
			dirs_last_bit( cntr ) <= '0';
		 end if;

		 if ( dirs_tmp( cntr ) = "111" ) then
			dirs_last_bit( cntr ) <= '1';
		 end if;



	   --  check for a new state of DIR & CLK
		--  then take a counting action depending on the previous state

		-- state 10

		 if  ( clks_tmp( cntr ) = "111" and  dirs_tmp( cntr ) = "000"   ) then

			if  ( clks_last_bit( cntr ) ='0' and dirs_last_bit( cntr ) ='0' and resoln = '1' ) then
				count_register(cntr) <= count_register(cntr)+1;
			end if;

			if  ( clks_last_bit( cntr ) ='1' and dirs_last_bit( cntr ) ='1'  ) then
				count_register(cntr) <= count_register(cntr)-1;
			end if;

		end if;


		-- state 11

		if  ( clks_tmp( cntr ) = "111" and  dirs_tmp( cntr ) = "111"   ) then

			if  ( clks_last_bit( cntr ) ='1' and dirs_last_bit( cntr ) ='0' ) then
				count_register(cntr) <= count_register(cntr)+1;
			end if;

			if  ( clks_last_bit( cntr ) ='0' and dirs_last_bit( cntr ) ='1'  and resoln = '1' ) then
				count_register(cntr) <= count_register(cntr)-1;
			end if;

		end if;


		-- state 01

		if  ( clks_tmp( cntr ) = "000" and  dirs_tmp( cntr ) = "111"  ) then

			if  ( clks_last_bit( cntr ) ='0' and dirs_last_bit( cntr ) ='0' ) then
				count_register(cntr) <= count_register(cntr)-1;
			end if;

			if  ( clks_last_bit( cntr ) ='1' and dirs_last_bit( cntr ) ='1'  and resoln = '1' ) then
				count_register(cntr) <= count_register(cntr)+1;
			end if;

		end if;

		-- state 00

		if  ( clks_tmp( cntr ) = "000" and  dirs_tmp( cntr ) = "000"   ) then

			if  ( clks_last_bit( cntr ) ='0' and dirs_last_bit( cntr ) ='1'  ) then
				count_register(cntr) <= count_register(cntr)+1;
			end if;

			if  ( clks_last_bit( cntr ) ='1' and dirs_last_bit( cntr ) ='0'  and resoln = '1') then
				count_register(cntr) <= count_register(cntr)-1;
			end if;

		end if;

	 end if; -- test mode check

	end loop;

end if;

end process;

-- ----------------------------------------------------------
process( cs, count_register, ad, test,dirs, clks )
begin
	if ( cs = '1' ) then
		db <= "ZZZZZZZZ";
	else
		if ( test = '0' ) then

			-- put the register pointed to by A0 & A1
			-- onto the databus

			db   <= count_register( conv_integer( ad ) ) ;
		else

			-- test mode so just pass thru' the INVERTED states
			-- of the dir and clk inputs
			-- A0/A1 are irrelevant

			db(0) <= not( dirs(0) );
			db(1) <= not( clks(0) );
			db(2) <= not( dirs(1) );
			db(3) <= not( clks(1) );
			db(4) <= not( dirs(2) );
			db(5) <= not( clks(2) );
			db(6) <= not( dirs(3) );
			db(7) <= not( clks(3) );

		end if;
	end if;
end process;

-- ----------------------------------------------------------

end Behavioral;
