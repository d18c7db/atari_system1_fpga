library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity hps_io_emu is
generic (
	STRLEN : natural:=0; PS2DIV : natural:=0; WIDE : natural:=0; VDNUM : natural:=1; PS2WE : natural:=0);
port (
	clk_sys                  : in  std_logic;
	HPS_BUS                  : inout std_logic_vector(45 downto 0);
	EXT_BUS                  : inout std_logic_vector(35 downto 0);
	gamma_bus                : inout std_logic_vector(21 downto 0);

	conf_str                 : in  std_logic_vector((STRLEN*8)-1 downto 0);
	forced_scandoubler       : out std_logic;

	buttons                  : out std_logic_vector( 1 downto 0);
	status                   : out std_logic_vector(31 downto 0);
	status_menumask          : in  std_logic_vector( 1 downto 0);
	direct_video             : out std_logic;

	ioctl_download           : out std_logic;
	ioctl_wr                 : out std_logic;
	ioctl_addr               : out std_logic_vector(24 downto 0) := (others=>'0');
	ioctl_dout               : out std_logic_vector( 7 downto 0) := (others=>'0');
	ioctl_index              : out std_logic_vector( 7 downto 0);
	ioctl_wait               : in  std_logic;

	joystick_0               : out std_logic_vector(15 downto 0);
	joystick_1               : out std_logic_vector(15 downto 0);
	joystick_2               : out std_logic_vector(15 downto 0);
	joystick_3               : out std_logic_vector(15 downto 0);
	ps2_key                  : out std_logic_vector(10 downto 0)
);

end hps_io_emu;
architecture arch of hps_io_emu is
	constant max_delay : integer := 220000 / (1000 / 10 / 2);
	constant CLK1M_period : TIME := 1000 ns / 10; -- 1MHz
	signal download     : std_logic := '0';
	signal ioctl_wr_next: std_logic := '0';
	signal clk_1m       : std_logic := '0';
	signal clk_1m_last  : std_logic := '0';
	signal addr         : std_logic_vector(31 downto 0) := (others=>'1');
	signal data         : std_logic_vector( 7 downto 0) := (others=>'0');
	signal delay        : integer range 0 to 32767 := 0;
	signal
		slv_ROM_135, slv_ROM_136, slv_ROM_137, slv_ROM_138,
		slv_ROM_139, slv_ROM_140, slv_ROM_141, slv_ROM_142,
		slv_ROM_143, slv_ROM_144, slv_ROM_145, slv_ROM_146,
		slv_ROM_147, slv_ROM_148, slv_ROM_149, slv_ROM_150
	: std_logic_vector( 7 downto 0);

begin
--GAME( 1984, marble,     103, "Marble Madness (set 1)"
--GAME( 1984, marble2,    103, "Marble Madness (set 2)"
--GAME( 1984, marble3,    103, "Marble Madness (set 3)"
--GAME( 1984, marble4,    103, "Marble Madness (set 4)"
--GAME( 1984, marble5,    103, "Marble Madness (set 5 - LSI Cartridge)"
--
--GAME( 1985, indytemp,   105, "Indiana Jones and the Temple of Doom (set 1)"
--GAME( 1985, indytemp2,  105, "Indiana Jones and the Temple of Doom (set 2)"
--GAME( 1985, indytemp3,  105, "Indiana Jones and the Temple of Doom (set 3)"
--GAME( 1985, indytemp4,  105, "Indiana Jones and the Temple of Doom (set 4)"
--GAME( 1985, indytempd,  105, "Indiana Jones and the Temple of Doom (German)"
--GAME( 1985, indytempc,  105, "Indiana Jones and the Temple of Doom (cocktail)"
--
--GAME( 1984, peterpak,   107, "Peter Pack Rat"
--
--GAME( 1985, roadrunn,   108, "Road Runner (rev 2)"
--GAME( 1985, roadrunn1,  108, "Road Runner (rev 1)"
--GAME( 1985, roadrunn2,  108, "Road Runner (rev 1+)"
--
--GAME( 1987, roadblstg1, 109, "Road Blasters (upright, German, rev 1)"
--GAME( 1987, roadblstcg, 109, "Road Blasters (cockpit, German, rev 1)"
--GAME( 1987, roadblstg,  109, "Road Blasters (upright, German, rev 3)"
--GAME( 1987, roadblstgu, 109, "Road Blasters (upright, German, rev ?)"
--GAME( 1987, roadblst1,  109, "Road Blasters (upright, rev 1)"
--GAME( 1987, roadblstc1, 109, "Road Blasters (cockpit, rev 1)"
--GAME( 1987, roadblst3,  109, "Road Blasters (upright, rev 3)"
--
--GAME( 1987, roadblst2,  110, "Road Blasters (upright, rev 2)"
--GAME( 1987, roadblstc,  110, "Road Blasters (cockpit, rev 2)"
--GAME( 1987, roadblstg2, 110, "Road Blasters (upright, German, rev 2)"
--GAME( 1987, roadblst,   110, "Road Blasters (upright, rev 4)"


--	-- VIDEO ROMS
	ROM_135 : entity work.ROM_135 port map ( CLK => clk_sys, DATA => slv_ROM_135, ADDR => addr(16 downto 2) ); -- 1B
	ROM_136 : entity work.ROM_136 port map ( CLK => clk_sys, DATA => slv_ROM_136, ADDR => addr(16 downto 2) ); -- 2B
	ROM_137 : entity work.ROM_137 port map ( CLK => clk_sys, DATA => slv_ROM_137, ADDR => addr(16 downto 2) ); -- 3B
	ROM_138 : entity work.ROM_138 port map ( CLK => clk_sys, DATA => slv_ROM_138, ADDR => addr(16 downto 2) ); -- 4B
	ROM_139 : entity work.ROM_139 port map ( CLK => clk_sys, DATA => slv_ROM_139, ADDR => addr(16 downto 2) ); -- 6B
	ROM_140 : entity work.ROM_140 port map ( CLK => clk_sys, DATA => slv_ROM_140, ADDR => addr(16 downto 2) ); -- 7B
	ROM_141 : entity work.ROM_141 port map ( CLK => clk_sys, DATA => slv_ROM_141, ADDR => addr(16 downto 2) ); -- 8B
	ROM_142 : entity work.ROM_142 port map ( CLK => clk_sys, DATA => slv_ROM_142, ADDR => addr(16 downto 2) ); -- 9B
	ROM_143 : entity work.ROM_143 port map ( CLK => clk_sys, DATA => slv_ROM_143, ADDR => addr(16 downto 2) ); -- 1C
	ROM_144 : entity work.ROM_144 port map ( CLK => clk_sys, DATA => slv_ROM_144, ADDR => addr(16 downto 2) ); -- 2C
	ROM_145 : entity work.ROM_145 port map ( CLK => clk_sys, DATA => slv_ROM_145, ADDR => addr(16 downto 2) ); -- 3C
	ROM_146 : entity work.ROM_146 port map ( CLK => clk_sys, DATA => slv_ROM_146, ADDR => addr(16 downto 2) ); -- 4C
	ROM_147 : entity work.ROM_147 port map ( CLK => clk_sys, DATA => slv_ROM_147, ADDR => addr(16 downto 2) ); -- 6C
	ROM_148 : entity work.ROM_148 port map ( CLK => clk_sys, DATA => slv_ROM_148, ADDR => addr(16 downto 2) ); -- 7C
	ROM_149 : entity work.ROM_149 port map ( CLK => clk_sys, DATA => slv_ROM_149, ADDR => addr(16 downto 2) ); -- 8C
	ROM_150 : entity work.ROM_150 port map ( CLK => clk_sys, DATA => slv_ROM_150, ADDR => addr(16 downto 2) ); -- 9C

--                                        0123
-- 5C-B I_5C_DB gpdata(31 downto 24)), // 1234C
-- 5C-A I_5C_DA gpdata(24 downto 16)), // 6789C
-- 5B-B I_5B_DB gpdata(15 downto  8)), // 1234B
-- 5B-A I_5B_DA gpdata( 7 downto  0))  // 6789B

	-- video ROMs interleaved
	data <=
	--GCS1 1C 6C 1B 6B
	slv_ROM_143 when (addr(24 downto 17)="00000000" ) and addr(1 downto 0)="00" else
	slv_ROM_147 when (addr(24 downto 17)="00000000" ) and addr(1 downto 0)="01" else
	slv_ROM_135 when (addr(24 downto 17)="00000000" ) and addr(1 downto 0)="10" else
	slv_ROM_139 when (addr(24 downto 17)="00000000" ) and addr(1 downto 0)="11" else
	--GCS2 2C 7C 2B 7B
	slv_ROM_144 when (addr(24 downto 17)="00000001" ) and addr(1 downto 0)="00" else
	slv_ROM_148 when (addr(24 downto 17)="00000001" ) and addr(1 downto 0)="01" else
	slv_ROM_136 when (addr(24 downto 17)="00000001" ) and addr(1 downto 0)="10" else
	slv_ROM_140 when (addr(24 downto 17)="00000001" ) and addr(1 downto 0)="11" else
	--GCS3 3C 8C 2B 8B
	slv_ROM_145 when (addr(24 downto 17)="00000010" ) and addr(1 downto 0)="00" else
	slv_ROM_149 when (addr(24 downto 17)="00000010" ) and addr(1 downto 0)="01" else
	slv_ROM_137 when (addr(24 downto 17)="00000010" ) and addr(1 downto 0)="10" else
	slv_ROM_141 when (addr(24 downto 17)="00000010" ) and addr(1 downto 0)="11" else
	--GCS4 4C 9C 4B 9B
	slv_ROM_146 when (addr(24 downto 17)="00000011" ) and addr(1 downto 0)="00" else
	slv_ROM_150 when (addr(24 downto 17)="00000011" ) and addr(1 downto 0)="01" else
	slv_ROM_138 when (addr(24 downto 17)="00000011" ) and addr(1 downto 0)="10" else
	slv_ROM_142 when (addr(24 downto 17)="00000011" ) and addr(1 downto 0)="11" else
	(others=>'0');

	HPS_BUS            <= (others=>'Z');
	EXT_BUS            <= (others=>'Z');
	gamma_bus          <= (others=>'Z');

	forced_scandoubler <= '0';
	buttons            <= (others=>'0');
	status             <= (others=>'0');
	direct_video       <= '0';

	joystick_0         <= (others=>'0');
	joystick_1         <= (others=>'0');
	joystick_2         <= (others=>'0');
	joystick_3         <= (others=>'0');
	ps2_key            <= (others=>'0');

	ioctl_addr         <= addr(24 downto 0);
	ioctl_dout         <= data;
	ioctl_download     <= download;
	ioctl_index        <= (others=>'0');
	download           <= '1' when ( ((addr < x"00080000") or (addr = x"FFFFFFFF")) and delay = max_delay) else '0';

	p_clk : process
	begin
		wait for CLK1M_period/2;
		clk_1M <= not clk_1M;
		if delay < max_delay then delay <= delay + 1; end if;
	end process;

	p_addr : process
	begin
		wait until rising_edge(clk_sys);
		clk_1M_last <= clk_1M;
		ioctl_wr <= ioctl_wr_next;
		if (ioctl_wait = '0' and download = '1' and clk_1M_last = '0' and clk_1M = '1') then
			ioctl_wr_next <= '1';
			addr <= addr + 1;
		else
			ioctl_wr_next <= '0';
		end if;
	end process;
end architecture arch;
