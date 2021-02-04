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
	use ieee.numeric_std.all;

--pragma translate_off
	use ieee.std_logic_textio.all;
	use std.textio.all;
--pragma translate_on

entity FPGA_ATARISYS1 is
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
		I_SLAP_TYPE: in  integer range 0 to 118; -- slapstic type can be changed dynamically

		O_LEDS     : out std_logic_vector(2 downto 1);

		-- Audio out
		O_AUDIO_L  : out std_logic_vector(15 downto 0) := (others=>'0');
		O_AUDIO_R  : out std_logic_vector(15 downto 0) := (others=>'0');

		-- Monitor output
		O_VIDEO_I  : out std_logic_vector(3 downto 0);
		O_VIDEO_R  : out std_logic_vector(3 downto 0);
		O_VIDEO_G  : out std_logic_vector(3 downto 0);
		O_VIDEO_B  : out std_logic_vector(3 downto 0);
		O_HSYNC    : out std_logic;
		O_VSYNC    : out std_logic;
		O_CSYNC    : out std_logic;

--		I_USB_RXD  : in  std_logic;
--		O_USB_TXD  : out std_logic := '1';
		O_HBLANK   : out	std_logic;
		O_VBLANK   : out	std_logic;

		-- video ROMs addr/data bus
		O_VADDR    : out std_logic_vector(16 downto 0);
		I_5C_DB    : in  std_logic_vector( 7 downto 0);
		I_5C_DA    : in  std_logic_vector( 7 downto 0);
		I_5B_DB    : in  std_logic_vector( 7 downto 0);
		I_5B_DA    : in  std_logic_vector( 7 downto 0)
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
		sl_SNDBW_Rn,
		sl_LDSn,
		sl_UDSn,
		sl_BLDS,
		sl_B02,
		sl_MEXTn,
		sl_VCPU,
		sl_WR68Kn,
		sl_RD68Kn,
		sl_SNDNMIn,
		sl_SNDRESn,
		sl_SNDEXTn,
		sl_SNDINTn,
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
		sl_HBLANKn,
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
		s_POK_out
								: signed( 5 downto 0) := (others => '0');
	signal
		slv_MOSR
								: std_logic_vector( 6 downto 0) := (others=>'0');
	signal
		slv_PFSR,
		slv_SMDI,
--		slv_SMDO,
		slv_SBDI,
		slv_SBDO
								: std_logic_vector( 7 downto 0) := (others=>'0');
	signal
		s_TMS_out
								: signed(13 downto 0) := (others => '0');
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
		s_chan_l,
		s_chan_r,
		s_audio_YML,
		s_audio_YMR
								: signed(15 downto 0) := (others => '0');
	signal
		slv_MGRA
								: std_logic_vector(19 downto 1) := (others=>'0');
begin
-- pragma translate_off
-- horizontal/vertical scroll offsets and plane selection for testing
--	stim : process
--	begin
--		wait until rising_edge(sl_VSYNC);
--		slv_MDO  <= x"0000";
--		sl_W_Rn  <= '0';
--		sl_HSCRLDn <= '1'; -- 800000 Play Field Horizontal Scroll
--		sl_VSCRLDn <= '1'; -- 820000 PFV
--		sl_PFSPCn  <= '1'; -- 840000 Play Field H scroll
--		sl_MISCn   <= '1'; -- 860000 Bank Select "..MMMP.A"
--		sl_VBUSn   <= '0';
--		wait for 2*140 ns;
--
--		slv_MDO <= x"0040";
--		sl_W_Rn <= '1';
--		wait for 8*140 ns;
--		sl_HSCRLDn <= '0';
--		wait for 8*140 ns;
--		sl_HSCRLDn <= '1';
--		sl_W_Rn <= '0';
--		wait for 8*140 ns;
--
--		slv_MDO <= x"0040";
--		sl_W_Rn <= '1';
--		wait for 8*140 ns;
--		sl_VSCRLDn <= '0';
--		wait for 8*140 ns;
--		sl_VSCRLDn <= '1';
--		sl_W_Rn <= '0';
--		wait for 8*140 ns;
--
--		slv_MDO <= x"0000";
--		sl_W_Rn <= '1';
--		wait for 8*140 ns;
--		sl_PFSPCn <= '0';
--		wait for 8*140 ns;
--		sl_PFSPCn <= '1';
--		sl_W_Rn <= '0';
--		wait for 8*140 ns;
--
--		slv_MDO <= x"0090";
--		sl_W_Rn <= '1';
--		wait for 8*140 ns;
--		sl_MISCn <= '0';
--		wait for 8*140 ns;
--		sl_MISCn <= '1';
--		sl_W_Rn <= '0';
--		wait for 8*140 ns;
--
--		slv_MDO <= x"0000";
--		sl_VBUSn   <= '1';
--	end process;
--pragma translate_on

	O_HBLANK <= sl_HBLANKn;
	O_VBLANK <= sl_VBLANKn;

	u_main : entity work.MAIN
	port map (
		I_MCKR      => I_CLK_7M,
		I_XCKR      => I_CLK_14M,
		I_RESET     => I_RESET,
		I_VBLANKn   => sl_VBLANKn,
		I_VBKINTn   => sl_VBKINTn,

		I_4H        => sl_4H,
		I_INT1n     => sl_INT1n,
		I_INT3n     => sl_INT3n,
		I_WAITn     => sl_WAITn,
		I_VRAC2     => sl_VRAC2,
		I_WR68Kn    => sl_WR68Kn,
		I_RD68Kn    => sl_RD68Kn,

		I_SNDRESn   => sl_SNDRESn,

--		I_USB_RXD   => I_USB_RXD,
--		O_USB_TXD   => O_USB_TXD,

		O_BW_Rn     => sl_W_Rn,
		O_CRAMn     => sl_CRAMn,
		O_CRAMWRn   => sl_CRAMWRn,
		O_VRAMWR    => sl_VRAMWR,
		O_CRBUSn    => sl_CRBUSn,

		O_HSCRLDn   => sl_HSCRLDn,
		O_SNDNMIn   => sl_SNDNMIn,
		O_SNDINTn   => sl_SNDINTn,
		O_VBKACKn   => sl_VBKACKn,
		O_VBUSn     => sl_VBUSn,
		O_MISCn     => sl_MISCn,
		O_PFSPCn    => sl_PFSPCn,
		O_VSCRLDn   => sl_VSCRLDn,
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
		I_ADC_EOC   => '0', -- active high

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
		I_VBKACKn   => sl_VBKACKn,
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
		O_1H        => sl_1H,
		O_2H        => sl_2H,
		O_4H        => sl_4H,
		O_TBTEST    => sl_TBTEST,
		O_TBRESn    => sl_TBRESn,

		O_VBLANKn   => sl_VBLANKn,
		O_HBLANKn   => sl_HBLANKn,
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
		I_SLAP_TYPE => I_SLAP_TYPE,
		I_MCKR      => I_CLK_7M,
		I_XCKR      => I_CLK_14M,

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
		I_SMD       => slv_SBDO, --slv_SMDO, -- from Audio
		O_SMD       => slv_SMDI, -- to Audio
		I_SBA       => slv_SBA,

		I_MGRA      => slv_MGRA,
		I_MATCHn    => sl_MATCHn,
		I_MGHF      => sl_MGHF,
		I_GLDn      => sl_GLDn,
		I_MO_PFn    => sl_MO_PFn,
		I_SNDEXTn   => sl_SNDEXTn,
		I_SNDRSTn   => sl_SNDRESn,
		I_SNDBW_Rn  => sl_SNDBW_Rn,
		I_B02       => sl_B02,

		-- video
		O_MOSR      => slv_MOSR,
		O_PFSR      => slv_PFSR,

		-- sound L and R are the same
		O_SND       => s_TMS_out,
		O_VADDR     => O_VADDR,
		I_5C_DB     => I_5C_DB,
		I_5C_DA     => I_5C_DA,
		I_5B_DB     => I_5B_DB,
		I_5B_DA     => I_5B_DA
	);

	u_audio : entity work.AUDIO
	port map (
		I_MCKR      => I_CLK_7M,
		I_1H        => sl_1H,
		I_2H        => sl_2H,
		O_B02       => sl_B02,

		I_SNDNMIn   => sl_SNDNMIn,
		I_SNDRSTn   => sl_SNDRESn,
		I_SNDINTn   => sl_SNDINTn,
		O_SNDBW_Rn  => sl_SNDBW_Rn,
		O_WR68Kn    => sl_WR68Kn,
		O_RD68Kn    => sl_RD68Kn,

		I_SELFTESTn => '1', -- FIXME connect inputs
		I_COIN_AUX  => '1', -- FIXME connect inputs
		I_COIN_L    => '1', -- FIXME connect inputs
		I_COIN_R    => '1', -- FIXME connect inputs

		O_LED       => open,	-- LED indicators
		O_CCTRn     => open,	-- coin counters open collector active low
		O_YM_L      => s_audio_YML,
		O_YM_R      => s_audio_YMR,
		O_PKS       => s_POK_out,

		O_SROMn     => slv_SROMn,
		O_SNDEXTn   => sl_SNDEXTn,
		O_SBA       => slv_SBA,
		O_SBD       => slv_SBDO,
		I_SMD       => slv_SMDI,
--		O_SMD       => slv_SMDO,
		I_SBD       => slv_SBDI
	);

	p_volmux : process
	begin
		wait until rising_edge(I_CLK_7M);
		-- add signed outputs together, already have extra spare bits for overflow
		s_chan_l <= ( ((s_TMS_out & "00") + s_audio_YML) + (s_POK_out(s_POK_out'left) & s_POK_out & "000000000") );
		s_chan_r <= ( ((s_TMS_out & "00") + s_audio_YMR) + (s_POK_out(s_POK_out'left) & s_POK_out & "000000000") );

		-- convert to unsigned slv for DAC usage
		O_AUDIO_L <= std_logic_vector(s_chan_l + 16383);
		O_AUDIO_R <= std_logic_vector(s_chan_r + 16383);
	end process;

end RTL;
