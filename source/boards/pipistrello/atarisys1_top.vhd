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

--------------------------------------------------------------------------------
--	Top level for Atari System-1 arcade game targeted for Pipistrello board, basic h/w specs:
--		Spartan 6 LX45
--		50Mhz xtal oscillator
--		128Mbit serial Flash
--		2Mx16 SRAM 10ns on external board

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library unisim;
	use unisim.vcomponents.all;

library std;
	use std.textio.all;

entity ATARISYS1_TOP is
	port(
		-- FLASH
		FLASH_MOSI			: out	std_logic;								-- Serial output to FLASH chip SI pin
		FLASH_SCK			: out	std_logic;								-- FLASH clock
		FLASH_MISO			: in	std_logic;								-- Serial input from FLASH chip SO pin
		FLASH_WPn			: out	std_logic;								-- Write Protect
		FLASH_HOLDn			: out	std_logic;								-- Pause comm without deselecting
		FLASH_CSn			: out	std_logic;								-- Chip select

		-- EXTERNAL MEMORY
		MEM_A					: out	std_logic_vector(20 downto 0);	-- SRAM address bus
		MEM_D					: inout std_logic_vector(15 downto 0);	-- SRAM data bus
		SRAM_nCS				: out	std_logic;								-- SRAM chip select active low
		FLASH_nCE			: out	std_logic;								-- Active low FLASH chip select
		MEM_nWE				: out	std_logic;								-- SRAM write enable active low
		MEM_nOE				: out	std_logic;								-- SRAM output enable active low
		MEM_nBHE				: out	std_logic;								-- SRAM byte hi enable active low
		MEM_nBLE				: out	std_logic;								-- SRAM byte lo enable active low
		MEM_CK				: out	std_logic;

		-- RGB monitor output
--		O_VIDEO_R			: out	std_logic_vector(3 downto 0);
--		O_VIDEO_G			: out	std_logic_vector(3 downto 0);
--		O_VIDEO_B			: out	std_logic_vector(3 downto 0);
--		O_HSYNC				: out	std_logic;
--		O_VSYNC				: out	std_logic;

		I_USB_RXD			: in	std_logic;
		O_USB_TXD			: out	std_logic := '1';

--		-- HDMI monitor output
		TMDS_P,
		TMDS_N				: out	std_logic_vector(3 downto 0);

		-- Sound out
		O_AUDIO_L,
		O_AUDIO_R			: out	std_logic;

		-- External controller
		PMOD1_IO				: in	std_logic_vector(4 downto 1);
		PMOD2_IO				: in	std_logic_vector(4 downto 1);
		LEDS					: out	std_logic_vector(4 downto 1);

		I_RESET				: in	std_logic;								-- active high reset

		-- 50MHz clock
		CLK_IN				: in	std_logic := '0'						-- External clock
	);
end ATARISYS1_TOP;

architecture RTL of ATARISYS1_TOP is
	constant clk_type			: string :="SIM"; -- "CTR", "SIM", "DCM", "PLL"
	constant flash_length	: std_logic_vector(23 downto 0) := x"000002"; -- for faster simulation

	-- Define Cart1 params
	constant slap_type		: integer := 104;
	constant flash_address	: std_logic_vector(23 downto 0) := x"200000"; -- byte offset in flash
--	constant flash_length	: std_logic_vector(23 downto 0) := x"0C8000"; -- length in words

	-- bootstrap control of SRAM, these signals connect to SRAM when bs_done = '0'
	signal bs_AD			: std_logic_vector(20 downto 0) := (others => '0');
	signal bs_DO			: std_logic_vector(15 downto 0) := (others => '0');
	signal bs_nCS			: std_logic := '1';
	signal bs_nWE			: std_logic := '1';
	signal bs_nOE			: std_logic := '1';
	signal bs_nBLE			: std_logic := '1';
	signal bs_nBHE			: std_logic := '1';

	signal bs_done			: std_logic := '1';	-- low when FLASH is being copied to SRAM, can be used by user as active low reset
	signal bs_reset		: std_logic := '1';

	--
	-- ATARISYS1 signals
	--
	signal ram_state_ctr		: natural range 0 to 7 := 0;
	signal
		int_reset,
		ready,
		s_blank,
		clk_7M,    gclk_7M,
		clk_14M,   gclk_14M,
		clk_28M,   gclk_28M, clk_28M_inv,
		clk_dvi_p, gclk_dvi_p,
		clk_dvi_n, gclk_dvi_n,

		user_nCS,
		user_nWE,
		user_nOE,
		user_nBLE,
		user_nBHE,

		s_cmpblk_n,
		s_cmpblk_n_out,
		s_dac_out_l,
		s_dac_out_r,
		s_hsync_n,
		s_vsync_n,
		s_AP_EN,
		s_GP_EN,
		s_MP_EN,
		HSync,
		VSync
								: std_logic := '1';
	-- video
	signal
		s_int,
		s_red,
		s_grn,
		s_blu,
		VideoI,
		VideoR,
		VideoG,
		VideoB
								: std_logic_vector(3 downto 0) := (others => '0');
	signal
		s_audio_l,
		s_audio_r
								: std_logic_vector( 7 downto 0) := (others => '0');

	signal s_GP_DATA		: std_logic_vector(31 downto 0) := (others => '0');
	signal s_MP_DATA		: std_logic_vector(15 downto 0) := (others => '0');
	signal s_AP_DATA		: std_logic_vector( 7 downto 0) := (others => '0');

	signal s_GP_ADDR		: std_logic_vector(17 downto 0) := (others => '0');
	signal s_MP_ADDR		: std_logic_vector(18 downto 0) := (others => '0');
	signal s_AP_ADDR		: std_logic_vector(15 downto 0) := (others => '0');

	signal user_AD			: std_logic_vector(20 downto 0) := (others => '0');
	signal user_DI			: std_logic_vector(15 downto 0) := (others => '0');

begin
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- SRAM Bootstrap begins here
------------------------------------------------------------------------------
------------------------------------------------------------------------------

	-- SRAM muxer, allows access to physical SRAM by either bootstrap or user
	MEM_D		<= bs_DO		when bs_done = '0' and bs_nWE = '0' else (others => 'Z');	-- no need for user write
	MEM_A		<= bs_AD		when bs_done = '0' else user_AD;
	SRAM_nCS	<= bs_nCS	when bs_done = '0' else user_nCS;
	MEM_nWE	<= bs_nWE	when bs_done = '0' else user_nWE;
	MEM_nOE	<= bs_nOE	when bs_done = '0' else user_nOE;

	MEM_nBHE	<= bs_nBHE	when bs_done = '0' else user_nBHE;	-- for accessing hi byte lane
	MEM_nBLE	<= bs_nBLE	when bs_done = '0' else user_nBLE;	-- for accessing lo byte lane

	FLASH_nCE	<= '1'; -- SST39LF800A deselected

	-- this isn't needed, just used in the testbench to simulate a 10ns access delay
	ODDR2_inst : ODDR2 generic map(DDR_ALIGNMENT=>"NONE", INIT=>'0', SRTYPE=>"SYNC")
		port map (Q=>MEM_CK, C0=>clk_28M, C1=>clk_28M_inv, CE=>'1', D0=>'1', D1=>'0', R=>'0', S=>'0');
	clk_28M_inv <= not clk_28M;

	u_bs : entity work.bootstrap
	generic map (
		-- Keep the first 2MB of flash available for FPGA bitstream so place game ROM data starting at flash offset 0x200000
		user_address	=> flash_address,
		user_length		=> flash_length
	)
	port map (
		I_CLK				=> gclk_28M,
		I_RESET			=> bs_reset,
		-- FLASH interface
		I_FLASH_SO		=> FLASH_MISO,	-- to FLASH chip SPI output
		O_FLASH_CK		=> FLASH_SCK,	-- to FLASH chip SPI clock
		O_FLASH_CS		=> FLASH_CSn,	-- to FLASH chip select
		O_FLASH_SI		=> FLASH_MOSI,	-- to FLASH chip SPI input
		O_FLASH_WPn		=> FLASH_WPn,  -- N25Q128A write enabled
		O_FLASH_HOLDn	=> FLASH_HOLDn,-- N25Q128A hold deactivated
		-- SRAM interface
		O_A				=> bs_AD,
		O_DOUT			=> bs_DO,
		O_nCS				=> bs_nCS,
		O_nWE				=> bs_nWE,
		O_nOE				=> bs_nOE,
		O_BHEn			=> bs_nBHE,
		O_BLEn			=> bs_nBLE,
		O_BS_DONE		=> bs_done -- reset output to rest of machine
	);

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- USER portion begins here
------------------------------------------------------------------------------
------------------------------------------------------------------------------

	-- Audio output
	O_AUDIO_L	<= s_dac_out_l;
	O_AUDIO_R	<= s_dac_out_r;

	-- VGA output
--	O_HSYNC		<= HSync;
--	O_VSYNC		<= VSync;
--	O_VIDEO_R	<= VideoR;
--	O_VIDEO_G	<= VideoG;
--	O_VIDEO_B	<= VideoB;

	user_nCS		<= '0';				-- SRAM always selected
	user_nOE		<= '0';				-- SRAM output enabled
	user_nWE		<= '1';				-- SRAM write enable inactive (we use it as ROM)
	user_nBLE	<= '0';
	user_nBHE	<= '0';

	int_reset	<= not bs_done;	-- active high reset

	-- Clock
	u_clks : entity work.TIMING
	generic map (
		clk_type => clk_type
	)
	port map(
		I_CLK => CLK_IN,		-- 50MHz clock
		I_RST => I_RESET,		-- active high reset input
		O_RST => bs_reset,	-- active high reset output
		O_CK0 => clk_7M,		-- 7MHz
		O_CK1 => clk_14M,		-- 14MHz
		O_CK2 => clk_28M,		-- 28MHz
		O_CK3 => clk_dvi_p,	-- 140MHz pos
		O_CK4 => clk_dvi_n,	-- 140MHz neg
		O_CK5 => open			-- UNUSED
	);

	-- route clocks on global clock lines
	clk0_bufg : BUFG port map (O => gclk_7M   , I => clk_7M   );
	clk1_bufg : BUFG port map (O => gclk_14M  , I => clk_14M  );
	clk2_bufg : BUFG port map (O => gclk_28M  , I => clk_28M  );
	clk3_bufg : BUFG port map (O => gclk_dvi_p, I => clk_dvi_p);
	clk4_bufg : BUFG port map (O => gclk_dvi_n, I => clk_dvi_n);

	u_ATARISYS1 : entity work.FPGA_ATARISYS1
	generic map (slap_type=>slap_type)
	port map(
		-- System Clock
		I_CLK_14M	=> gclk_14M,
		I_CLK_7M		=> gclk_7M,

		-- Active high reset
		I_RESET		=> int_reset,

		-- player controls, active low
		I_JOY			=> x"FF",		-- joysticks: U2,D2,L2,R2,U1,D1,L1,R1

		--	J103 pin 2 HORZ CLK2   LETA pin 1 DIR(3)
		--	J103 pin 3 HORZ DIR2   LETA pin 2 CLK(3)
		--	J103 pin 4 VERT CLK2   LETA pin 3 DIR(2)
		--	J103 pin 5 VERT DIR2   LETA pin 4 CLK(2)
		--	J103 pin 6 HORZ CLK1   LETA pin 5 DIR(1)
		--	J103 pin 7 HORZ DIR1   LETA pin 6 CLK(1)
		--	J103 pin 8 VERT CLK1   LETA pin 7 DIR(0)
		--	J103 pin 9 KEY
		--	J103 pin10 VERT DIR1   LETA pin 8 CLK(0)
		I_CLK			=> x"F",
		I_DIR			=> x"F",

		-- system inputs, active low
		I_SYS			=> "11111",		-- SW 5, 4, 3, 2, 1

		O_LEDS		=> open,	-- LED2, LED1

		-- Audio out
		O_AUDIO_L	=> s_audio_l,
		O_AUDIO_R	=> s_audio_r,

		-- VGA monitor output
		O_VIDEO_I	=> s_int,
		O_VIDEO_R	=> s_red,
		O_VIDEO_G	=> s_grn,
		O_VIDEO_B	=> s_blu,
		O_HSYNC		=> s_hsync_n,
		O_VSYNC		=> s_vsync_n,
		O_CSYNC		=> s_cmpblk_n,

		I_USB_RXD	=> I_USB_RXD,
		O_USB_TXD	=> O_USB_TXD,

		-- Access to external ROMs
		-- GFX ROMs
		O_GP_EN		=> s_GP_EN,  -- active high (GPEN)
		O_GP_ADDR	=> s_GP_ADDR,
		I_GP_DATA	=> s_GP_DATA,
		-- Main Program ROMs
		O_MP_EN		=> s_MP_EN,  -- active high (AS)
		O_MP_ADDR	=> s_MP_ADDR,
		I_MP_DATA	=> s_MP_DATA,
		-- Audio Program ROMs
		O_AP_EN		=> s_AP_EN,  -- active high (CPUENA)
		O_AP_ADDR	=> s_AP_ADDR,
		I_AP_DATA	=> s_AP_DATA
	);

-- Status indicators for debugging
	LEDS <= bs_reset & int_reset & I_RESET & '0';
--					L4			L3			L2			L1
--	L5    L2
-- uSD   L1
--	L3  HDMI
--	L4

	-----------------------------------------------------------------
	-- video scan converter required to display video on VGA hardware
	-----------------------------------------------------------------
	-- game native resolution 336x240 visible area or 456x262 total pixel area
	-- take note: the values below are relative to the CLK period not standard VGA clock period
	u_scan : entity work.VGA_SCANCONV
	generic map (
		-- mark start of active area of input video
		vstart      =>   88,  -- start  of active video
		vlength     =>  336,  -- length of active video

		-- parameters below affect output video timing
		-- these must add up to 456 (including hpad*2)
		hF				=>   8,	-- h front porch
		hS				=>  46,	-- h sync
		hB				=>  22,	-- h back porch
		hV				=> 336,	-- active video
		hpad			=>  22,	-- create H black border

		-- these should add up to 262 (including vpad*2)
		vF				=>   1,	-- v front porch
		vS				=>   1,	-- v sync
		vB				=>  20,	-- v back porch
		vV				=> 240,	-- active video
		vpad			=>   0	-- create V black border
	)
	port map (
		I_VIDEO(15 downto 12)=> s_int,
		I_VIDEO(11 downto 8) => s_red,
		I_VIDEO( 7 downto 4) => s_grn,
		I_VIDEO( 3 downto 0) => s_blu,

		I_HSYNC					=> s_hsync_n,
		I_VSYNC					=> s_vsync_n,
		--
		O_VIDEO(15 downto 12)=> VideoI,
		O_VIDEO(11 downto 8) => VideoR,
		O_VIDEO( 7 downto 4) => VideoG,
		O_VIDEO( 3 downto 0) => VideoB,
		O_HSYNC					=> HSync,
		O_VSYNC					=> VSync,
		O_CMPBLK_N				=> s_cmpblk_n_out,
		--
		CLK						=> clk_7M,
		CLK_x2					=> gclk_14M
	);

	s_blank <= not s_cmpblk_n_out;

	u_dvid : entity work.dvid
	port map(
		--clocks
		clk_p					=> gclk_dvi_p,
		clk_n					=> gclk_dvi_n,
		clk_pixel			=> gclk_28M,
		-- inputs
		red_p(7 downto 4)	=> VideoR,
		red_p(3 downto 0)	=> x"0",
		grn_p(7 downto 4)	=> VideoG,
		grn_p(3 downto 0)	=> x"0",
		blu_p(7 downto 4)	=> VideoB,
		blu_p(3 downto 0)	=> x"0",
		blank					=> s_blank,
		hsync					=> HSync,
		vsync					=> VSync,
		-- outputs
		tmds_p				=> TMDS_P,
		tmds_n				=> TMDS_N
	);

	-----------------------
	-- 1 bit D/A converters
	-----------------------
	u_dacl : entity work.DAC
	generic map (msbi_g => 7)
	port map (
		clk_i	=> gclk_28M,
		res_i	=> int_reset,
		dac_i	=> s_audio_l,
		dac_o	=> s_dac_out_l
	);

	u_dacr : entity work.DAC
	generic map (msbi_g => 7)
	port map (
		clk_i	=> gclk_28M,
		res_i	=> int_reset,
		dac_i	=> s_audio_r,
		dac_o	=> s_dac_out_r
	);

--	#################################################
-- ## Internal ROM addresses to external SRAM mapper

-- SRAM			ROMS
--	A20..15		A14..0

--	000000	-
--	000001	-
--	000010	-
--	000011	-
--	000100	-
--	000101	-
--	000110	-
--	000111	-
--	001000	-
--	001001	-
--	001010	-
--	001011	-
--	001100	-
--	001101	-
--	001110	-
--	001111	-
--	010000	-
--	010001	-
--	010010	-
--	010011	-
--	010100	-
--	010101	-
--	010110	-
--	010111	-
--	011000	-
--	011001	-
--	011010	-
--	011011	-
--	011100	-
--	011101	-
--	011110	-
--	011111	-

	-- multiplex internal ROMs to external SRAM
	p_ram_mux : process
	begin
		wait until rising_edge(gclk_28M);
		if ram_state_ctr /= 0 and clk_7M = '1' then
			ram_state_ctr <= 0;
		else
			ram_state_ctr <= ram_state_ctr + 1;
		end if;

		case ram_state_ctr is
			when 3 =>
				user_AD <= "01" & s_MP_ADDR;			-- set 68K program ROM address
			when 0 =>
				user_AD <= "000" & s_GP_ADDR;			-- set graphics ROM address for lower data word
				s_MP_DATA <= MEM_D; 						-- get 68K program data word
			when 1 =>
				user_AD <= "001" & s_GP_ADDR;			-- set graphics ROM address for upper data word
				s_GP_DATA(15 downto  0) <= MEM_D;	-- get graphics ROM lower data word
			when 2 =>
				s_GP_DATA(31 downto 16) <= MEM_D;	-- get graphics ROM upper data word
			when others => null;
		end case;
	end process;

	-- 6502 directly connected ROMS
--	ROM_16R : entity work.ROM_16R port map ( CLK=>gclk_28M, DATA=>slv_ROM_16R, ADDR=>s_AP_ADDR(13 downto 0) );	-- @4000-7FFF
--	ROM_16S : entity work.ROM_16S port map ( CLK=>gclk_28M, DATA=>slv_ROM_16S, ADDR=>s_AP_ADDR(14 downto 0) );	-- @8000-FFFF
--	s_AP_DATA <= slv_ROM_16S when s_AP_ADDR(15)='1' else slv_ROM_16R;

	-- 68K directly connected ROMS
--	ROM_9A  : entity work.ROM_9A  port map ( CLK=>gclk_28M, DATA=>slv_ROM_9A,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_9B  : entity work.ROM_9B  port map ( CLK=>gclk_28M, DATA=>slv_ROM_9B,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_10A : entity work.ROM_10A port map ( CLK=>gclk_28M, DATA=>slv_ROM_10A, ADDR=>s_MP_ADDR(13 downto 0) );
--	ROM_10B : entity work.ROM_10B port map ( CLK=>gclk_28M, DATA=>slv_ROM_10B, ADDR=>s_MP_ADDR(13 downto 0) );
--	ROM_7A  : entity work.ROM_7A  port map ( CLK=>gclk_28M, DATA=>slv_ROM_7A,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_7B  : entity work.ROM_7B  port map ( CLK=>gclk_28M, DATA=>slv_ROM_7B,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_6A  : entity work.ROM_6A  port map ( CLK=>gclk_28M, DATA=>slv_ROM_6A,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_6B  : entity work.ROM_6B  port map ( CLK=>gclk_28M, DATA=>slv_ROM_6B,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_5A  : entity work.ROM_5A  port map ( CLK=>gclk_28M, DATA=>slv_ROM_5A,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_5B  : entity work.ROM_5B  port map ( CLK=>gclk_28M, DATA=>slv_ROM_5B,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_3A  : entity work.ROM_3A  port map ( CLK=>gclk_28M, DATA=>slv_ROM_3A,  ADDR=>s_MP_ADDR(14 downto 0) );
--	ROM_3B  : entity work.ROM_3B  port map ( CLK=>gclk_28M, DATA=>slv_ROM_3B,  ADDR=>s_MP_ADDR(14 downto 0) );
--	s_MP_DATA <=
--		slv_ROM_9A  & slv_ROM_9B  when s_MP_ADDR(18 downto 15)="0000" else -- /ROM0 00000
--		slv_ROM_10A & slv_ROM_10B when s_MP_ADDR(18 downto 15)="0011" else -- /SLAP 38000
--		slv_ROM_7A  & slv_ROM_7B  when s_MP_ADDR(18 downto 15)="0100" else -- /ROM1 40000
--		slv_ROM_6A  & slv_ROM_6B  when s_MP_ADDR(18 downto 15)="0101" else -- /ROM2 50000
--		slv_ROM_5A  & slv_ROM_5B  when s_MP_ADDR(18 downto 15)="0110" else -- /ROM3 60000
--		slv_ROM_3A  & slv_ROM_3B  when s_MP_ADDR(18 downto 15)="0111" else -- /ROM4 70000
--		(others=>'1');
end RTL;
