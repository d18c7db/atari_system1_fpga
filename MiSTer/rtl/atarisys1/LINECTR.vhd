--	(c) 2020 d18c7db(a)hotmail
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
-- Custom chip LBC 137419-102

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity LINECTR is
	port(
		I_MCKR   : in  std_logic;
		I_VRD    : in  std_logic_vector(15 downto 5);
		I_NXLn   : in  std_logic;

		O_BQ     : out std_logic_vector(8 downto 0);
		O_PA     : out std_logic;
		O_PAn    : out std_logic;
		O_GLDn   : out std_logic;
		O_H01n   : out std_logic;
		O_H02n   : out std_logic;
		O_H03n   : out std_logic;
		O_MOn    : out std_logic
	);
end LINECTR;

architecture RTL of LINECTR is
	signal
		sl_LDn,
		sl_4H,
		sl_PAD,
		sl_NXLn,
		sl_CLRn,
		sl_GLDn,
		sl_H01n,
		sl_H02n,
		sl_H03n,
		sl_MOSR7D,
		sl_BUFCLRn,
		sl_MOn
								: std_logic := '1';
	signal
		slv_H
								: std_logic_vector( 2 downto 0) := (others=>'1');
	signal
		slv_NXL_delay
								: std_logic_vector( 7 downto 0) := (others=>'1');
	signal
		slv_LB,
		slv_3J
								: std_logic_vector( 8 downto 0) := (others=>'1');
begin
	O_GLDn     <= sl_GLDn;
	O_H01n     <= sl_H01n;
	O_H02n     <= sl_H02n;
	O_H03n     <= sl_H03n;
	O_PAn      <= not sl_PAD;
	O_PA       <=     sl_PAD;
	O_BQ       <= slv_LB;
	O_MOn      <= sl_MOn;
	sl_NXLn    <= I_NXLn;
	sl_4H      <= slv_H(2);
	sl_BUFCLRn <= slv_NXL_delay(7);
	sl_CLRn    <= sl_PAD or sl_BUFCLRn;

	-- recreate part of the horizontal counter and generate other internal signals
	p_hcnt : process
	begin
		wait until rising_edge(I_MCKR);
		-- /BUFCLR signal is just /NXL delayed 8 clocks
		slv_NXL_delay <= slv_NXL_delay(6 downto 0) & sl_NXLn;
		-- create PADB signal from recovered /BUFCLRN
		sl_PAD   <= (not sl_PAD) xor sl_BUFCLRn;

		if (sl_NXLn='0' and sl_4H='1') then
			slv_H<="111";
		else
			slv_H <= slv_H + 1;
		end if;
	end process;

	-- 4J, 3D on SP-277 schema sheet 8
	sl_LDn  <= sl_4H or sl_H02n or sl_PAD;

	-- 2H 1H  /H03 /H02 /H01 /GLD
	-- 0  0    1    1    1    0
	-- 0  1    1    1    0    1
	-- 1  0    1    0    1    1
	-- 1  1    0    1    1    1
	sl_GLDn <= ((    slv_H(1)) or (    slv_H(0)));
	sl_H01n <= ((    slv_H(1)) or (not slv_H(0)));
	sl_H02n <= ((not slv_H(1)) or (    slv_H(0)));
	sl_H03n <= ((not slv_H(1)) or (not slv_H(0)));

	-- 3T, 3R, 3W, 3U, 3S, 3X counters
	p_ctrs : process
	begin
		wait until rising_edge(I_MCKR);
		if sl_CLRn = '0' then
			slv_LB <= (others=>'0');
		elsif sl_LDn = '0' then
			slv_LB <= slv_3J;
		else
			slv_LB <= slv_LB + 1;
		end if;
	end process;

--         V     V         V     V
--/4HD3  __--------________--------__
-- 4HD3  --________--------________--
--/4HDD  --------________--------____
-- 4HDD  ________--------________----
-- 4HD   ______--------________------
-- 4H    ____--------________--------
-- GLDn  ----__------__------__------
-- H01   ------__------__------__----
-- H02   __------__------__------__--
-- H03   --__------__------__------__
-- MCKR  -_-_-_-_-_-_-_-_-_-_-_-_-_-_

	p_MOSR7 : process
	begin
		wait until rising_edge(I_MCKR);
		if (sl_H01n = '0') and (sl_4H = '1') then -- rising 4HDD
			sl_MOSR7D  <= I_VRD(15);
			slv_3J     <= I_VRD(13 downto 5); -- latch 3J
		end if;
		if (sl_H02n = '0') and (sl_4H = '0') then -- rising /4HD3
			sl_MOn <= sl_MOSR7D; -- VRD15 delayed by 4HDD and then by /4HD3
		end if;
	end process;
end RTL;
