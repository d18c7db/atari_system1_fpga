--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   00:00:00 01/01/2020
-- Design Name:
-- Module Name:   tb_atarisys1.vhd
-- Project Name:  ATARISYS1_TOP
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: ATARISYS1_TOP
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
library std;
	use std.textio.all;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_textio.all;

entity TB_ATARISYS1 is
end TB_ATARISYS1;

architecture RTL of TB_ATARISYS1 is
	--Inputs
	signal I_RESET			: std_logic := '0';
	signal CLK				: std_logic := '0';
	signal CLKS				: std_logic := '0';
	signal MEM_CK			: std_logic := '0';

	--Outputs

	signal I_USB_RXD		: std_logic;
	signal serio			: std_logic := 'Z';

	signal txval 			: std_logic_vector( 7 downto 0);

	signal MEM_A			: std_logic_vector(20 downto 0);
	signal MEM_D			: std_logic_vector(15 downto 0);

	constant CLK_period  : TIME := 1000 ns / 50;		-- 50MHz external clock
	constant UART_period : TIME := 1000 ms / 256000;

	procedure TXBYTE (
		signal val : in  std_logic_vector(7 downto 0);
		signal txd : out std_logic
	) is
	constant UART_period  : TIME := 1000 ms / 256000;
	variable bitnum : integer := 8;
	begin
		txd <= '0';	-- start bit
		wait for UART_period;

		for bitnum in 0 to 7 loop
			txd <= val(bitnum);	-- send bit
			wait for UART_period;
		end loop;

		txd <= '1';	-- stop bit
		wait for UART_period;
	end TXBYTE;

begin
-- pragma translate_off
--	--horizontal/vertical scroll offsets and plane selection for testing
--	stim_video : process
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

--	-- drive audio section speech synth
--	stim_audio : process
--	begin
----		wait until rising_edge(I_CLK_7M);
--		sl_SNDNMIn <= '1';
--		sl_SNDINTn <= '1';
--		slv_SBDI <= x"08"; -- selects sound
--
--		sl_W_Rn  <= '0';
--		sl_VBUSn <= '1';
--		sl_MISCn <= '1';
--		slv_MDO <= x"007F";
--		wait for 1 us;
--
--		sl_W_Rn  <= '1';
--		sl_VBUSn <= '0';
--		sl_MISCn <= '0';
--		wait for 1 us;
--
--		sl_W_Rn  <= '0';
--		sl_VBUSn <= '1';
--		sl_MISCn <= '1';
--		slv_MDO <= x"00FF";
--		wait for 1 us;
--
--		sl_W_Rn  <= '1';
--		sl_VBUSn <= '0';
--		sl_MISCn <= '0';
--		wait for 1 us;
--
--		sl_W_Rn  <= '0';
--		sl_VBUSn <= '1';
--		sl_MISCn <= '1';
--		wait for 123 ms;
--
--		sl_SNDNMIn <= '0';
--		wait for 1 us;
--		sl_SNDNMIn <= '1';
--
--		wait;
--	end process;
--pragma translate_on

	u_ROMS_EXT : entity work.ROMS_EXT
	port map (
		CLK			=>	CLKS,
		ENA			=>	'1',
		ADDR			=>	MEM_A,
		DATA			=>	MEM_D
	);

	-- Unit Under Test (uut)
	u_ATARISYS1_TOP : entity work.ATARISYS1_TOP
	PORT MAP (
		-- FLASH
		FLASH_MOSI	=> open,
		FLASH_SCK	=> open,
		FLASH_MISO	=> 'Z',
		FLASH_WPn	=> open,
		FLASH_HOLDn	=> open,

		-- SRAM
		MEM_A			=> MEM_A,
		MEM_D			=> MEM_D,
		SRAM_nCS		=> open,
		FLASH_nCE	=> open,
		MEM_nWE		=> open,
		MEM_nOE		=> open,
		MEM_nBHE		=> open,
		MEM_nBLE		=> open,
		MEM_CK		=> MEM_CK,

		O_USB_TXD	=> open,
		I_USB_RXD	=> I_USB_RXD,

		-- Video output
		TMDS_P		=> open,
		TMDS_N		=> open,

		-- Sound out
		O_AUDIO_L	=> open,
		O_AUDIO_R	=> open,

		-- External controls
		PMOD1_IO1	=> '1',
		PMOD1_IO4	=> serio,

		I_RESET		=> I_RESET,
		CLK_IN		=> CLK
	);

	-- Clock process definitions
	p_clk : process
		begin
		wait for CLK_period/2;
		CLK <= not CLK;
	end process;

	CLKS <= MEM_CK after 10 ns; -- simulate 10ns access time SRAM

	-- Stimulus process
	p_stim : process
	begin
		I_RESET <= '1';
		wait for CLK_period*32;
		I_RESET <= '0';

		I_USB_RXD <= '1';
		wait for 1 ms;

		txval <= x"52";
		TXBYTE(txval, I_USB_RXD);
		wait for 500 us;

		wait;
	end process;
end RTL;
