library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity hps_io is
generic (
	CONF_STR : in  std_logic_vector(255 downto 0);
	PS2DIV : natural:=0; WIDE : natural:=0; VDNUM : natural:=1; PS2WE : natural:=0);
port (
	clk_sys                  : in  std_logic;
	HPS_BUS                  : inout std_logic_vector(48 downto 0);
	joystick_0               : out std_logic_vector(31 downto 0);
	joystick_1               : out std_logic_vector(31 downto 0);
	joystick_2               : out std_logic_vector(31 downto 0);
	joystick_3               : out std_logic_vector(31 downto 0);
	ps2_key                  : out std_logic_vector(10 downto 0);
	buttons                  : out std_logic_vector( 1 downto 0);
	forced_scandoubler       : out std_logic;
	direct_video             : out std_logic;
	gamma_bus                : inout std_logic_vector(21 downto 0);
	status                   : out std_logic_vector(127 downto 0);
	status_menumask          : in  std_logic_vector( 1 downto 0);
	ioctl_download           : out std_logic;
	ioctl_index              : out std_logic_vector( 7 downto 0);
	ioctl_wr                 : out std_logic;
	ioctl_addr               : out std_logic_vector(24 downto 0) := (others=>'0');
	ioctl_dout               : out std_logic_vector( 7 downto 0) := (others=>'0');
	ioctl_wait               : in  std_logic;
	EXT_BUS                  : inout std_logic_vector(35 downto 0)
);

end hps_io;
architecture arch of hps_io is
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
		slv_ROM_1B, slv_ROM_2B, slv_ROM_3B, slv_ROM_4B,
		slv_ROM_6B, slv_ROM_7B, slv_ROM_8B, slv_ROM_9B,
		slv_ROM_1C, slv_ROM_2C, slv_ROM_3C, slv_ROM_4C,
		slv_ROM_6C, slv_ROM_7C, slv_ROM_8C, slv_ROM_9C,
		slv_ROM_10A, slv_ROM_10B, slv_ROM_12A, slv_ROM_12B,
		slv_ROM_11A, slv_ROM_11B,
		slv_ROM_14A, slv_ROM_14B, slv_ROM_16B, slv_ROM_16A,
		slv_ROM_11J, slv_ROM_10J, slv_ROM_13D, slv_ROM_14D,
		slv_ROM_16D, slv_ROM_5F, slv_ROM_5A, slv_ROM_7A
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
	ROM_135 : entity work.ROM_135 port map ( CLK => clk_sys, DATA => slv_ROM_1B,  ADDR => addr(16 downto 2) ); -- 32K x000000
	ROM_139 : entity work.ROM_139 port map ( CLK => clk_sys, DATA => slv_ROM_6B,  ADDR => addr(16 downto 2) ); -- 32K x010000
	ROM_143 : entity work.ROM_143 port map ( CLK => clk_sys, DATA => slv_ROM_1C,  ADDR => addr(16 downto 2) ); -- 32K x020000
	ROM_147 : entity work.ROM_147 port map ( CLK => clk_sys, DATA => slv_ROM_6C,  ADDR => addr(16 downto 2) ); -- 32K x030000
	ROM_136 : entity work.ROM_136 port map ( CLK => clk_sys, DATA => slv_ROM_2B,  ADDR => addr(16 downto 2) ); -- 32K x080000
	ROM_140 : entity work.ROM_140 port map ( CLK => clk_sys, DATA => slv_ROM_7B,  ADDR => addr(16 downto 2) ); -- 32K x090000
	ROM_144 : entity work.ROM_144 port map ( CLK => clk_sys, DATA => slv_ROM_2C,  ADDR => addr(16 downto 2) ); -- 32K x0A0000
	ROM_148 : entity work.ROM_148 port map ( CLK => clk_sys, DATA => slv_ROM_7C,  ADDR => addr(16 downto 2) ); -- 32K x0B0000
	ROM_137 : entity work.ROM_137 port map ( CLK => clk_sys, DATA => slv_ROM_3B,  ADDR => addr(16 downto 2) ); -- 32K x100000
	ROM_141 : entity work.ROM_141 port map ( CLK => clk_sys, DATA => slv_ROM_8B,  ADDR => addr(16 downto 2) ); -- 32K x110000
	ROM_145 : entity work.ROM_145 port map ( CLK => clk_sys, DATA => slv_ROM_3C,  ADDR => addr(16 downto 2) ); -- 32K x120000
	ROM_149 : entity work.ROM_149 port map ( CLK => clk_sys, DATA => slv_ROM_8C,  ADDR => addr(16 downto 2) ); -- 32K x130000
	ROM_138 : entity work.ROM_138 port map ( CLK => clk_sys, DATA => slv_ROM_4B,  ADDR => addr(16 downto 2) ); -- 32K x180000
	ROM_142 : entity work.ROM_142 port map ( CLK => clk_sys, DATA => slv_ROM_9B,  ADDR => addr(16 downto 2) ); -- 32K x190000
	ROM_146 : entity work.ROM_146 port map ( CLK => clk_sys, DATA => slv_ROM_4C,  ADDR => addr(16 downto 2) ); -- 32K x1A0000
	ROM_150 : entity work.ROM_150 port map ( CLK => clk_sys, DATA => slv_ROM_9C,  ADDR => addr(16 downto 2) ); -- 32K x1B0000

	-- BIOS
	ROM_11J : entity work.ROM_11J port map ( CLK => clk_sys, DATA => slv_ROM_11J, ADDR => addr(14 downto 1) ); -- 16K x00000
	ROM_10J : entity work.ROM_10J port map ( CLK => clk_sys, DATA => slv_ROM_10J, ADDR => addr(14 downto 1) ); -- 16K x00001
	-- maincpu
	ROM_432 : entity work.ROM_432 port map ( CLK => clk_sys, DATA => slv_ROM_10B, ADDR => addr(15 downto 1) ); -- 32K x10000
	ROM_431 : entity work.ROM_431 port map ( CLK => clk_sys, DATA => slv_ROM_10A, ADDR => addr(15 downto 1) ); -- 32K x10001
	--
	--
	ROM_434 : entity work.ROM_434 port map ( CLK => clk_sys, DATA => slv_ROM_12B, ADDR => addr(15 downto 1) ); -- 32K x20000
	ROM_433 : entity work.ROM_433 port map ( CLK => clk_sys, DATA => slv_ROM_12A, ADDR => addr(15 downto 1) ); -- 32K x20001
	ROM_456 : entity work.ROM_456 port map ( CLK => clk_sys, DATA => slv_ROM_14B, ADDR => addr(14 downto 1) ); -- 16K x30000
	ROM_457 : entity work.ROM_457 port map ( CLK => clk_sys, DATA => slv_ROM_14A, ADDR => addr(14 downto 1) ); -- 16K x30001
	ROM_358 : entity work.ROM_358 port map ( CLK => clk_sys, DATA => slv_ROM_16B, ADDR => addr(14 downto 1) ); -- 16K x80000
	ROM_359 : entity work.ROM_359 port map ( CLK => clk_sys, DATA => slv_ROM_16A, ADDR => addr(14 downto 1) ); -- 16K x80001
	-- audiocpu
	ROM_153 : entity work.ROM_153 port map ( CLK => clk_sys, DATA => slv_ROM_13D, ADDR => addr(13 downto 0) ); -- 16K x4000
	ROM_154 : entity work.ROM_154 port map ( CLK => clk_sys, DATA => slv_ROM_14D, ADDR => addr(13 downto 0) ); -- 16K x8000
	ROM_155 : entity work.ROM_155 port map ( CLK => clk_sys, DATA => slv_ROM_16D, ADDR => addr(13 downto 0) ); -- 16K xC000
	-- PROMs
	ROM_5F  : entity work.ROM_5F  port map ( CLK => clk_sys, DATA => slv_ROM_5F,  ADDR => addr(12 downto 0) ); --  8K
	ROM_151 : entity work.ROM_151 port map ( CLK => clk_sys, DATA => slv_ROM_5A,  ADDR => addr( 8 downto 0) ); -- 512 x200
	ROM_152 : entity work.ROM_152 port map ( CLK => clk_sys, DATA => slv_ROM_7A,  ADDR => addr( 8 downto 0) ); -- 512 x000

	-- video ROMs interleaved
	data <=
	--GCS1 1C 6C 1B 6B
	slv_ROM_1B  when (addr(24 downto 17)="00000000"   ) and addr(1 downto 0)="10" else -- 32K
	slv_ROM_6B  when (addr(24 downto 17)="00000000"   ) and addr(1 downto 0)="11" else -- 32K
	slv_ROM_1C  when (addr(24 downto 17)="00000000"   ) and addr(1 downto 0)="00" else -- 32K
	slv_ROM_6C  when (addr(24 downto 17)="00000000"   ) and addr(1 downto 0)="01" else -- 32K
	--GCS2 2C 7C 2B 7B
	slv_ROM_2B  when (addr(24 downto 17)="00000001"   ) and addr(1 downto 0)="10" else -- 32K
	slv_ROM_7B  when (addr(24 downto 17)="00000001"   ) and addr(1 downto 0)="11" else -- 32K
	slv_ROM_2C  when (addr(24 downto 17)="00000001"   ) and addr(1 downto 0)="00" else -- 32K
	slv_ROM_7C  when (addr(24 downto 17)="00000001"   ) and addr(1 downto 0)="01" else -- 32K
	--GCS3 3C 8C 2B 8B
	slv_ROM_3B  when (addr(24 downto 17)="00000010"   ) and addr(1 downto 0)="10" else -- 32K
	slv_ROM_8B  when (addr(24 downto 17)="00000010"   ) and addr(1 downto 0)="11" else -- 32K
	slv_ROM_3C  when (addr(24 downto 17)="00000010"   ) and addr(1 downto 0)="00" else -- 32K
	slv_ROM_8C  when (addr(24 downto 17)="00000010"   ) and addr(1 downto 0)="01" else -- 32K
	--GCS4 4C 9C 4B 9B
	slv_ROM_4B  when (addr(24 downto 17)="00000011"   ) and addr(1 downto 0)="10" else -- 32K
	slv_ROM_9B  when (addr(24 downto 17)="00000011"   ) and addr(1 downto 0)="11" else -- 32K
	slv_ROM_4C  when (addr(24 downto 17)="00000011"   ) and addr(1 downto 0)="00" else -- 32K
	slv_ROM_9C  when (addr(24 downto 17)="00000011"   ) and addr(1 downto 0)="01" else -- 32K
	-- maincpu
	slv_ROM_10B when (addr(24 downto 16)="000001000"  ) and addr(0)='0' else --           32K
	slv_ROM_10A when (addr(24 downto 16)="000001000"  ) and addr(0)='1' else --           32K
	--
	--
	slv_ROM_12B when (addr(24 downto 16)="000001001"  ) and addr(0)='0' else --           32K
	slv_ROM_12A when (addr(24 downto 16)="000001001"  ) and addr(0)='1' else --           32K
	slv_ROM_14B when (addr(24 downto 15)="0000010100" ) and addr(0)='0' else --           16K
	slv_ROM_14A when (addr(24 downto 15)="0000010100" ) and addr(0)='1' else --           16K
	slv_ROM_16B when (addr(24 downto 15)="0000010101" ) and addr(0)='0' else --           16K
	slv_ROM_16A when (addr(24 downto 15)="0000010101" ) and addr(0)='1' else --           16K
	-- BIOS
	slv_ROM_11J when (addr(24 downto 15)="0000010110" ) and addr(0)='0' else --           16K
	slv_ROM_10J when (addr(24 downto 15)="0000010110" ) and addr(0)='1' else --           16K
	-- audiocpu
	slv_ROM_13D when (addr(24 downto 14)="00000101110"     ) else --
	slv_ROM_14D when (addr(24 downto 14)="00000101111"     ) else -- 16K
	slv_ROM_16D when (addr(24 downto 14)="00000110000"     ) else -- 16K
	-- PROMs
	slv_ROM_5F  when (addr(24 downto 13)="000001100010"    ) else --  8K
	slv_ROM_5A  when (addr(24 downto 9 )="0000011000110000") else -- 512
	slv_ROM_7A  when (addr(24 downto 9 )="0000011000110001") else -- 512

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
	download           <= '1' when ( ((addr < x"000C6400") or (addr = x"FFFFFFFF")) and delay = max_delay) else '0';

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
