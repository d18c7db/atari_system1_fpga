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

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity AUDIO is
	port(
		I_MCKR      : in  std_logic;	-- 7.14MHz
		I_1H        : in  std_logic;
		I_2H        : in  std_logic;
		O_B02       : out std_logic;


		I_SNDNMIn   : in  std_logic;
		I_SNDRSTn   : in  std_logic;
		I_SNDINTn   : in  std_logic;
		O_SNDBW_Rn  : out std_logic;
		O_WR68Kn    : out std_logic;
		O_RD68Kn    : out std_logic;

		I_SELFTESTn : in  std_logic;
		I_COIN_AUX  : in  std_logic;
		I_COIN_L    : in  std_logic;
		I_COIN_R    : in  std_logic;

		O_LED       : out std_logic_vector( 1 downto 0);
		O_CCTRn     : out std_logic_vector( 1 downto 0);
		O_AUDIO_L   : out std_logic_vector( 7 downto 0) := (others=>'1');
		O_AUDIO_R   : out std_logic_vector( 7 downto 0) := (others=>'1');

		O_SROMn     : out std_logic_vector( 2 downto 0);

		O_SBA       : out std_logic_vector(13 downto 0) := (others=>'1');
		O_SBD       : out std_logic_vector( 7 downto 0);
		I_SMD       : in  std_logic_vector( 7 downto 0);
		I_SBD       : in  std_logic_vector( 7 downto 0)
	);
end AUDIO;

architecture RTL of AUDIO is
	component jt51
	port (
		rst		:	 in std_logic;
		clk		:	 in std_logic;
		cen		:	 in std_logic;
		cen_p1	:	 in std_logic;
		cs_n		:	 in std_logic;
		wr_n		:	 in std_logic;
		a0			:	 in std_logic;
		din		:	 in std_logic_vector(7 downto 0);
		dout		:	 out std_logic_vector(7 downto 0);
		ct1		:	 out std_logic;
		ct2		:	 out std_logic;
		irq_n		:	 out std_logic;
		sample	:	 out std_logic;
		left		:	 out std_logic_vector(15 downto 0);
		right		:	 out std_logic_vector(15 downto 0);
		xleft		:	 out signed(15 downto 0);
		xright	:	 out signed(15 downto 0);
		dacleft	:	 out std_logic_vector(15 downto 0);
		dacright	:	 out std_logic_vector(15 downto 0)
	);
	end component;

	signal
		sl_POKEYn,
		sl_14L_CSn,
		sl_15L_CSn,
		sl_MXTn,
		sl_SNDEXTn,
		sl_SIORDn,
		sl_ASn,
		sl_YMHCSn,
		sl_RD02n,
		sl_WR02n,
		sl_SIOWRn,
		sl_YMHRES,
		sl_YMHRESn,
		sl_1H,
		sl_2H,
		sl_6502IRQn,
		sl_SNDNMIn,
		sl_SNDRSTn,
		sl_SELFTESTn,
		sl_COIN_AUX,
		sl_COIN_L,
		sl_COIN_R,
		sl_MCKF,
		sl_CPU_ena,
		sl_B02,
		sl_SNDBUF,
		sl_68KBUF,
		sl_SNDBW_Rn,
		sl_SNDBR_Wn,
		sl_WR68Kn,
		sl_RD68Kn
								: std_logic := '1';
	signal
		slv_LED,
		slv_CCTRn
								: std_logic_vector( 1 downto 0) := (others => '0');
	signal
		slv_SROMn
								: std_logic_vector( 2 downto 0) := (others => '0');
	signal
		slv_14Ja_Y,
		slv_14Jb_Y
								: std_logic_vector( 3 downto 0) := (others => '0');
	signal
		slv_l,
		slv_r,
		slv_YM_data,
		slv_POKEY_data,
		slv_14L_RAM_data,
		slv_15L_RAM_data,
		slv_15H_Y,
		slv_SBDO,
		slv_SBDI,
		slv_SMD,
		slv_SBD
								: std_logic_vector( 7 downto 0) := (others => '0');
	signal
		s_POK_out
								: signed( 7 downto 0) := (others => '0');
----	signal
----		s_audio_TMS,
----		s_audio_POK,
----		s_audio_YML,
----		s_audio_YMR
----								: signed(11 downto 0) := (others => '0');
--	signal
--		s_chan_l,
--		s_chan_r
--								: std_logic_vector(13 downto 0) := (others => '0');
	signal
		s_YML_out,
		s_YMR_out
								: signed(15 downto 0) := (others => '0');
	signal
		slv_SBA
								: std_logic_vector(23 downto 0) := (others => '0');
begin

--	-- FIXME this mixing isn't ideal, sound volume ends up too low
--	-- Pokey sounds OK, but YM seems a bit distorted, try and do better
--	p_volmux : process
--	begin
--		wait until rising_edge(I_MCKR);
--
--		-- volume control applied to signed outputs
--		s_audio_TMS <= signed('0' & slv_SM_vol) * signed(s_TMS_out);
--		s_audio_POK <= signed('0' & slv_PM_vol) * signed(s_POK_out);
--		s_audio_YML <= signed('0' & slv_YM_vol) * signed(s_YML_out(15 downto 8));
--		s_audio_YMR <= signed('0' & slv_YM_vol) * signed(s_YMR_out(15 downto 8));
--
--		-- sign extend to 14 bits and add all outputs together as signed integers
--		s_chan_l <=  signed(s_audio_YML(11) & s_audio_YML(11) & s_audio_YML)
--					+ ( signed(s_audio_POK(11) & s_audio_POK(11) & s_audio_POK)
--					+   signed(s_audio_TMS(11) & s_audio_TMS(11) & s_audio_TMS) );
--		s_chan_r <=  signed(s_audio_YMR(11) & s_audio_YMR(11) & s_audio_YMR)
--					+ ( signed(s_audio_POK(11) & s_audio_POK(11) & s_audio_POK)
--					+   signed(s_audio_TMS(11) & s_audio_TMS(11) & s_audio_TMS) );
--
--		-- convert output back to unsigned for DAC usage
--		slv_l <= std_logic_vector(not s_chan_l(13) & s_chan_l(12 downto 6));
--		slv_r <= std_logic_vector(not s_chan_r(13) & s_chan_r(12 downto 6));
--	end process;
		sl_1H        <= I_1H;
		sl_2H        <= I_2H;
		sl_SNDNMIn   <= I_SNDNMIn;
		sl_SNDRSTn   <= I_SNDRSTn;
		sl_68KBUF    <= not I_SNDNMIn;
		sl_SNDBUF    <= not I_SNDINTn;
		sl_SELFTESTn <= I_SELFTESTn;
		sl_COIN_AUX  <= I_COIN_AUX;
		sl_COIN_L    <= I_COIN_L;
		sl_COIN_R    <= I_COIN_R;
		slv_SBD      <= I_SBD;
		slv_SMD      <= I_SMD;

		O_B02        <= sl_B02;
		O_SNDBW_Rn   <= sl_SNDBW_Rn;
		O_WR68Kn     <= sl_WR68Kn;
		O_RD68Kn     <= sl_RD68Kn;
		O_LED        <= slv_LED;
		O_CCTRn      <= slv_CCTRn;

		O_AUDIO_L    <= slv_l;
		O_AUDIO_R    <= slv_r;

		O_SROMn      <= slv_SROMn;
		O_SBA        <= slv_SBA(13 downto 0);
		O_SBD        <= slv_SBDO;

	-------------
	-- sheet 5 --
	-------------

	u_16JK : entity work.T65
	port map (
		MODE    => "00",        -- "00" => 6502, "01" => 65C02, "10" => 65C816
		Enable  => sl_CPU_ena,  -- clock enable to run at 1.7MHz

		CLK     => I_MCKR,      -- in, system clock 7MHz
		IRQ_n   => sl_6502IRQn, -- in, active low irq
		NMI_n   => sl_SNDNMIn,  -- in, active low nmi
		RES_n   => sl_SNDRSTn,  -- in, active low reset
		RDY     => '1',         -- in, ready
		SO_n    => '1',         -- in, set overflow
		DI      => slv_SBDI,    -- in, data

		A       => slv_SBA,     -- out, address
		DO      => slv_SBDO,    -- out, data
		R_W_n   => sl_SNDBR_Wn, -- out, read /write
		SYNC    => open         -- out, sync
	);

	sl_MCKF <= not I_MCKR;

	-- 14L, 15L RAMs
	p_RAM_14L : entity work.RAM_2K8 port map (I_MCKR => sl_MCKF, I_EN => sl_14L_CSn, I_WR => sl_WR02n, I_ADDR => slv_SBA(10 downto 0), I_DATA => slv_SBDO, O_DATA => slv_14L_RAM_data );
	p_RAM_15L : entity work.RAM_2K8 port map (I_MCKR => sl_MCKF, I_EN => sl_15L_CSn, I_WR => sl_WR02n, I_ADDR => slv_SBA(10 downto 0), I_DATA => slv_SBDO, O_DATA => slv_15L_RAM_data );

	-- mux CPU input data bus
	p_cpu_dbus : process
	begin
		wait until falling_edge(I_MCKR);
		if sl_B02 = '1' then
			-- CPU input data bus mux
			   if sl_SNDBW_Rn = '0' and sl_14L_CSn = '0' then slv_SBDI <= slv_14L_RAM_data;
			elsif sl_SNDBW_Rn = '0' and sl_15L_CSn = '0' then slv_SBDI <= slv_15L_RAM_data;
			elsif sl_SNDBW_Rn = '0' and (slv_SROMn(2) = '0' or slv_SROMn(1) = '0' or slv_SROMn(0) = '0' or sl_MXTn = '0') then slv_SBDI <= slv_SMD;
			elsif sl_SNDBW_Rn = '0' and sl_POKEYn  = '0' then slv_SBDI <= slv_POKEY_data;
			elsif sl_SNDBW_Rn = '0' and sl_YMHCSn  = '0' then slv_SBDI <= slv_YM_data;
			elsif sl_SNDBW_Rn = '0' and sl_RD68Kn  = '0' then slv_SBDI <= slv_SBD;
			elsif sl_SNDBW_Rn = '0' and sl_SIORDn  = '0' then slv_SBDI <= sl_SELFTESTn & "00" & sl_SNDBUF & sl_68KBUF & sl_COIN_AUX & sl_COIN_L & sl_COIN_R; -- buffer 15C
			else slv_SBDI <= (others=>'Z'); -- FIXME
			end if;
		end if;
	end process;

-- Delay CPU enable to create an artificial PHI2 clock enable, PHI1 is not used
	p_cpuena : process
	begin
		wait until falling_edge(I_MCKR);
		-- use 1H and 2H to create a short clock enable for the 7MHz master clock
		sl_CPU_ena <= sl_1H and (not sl_2H);
		sl_B02 <= sl_CPU_ena;
	end process;

	-- 14Ja 2:4 decoder
	slv_14Ja_Y(3) <= ( not slv_SBA(15) ) or ( not slv_SBA(14) );
	slv_14Ja_Y(2) <= ( not slv_SBA(15) ) or (     slv_SBA(14) );
	slv_14Ja_Y(1) <= (     slv_SBA(15) ) or ( not slv_SBA(14) );
	slv_14Ja_Y(0) <= (     slv_SBA(15) ) or (     slv_SBA(14) );

	slv_SROMn(2) <= slv_14Ja_Y(3);
	slv_SROMn(1) <= slv_14Ja_Y(2);
	slv_SROMn(0) <= slv_14Ja_Y(1);
	sl_ASn       <= slv_14Ja_Y(0);

	-- 14Jb 2:4 decoder
	slv_14Jb_Y(3) <= sl_ASn  or ( not slv_SBA(12) ) or ( not slv_SBA(11) );
	slv_14Jb_Y(2) <= sl_ASn  or ( not slv_SBA(12) ) or (     slv_SBA(11) );
	slv_14Jb_Y(1) <= sl_ASn  or (     slv_SBA(12) ) or ( not slv_SBA(11) );
	slv_14Jb_Y(0) <= sl_ASn  or (     slv_SBA(12) ) or (     slv_SBA(11) );

	sl_MXTn    <= slv_14Jb_Y(3);
	sl_SNDEXTn <= slv_14Jb_Y(2);
	sl_14L_CSn <= slv_14Jb_Y(1);
	sl_15L_CSn <= slv_14Jb_Y(0);

	-- 15H 3:8 decoder
	slv_15H_Y(7) <= sl_MXTn  or ( not slv_SBA(6) ) or ( not slv_SBA(5) ) or ( not slv_SBA(4) );
--	slv_15H_Y(6) <= sl_MXTn  or ( not slv_SBA(6) ) or ( not slv_SBA(5) ) or (     slv_SBA(4) );	-- unused
--	slv_15H_Y(5) <= sl_MXTn  or ( not slv_SBA(6) ) or (     slv_SBA(5) ) or ( not slv_SBA(4) );	-- unused
--	slv_15H_Y(4) <= sl_MXTn  or ( not slv_SBA(6) ) or (     slv_SBA(5) ) or (     slv_SBA(4) );	-- unused
--	slv_15H_Y(3) <= sl_MXTn  or (     slv_SBA(6) ) or ( not slv_SBA(5) ) or ( not slv_SBA(4) );	-- unused
	slv_15H_Y(2) <= sl_MXTn  or (     slv_SBA(6) ) or ( not slv_SBA(5) ) or (     slv_SBA(4) );
	slv_15H_Y(1) <= sl_MXTn  or (     slv_SBA(6) ) or (     slv_SBA(5) ) or ( not slv_SBA(4) );
	slv_15H_Y(0) <= sl_MXTn  or (     slv_SBA(6) ) or (     slv_SBA(5) ) or (     slv_SBA(4) );

	-- gates 13F
	sl_POKEYn <= slv_15H_Y(7);
	sl_SIOWRn <= slv_15H_Y(2) or sl_WR02n;
	sl_WR68Kn <= slv_15H_Y(1) or sl_WR02n;
	sl_SIORDn <= slv_15H_Y(2) or sl_RD02n;
	sl_RD68Kn <= slv_15H_Y(1) or sl_RD02n;
	sl_YMHCSn <= slv_15H_Y(0);


	-- gate 8F
	sl_SNDBW_Rn <= not sl_SNDBR_Wn;

--	-- gates 15J
	sl_RD02n <= sl_B02 and sl_SNDBR_Wn;
	sl_WR02n <= sl_B02 and sl_SNDBW_Rn;


	--	POKEY sound (Atari custom chip 137430-001)
	u_17J : entity work.POKEY
	port map (
		ADDR      => slv_SBA(3 downto 0),
		DIN       => slv_SBDO,
		DOUT      => slv_POKEY_data,
		DOUT_OE_L => open,
		CS        => '1',
		CS_L      => sl_POKEYn,
		RW_L      => sl_SNDBR_Wn,

		PIN       => x"00",
		ENA       => sl_B02,
		CLK       => I_MCKR,

		AUDIO_OUT => s_POK_out
	);

	-------------
	-- sheet 6 --
	-------------

	sl_YMHRES <= not sl_YMHRESn;

	-- YM2151 sound
	u_15R : entity work.JT51
	port map(
		-- inputs
		rst      => sl_YMHRES, -- active high reset
		clk      => I_MCKR,
		cen      => I_1H,
		cen_p1   => I_1H,
		a0       => slv_SBA(0),
		wr_n     => sl_WR02n,
		cs_n     => sl_YMHCSn,
		din      => slv_SBDO,

		-- outputs
		dout     => slv_YM_data,
		irq_n    => sl_6502IRQn,

		ct1      => open,
		ct2      => open,

		--	 Low resolution outputs (same as real chip)
		sample   => open,      -- marks new output sample
		left     => open,      -- std_logic_vector(15 downto 0)
		right    => open,      -- std_logic_vector(15 downto 0)

		--	 Full resolution outputs
		xleft    => s_YML_out, -- std_logic_vector(15 downto 0)
		xright   => s_YMR_out, -- std_logic_vector(15 downto 0)
		dacleft  => open,
		dacright => open
	);

	-- YM3012 DAC - not used becase YM2151 core outputs parallel sound data

	-- 14F simplified addressable latch
	p_14F : process
	begin
		wait until rising_edge(I_MCKR);
		if sl_SNDRSTn = '0' then
			sl_YMHRESn <= '0';
			O_LED <= (others=>'0');
			O_CCTRn <= (others=>'0');
		else
			if sl_SIOWRn = '0' then
				case slv_SBA(2 downto 0) is
					when "000" => sl_YMHRESn   <= slv_SBDO(0);
					when "100" => slv_LED(0)   <= slv_SBDO(0);
					when "101" => slv_LED(1)   <= slv_SBDO(0);
					when "110" => slv_CCTRn(0) <= slv_SBDO(0);
					when "111" => slv_CCTRn(1) <= slv_SBDO(0);
					when others => null;
				end case;
			end if;
		end if;
	end process;
end RTL;
