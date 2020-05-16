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

library ieee;
	use ieee.std_logic_1164.all;

-- ROMs organized as 512K x 16
entity ROMS_EXT is
	generic (
		chip_type			: integer range 100 to 118 := 104
	);
	port(
		CLK		: in	std_logic;
		ENA		: in	std_logic;
		ADDR		: in	std_logic_vector(20 downto 0);
		DATA		: out	std_logic_vector(15 downto 0)
	);
end ROMS_EXT;

architecture RTL of ROMS_EXT is
	signal
		slv_ROM_2B , slv_ROM_5F , slv_ROM_10J, slv_ROM_11J,
		slv_ROM_135, slv_ROM_136, slv_ROM_137, slv_ROM_138, slv_ROM_139,
		slv_ROM_140, slv_ROM_141, slv_ROM_142, slv_ROM_143,
		slv_ROM_144, slv_ROM_145, slv_ROM_146, slv_ROM_147,
		slv_ROM_148, slv_ROM_149, slv_ROM_150, slv_ROM_151,
		slv_ROM_152, slv_ROM_153, slv_ROM_154, slv_ROM_155,
		slv_ROM_358, slv_ROM_359,
		slv_ROM_431, slv_ROM_432, slv_ROM_433, slv_ROM_434, slv_ROM_456, slv_ROM_457
		: std_logic_vector( 7 downto 0) := (others=>'1');
begin
		-- top 6 address bits map each ROM into external memory space
	DATA <=
--		slv_ROM_16R & slv_ROM_16S when ADDR(20 downto 15)="000000"  and ENA = '1' else -- B0000-B7FFF 16K-32K Audio
		(others=>'1');

	-- System1 ROMs
	ROM_2B  : entity work.ROM_2B  port map ( CLK=>CLK, DATA=>slv_ROM_2B , ADDR=>ADDR(12 downto 0) );
	ROM_5F  : entity work.ROM_5F  port map ( CLK=>CLK, DATA=>slv_ROM_5F , ADDR=>ADDR(12 downto 0) );
	ROM_10J : entity work.ROM_10J port map ( CLK=>CLK, DATA=>slv_ROM_10J, ADDR=>ADDR(13 downto 0) );
	ROM_11J : entity work.ROM_11J port map ( CLK=>CLK, DATA=>slv_ROM_11J, ADDR=>ADDR(13 downto 0) );

	-- indytemp cart ROMs
	ROM_135 : entity work.ROM_135 port map ( CLK=>CLK, DATA=>slv_ROM_135, ADDR=>ADDR(14 downto 0) );
	ROM_136 : entity work.ROM_136 port map ( CLK=>CLK, DATA=>slv_ROM_136, ADDR=>ADDR(14 downto 0) );
	ROM_137 : entity work.ROM_137 port map ( CLK=>CLK, DATA=>slv_ROM_137, ADDR=>ADDR(14 downto 0) );
	ROM_138 : entity work.ROM_138 port map ( CLK=>CLK, DATA=>slv_ROM_138, ADDR=>ADDR(14 downto 0) );
	ROM_139 : entity work.ROM_139 port map ( CLK=>CLK, DATA=>slv_ROM_139, ADDR=>ADDR(14 downto 0) );
	ROM_140 : entity work.ROM_140 port map ( CLK=>CLK, DATA=>slv_ROM_140, ADDR=>ADDR(14 downto 0) );
	ROM_141 : entity work.ROM_141 port map ( CLK=>CLK, DATA=>slv_ROM_141, ADDR=>ADDR(14 downto 0) );
	ROM_142 : entity work.ROM_142 port map ( CLK=>CLK, DATA=>slv_ROM_142, ADDR=>ADDR(14 downto 0) );
	ROM_143 : entity work.ROM_143 port map ( CLK=>CLK, DATA=>slv_ROM_143, ADDR=>ADDR(14 downto 0) );
	ROM_144 : entity work.ROM_144 port map ( CLK=>CLK, DATA=>slv_ROM_144, ADDR=>ADDR(14 downto 0) );
	ROM_145 : entity work.ROM_145 port map ( CLK=>CLK, DATA=>slv_ROM_145, ADDR=>ADDR(14 downto 0) );
	ROM_146 : entity work.ROM_146 port map ( CLK=>CLK, DATA=>slv_ROM_146, ADDR=>ADDR(14 downto 0) );
	ROM_147 : entity work.ROM_147 port map ( CLK=>CLK, DATA=>slv_ROM_147, ADDR=>ADDR(14 downto 0) );
	ROM_148 : entity work.ROM_148 port map ( CLK=>CLK, DATA=>slv_ROM_148, ADDR=>ADDR(14 downto 0) );
	ROM_149 : entity work.ROM_149 port map ( CLK=>CLK, DATA=>slv_ROM_149, ADDR=>ADDR(14 downto 0) );
	ROM_150 : entity work.ROM_150 port map ( CLK=>CLK, DATA=>slv_ROM_150, ADDR=>ADDR(14 downto 0) );
	ROM_151 : entity work.ROM_151 port map ( CLK=>CLK, DATA=>slv_ROM_151, ADDR=>ADDR( 8 downto 0) );
	ROM_152 : entity work.ROM_152 port map ( CLK=>CLK, DATA=>slv_ROM_152, ADDR=>ADDR( 8 downto 0) );
	ROM_153 : entity work.ROM_153 port map ( CLK=>CLK, DATA=>slv_ROM_153, ADDR=>ADDR(13 downto 0) );
	ROM_154 : entity work.ROM_154 port map ( CLK=>CLK, DATA=>slv_ROM_154, ADDR=>ADDR(13 downto 0) );
	ROM_155 : entity work.ROM_155 port map ( CLK=>CLK, DATA=>slv_ROM_155, ADDR=>ADDR(13 downto 0) );
	ROM_358 : entity work.ROM_358 port map ( CLK=>CLK, DATA=>slv_ROM_358, ADDR=>ADDR(13 downto 0) );
	ROM_359 : entity work.ROM_359 port map ( CLK=>CLK, DATA=>slv_ROM_359, ADDR=>ADDR(13 downto 0) );
	ROM_431 : entity work.ROM_431 port map ( CLK=>CLK, DATA=>slv_ROM_431, ADDR=>ADDR(14 downto 0) );
	ROM_432 : entity work.ROM_432 port map ( CLK=>CLK, DATA=>slv_ROM_432, ADDR=>ADDR(14 downto 0) );
	ROM_433 : entity work.ROM_433 port map ( CLK=>CLK, DATA=>slv_ROM_433, ADDR=>ADDR(14 downto 0) );
	ROM_434 : entity work.ROM_434 port map ( CLK=>CLK, DATA=>slv_ROM_434, ADDR=>ADDR(14 downto 0) );
	ROM_456 : entity work.ROM_456 port map ( CLK=>CLK, DATA=>slv_ROM_456, ADDR=>ADDR(13 downto 0) );
	ROM_457 : entity work.ROM_457 port map ( CLK=>CLK, DATA=>slv_ROM_457, ADDR=>ADDR(13 downto 0) );
end RTL;
