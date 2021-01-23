--	(c) 2019 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses
--

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library unisim;
	use unisim.vcomponents.all;

-- general purpose debug unit via RS232
entity DEBUG is
	port(
		I_RX					: in	std_logic;
		O_TX					: out	std_logic;

		I_CK					: in	std_logic;
		I_RST					: in	std_logic;
		O_ENA					: out	std_logic;

		I_SEL					: in	std_logic;
		I_ADDR				: in	std_logic_vector(31 downto 0);
		I_DATA				: in	std_logic_vector(15 downto 0)
	);
end DEBUG;

architecture RTL of DEBUG is
	type state_type is (
		st_paddr0, st_paddr1,
		st_view0,  st_view1,  st_view2,  st_view3,  st_view4,  st_view5,
		st_idle
	);
	signal state : state_type := st_idle;
	signal
		TxD_start,
		TxD,
		TxD_busy,
		RxD,
		RxD_data_ready,
		ena_out,
		s_OBJCEn
								: std_logic := '0';
	signal
		wctr,
		ctr
								: natural range 0 to 31;
	signal
		addr,
		txdata
								: std_logic_vector(23 downto 0) := (others=>'0');
	signal
		data,
		TxD_data,
		RxD_data,
		RxD_buf
								: std_logic_vector( 7 downto 0) := (others=>'0');
begin
	O_ENA <= ena_out;

	ser: entity async_transmitter
	port map (
		clk					=> I_CK,
		TxD					=> O_TX,

		TxD_start			=> TxD_start,			--	start send when set
		TxD_data				=> TxD_data,			-- data byte to send
		TxD_busy				=> TxD_busy				-- busy when set
	);

	des: entity async_receiver
	port map (
		clk					=> I_CK,
		RxD					=> I_RX,

		RxD_data				=> RxD_data,			-- received byte
		RxD_data_ready		=> RxD_data_ready		-- one clock pulse when RxD_data is valid
	);

	-- state machine
	state_machine : process(I_CK)
	begin
		if rising_edge(I_CK) then
			if I_RST = '0' then
				ena_out <= '0';
				state <= st_idle;
--				addr  <= (others=>'0');
			else
				case state is
				--		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
				--	0  nul soh stx etx eot enq ack bel  bs tab  lf  vt  ff  cr  so  si
				--	1  dle dc1 dc2 dc3 dc4 nak syn etb can  em eof esc  fs  gs  rs  us
				--	2       !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
				--	3   0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
				--	4   @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
				--	5   P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
				--	6   `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
				--	7   p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~   ?
				when st_idle =>
					TxD_start<= '0';
					if RxD_data_ready = '1' then
--						if (RxD_data and x"DF") > x"40" and (RxD_data and x"DF") < x"47" then -- "A"-"F"
--							addr  <= addr(19 downto 0) & (RxD_data(3 downto 0)+9);
--							ctr   <= 0;
--							state <= st_paddr0;
--						elsif RxD_data > x"2F" and RxD_data < x"3A" then
--							addr  <= addr(19 downto 0) & RxD_data(3 downto 0);
--							ctr   <= 0;
--							state <= st_paddr0;
--						elsif RxD_data = x"1B" then					-- "ESC" zero
--							addr  <= (others=>'0');
--							ctr   <= 0;
--							state <= st_paddr0;
--						elsif (RxD_data and x"DF") = x"56" then	-- "V" view data
--							ctr   <= 0;
--							wctr  <= 0;
--							state <= st_view0;
						if (RxD_data and x"DF") = x"48" then	-- "H" halt
							ena_out <= '0';
							state <= st_idle;
						elsif (RxD_data and x"DF") = x"52" then	-- "R" run
							ena_out <= '1';
						else
							state <= st_idle;
						end if;
					elsif I_SEL = '1' then
						state <= st_paddr0;
					end if;

				-- ########################################
				-- print line feed
				when st_paddr0 =>
					ena_out <= '0';
					TxD_start<= '0';
					TxD_data <= x"0A";	-- LF
					if TxD_busy = '0' and TxD_start = '0' then
						TxD_start <= '1';
						txdata    <= I_ADDR(23 downto 0);
						state     <= st_paddr1;
					end if;

				-- print 6 address hex digits
				when st_paddr1 =>
					TxD_start <= '0';
					if TxD_busy = '0' and TxD_start = '0' then
						if txdata(23 downto 20) > 9 then
							TxD_data <= x"37" + txdata(23 downto 20);	-- letters
						else
							TxD_data <= x"30" + txdata(23 downto 20);	-- numbers
						end if;
						if ctr = 5 then
							state <= st_view0;
						end if;
						txdata <= txdata(19 downto 0) & x"0";
						TxD_start <= '1';
						ctr <= ctr + 1;
					end if;

				-- ########################################
				-- print a space
				when st_view0 =>
					TxD_start<= '0';
					TxD_data <= x"20";	-- Space
					if TxD_busy = '0' and TxD_start = '0' then
						TxD_start <= '1';
						state  <= st_view1;
					end if;

				-- get word data from memory
				when st_view1 =>
					txdata <= I_DATA & x"00";
					state  <= st_view2;
					ctr <= 0;

				-- print 4 data hex digits
				when st_view2 =>
					TxD_start <= '0';
					if TxD_busy = '0' and TxD_start = '0' then
						if txdata(23 downto 20) > 9 then
							TxD_data <= x"37" + txdata(23 downto 20);	-- letters
						else
							TxD_data <= x"30" + txdata(23 downto 20);	-- numbers
						end if;
						txdata <= txdata(19 downto 0) & x"0";
						TxD_start <= '1';
						if ctr = 3 then
							ctr <= 0;
							state <= st_view3; -- finished
						else
							ctr <= ctr + 1;
						end if;
					end if;

				-- print a space
				when st_view3 =>
					TxD_start<= '0';
					TxD_data <= x"20";	-- Space
					if TxD_busy = '0' and TxD_start = '0' then
						TxD_start <= '1';
						state  <= st_view4;
					end if;

				-- print carriage return
				when st_view4 =>
					TxD_start<= '0';
					TxD_data <= x"0D";	-- CR
					if TxD_busy = '0' and TxD_start = '0' then
						TxD_start <= '1';
						state     <= st_view5;
					end if;

				when st_view5 =>
					ena_out <= '1';
					if I_SEL = '0' then
						state     <= st_idle;
					end if;
				when others =>
					state <= st_idle;
				end case;
			end if;
		end if;
	end process;
end RTL;
