--	(c) 2023 d18c7db(a)hotmail
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
-- Code partially generated with help from OpenAI's ChatGPT

-- P1     U D L R
-- f20001 - + + -
-- f20003 + - + -
--
-- P2     U D L R
-- f20005 - + + -
-- f20007 + - + -

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LETA is
port (
	clk   : in  std_logic;  -- actual system clock network
	ck    : in  std_logic;  -- LETA "clock", typically 8H or about 14KHz
	resn  : in  std_logic;
	cs    : in  std_logic;
	test  : in  std_logic;
	ad    : in  std_logic_vector(1 downto 0);
	clks  : in  std_logic_vector(3 downto 0); -- HCLK2,VCLK2,HCLK1,VCLK1
	dirs  : in  std_logic_vector(3 downto 0); -- HDIR2,VDIR2,HDIR1,VDIR1
	db    : out std_logic_vector(7 downto 0)
);
end entity LETA;

architecture rtl of LETA is
	type counter_array is array(3 downto 0) of std_logic_vector(7 downto 0);
	signal counters  : counter_array := (others => (others => '0'));
	signal clks_last : std_logic_vector(3 downto 0) := (others => '0');
	signal ck_last   : std_logic := '0';
begin
	process(clk)
	begin
		if rising_edge(clk) then
			db <= (others => '0');
			if cs = '0' then
				if test = '1' then
					db <= not(clks(3) & dirs(3) & clks(2) & dirs(2) & clks(1) & dirs(1) & clks(0) & dirs(0));
				else
					db <= counters(to_integer(unsigned(ad)));
				end if;
			end if;

			ck_last <= ck;
			-- we trigger on rising edge of LETA clock
			if resn = '1' then
				-- reset counters
				counters <= (others => (others => '0'));
			elsif ck_last = '0' and ck = '1' then
				-- update counters based on clks transitions and dirs
				clks_last <= clks;
--				for i in 0 to 3 loop
--					if clks_last(i) = '0' and clks(i) = '1' then
--						if dirs(i) = '1' then
--							counters(i) <= std_logic_vector(unsigned(counters(i)) + 1);
--						else
--							counters(i) <= std_logic_vector(unsigned(counters(i)) - 1);
--						end if;
--					end if;
--				end loop;

				-- VCLK1
				if clks_last(0) = '0' and clks(0) = '1' then
					-- VDIR1
					if dirs(0) = '0' then
						-- U
						counters(0) <= std_logic_vector(unsigned(counters(0)) - 1);
						counters(1) <= std_logic_vector(unsigned(counters(1)) + 1);
					else
						-- D
						counters(0) <= std_logic_vector(unsigned(counters(0)) + 1);
						counters(1) <= std_logic_vector(unsigned(counters(1)) - 1);
					end if;
				end if;
				-- HCLK1
				if clks_last(1) = '0' and clks(1) = '1' then
					-- HDIR1
					if dirs(1) = '0' then
						-- L
						counters(0) <= std_logic_vector(unsigned(counters(0)) - 1);
						counters(1) <= std_logic_vector(unsigned(counters(1)) - 1);
					else
						-- R
						counters(0) <= std_logic_vector(unsigned(counters(0)) + 1);
						counters(1) <= std_logic_vector(unsigned(counters(1)) + 1);
					end if;
				end if;
				-- VCLK2
				if clks_last(2) = '0' and clks(2) = '1' then
					-- VDIR2
					if dirs(2) = '0' then
						-- U
						counters(2) <= std_logic_vector(unsigned(counters(2)) - 1);
						counters(3) <= std_logic_vector(unsigned(counters(3)) + 1);
					else
						-- D
						counters(2) <= std_logic_vector(unsigned(counters(2)) + 1);
						counters(3) <= std_logic_vector(unsigned(counters(3)) - 1);
					end if;
				end if;
				-- HCLK2
				if clks_last(3) = '0' and clks(3) = '1' then
					-- HDIR2
					if dirs(3) = '0' then
						-- L
						counters(2) <= std_logic_vector(unsigned(counters(2)) - 1);
						counters(3) <= std_logic_vector(unsigned(counters(3)) - 1);
					else
						-- R
						counters(2) <= std_logic_vector(unsigned(counters(2)) + 1);
						counters(3) <= std_logic_vector(unsigned(counters(3)) + 1);
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture rtl;
