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
-- Ïndiana Jones and the Temple of Doom cartridge for Atari System 1
-- controls
-- UP1 up
-- DN1 down
-- LT1 left
-- RT1 right
-- SW1 start1/whip
-- SW2 start2/whip

-- ROM mapping on PCB
-- VIDEO             VIDEO             VIDEO             VIDEO
-- 1B  2B  3B  4B    6B  7B  8B  9B    1C  2C  3C  4C    6C  7C  8C  9C
-- 135 136 137 138   139 140 141 142   143 144 145 146   147 148 149 150

-- MAINCPU           MAINCPU           PROMS        AUDIOCPU
-- 10A 12A 14A 16A   10B 12B 14B 16B   4/5A  7A     13D 14/15D 16D
-- 431 433 457 359   432 434 456 358   151   152    153  154   155
-- 132 134 156 158   131 133 157 159   151   152    153  154   155

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity INDY_CART is
port(
	I_MCKR       : in  std_logic;

	I_SLAPn      : in  std_logic;
	I_MEXTn      : in  std_logic;
	I_BLDSn      : in  std_logic;
	I_BASn       : in  std_logic;
	I_BW_Rn      : in  std_logic;
	O_INT1n      : out std_logic;
	O_INT3n      : out std_logic;
	O_WAITn      : out std_logic;
	I_MA18n      : in  std_logic;
	I_MA         : in  std_logic_vector(15 downto 1);
	O_MD         : out std_logic_vector(15 downto 0);

	I_ROMn       : in  std_logic_vector( 3 downto 0);
	I_SROMn      : in  std_logic_vector( 2 downto 0);
	I_SBA        : in  std_logic_vector(13 downto 0);
	I_MGRA       : in  std_logic_vector(19 downto 1);
	I_MATCHn     : in  std_logic;
	I_MGHF       : in  std_logic;
	I_GLDn       : in  std_logic;
	I_MO_PFn     : in  std_logic;
	I_SNDRSTn    : in  std_logic;
	I_SNDBW_Rn   : in  std_logic;
	I_B02        : in  std_logic;

	-- video
	O_MOSR       : out std_logic_vector(6 downto 0);
	O_PFSR       : out std_logic_vector(7 downto 0);

	-- sound
	O_SNDL       : out std_logic_vector(7 downto 0);
	O_SNDR       : out std_logic_vector(7 downto 0)
);
end INDY_CART;

architecture logic of INDY_CART is
	signal
		sl_GCS4n,
		sl_GCS3n,
		sl_GCS2n,
		sl_GCS1n,
		sl_GD7P7,
		sl_GD7P6,
		sl_GD7P5,
		sl_GD7P4,
		sl_BASn,
		sl_SLAPn,
		sl_MEXTn,
		sl_BLDSn,
		sl_BW_Rn,
		sl_GBA15n,
		sl_INT1n,
		sl_INT3n,
		sl_WAITn,
		sl_MA18n,
		sl_BMO_PFn,
		sl_MATCHn,
		sl_MGHF,
		sl_GLDn,
		sl_SNDRSTn,
		sl_SNDBW_Rn,
		sl_B02,
		sl_NOROM7n,
		sl_NOROM6n,
		sl_NOROM5n,
		sl_NOROM4n
								: std_logic:='1';
	signal
		slv_BS
								: std_logic_vector( 1 downto 0):=(others=>'0');
	signal
		slv_SROMn
								: std_logic_vector( 2 downto 0):=(others=>'1');
	signal
		slv_ROMn
								: std_logic_vector( 3 downto 0):=(others=>'1');
	signal
		slv_MOSR
								: std_logic_vector( 6 downto 0):=(others=>'1');
	signal
		slv_PFSR,
		slv_SMD,
		slv_5B_DB,
		slv_5B_DA,
		slv_5C_DB,
		slv_5C_DA,
		slv_ROM_16A,
		slv_ROM_16B,
		slv_ROM_10A,
		slv_ROM_10B,
		slv_ROM_12A,
		slv_ROM_12B,
		slv_ROM_14A,
		slv_ROM_14B,
		slv_ROM_4A,
		slv_ROM_7A,
		slv_ROM_13D,
		slv_ROM_14D,
		slv_ROM_16D,
		slv_ROM_1B,
		slv_ROM_2B,
		slv_ROM_3B,
		slv_ROM_4B,
		slv_ROM_6B,
		slv_ROM_7B,
		slv_ROM_8B,
		slv_ROM_9B,
		slv_ROM_1C,
		slv_ROM_2C,
		slv_ROM_3C,
		slv_ROM_4C,
		slv_ROM_6C,
		slv_ROM_7C,
		slv_ROM_8C,
		slv_ROM_9C
								: std_logic_vector( 7 downto 0):=(others=>'1');
	signal
		slv_SBA
								: std_logic_vector(13 downto 0):=(others=>'0');
	signal
		slv_MA
								: std_logic_vector(15 downto 1):=(others=>'0');
	signal
		slv_MD
								: std_logic_vector(15 downto 0):=(others=>'0');
	signal
		slv_GBA
								: std_logic_vector(15 downto 1):=(others=>'0');
	signal
		slv_MGRA
								: std_logic_vector(19 downto 1):=(others=>'0');
begin
	sl_SLAPn    <= I_SLAPn;
	sl_MEXTn    <= I_MEXTn;
	sl_BLDSn    <= I_BLDSn;
	sl_BASn     <= I_BASn;
	sl_BW_Rn    <= I_BW_Rn;
	sl_MA18n    <= I_MA18n;
	sl_MATCHn   <= I_MATCHn;
	sl_MGHF     <= I_MGHF;
	sl_GLDn     <= I_GLDn;
	sl_BMO_PFn  <= I_MO_PFn;
	sl_SNDRSTn  <= I_SNDRSTn;
	sl_SNDBW_Rn <= I_SNDBW_Rn;
	sl_B02      <= I_B02;

	slv_SBA     <= I_SBA;
	slv_MGRA    <= I_MGRA;

	slv_MA      <= I_MA;
	O_MD        <= slv_MD;

	slv_ROMn    <= I_ROMn;
	slv_SROMn   <= I_SROMn;

	O_MOSR      <= slv_MOSR;
	O_PFSR      <= slv_PFSR;
	O_INT1n     <= sl_INT1n;
	O_INT3n     <= sl_INT3n;
	O_WAITn     <= sl_WAITn;

	O_SNDL <= (others=>'0'); -- FIXME
	O_SNDR <= (others=>'0');

	-------------
	-- sheet 2 --
	-- sheet 3 --
	-------------
	p_17A : entity work.SLAPSTIC
	generic map (chip_type=>105)
	port map (
		I_CK  => I_MCKR,
		I_ASn => sl_BASn,
		I_CSn => sl_SLAPn,
		I_A   => slv_MA(14 downto 1),
		O_BS  => slv_BS
	);

	-- SLAPSTIC controlled ROMs
	ROM_16A : entity work.ROM_359 port map ( CLK=>I_MCKR, DATA=>slv_ROM_16A, ADDR(13 downto 12)=>slv_BS, ADDR(11 downto 0)=>slv_MA(12 downto 1) );
	ROM_16B : entity work.ROM_358 port map ( CLK=>I_MCKR, DATA=>slv_ROM_16B, ADDR(13 downto 12)=>slv_BS, ADDR(11 downto 0)=>slv_MA(12 downto 1) );

	-- MAIN CPU ROMs
	ROM_10A : entity work.ROM_431 port map ( CLK=>I_MCKR, DATA=>slv_ROM_10A, ADDR=>slv_MA(15 downto 1) );
	ROM_10B : entity work.ROM_432 port map ( CLK=>I_MCKR, DATA=>slv_ROM_10B, ADDR=>slv_MA(15 downto 1) );
	ROM_12A : entity work.ROM_433 port map ( CLK=>I_MCKR, DATA=>slv_ROM_12A, ADDR=>slv_MA(15 downto 1) );
	ROM_12B : entity work.ROM_434 port map ( CLK=>I_MCKR, DATA=>slv_ROM_12B, ADDR=>slv_MA(15 downto 1) );
	ROM_14A : entity work.ROM_457 port map ( CLK=>I_MCKR, DATA=>slv_ROM_14A, ADDR=>slv_MA(14 downto 1) );
	ROM_14B : entity work.ROM_456 port map ( CLK=>I_MCKR, DATA=>slv_ROM_14B, ADDR=>slv_MA(14 downto 1) );

	slv_MD <=
		slv_ROM_10B & slv_ROM_10A when sl_MA18n = '1' and slv_ROMn(1) = '0' else
		slv_ROM_12B & slv_ROM_12A when sl_MA18n = '1' and slv_ROMn(2) = '0' else
		slv_ROM_14B & slv_ROM_14A when sl_MA18n = '1' and slv_ROMn(3) = '0' else
		slv_ROM_16B & slv_ROM_16A when sl_MA18n = '1' and sl_SLAPn = '0' else
		(others=>'Z');

	-------------
	-- sheet 4 --
	-------------

	-- FIXME implement 14D/E 6522
	-- FIXME implement 14E   TMS5220

--	slv_SMD <=
--		slv_ROM_13D when sl_SNDBW_Rn = '0' and slv_SROMn(0) = '0' else
--		slv_ROM_14D when sl_SNDBW_Rn = '0' and slv_SROMn(1) = '0' else
--		slv_ROM_16D when sl_SNDBW_Rn = '0' and slv_SROMn(2) = '0' else
--		(others=>'Z');
--
--	-- AUDIO CPU ROMs
--	ROM_13D : entity work.ROM_153 port map ( CLK=>I_MCKR, DATA=>slv_ROM_13D, ADDR=>slv_SBA(13 downto 0) );
--	ROM_14D : entity work.ROM_154 port map ( CLK=>I_MCKR, DATA=>slv_ROM_14D, ADDR=>slv_SBA(13 downto 0) );
--	ROM_16D : entity work.ROM_155 port map ( CLK=>I_MCKR, DATA=>slv_ROM_16D, ADDR=>slv_SBA(13 downto 0) );

	-- PROMs
	ROM_4A  : entity work.ROM_151 port map ( CLK=>I_MCKR, DATA=>slv_ROM_4A, ADDR(8)=>sl_BMO_PFn, ADDR(7 downto 0)=>slv_MGRA(19 downto 12) );
	ROM_7A  : entity work.ROM_152 port map ( CLK=>I_MCKR, DATA=>slv_ROM_7A, ADDR(8)=>sl_BMO_PFn, ADDR(7 downto 0)=>slv_MGRA(19 downto 12) );

	-- implement pullups
	sl_NOROM7n <= slv_ROM_4A(7) when sl_MATCHn = '0' else '1';
	sl_NOROM6n <= slv_ROM_4A(6) when sl_MATCHn = '0' else '1';
	sl_NOROM5n <= slv_ROM_4A(5) when sl_MATCHn = '0' else '1';
	sl_NOROM4n <= slv_ROM_4A(4) when sl_MATCHn = '0' else '1';

	sl_GD7P7   <= slv_ROM_4A(3) when sl_MATCHn = '0' else '1';
	sl_GD7P6   <= slv_ROM_4A(2) when sl_MATCHn = '0' else '1';
	sl_GD7P5   <= slv_ROM_4A(1) when sl_MATCHn = '0' else '1';
	sl_GD7P4   <= slv_ROM_4A(0) when sl_MATCHn = '0' else '1';

	sl_GCS4n   <= slv_ROM_7A(7) when sl_MATCHn = '0' else '1';
	sl_GCS3n   <= slv_ROM_7A(6) when sl_MATCHn = '0' else '1';
	sl_GCS2n   <= slv_ROM_7A(5) when sl_MATCHn = '0' else '1';
	sl_GCS1n   <= slv_ROM_7A(4) when sl_MATCHn = '0' else '1';


	-- gate 9A
	sl_GBA15n <= not slv_GBA(15);

	-- buffers 3A, 6A
	slv_GBA(15 downto 12) <= slv_ROM_7A(3 downto 0)  when sl_MATCHn = '0' else "1111"; -- FIXME what happens to these lines when PROM /CS is inactive?
	slv_GBA(11 downto  1) <= slv_MGRA(11 downto 1);

	-------------
	-- sheet 5 --
	-------------

	-- 5B Storage/Logic Array Graphics Shifter
	u_5B : entity work.SLAGS
	port map (
		I_MCKR     => I_MCKR,
		I_B        => slv_5B_DB,
		I_A        => slv_5B_DA,
		I_HLDBn    => '1',
		I_HLDAn    => '1',
		I_FLP      => sl_MGHF,
		I_MO_PFn   => sl_BMO_PFn,
		I_LDn      => sl_GLDn,

		O_PFDA     => slv_PFSR(1),
		O_PFDB     => slv_PFSR(0),
		O_MODA     => slv_MOSR(1),
		O_MODB     => slv_MOSR(0)
	);

	slv_5B_DB <=
		slv_ROM_1B when sl_GCS1n = '0' else
		slv_ROM_2B when sl_GCS2n = '0' else
		slv_ROM_3B when sl_GCS3n = '0' else
		slv_ROM_4B when sl_GCS4n = '0' else
		(others=>'1');
	slv_5B_DA <=
		slv_ROM_6B when sl_GCS1n = '0' else
		slv_ROM_7B when sl_GCS2n = '0' else
		slv_ROM_8B when sl_GCS3n = '0' else
		slv_ROM_9B when sl_GCS4n = '0' else
		(others=>'1');

	ROM_1B : entity work.ROM_135 port map ( CLK=>I_MCKR, DATA=>slv_ROM_1B, ADDR=>slv_GBA(15 downto 1) );
	ROM_2B : entity work.ROM_136 port map ( CLK=>I_MCKR, DATA=>slv_ROM_2B, ADDR=>slv_GBA(15 downto 1) );
	ROM_3B : entity work.ROM_137 port map ( CLK=>I_MCKR, DATA=>slv_ROM_3B, ADDR=>slv_GBA(15 downto 1) );
	ROM_4B : entity work.ROM_138 port map ( CLK=>I_MCKR, DATA=>slv_ROM_4B, ADDR=>slv_GBA(15 downto 1) );
	ROM_6B : entity work.ROM_139 port map ( CLK=>I_MCKR, DATA=>slv_ROM_6B, ADDR=>slv_GBA(15 downto 1) );
	ROM_7B : entity work.ROM_140 port map ( CLK=>I_MCKR, DATA=>slv_ROM_7B, ADDR=>slv_GBA(15 downto 1) );
	ROM_8B : entity work.ROM_141 port map ( CLK=>I_MCKR, DATA=>slv_ROM_8B, ADDR=>slv_GBA(15 downto 1) );
	ROM_9B : entity work.ROM_142 port map ( CLK=>I_MCKR, DATA=>slv_ROM_9B, ADDR=>slv_GBA(15 downto 1) );

	-------------
	-- sheet 6 --
	-------------

	-- 5C Storage/Logic Array Graphics Shifter
	u_5C : entity work.SLAGS
	port map (
		I_MCKR     => I_MCKR,
		I_B        => slv_5C_DB,
		I_A        => slv_5C_DA,
		I_HLDBn    => '1',
		I_HLDAn    => '1',
		I_FLP      => sl_MGHF,
		I_MO_PFn   => sl_BMO_PFn,
		I_LDn      => sl_GLDn,

		O_PFDA     => slv_PFSR(3),
		O_PFDB     => slv_PFSR(2),
		O_MODA     => slv_MOSR(3),
		O_MODB     => slv_MOSR(2)
	);

	slv_5C_DB <=
		slv_ROM_1C when sl_GCS1n = '0' else
		slv_ROM_2C when sl_GCS2n = '0' else
		slv_ROM_3C when sl_GCS3n = '0' else
		slv_ROM_4C when sl_GCS4n = '0' else
		(others=>'1');
	slv_5C_DA <=
		slv_ROM_6C when sl_GCS1n = '0' else
		slv_ROM_7C when sl_GCS2n = '0' else
		slv_ROM_8C when sl_GCS3n = '0' else
		slv_ROM_9C when sl_GCS4n = '0' else
		(others=>'1');

	ROM_1C : entity work.ROM_143 port map ( CLK=>I_MCKR, DATA=>slv_ROM_1C, ADDR=>slv_GBA(15 downto 1) );
	ROM_2C : entity work.ROM_144 port map ( CLK=>I_MCKR, DATA=>slv_ROM_2C, ADDR=>slv_GBA(15 downto 1) );
	ROM_3C : entity work.ROM_145 port map ( CLK=>I_MCKR, DATA=>slv_ROM_3C, ADDR=>slv_GBA(15 downto 1) );
	ROM_4C : entity work.ROM_146 port map ( CLK=>I_MCKR, DATA=>slv_ROM_4C, ADDR=>slv_GBA(15 downto 1) );
	ROM_6C : entity work.ROM_147 port map ( CLK=>I_MCKR, DATA=>slv_ROM_6C, ADDR=>slv_GBA(15 downto 1) );
	ROM_7C : entity work.ROM_148 port map ( CLK=>I_MCKR, DATA=>slv_ROM_7C, ADDR=>slv_GBA(15 downto 1) );
	ROM_8C : entity work.ROM_149 port map ( CLK=>I_MCKR, DATA=>slv_ROM_8C, ADDR=>slv_GBA(15 downto 1) );
	ROM_9C : entity work.ROM_150 port map ( CLK=>I_MCKR, DATA=>slv_ROM_9C, ADDR=>slv_GBA(15 downto 1) );

	-------------
	-- sheet 7 --
	-------------
	-- 5D Storage/Logic Array Graphics Shifter
	u_5D : entity work.SLAGS
	port map (
		I_MCKR          => I_MCKR,
		I_B(7)          => sl_GD7P4,
		I_B(6 downto 0) => (others=>'1'), -- no ROMs fitted on PCB
		I_A(7)          => sl_GD7P5,
		I_A(6 downto 0) => (others=>'1'), -- no ROMs fitted on PCB
		I_HLDBn         => sl_NOROM4n,
		I_HLDAn         => sl_NOROM5n,
		I_FLP           => sl_MGHF,
		I_MO_PFn        => sl_BMO_PFn,
		I_LDn           => sl_GLDn,

		O_PFDA          => slv_PFSR(5),
		O_PFDB          => slv_PFSR(4),
		O_MODA          => slv_MOSR(5),
		O_MODB          => slv_MOSR(4)
	);

	-------------
	-- sheet 8 --
	-------------
	-- 5E Storage/Logic Array Graphics Shifter
	u_5E : entity work.SLAGS
	port map (
		I_MCKR          => I_MCKR,
		I_B(7)          => sl_GD7P6,
		I_B(6 downto 0) => (others=>'1'), -- no ROMs fitted on PCB
		I_A(7)          => sl_GD7P7,
		I_A(6 downto 0) => (others=>'1'), -- no ROMs fitted on PCB
		I_HLDBn         => sl_NOROM6n,
		I_HLDAn         => sl_NOROM7n,
		I_FLP           => sl_MGHF,
		I_MO_PFn        => sl_BMO_PFn,
		I_LDn           => sl_GLDn,

		O_PFDA          => slv_PFSR(7),
		O_PFDB          => slv_PFSR(6),
		O_MODA          => open,
		O_MODB          => slv_MOSR(6)
	);
end;
