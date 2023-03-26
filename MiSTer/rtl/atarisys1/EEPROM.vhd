library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity EEPROM is
port (
	CLK : in  std_logic;
	WEn : in  std_logic;
	CEn : in  std_logic;
	OEn : in  std_logic;
	AD  : in  std_logic_vector(8 downto 0);
	DI  : in  std_logic_vector(7 downto 0);
	DO  : out std_logic_vector(7 downto 0)
	);
end entity;

-- EEPROM as RAM
architecture RTL of EEPROM is
	type RAM_ARRAY is array (0 to 511) of std_logic_vector(7 downto 0);
--	signal RAM : RAM_ARRAY:=(others=>(others=>'0'));
	-- initialized EEPROM contents dumped from MAME
	signal RAM : RAM_ARRAY := (
		x"FF",x"00",x"12",x"00",x"12",x"00",x"00",x"00",x"12",x"00",x"00",x"00",x"00",x"00",x"12",x"7D", -- 0x0000
		x"5C",x"DC",x"00",x"23",x"FF",x"7D",x"A3",x"02",x"00",x"00",x"00",x"00",x"00",x"02",x"FF",x"00", -- 0x0010
		x"12",x"00",x"12",x"00",x"00",x"00",x"12",x"00",x"00",x"00",x"00",x"00",x"12",x"7D",x"5C",x"DC", -- 0x0020
		x"00",x"23",x"FF",x"7D",x"A3",x"02",x"00",x"00",x"00",x"00",x"00",x"02",x"89",x"B0",x"7A",x"01", -- 0x0030
		x"C0",x"B6",x"AC",x"67",x"D1",x"32",x"01",x"5F",x"5E",x"0D",x"EE",x"EA",x"E9",x"0C",x"01",x"5A", -- 0x0040
		x"48",x"84",x"67",x"4F",x"4C",x"00",x"F2",x"94",x"79",x"1C",x"FF",x"00",x"00",x"00",x"00",x"00", -- 0x0050
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x0060
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x0070
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x0080
		x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x0090
		x"00",x"00",x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x00A0
		x"00",x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x00B0
		x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x00C0
		x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x00D0
		x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- 0x00E0
		x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF", -- 0x00F0
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"00", -- 0x0100
		x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF", -- 0x0110
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x0120
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x0130
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x0140
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x0150
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x0160
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x0170
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x0180
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x0190
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x01A0
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x01B0
		x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF", -- 0x01C0
		x"FF",x"FF",x"FD",x"A3",x"00",x"5E",x"00",x"00",x"00",x"5E",x"00",x"00",x"00",x"00",x"FD",x"A3", -- 0x01D0
		x"EA",x"E9",x"0C",x"01",x"5A",x"48",x"84",x"67",x"4F",x"4C",x"00",x"F2",x"94",x"79",x"1C",x"89", -- 0x01E0
		x"B0",x"7A",x"01",x"C0",x"B6",x"AC",x"67",x"D1",x"32",x"01",x"5F",x"5E",x"0D",x"EE",x"FF",x"FF"  -- 0x01F0
	);
	-- Ask Xilinx synthesis to use block RAMs if possible
	attribute ram_style : string;
	attribute ram_style of RAM : signal is "block";
	-- Ask Quartus synthesis to use block RAMs if possible
	attribute ramstyle : string;
	attribute ramstyle of RAM : signal is "M10K";

begin
	mem_proc : process
	begin
		wait until rising_edge(CLK);
		DO <= (others=>'0');
		if CEn = '0' then
			if OEn = '0' then
				DO <= RAM(to_integer(unsigned(AD)));
			elsif WEn = '0' then
				RAM(to_integer(unsigned(AD))) <= DI;
			end if;
		end if;
	end process;
end RTL;
