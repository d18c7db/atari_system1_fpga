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
-- Indiana Jones and the Temple of Doom cartridge for Atari System 1
-- From SP-282 schematic (identical to SP-280 just different page order)
--
-- controls
-- UP1 up
-- DN1 down
-- LT1 left
-- RT1 right
-- SW1 start1/whip
-- SW2 start2/whip

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ATARI_CART is
port(
	I_SLAP_TYPE  : in  integer range 0 to 118; -- slapstic type can be changed dynamically
	I_MCKR       : in  std_logic;
	I_XCKR       : in  std_logic;

	I_BLDSn      : in  std_logic;
	I_BASn       : in  std_logic;
	I_BW_Rn      : in  std_logic;
	O_INT1n      : out std_logic;
	O_INT3n      : out std_logic;
	O_WAITn      : out std_logic;

	-- sound ROMs
	I_SBA        : in  std_logic_vector(13 downto 0);
	I_SMD        : in  std_logic_vector( 7 downto 0);
	O_SMD        : out std_logic_vector( 7 downto 0);

	-- main ROMs
	I_SLAPn      : in  std_logic;
	I_MA18n      : in  std_logic;
	I_MADDR      : in  std_logic_vector(15 downto 1);

	I_MGRA       : in  std_logic_vector(19 downto 1);
	I_MATCHn     : in  std_logic;
	I_MGHF       : in  std_logic;
	I_GLDn       : in  std_logic;
	I_MO_PFn     : in  std_logic;
	I_SNDEXTn    : in  std_logic;
	I_SNDRSTn    : in  std_logic;
	I_SNDBW_Rn   : in  std_logic;
	I_B02        : in  std_logic;

	-- video
	O_MOSR       : out std_logic_vector(6 downto 0);
	O_PFSR       : out std_logic_vector(7 downto 0);

	-- sound L and R are identical
	O_SND        : out signed(13 downto 0);

	-- CPU address to ROMs after Slapstic decoding
	O_MADDR      : out std_logic_vector(15 downto 1);

	-- PROMs
	O_PADDR      : out std_logic_vector( 8 downto 0);
	I_PD4A       : in  std_logic_vector( 7 downto 0);
	I_PD7A       : in  std_logic_vector( 7 downto 0);

	-- sound ROMs
	I_SDATA      : in  std_logic_vector( 7 downto 0);

	-- video ROMs
	O_VADDR      : out std_logic_vector(16 downto 0);
	I_VDATA      : in  std_logic_vector(31 downto 0)
);
end ATARI_CART;

architecture logic of ATARI_CART is
	signal
		sl_MCKF,
		sl_GD7P7,
		sl_GD7P6,
		sl_GD7P5,
		sl_GD7P4,
		sl_BASn,
		sl_SLAPn,
		sl_BLDSn,
		sl_BW_Rn,
		sl_GBA15n,
		sl_INT1n,
		sl_INT3n,
		sl_WAITn,
		sl_BMO_PFn,
		sl_MATCHn,
		sl_MGHF,
		sl_GLDn,
		sl_SNDEXTn,
		sl_SNDRSTn,
		sl_SNDBR_Wn,
		sl_B02,
		sl_NOROM7n,
		sl_NOROM6n,
		sl_NOROM5n,
		sl_NOROM4n,
		sl_TMS_EN,
		sl_TMS_RDYn,
		sl_TMS_INTn
								: std_logic:='1';
	signal
		slv_BS
								: std_logic_vector( 1 downto 0):=(others=>'0');
	signal
		slv_GCSn
								: std_logic_vector( 4 downto 1):=(others=>'1');
	signal
		slv_14S
								: std_logic_vector( 3 downto 0):=(others=>'1');
	signal
		slv_MOSR
								: std_logic_vector( 6 downto 0):=(others=>'1');
	signal
		slv_PBO,
		slv_TMS_DI,
		slv_TMS_DO,
		slv_PFSR,
		slv_VIA_DI,
		slv_SMDO,
		slv_VIA_DO,
		slv_5B_DB,
		slv_5B_DA,
		slv_5C_DB,
		slv_5C_DA,
		slv_5D_DB,
		slv_5D_DA,
		slv_5E_DB,
		slv_5E_DA
								: std_logic_vector( 7 downto 0):=(others=>'1');
	signal
		slv_SBA
								: std_logic_vector(13 downto 0):=(others=>'0');
	signal
		slv_MADDR
								: std_logic_vector(15 downto 1):=(others=>'0');
	signal
		slv_GBA
								: std_logic_vector(15 downto 1):=(others=>'0');
	signal
		slv_MGRA
								: std_logic_vector(19 downto 1):=(others=>'0');
begin
	O_VADDR(14 downto 0) <= slv_GBA;
	O_VADDR(16 downto 15) <=
		"00" when slv_GCSn(1) = '0' else
		"01" when slv_GCSn(2) = '0' else
		"10" when slv_GCSn(3) = '0' else
		"11" when slv_GCSn(4) = '0' else
		(others=>'1');

	sl_SLAPn    <= I_SLAPn;
	sl_BLDSn    <= I_BLDSn;
	sl_BASn     <= I_BASn;
	sl_BW_Rn    <= I_BW_Rn;
	sl_MATCHn   <= I_MATCHn;
	sl_MGHF     <= I_MGHF;
	sl_GLDn     <= I_GLDn;
	sl_BMO_PFn  <= I_MO_PFn;
	sl_SNDEXTn  <= I_SNDEXTn;
	sl_SNDRSTn  <= I_SNDRSTn;
	sl_SNDBR_Wn <= not I_SNDBW_Rn;
	sl_B02      <= I_B02;

	slv_SBA     <= I_SBA;
	slv_MGRA    <= I_MGRA;

	slv_MADDR   <= I_MADDR;

	O_SMD       <= slv_SMDO;
	slv_VIA_DI  <= I_SMD;

	O_MOSR      <= slv_MOSR;
	O_PFSR      <= slv_PFSR;
	O_INT1n     <= sl_INT1n;
	O_INT3n     <= sl_INT3n;
	O_WAITn     <= sl_WAITn;

	----------------------------------------
	-- sheet 2 SP-282 -- (sheet 8 SP-280) --
	-- sheet 3 SP-282 -- (sheet 7 SP-280) --
	----------------------------------------
	p_17A : entity work.SLAPSTIC
	port map (
		I_SLAP_TYPE => I_SLAP_TYPE,
		I_CK  => I_MCKR,
		I_ASn => sl_BASn,
		I_CSn => sl_SLAPn,
		I_A   => slv_MADDR(14 downto 1),
		O_BS  => slv_BS
	);

	-- Main CPU ROMs
	-- if slapstic selected use descrambled addresses else use normal addresses
	O_MADDR <= slv_MADDR(15 downto 1) when sl_SLAPn = '1' else '0' & slv_BS & slv_MADDR(12 downto 1);

	----------------------------------------
	-- sheet 4 SP-282 -- (sheet 2 SP-280) --
	----------------------------------------

	-- 14D 6522 VIA
	u_14D : entity work.M6522
	port map (
		I_RS        => slv_SBA(3 downto 0),
		I_DATA      => slv_VIA_DI,
		O_DATA      => slv_VIA_DO,
		O_DATA_OE_L => open,

		I_RW_L      => sl_SNDBR_Wn,
		I_CS1       => '1',
		I_CS2_L     => sl_SNDEXTn,

		O_IRQ_L     => open,

		-- Port A
		I_CA1       => '1',
		I_CA2       => '1',
		O_CA2       => open,
		O_CA2_OE_L  => open,

		I_PA        => slv_TMS_DO,
		O_PA        => slv_TMS_DI,
		O_PA_OE_L   => open,

		-- Port B
		I_CB1       => '1',
		O_CB1       => open,
		O_CB1_OE_L  => open,

		I_CB2       => '1',
		O_CB2       => open,
		O_CB2_OE_L  => open,

		I_PB(7)     => slv_PBO(7),
		I_PB(6)     => slv_PBO(6),
		I_PB(5)     => slv_PBO(5),
		I_PB(4)     => slv_PBO(4),
		I_PB(3)     => sl_TMS_INTn,
		I_PB(2)     => sl_TMS_RDYn,
		I_PB(1)     => slv_PBO(1),
		I_PB(0)     => slv_PBO(0),

		O_PB        => slv_PBO,
		O_PB_OE_L   => open,

		I_P2_H      => sl_B02, -- FIXME
		RESET_L     => sl_SNDRSTn,
		ENA_4       => '1',-- FIXME
		CLK         => sl_MCKF
	);
	-- running 6522 off inverted clk gives it a chance to place data on the
	-- data bus in time for 6502 to read it else the CPU misses it
	sl_MCKF <= not I_MCKR;

	-- 12E counter is clocked by 7.159MHz and provides TMS5220 clock
	-- when PB4 is 0 counter is preset with 5, else 7 then counts up to F before being preset again
	--	divide by 11 gives 650.8KHz, divide by 9 gives 795.4KHz
	p_14S : process
	begin
		wait until rising_edge(I_MCKR);
		if slv_14S = "1111" or sl_SNDRSTn = '0' then
			slv_14S <= "01" & slv_PBO(4) & '1';
		else
			slv_14S <= slv_14S + 1;
		end if;
	end process;

	-- generate TMS5220 clock enable
	sl_TMS_EN <= '1' when (slv_14S="1111") else '0';

	-- 14E TMS5220
	u_14E : entity work.TMS5220
	port map (
		I_OSC    => I_MCKR,
		I_ENA    => sl_TMS_EN,
		I_WSn    => slv_PBO(0),
		I_RSn    => slv_PBO(1),
		I_DATA   => '1',
		I_TEST   => '1',
		I_DBUS   => slv_TMS_DI,

		O_DBUS   => slv_TMS_DO,
		O_RDYn   => sl_TMS_RDYn,
		O_INTn   => sl_TMS_INTn,

		O_M0     => open,
		O_M1     => open,
		O_ADD8   => open,
		O_ADD4   => open,
		O_ADD2   => open,
		O_ADD1   => open,
		O_ROMCLK => open,

		O_T11    => open,
		O_IO     => open,
		O_PRMOUT => open,
		O_SPKR   => O_SND
	);

	-- sound ROMs
	slv_SMDO <= slv_VIA_DO when (sl_SNDEXTn = '0') else I_SDATA;

	--	PROMs
	O_PADDR <= sl_BMO_PFn & slv_MGRA(19 downto 12);

	-- implement pullups
	sl_NOROM7n <= I_PD4A(7) when sl_MATCHn = '0' else '1';
	sl_NOROM6n <= I_PD4A(6) when sl_MATCHn = '0' else '1';
	sl_NOROM5n <= I_PD4A(5) when sl_MATCHn = '0' else '1';
	sl_NOROM4n <= I_PD4A(4) when sl_MATCHn = '0' else '1';

	sl_GD7P7   <= I_PD4A(3) when sl_MATCHn = '0' else '1';
	sl_GD7P6   <= I_PD4A(2) when sl_MATCHn = '0' else '1';
	sl_GD7P5   <= I_PD4A(1) when sl_MATCHn = '0' else '1';
	sl_GD7P4   <= I_PD4A(0) when sl_MATCHn = '0' else '1';
	--(sl_NOROM7n,sl_NOROM6n,sl_NOROM5n,sl_NOROM4n,sl_GD7P7,sl_GD7P6,sl_GD7P5,sl_GD7P4) <= I_PD4A when sl_MATCHn = '0' else (others=>'1');

	-- buffers 3A, 6A
	--(slv_GCSn,slv_GBA(15 downto 12)) <= I_PD7A when sl_MATCHn = '0' else (others=>'1');
	slv_GCSn <= I_PD7A(7 downto 4) when sl_MATCHn = '0' else (others=>'1');
	slv_GBA(15 downto 12) <= I_PD7A(3 downto 0)  when sl_MATCHn = '0' else (others=>'1'); -- FIXME what happens to these lines when PROM /CS is inactive?
	slv_GBA(11 downto  1) <= slv_MGRA(11 downto 1);

	-- gate 9A
	sl_GBA15n <= not slv_GBA(15);

	----------------------------------------
	-- sheet 5 SP-282 -- (sheet 4 SP-280) --
	----------------------------------------

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

	slv_5B_DB <= I_VDATA(31 downto 24);
	slv_5B_DA <= I_VDATA(23 downto 16);

	----------------------------------------
	-- sheet 6 SP-282 -- (sheet 5 SP-280) --
	----------------------------------------

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

	slv_5C_DB <= I_VDATA(15 downto 8);
	slv_5C_DA <= I_VDATA( 7 downto 0);

	----------------------------------------
	-- sheet 7 SP-282 -- (sheet 6 SP-280) --
	----------------------------------------
	-- 5D Storage/Logic Array Graphics Shifter
	u_5D : entity work.SLAGS
	port map (
		I_MCKR          => I_MCKR,
		I_B             => slv_5D_DB,
		I_A             => slv_5D_DA,
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

	-- for if no ROMs fitted on PCB
	slv_5D_DB <= sl_GD7P4 & "1111111" when sl_NOROM4n = '0' else I_VDATA(31 downto 24);
	slv_5D_DA <= sl_GD7P5 & "1111111" when sl_NOROM5n = '0' else I_VDATA(23 downto 16);

	----------------------------------------
	-- sheet 8 SP-282 -- (sheet 3 SP-280) --
	----------------------------------------
	-- 5E Storage/Logic Array Graphics Shifter
	u_5E : entity work.SLAGS
	port map (
		I_MCKR          => I_MCKR,
		I_B             => slv_5E_DB,
		I_A             => slv_5E_DA,
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

	-- for if no ROMs fitted on PCB
	slv_5E_DB <= sl_GD7P6 & "1111111" when sl_NOROM6n = '0' else I_VDATA(15 downto 8);
	slv_5E_DA <= sl_GD7P7 & "1111111" when sl_NOROM7n = '0' else I_VDATA( 7 downto 0);

end;
