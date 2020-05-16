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

--	Developer: Atari Games
--	Platform:  Arcade
--	Release:   1984
--	CPU:       Motorola 68010 @ 7.15909 MHz, MOS Technology 6502 @ 1.789772 MHz
--	Sound:     Yamaha YM2151 @ 3.579545, Atari POKEY @ 1.789772 MHz, Texas Instruments TMS5220@ 650.826 kHz
--	Display:   Raster, 336x240 resolution

library ieee;
	use ieee.std_logic_1164.all;

--pragma translate_off
	use ieee.std_logic_textio.all;
	use std.textio.all;
--pragma translate_on

entity FPGA_ATARISYS1 is
	generic (
		slap_type  : integer range 100 to 118 := 104
	);
	port(
		-- System Clock
		I_CLK_14M  : in  std_logic;
		I_CLK_7M   : in  std_logic;

		-- Active high reset
		I_RESET    : in  std_logic;

		-- Player controls, active low
		-- joysticks: U2,D2,L2,R2,U1,D1,L1,R1
		I_JOY      : in  std_logic_vector(7 downto 0);
		-- trackballs: HCLK2,VCLK2,HCLK1,VCLK1,HDIR2,VDIR2,HCLK1,VDIR1
		I_CLK      : in  std_logic_vector(3 downto 0);
		I_DIR      : in  std_logic_vector(3 downto 0);
		-- System inputs
		I_SYS      : in  std_logic_vector(4 downto 0);

		O_LEDS     : out std_logic_vector(2 downto 1);

		-- Audio out
		O_AUDIO_L  : out std_logic_vector( 7 downto 0) := (others=>'0');
		O_AUDIO_R  : out std_logic_vector( 7 downto 0) := (others=>'0');

		-- Monitor output
		O_VIDEO_I  : out std_logic_vector(3 downto 0);
		O_VIDEO_R  : out std_logic_vector(3 downto 0);
		O_VIDEO_G  : out std_logic_vector(3 downto 0);
		O_VIDEO_B  : out std_logic_vector(3 downto 0);
		O_HSYNC    : out std_logic;
		O_VSYNC    : out std_logic;
		O_CSYNC    : out std_logic;

		I_USB_RXD  : in  std_logic;
		O_USB_TXD  : out std_logic := '1';

		-- GFX ROMs, read from non existent ROMs MUST return FFFFFFFF
		O_GP_EN    : out std_logic := '0';
		O_GP_ADDR  : out std_logic_vector(17 downto 0) := (others=>'0');
		I_GP_DATA  : in  std_logic_vector(31 downto 0) := (others=>'0');
		-- Main Program ROMs
		O_MP_EN    : out std_logic := '0';
		O_MP_ADDR  : out std_logic_vector(18 downto 0) := (others=>'0');
		I_MP_DATA  : in  std_logic_vector(15 downto 0) := (others=>'0');
		-- Audio Program ROMs
		O_AP_EN    : out std_logic := '0';
		O_AP_ADDR  : out std_logic_vector(15 downto 0) := (others=>'0');
		I_AP_DATA  : in  std_logic_vector( 7 downto 0) := (others=>'0')
	);
end FPGA_ATARISYS1;

architecture RTL of FPGA_ATARISYS1 is
	signal
		sl_TBTEST,
		sl_TBRESn,
		sl_INT1n,
		sl_INT3n,
		sl_WAITn,
		sl_MA18n,
		sl_BASn,
		sl_1H,
		sl_2H,
		sl_4H,
		sl_32V,
		sl_W_Rn,
		sl_LDSn,
		sl_UDSn,
		sl_BLDS,
		sl_MEXTn,
		sl_VCPU,
		sl_WR68Kn,
		sl_RD68Kn,
		sl_SNDNMIn,
		sl_SNDINTn,
		sl_SNDRESn,
		sl_MO_PFn,
		sl_MATCHn,
		sl_MGHF,
		sl_SLAP,
		sl_GLDn,
		sl_CRAMn,
		sl_CRBUSn,
		sl_CRAMWRn,
		sl_VRAMWR,
		sl_VBUSn,
		sl_VRAC2,
		sl_VRAMn,
		sl_MBUSn,
		sl_VRDTACK,
		sl_VBLANKn,
		sl_VBKACKn,
		sl_VBKINTn,
		sl_MISCn,
		sl_PFSPCn,
		sl_VSCRLDn,
		sl_HSCRLDn
								: std_logic := '1';
	signal
		slv_SROMn
								: std_logic_vector( 2 downto 0) := (others=>'0');
	signal
		slv_ROMn
								: std_logic_vector( 3 downto 0) := (others=>'0');
	signal
		slv_MOSR
								: std_logic_vector( 6 downto 0) := (others=>'0');
	signal
		slv_PFSR,
		slv_SBDI,
		slv_SBDO
								: std_logic_vector( 7 downto 0) := (others=>'0');
	signal
		slv_SBA
								: std_logic_vector(13 downto 0) := (others=>'0');
	signal
		slv_VBUSD,
		slv_MEXTD,
		slv_MDO
								: std_logic_vector(15 downto 0) := (others=>'0');
	signal
		slv_MA
								: std_logic_vector(15 downto 1) := (others=>'0');
	signal
		slv_MGRA
								: std_logic_vector(19 downto 1) := (others=>'0');
begin
-- pragma translate_off
-- horizontal/vertical scroll offsets and plane selection for testing
--	stim : process
--	begin
--		sl_MISCn   <= '1';
--		sl_PFSPCn  <= '1';
--		sl_VSCRLDn <= '1';
--		sl_HSCRLDn <= '1';
--		sl_VBUSn   <= '0';
--		slv_MDO <= x"0000";
--		wait for 33.63us;
--
--		slv_MDO <= x"0040";
--		sl_R_Wn    <= '0';
--		wait for 2.84ns;
--		sl_VSCRLDn <= '0';
--		sl_HSCRLDn <= '0';
--		wait for 140ns;
--		sl_R_Wn    <= '1';
--		sl_VSCRLDn <= '1';
--		sl_HSCRLDn <= '1';
--		wait for 428.52ns;
--
--		slv_MDO <= x"00B0";
--		sl_R_Wn    <= '0';
--		wait for 2.84ns;
--		sl_MISCn   <= '0';
--		wait for 140ns;
--		sl_R_Wn    <= '1';
--		sl_MISCn   <= '1';
--		wait for 428.52ns;
--
--		slv_MDO <= x"0000";
--		sl_R_Wn    <= '0';
--		wait for 2.84ns;
--		sl_PFSPCn  <= '0';
--		wait for 140ns;
--		sl_R_Wn    <= '1';
--		sl_PFSPCn  <= '1';
--		wait for 428.52ns;
--
--		sl_VBUSn   <= '1';
--		wait;
--	end process;
-- pragma translate_on

	u_main : entity work.MAIN
	port map (
		I_MCKR      => I_CLK_7M,
		I_XCKR      => I_CLK_14M,
		I_4H        => sl_4H,
		I_RESET     => I_RESET,
		I_INT1n     => sl_INT1n,
		I_INT3n     => sl_INT3n,
		I_WAITn     => sl_WAITn,
		I_VRAC2     => sl_VRAC2,
		I_WR68Kn    => sl_WR68Kn,
		I_RD68Kn    => sl_RD68Kn,

		I_VBLANKn   => sl_VBLANKn,
		I_VBKINTn   => sl_VBKINTn,
		I_SNDRESn   => sl_SNDRESn,

		I_USB_RXD   => I_USB_RXD,
		O_USB_TXD   => O_USB_TXD,

		O_BW_Rn     => sl_W_Rn,
		O_CRAMn     => sl_CRAMn,
		O_CRAMWRn   => sl_CRAMWRn,
		O_VRAMWR    => sl_VRAMWR,
		O_CRBUSn    => sl_CRBUSn,

		O_VBKACKn   => sl_VBKACKn,
		O_VBUSn     => sl_VBUSn,
		O_MISCn     => sl_MISCn,
		O_PFSPCn    => sl_PFSPCn,
		O_VSCRLDn   => sl_VSCRLDn,
		O_HSCRLDn   => sl_HSCRLDn,
		O_SNDNMIn   => sl_SNDNMIn,
		O_SNDINTn   => sl_SNDINTn,
		O_SBD       => slv_SBDI,
		I_SBD       => slv_SBDO,

		-- inputs PB5, PB4, PB3, PB2, PB1, SELFTEST
		I_PB        => (others=>'1'),
		I_SELFTESTn => '1',

		-- interface to extenal ADC0809 chip
		O_ADC_SEL   => open,
		O_ADC_CLK   => open,
		O_ADC_ADDR  => open,
		I_ADC_DATA  => (others=>'1'),
		I_ADC_EOC   => '1', -- active low

		-- trackball interface
		I_LETA_CLK  => (others=>'1'),
		I_LETA_DIR  => (others=>'1'),
		I_LETA_TST  => sl_TBTEST,
		I_LETA_RES  => sl_TBRESn,

		-- to game cartridge
		O_MA18n     => sl_MA18n,
		O_BLDS      => sl_BLDS,
		O_SLAP      => sl_SLAP,
		O_ROMn      => slv_ROMn,
		O_BASn      => sl_BASn,
		O_MEXTn     => sl_MEXTn,
		O_MA        => slv_MA,
		O_MD        => slv_MDO,
		I_VBUSD     => slv_VBUSD,
		I_MEXTD     => slv_MEXTD
	);

	u_video : entity work.VIDEO
	port map (
		I_MCKR      => I_CLK_7M,
		I_XCKR      => I_CLK_14M,
		I_CRBUSn    => sl_CRBUSn,
		I_CRAMn     => sl_CRAMn,
		I_CRAMWRn   => sl_CRAMWRn,
		I_VRAMWR    => sl_VRAMWR,

		I_BW_Rn     => sl_W_Rn,
		I_VBUSn     => sl_VBUSn,
		I_MISCn     => sl_MISCn,
		I_PFSPCn    => sl_PFSPCn,
		I_VSCRLDn   => sl_VSCRLDn,
		I_HSCRLDn   => sl_HSCRLDn,
		I_VBKACKn   => '0',
		I_MOSR      => slv_MOSR,
		I_PFSR      => slv_PFSR,
		I_CPU_A     => slv_MA(13 downto 1),
		I_CPU_D     => slv_MDO,
		O_CPU_D     => slv_VBUSD,

		O_SNDRESn   => sl_SNDRESn,
		O_MGHF      => sl_MGHF,
		O_GLDn      => sl_GLDn,
		O_MO_PFn    => sl_MO_PFn,
		O_MATCHn    => sl_MATCHn,
		O_VBKINTn   => sl_VBKINTn,
		O_MGRA      => slv_MGRA,
		O_VRAC2     => sl_VRAC2,
		O_4H        => sl_4H,
		O_TBTEST    => sl_TBTEST,
		O_TBRESn    => sl_TBRESn,

		O_I         => O_VIDEO_I,
		O_R         => O_VIDEO_R,
		O_G         => O_VIDEO_G,
		O_B         => O_VIDEO_B,
		O_HSYNC     => O_HSYNC,
		O_VSYNC     => O_VSYNC,
		O_CSYNC     => O_CSYNC
	);

	u_cart : entity work.INDY_CART
	port map (
		I_MCKR      => I_CLK_7M,

		I_SLAPn     => sl_SLAP,
		I_MEXTn     => sl_MEXTn,
		I_BLDSn     => sl_BLDS,
		I_BASn      => sl_BASn,
		I_BW_Rn     => sl_W_Rn,
		O_INT1n     => sl_INT1n,
		O_INT3n     => sl_INT3n,
		O_WAITn     => sl_WAITn,
		I_ROMn      => slv_ROMn,
		I_MA18n     => sl_MA18n,
		I_MA        => slv_MA,
		O_MD        => slv_MEXTD,

		I_SROMn     => slv_SROMn,
		I_SBA       => slv_SBA,
		I_MGRA      => slv_MGRA,
		I_MATCHn    => sl_MATCHn,
		I_MGHF      => sl_MGHF,
		I_GLDn      => sl_GLDn,
		I_MO_PFn    => sl_MO_PFn,
		I_SNDRSTn   => sl_SNDRESn,
		I_SNDBW_Rn  => sl_W_Rn,
		I_B02       => '0', -- From Sound Section

		-- video
		O_MOSR      => slv_MOSR,
		O_PFSR      => slv_PFSR,

		-- sound
		O_SNDL      => open,
		O_SNDR      => open
	);

--	u_audio : entity work.AUDIO
--	port map (
--		I_MCKR      => I_CLK_7M,
--
--		I_1H        => sl_1H,
--		I_2H        => sl_2H,
--		I_32V       => sl_32V,
--		I_VBLANKn   => sl_VBLANKn,
--
--		I_SNDNMIn   => sl_SNDNMIn,
--		I_SNDINTn   => sl_SNDINTn,
--		I_SNDRESn   => sl_SNDRESn,
--
--		I_SELFTESTn => I_SYS(4),
--		I_COIN      => I_SYS(3 downto 0),	-- 1L, 2, 3, 4R
--
--		I_SBD       => slv_SBDI,
--		O_SBD       => slv_SBDO,
--		O_WR68Kn    => sl_WR68Kn,
--		O_RD68Kn    => sl_RD68Kn,
--
--		O_CCTR1n    => open,	-- coin counter open collector active low
--		O_CCTR2n    => open,	-- coin counter open collector active low
--		O_AUDIO_L   => O_AUDIO_L,
--		O_AUDIO_R   => O_AUDIO_R,
--
--		-- external audio ROMs
--		O_AP_EN     => O_AP_EN,
--		O_AP_AD     => O_AP_ADDR,
--		I_AP_DI     => I_AP_DATA
--	);
end RTL;
