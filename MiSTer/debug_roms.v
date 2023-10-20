// hardcoded ROMs for testing, use SDRAM/DPRAM for release
`ifdef MODELSIM_INDYTEMP
	/* Indiana Jones
	ROM_REGION 0x88000, "maincpu"
		"136036.432",   0x10000, 0x08000
		"136036.431",   0x10001, 0x08000
		"136036.434",   0x20000, 0x08000
		"136036.433",   0x20001, 0x08000
		"136036.456",   0x30000, 0x04000
		"136036.457",   0x30001, 0x04000
		"136036.358",   0x80000, 0x04000
		"136036.359",   0x80001, 0x04000
	ROM_REGION 0x10000, "audiocpu"
		"136036.153",   0x04000, 0x04000
		"136036.154",   0x08000, 0x04000
		"136036.155",   0x0c000, 0x04000
	ROM_REGION 0x380000, "tiles"
		"136036.135",   0x000000, 0x08000
		"136036.139",   0x010000, 0x08000
		"136036.143",   0x020000, 0x08000
		"136036.147",   0x030000, 0x08000
		"136036.136",   0x080000, 0x08000
		"136036.140",   0x090000, 0x08000
		"136036.144",   0x0a0000, 0x08000
		"136036.148",   0x0b0000, 0x08000
		"136036.137",   0x100000, 0x08000
		"136036.141",   0x110000, 0x08000
		"136036.145",   0x120000, 0x08000
		"136036.149",   0x130000, 0x08000
		"136036.138",   0x180000, 0x08000
		"136036.142",   0x190000, 0x08000
		"136036.146",   0x1a0000, 0x08000
		"136036.150",   0x1b0000, 0x08000
	ROM_REGION 0x400, "proms"
		"136036.152",   0x000, 0x200
		"136036.151",   0x200, 0x200
	*/
	wire [63:0] slv_bank1, slv_bank2, slv_bank3, slv_bank4;
	wire [15:0]slv_ROM0_loc, slv_ROM1_loc, slv_ROM2_loc;

	// ROM patches range x00000-x0FFFF
	assign slv_ROM0 =
		// jump to 10000 skip mem checks
		({slv_MADEC,1'b0}==16'h055E)?16'h4EF9:
		({slv_MADEC,1'b0}==16'h0560)?16'h0001:
		// credits = 1
		({slv_MADEC,1'b0}==16'h3862)?16'h1481:
		slv_ROM0_loc;

	// ROM patches range x10000-x1FFFF
	assign slv_ROM1 =
		// start game immediatley
		({slv_MADEC,1'b0}==16'h77B4)?16'h7001:
		slv_ROM1_loc;

	// ROM patches range x20000-x2FFFF
	assign slv_ROM2 =
		slv_ROM2_loc;

	assign slv_VDATA =
		(slv_VADDR[18:16] == 4'b001)?slv_bank1:
		(slv_VADDR[18:16] == 3'b010)?slv_bank2:
		(slv_VADDR[18:16] == 3'b011)?slv_bank3:
		(slv_VADDR[18:16] == 3'b100)?slv_bank4:
		64'hffffffffffffffff;

	assign slv_bank1[63:32] = 32'hffffffff;
	assign slv_bank2[63:32] = 32'hffffffff;
	assign slv_bank3[63:32] = 32'hffffffff;
	assign slv_bank4[63:32] = 32'hffffffff;

	// Video ROMs
	ROM_143 ROM_000000( .CLK(clk_14M), .DATA(slv_bank1[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_147 ROM_010000( .CLK(clk_14M), .DATA(slv_bank1[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_135 ROM_020000( .CLK(clk_14M), .DATA(slv_bank1[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_139 ROM_030000( .CLK(clk_14M), .DATA(slv_bank1[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_144 ROM_080000( .CLK(clk_14M), .DATA(slv_bank2[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_148 ROM_090000( .CLK(clk_14M), .DATA(slv_bank2[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_136 ROM_0A0000( .CLK(clk_14M), .DATA(slv_bank2[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_140 ROM_0B0000( .CLK(clk_14M), .DATA(slv_bank2[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_145 ROM_100000( .CLK(clk_14M), .DATA(slv_bank3[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_149 ROM_110000( .CLK(clk_14M), .DATA(slv_bank3[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_137 ROM_120000( .CLK(clk_14M), .DATA(slv_bank3[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_141 ROM_130000( .CLK(clk_14M), .DATA(slv_bank3[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_146 ROM_180000( .CLK(clk_14M), .DATA(slv_bank4[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_150 ROM_190000( .CLK(clk_14M), .DATA(slv_bank4[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_138 ROM_1A0000( .CLK(clk_14M), .DATA(slv_bank4[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_142 ROM_1B0000( .CLK(clk_14M), .DATA(slv_bank4[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	// System BIOS ROM
	ROM_11J mp_rom0_hi( .CLK(clk_14M), .DATA(slv_ROM0_loc[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM0
	ROM_10J mp_rom0_lo( .CLK(clk_14M), .DATA(slv_ROM0_loc[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM0

	// MAIN CPU ROMs
	ROM_432 mp_rom1_hi( .CLK(clk_14M), .DATA(slv_ROM1_loc[15:8]), .ADDR(slv_MADEC[15:1]) ); // /ROM1
	ROM_431 mp_rom1_lo( .CLK(clk_14M), .DATA(slv_ROM1_loc[ 7:0]), .ADDR(slv_MADEC[15:1]) ); // /ROM1
	ROM_434 mp_rom2_hi( .CLK(clk_14M), .DATA(slv_ROM2_loc[15:8]), .ADDR(slv_MADEC[15:1]) ); // /ROM2
	ROM_433 mp_rom2_lo( .CLK(clk_14M), .DATA(slv_ROM2_loc[ 7:0]), .ADDR(slv_MADEC[15:1]) ); // /ROM2
//	ROM_000 mp_rom5_hi( .CLK(clk_14M), .DATA(slv_ROM5[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM5
//	ROM_000 mp_rom5_lo( .CLK(clk_14M), .DATA(slv_ROM5[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM5
//	ROM_000 mp_rom6_hi( .CLK(clk_14M), .DATA(slv_ROM6[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM6
//	ROM_000 mp_rom6_lo( .CLK(clk_14M), .DATA(slv_ROM6[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM6
	ROM_456 mp_rom7_hi( .CLK(clk_14M), .DATA(slv_ROM7[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM7
	ROM_457 mp_rom7_lo( .CLK(clk_14M), .DATA(slv_ROM7[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM7

	// SLAPSTIC controlled ROMs
	ROM_358 mp_rom_slap_hi( .CLK(clk_14M), .DATA(slv_SLAP[15:8]), .ADDR(slv_MADEC[14:1]) ); // /SLAP
	ROM_359 mp_rom_slap_lo( .CLK(clk_14M), .DATA(slv_SLAP[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /SLAP

	// AUDIO CPU ROMs
	ROM_153 ap_srom0 ( .CLK(clk_14M), .DATA(slv_SROM0), .ADDR(slv_SBA) );
	ROM_154 ap_srom1 ( .CLK(clk_14M), .DATA(slv_SROM1), .ADDR(slv_SBA) );
	ROM_155 ap_srom2 ( .CLK(clk_14M), .DATA(slv_SROM2), .ADDR(slv_SBA) );

	// PROMs
	ROM_5F  rom_alpha ( .CLK(clk_14M), .DATA(slv_PD2B), .ADDR(slv_PA2B[12:0] ) );
	ROM_151 rom_color ( .CLK(clk_14M), .DATA(slv_PD4A), .ADDR(slv_PADDR) );
	ROM_152 rom_remap ( .CLK(clk_14M), .DATA(slv_PD7A), .ADDR(slv_PADDR) );
	EEPROM  mp_eprom  ( .CLK(clk_14M), .DATA(slv_eprom_din), .ADDR(slv_MADEC[9:1]) );
`elsif MODELSIM_PETERPAK
/* Peter Pack-Rat
	ROM_REGION 0x88000, "maincpu"
		"136028.142",   0x10000, 0x04000
		"136028.143",   0x10001, 0x04000
		"136028.144",   0x18000, 0x04000
		"136028.145",   0x18001, 0x04000
		"136028.146",   0x20000, 0x04000
		"136028.147",   0x20001, 0x04000
		"136028.148",   0x80000, 0x04000
		"136028.149",   0x80001, 0x04000
	ROM_REGION 0x10000, "audiocpu"
		"136028.101",   0x08000, 0x04000
		"136028.102",   0x0c000, 0x04000
	ROM_REGION 0x380000, "tiles"
		"136028.138",   0x000000, 0x08000
		"136028.139",   0x010000, 0x08000
		"136028.140",   0x020000, 0x08000
		"136028.141",   0x030000, 0x08000
		"136028.150",   0x080000, 0x08000
		"136028.151",   0x090000, 0x08000
		"136028.152",   0x0a0000, 0x08000
		"136028.153",   0x0b0000, 0x08000
		"136028.105",   0x104000, 0x04000
		"136028.108",   0x114000, 0x04000
		"136028.111",   0x124000, 0x04000
		"136028.114",   0x134000, 0x04000
	ROM_REGION 0x400, "proms"
		"136028.136",   0x000, 0x200
		"136028.137",   0x200, 0x200
*/
	wire [63:0] slv_bank1, slv_bank2, slv_bank3;

	assign slv_VDATA =
		(slv_VADDR[18:16] == 4'b001)?slv_bank1:
		(slv_VADDR[18:16] == 3'b010)?slv_bank2:
		(slv_VADDR[18:16] == 3'b011)?slv_bank3:
		64'hffffffffffffffff;

	assign slv_bank1[63:32] = 32'hffffffff;
	assign slv_bank2[63:32] = 32'hffffffff;
	assign slv_bank3[63:32] = 32'hffffffff;

	// Video ROMs
	ROM_140 ROM_000000( .CLK(clk_14M), .DATA(slv_bank1[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_141 ROM_010000( .CLK(clk_14M), .DATA(slv_bank1[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_138 ROM_020000( .CLK(clk_14M), .DATA(slv_bank1[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_139 ROM_030000( .CLK(clk_14M), .DATA(slv_bank1[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_152 ROM_080000( .CLK(clk_14M), .DATA(slv_bank2[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_153 ROM_090000( .CLK(clk_14M), .DATA(slv_bank2[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_150 ROM_0A0000( .CLK(clk_14M), .DATA(slv_bank2[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_151 ROM_0B0000( .CLK(clk_14M), .DATA(slv_bank2[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_111 ROM_100000( .CLK(clk_14M), .DATA(slv_bank3[31:24]), .ADDR(slv_VADDR[13:0]) );
	ROM_114 ROM_110000( .CLK(clk_14M), .DATA(slv_bank3[23:16]), .ADDR(slv_VADDR[13:0]) );
	ROM_105 ROM_120000( .CLK(clk_14M), .DATA(slv_bank3[15:8 ]), .ADDR(slv_VADDR[13:0]) );
	ROM_108 ROM_130000( .CLK(clk_14M), .DATA(slv_bank3[ 7:0 ]), .ADDR(slv_VADDR[13:0]) );

	wire [15:0 ] slv_ROM_1_LO, slv_ROM_1_HI;
	assign slv_ROM1 =
		(~slv_ROMn[1] && ~slv_MADEC[15])?slv_ROM_1_LO:
		(~slv_ROMn[1] &&  slv_MADEC[15])?slv_ROM_1_HI:
		16'h0;

	// System BIOS ROM
	ROM_11J mp_rom0_hi( .CLK(clk_14M), .DATA(slv_ROM0[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM0
	ROM_10J mp_rom0_lo( .CLK(clk_14M), .DATA(slv_ROM0[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM0

	// MAIN CPU ROMs
	ROM_142 ROM_10B(    .CLK(clk_14M), .DATA(slv_ROM_1_LO[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM1 lo
	ROM_143 ROM_10A(    .CLK(clk_14M), .DATA(slv_ROM_1_LO[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM1 lo
	ROM_144 ROM_11B(    .CLK(clk_14M), .DATA(slv_ROM_1_HI[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM1 hi
	ROM_145 ROM_11A(    .CLK(clk_14M), .DATA(slv_ROM_1_HI[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM1 hi
	ROM_146 mp_rom2_hi( .CLK(clk_14M), .DATA(slv_ROM2[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM2 lo
	ROM_147 mp_rom2_lo( .CLK(clk_14M), .DATA(slv_ROM2[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM2 lo
//	ROM_000 mp_rom5_hi( .CLK(clk_14M), .DATA(slv_ROM5[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM5
//	ROM_000 mp_rom5_lo( .CLK(clk_14M), .DATA(slv_ROM5[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM5
//	ROM_000 mp_rom6_hi( .CLK(clk_14M), .DATA(slv_ROM6[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM6
//	ROM_000 mp_rom6_lo( .CLK(clk_14M), .DATA(slv_ROM6[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM6
//	ROM_000 mp_rom7_hi( .CLK(clk_14M), .DATA(slv_ROM7[15:8]), .ADDR(slv_MADEC[14:1]) ); // /ROM7
//	ROM_000 mp_rom7_lo( .CLK(clk_14M), .DATA(slv_ROM7[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /ROM7

	// SLAPSTIC controlled ROMs
	ROM_148 mp_rom_slap_hi( .CLK(clk_14M), .DATA(slv_SLAP[15:8]), .ADDR(slv_MADEC[14:1]) ); // /SLAP
	ROM_149 mp_rom_slap_lo( .CLK(clk_14M), .DATA(slv_SLAP[ 7:0]), .ADDR(slv_MADEC[14:1]) ); // /SLAP

	// AUDIO CPU ROMs
	assign slv_SROM0 = 0;
	ROM_101 ap_srom1 ( .CLK(clk_14M), .DATA(slv_SROM1), .ADDR(slv_SBA) );
	ROM_102 ap_srom2 ( .CLK(clk_14M), .DATA(slv_SROM2), .ADDR(slv_SBA) );

	// PROMs
	ROM_5F  rom_alpha ( .CLK(clk_14M), .DATA(slv_PD2B), .ADDR(slv_PA2B[12:0] ) );
	ROM_137 rom_color ( .CLK(clk_14M), .DATA(slv_PD4A), .ADDR(slv_PADDR) );
	ROM_136 rom_remap ( .CLK(clk_14M), .DATA(slv_PD7A), .ADDR(slv_PADDR) );

`elsif MODELSIM_MARBLEMAD
/* Marble Madness
	ROM_REGION 0x88000, "maincpu"
		"136033.623",   0x10000, 0x04000
		"136033.624",   0x10001, 0x04000
		"136033.625",   0x18000, 0x04000
		"136033.626",   0x18001, 0x04000
		"136033.627",   0x20000, 0x04000
		"136033.628",   0x20001, 0x04000
		"136033.229",   0x28000, 0x04000
		"136033.630",   0x28001, 0x04000
		"136033.107",   0x80000, 0x04000
		"136033.108",   0x80001, 0x04000
	ROM_REGION 0x10000, "audiocpu"
		"136033.421",   0x08000, 0x04000
		"136033.422",   0x0c000, 0x04000
	ROM_REGION 0x380000, "tiles"
		"136033.137",   0x000000, 0x04000
		"136033.138",   0x004000, 0x04000
		"136033.139",   0x010000, 0x04000
		"136033.140",   0x014000, 0x04000
		"136033.141",   0x020000, 0x04000
		"136033.142",   0x024000, 0x04000
		"136033.143",   0x030000, 0x04000
		"136033.144",   0x034000, 0x04000
		"136033.145",   0x040000, 0x04000
		"136033.146",   0x044000, 0x04000
		"136033.149",   0x084000, 0x04000
		"136033.151",   0x094000, 0x04000
		"136033.153",   0x0a4000, 0x04000
	ROM_REGION 0x400, "proms"
		"136033.118",   0x000, 0x200
		"136033.119",   0x200, 0x200
*/
`elsif MODELSIM_ROADRUN
/* Road Runner
	ROM_REGION 0x88000, "maincpu"
		"136040-228.11c",  0x10000, 0x08000
		"136040-229.11a",  0x10001, 0x08000
		"136040-230.13c",  0x20000, 0x08000
		"136040-231.13a",  0x20001, 0x08000
		"136040-134.12c",  0x50000, 0x08000
		"136040-135.12a",  0x50001, 0x08000
		"136040-136.14c",  0x60000, 0x08000
		"136040-137.14a",  0x60001, 0x08000
		"136040-138.16c",  0x70000, 0x08000
		"136040-139.16a",  0x70001, 0x08000
		"136040-140.17c",  0x80000, 0x04000
		"136040-141.17a",  0x80001, 0x04000
	ROM_REGION 0x10000, "audiocpu"
		"136040-143.15e",  0x08000, 0x4000
		"136040-144.17e",  0x0c000, 0x4000
	ROM_REGION 0x380000, "tiles"
		"136040-101.4b",   0x000000, 0x08000
		"136040-107.9b",   0x010000, 0x08000
		"136040-113.4f",   0x020000, 0x08000
		"136040-119.9f",   0x030000, 0x08000
		"136040-102.3b",   0x080000, 0x08000
		"136040-108.8b",   0x090000, 0x08000
		"136040-114.3f",   0x0a0000, 0x08000
		"136040-120.8f",   0x0b0000, 0x08000
		"136040-103.2b",   0x100000, 0x08000
		"136040-109.7b",   0x110000, 0x08000
		"136040-115.2f",   0x120000, 0x08000
		"136040-121.7f",   0x130000, 0x08000
		"136040-104.1b",   0x180000, 0x08000
		"136040-110.6b",   0x190000, 0x08000
		"136040-116.1f",   0x1a0000, 0x08000
		"136040-122.6f",   0x1b0000, 0x08000
		"136040-105.4d",   0x200000, 0x08000
		"136040-111.9d",   0x210000, 0x08000
		"136040-117.2d",   0x220000, 0x08000
		"136040-123.7d",   0x230000, 0x08000
		"136040-106.3d",   0x280000, 0x08000
		"136040-112.8d",   0x290000, 0x08000
		"136040-118.1d",   0x2a0000, 0x08000
		"136040-124.6d",   0x2b0000, 0x08000
	ROM_REGION 0x400, "proms"
		"136040-126.7a",   0x0000, 0x0200
		"136040-125.5a",   0x0200, 0x0200
*/
	wire [63:0] slv_bank1, slv_bank2, slv_bank3, slv_bank4, slv_bank5, slv_bank6;
	wire [15:0]slv_ROM0_loc, slv_ROM1_loc, slv_ROM2_loc;

	// ROM patches range x00000-x0FFFF
	assign slv_ROM0 =
		// jump to 89C skip ROM checks, start game
		({slv_MADEC,1'b0}==16'h055C)?16'h4EF8:
		({slv_MADEC,1'b0}==16'h055E)?16'h089C:
		slv_ROM0_loc;

	// ROM patches range x10000-x1FFFF
	assign slv_ROM1 =
		// immediately start game
		({slv_MADEC,1'b0}==16'h4E88)?16'h7006:
		({slv_MADEC,1'b0}==16'h586C)?16'h0035:
		({slv_MADEC,1'b0}==16'h5936)?16'h0010:
		({slv_MADEC,1'b0}==16'h5942)?16'h0003:
		({slv_MADEC,1'b0}==16'h595A)?16'h0001:
		({slv_MADEC,1'b0}==16'h5964)?16'h0002:
		({slv_MADEC,1'b0}==16'h5970)?16'h0004:
		({slv_MADEC,1'b0}==16'h597E)?16'h0005:
		({slv_MADEC,1'b0}==16'h598A)?16'h0014:
		({slv_MADEC,1'b0}==16'h5994)?16'h0011:
		({slv_MADEC,1'b0}==16'h59A0)?16'h0012:
		({slv_MADEC,1'b0}==16'h59A8)?16'h0013:
		({slv_MADEC,1'b0}==16'h59B2)?16'h0034:
		({slv_MADEC,1'b0}==16'h59BE)?16'h0035:
		({slv_MADEC,1'b0}==16'h6062)?16'h0001:
		({slv_MADEC,1'b0}==16'hFAC8)?16'hFFF0:
		slv_ROM1_loc;

	// ROM patches range x20000-x2FFFF
	assign slv_ROM2 =
		slv_ROM2_loc;

	assign slv_VDATA =
		(slv_VADDR[18:16] == 3'b001 )?( {slv_bank1[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b010 )?( {slv_bank2[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b011 )?( {slv_bank3[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b100 )?( {slv_bank4[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b101 )?( {slv_bank5[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b110 )?( {slv_bank6[63:32],32'hffffffff}):
		64'hffffffffffffffff;

	// Bank 1
	ROM_4B ROM_000000( .CLK(clk_14M), .DATA(slv_bank1[63:56]), .ADDR(slv_VADDR[14:0]) );
	ROM_9B ROM_010000( .CLK(clk_14M), .DATA(slv_bank1[55:48]), .ADDR(slv_VADDR[14:0]) );
	ROM_4F ROM_020000( .CLK(clk_14M), .DATA(slv_bank1[47:40]), .ADDR(slv_VADDR[14:0]) );
	ROM_9F ROM_030000( .CLK(clk_14M), .DATA(slv_bank1[39:32]), .ADDR(slv_VADDR[14:0]) );

	// Bank 2
	ROM_3B ROM_080000( .CLK(clk_14M), .DATA(slv_bank2[63:56]), .ADDR(slv_VADDR[14:0]) );
	ROM_8B ROM_090000( .CLK(clk_14M), .DATA(slv_bank2[55:48]), .ADDR(slv_VADDR[14:0]) );
	ROM_3F ROM_0A0000( .CLK(clk_14M), .DATA(slv_bank2[47:40]), .ADDR(slv_VADDR[14:0]) );
	ROM_8F ROM_0B0000( .CLK(clk_14M), .DATA(slv_bank2[39:32]), .ADDR(slv_VADDR[14:0]) );

	// Bank 3
	ROM_2B ROM_100000( .CLK(clk_14M), .DATA(slv_bank3[63:56]), .ADDR(slv_VADDR[14:0]) );
	ROM_7B ROM_110000( .CLK(clk_14M), .DATA(slv_bank3[55:48]), .ADDR(slv_VADDR[14:0]) );
	ROM_2F ROM_120000( .CLK(clk_14M), .DATA(slv_bank3[47:40]), .ADDR(slv_VADDR[14:0]) );
	ROM_7F ROM_130000( .CLK(clk_14M), .DATA(slv_bank3[39:32]), .ADDR(slv_VADDR[14:0]) );

	// Bank 4
	ROM_1B ROM_180000( .CLK(clk_14M), .DATA(slv_bank4[63:56]), .ADDR(slv_VADDR[14:0]) );
	ROM_6B ROM_190000( .CLK(clk_14M), .DATA(slv_bank4[55:48]), .ADDR(slv_VADDR[14:0]) );
	ROM_1F ROM_1A0000( .CLK(clk_14M), .DATA(slv_bank4[47:40]), .ADDR(slv_VADDR[14:0]) );
	ROM_6F ROM_1B0000( .CLK(clk_14M), .DATA(slv_bank4[39:32]), .ADDR(slv_VADDR[14:0]) );

	// Bank 5
	ROM_4D ROM_200000( .CLK(clk_14M), .DATA(slv_bank5[63:56]), .ADDR(slv_VADDR[14:0]) );
	ROM_9D ROM_210000( .CLK(clk_14M), .DATA(slv_bank5[55:48]), .ADDR(slv_VADDR[14:0]) );
	ROM_2D ROM_220000( .CLK(clk_14M), .DATA(slv_bank5[47:40]), .ADDR(slv_VADDR[14:0]) );
	ROM_7D ROM_230000( .CLK(clk_14M), .DATA(slv_bank5[39:32]), .ADDR(slv_VADDR[14:0]) );

	// Bank 6
	ROM_3D ROM_280000( .CLK(clk_14M), .DATA(slv_bank6[63:56]), .ADDR(slv_VADDR[14:0]) );
	ROM_8D ROM_290000( .CLK(clk_14M), .DATA(slv_bank6[55:48]), .ADDR(slv_VADDR[14:0]) );
	ROM_1D ROM_2A0000( .CLK(clk_14M), .DATA(slv_bank6[47:40]), .ADDR(slv_VADDR[14:0]) );
	ROM_6D ROM_2B0000( .CLK(clk_14M), .DATA(slv_bank6[39:32]), .ADDR(slv_VADDR[14:0]) );

	// System BIOS ROM
	ROM_11J mp_rom0_hi(     .CLK(clk_14M), .DATA(slv_ROM0_loc[15:8]), .ADDR(slv_MADEC[14:1]) );
	ROM_10J mp_rom0_lo(     .CLK(clk_14M), .DATA(slv_ROM0_loc[ 7:0]), .ADDR(slv_MADEC[14:1]) );

	// MAIN CPU ROMs
	ROM_11C mp_rom1_hi(     .CLK(clk_14M), .DATA(slv_ROM1_loc[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_11A mp_rom1_lo(     .CLK(clk_14M), .DATA(slv_ROM1_loc[ 7:0]), .ADDR(slv_MADEC[15:1]) );
	ROM_13C mp_rom2_hi(     .CLK(clk_14M), .DATA(slv_ROM2_loc[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_13A mp_rom2_lo(     .CLK(clk_14M), .DATA(slv_ROM2_loc[ 7:0]), .ADDR(slv_MADEC[15:1]) );
	ROM_12C mp_rom5_hi(     .CLK(clk_14M), .DATA(slv_ROM5[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_12A mp_rom5_lo(     .CLK(clk_14M), .DATA(slv_ROM5[ 7:0]), .ADDR(slv_MADEC[15:1]) );
	ROM_14C mp_rom6_hi(     .CLK(clk_14M), .DATA(slv_ROM6[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_14A mp_rom6_lo(     .CLK(clk_14M), .DATA(slv_ROM6[ 7:0]), .ADDR(slv_MADEC[15:1]) );
	ROM_16C mp_rom7_hi(     .CLK(clk_14M), .DATA(slv_ROM7[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_16A mp_rom7_lo(     .CLK(clk_14M), .DATA(slv_ROM7[ 7:0]), .ADDR(slv_MADEC[15:1]) );

	// SLAPSTIC controlled ROMs
	ROM_17C mp_rom_slap_hi( .CLK(clk_14M), .DATA(slv_SLAP[15:8]), .ADDR(slv_MADEC[14:1]) );
	ROM_17A mp_rom_slap_lo( .CLK(clk_14M), .DATA(slv_SLAP[ 7:0]), .ADDR(slv_MADEC[14:1]) );

	// AUDIO CPU ROMs
	assign slv_SROM0 = 8'h0;
	ROM_15E   ap_srom1 (    .CLK(clk_14M), .DATA(slv_SROM1),      .ADDR(slv_SBA  ) );
	ROM_17E   ap_srom2 (    .CLK(clk_14M), .DATA(slv_SROM2),      .ADDR(slv_SBA  ) );

	// PROMs
	ROM_5F   rom_alpha (    .CLK(clk_14M), .DATA(slv_PD2B),       .ADDR(slv_PA2B[12:0] ) );
	ROM_5A   rom_color (    .CLK(clk_14M), .DATA(slv_PD4A),       .ADDR(slv_PADDR) );
	ROM_7A   rom_remap (    .CLK(clk_14M), .DATA(slv_PD7A),       .ADDR(slv_PADDR) );

`elsif MODELSIM_ROADBLAST
/* Road Blasters
	ROM_REGION 0x88000, "maincpu"
		"136048-1157.11c",   0x10000, 0x08000
		"136048-1158.11a",   0x10001, 0x08000
		"136048-1159.13c",   0x20000, 0x08000
		"136048-1160.13a",   0x20001, 0x08000
		"136048-2141.7l",    0x50000, 0x08000
		"136048-2142.8l",    0x50001, 0x08000
		"136048-2143.7m",    0x60000, 0x08000
		"136048-2144.8m",    0x60001, 0x08000
		"136048-2145.7n",    0x70000, 0x08000
		"136048-2146.8n",    0x70001, 0x08000
		"136048-2147.7k",    0x80000, 0x04000
		"136048-2148.8k",    0x80001, 0x04000
	ROM_REGION 0x10000, "audiocpu"
		"136048-1149.14e",   0x04000, 0x04000
		"136048-1169.1516e", 0x08000, 0x04000
		"136048-1170.17e",   0x0c000, 0x04000
	ROM_REGION 0x380000, "tiles"
		"136048-1101.2s",  0x000000, 0x08000  - bank 1, plane 0
		"136048-1102.2r",  0x010000, 0x08000  - bank 1, plane 1
		"136048-1103.2n",  0x020000, 0x08000  - bank 1, plane 2
		"136048-1104.2m",  0x030000, 0x08000  - bank 1, plane 3
		"136048-1105.2k",  0x040000, 0x08000  - bank 1, plane 4
		"136048-1106.2j",  0x050000, 0x08000  - bank 1, plane 5
		"136048-1107.3s",  0x080000, 0x08000  - bank 2, plane 0
		"136048-1108.2p",  0x090000, 0x08000  - bank 2, plane 1
		"136048-1109.3n",  0x0a0000, 0x08000  - bank 2, plane 2
		"136048-1110.2l",  0x0b0000, 0x08000  - bank 2, plane 3
		"136048-1107.3s",  0x100000, 0x08000  - bank 3, plane 0
		"136048-1108.2p",  0x110000, 0x08000  - bank 3, plane 1
		"136048-1109.3n",  0x120000, 0x08000  - bank 3, plane 2
		"136048-1110.2l",  0x130000, 0x08000  - bank 3, plane 3
		"136048-1111.4s",  0x180000, 0x08000  - bank 4, plane 0
		"136048-1112.3r",  0x190000, 0x08000  - bank 4, plane 1
		"136048-1113.4n",  0x1a0000, 0x08000  - bank 4, plane 2
		"136048-1114.3m",  0x1b0000, 0x08000  - bank 4, plane 3
		"136048-1111.4s",  0x200000, 0x08000  - bank 5, plane 0
		"136048-1112.3r",  0x210000, 0x08000  - bank 5, plane 1
		"136048-1113.4n",  0x220000, 0x08000  - bank 5, plane 2
		"136048-1114.3m",  0x230000, 0x08000  - bank 5, plane 3
		"136048-1115.4r",  0x280000, 0x08000  - bank 6, plane 0
		"136048-1116.3p",  0x290000, 0x08000  - bank 6, plane 1
		"136048-1117.4m",  0x2a0000, 0x08000  - bank 6, plane 2
		"136048-1118.3l",  0x2b0000, 0x08000  - bank 6, plane 3
		"136048-1115.4r",  0x300000, 0x08000  - bank 7, plane 0
		"136048-1116.3p",  0x310000, 0x08000  - bank 7, plane 1
		"136048-1117.4m",  0x320000, 0x08000  - bank 7, plane 2
		"136048-1118.3l",  0x330000, 0x08000  - bank 7, plane 3
	ROM_REGION 0x400, "proms"
		"136048-1174.12d", 0x0000, 0x0200 - remap
		"136048-1173.2d",  0x0200, 0x0200 - color
*/

	wire [63:0] slv_bank1, slv_bank23, slv_bank45, slv_bank76;
	wire [15:0]slv_ROM0_loc, slv_ROM1_loc, slv_ROM2_loc;

	// ROM patches range x00000-x0FFFF
	assign slv_ROM0 =
		// jump to 102ee skip mem checks
		({slv_MADEC,1'b0}==16'h0558)?16'h4ef9:
		({slv_MADEC,1'b0}==16'h055a)?16'h0001:
		({slv_MADEC,1'b0}==16'h055c)?16'h02ee:
		// 
		({slv_MADEC,1'b0}==16'h4572)?16'h4e75:
		slv_ROM0_loc;

	// ROM patches range x10000-x1FFFF
	assign slv_ROM1 =
		// 
		({slv_MADEC,1'b0}==16'h034a)?16'h4e75:
		// 
		({slv_MADEC,1'b0}==16'h9946)?16'h0002:
		// 
		({slv_MADEC,1'b0}==16'h994e)?16'h0002:
		// 
		({slv_MADEC,1'b0}==16'h9d8c)?16'h9800:
		slv_ROM1_loc;

	// ROM patches range x20000-x2FFFF
	assign slv_ROM2 =
		slv_ROM2_loc;

	assign slv_VDATA =
		(slv_VADDR[18:16] == 3'b001 )?( {slv_bank1[63:16],16'hffff}):
		(slv_VADDR[18:16] == 3'b010 )?( {slv_bank23[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b011 )?( {slv_bank23[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b100 )?( {slv_bank45[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b101 )?( {slv_bank45[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b110 )?( {slv_bank76[63:32],32'hffffffff}):
		(slv_VADDR[18:16] == 3'b111 )?( {slv_bank76[63:32],32'hffffffff}):
		64'hffffffffffffffff;

	// Bank 1
	ROM_2S ROM_000000( .CLK(clk_14M), .DATA(slv_bank1[63:56]), .ADDR(                 slv_VADDR[14:0] ) );
	ROM_2R ROM_010000( .CLK(clk_14M), .DATA(slv_bank1[55:48]), .ADDR(                 slv_VADDR[14:0] ) );
	ROM_2N ROM_020000( .CLK(clk_14M), .DATA(slv_bank1[47:40]), .ADDR(                 slv_VADDR[14:0] ) );
	ROM_2M ROM_030000( .CLK(clk_14M), .DATA(slv_bank1[39:32]), .ADDR(                 slv_VADDR[14:0] ) );
	ROM_2K ROM_040000( .CLK(clk_14M), .DATA(slv_bank1[31:24]), .ADDR(                 slv_VADDR[14:0] ) );
	ROM_2J ROM_050000( .CLK(clk_14M), .DATA(slv_bank1[23:16]), .ADDR(                 slv_VADDR[14:0] ) );

	// Bank 2/3
	ROM_3S ROM_080000( .CLK(clk_14M), .DATA(slv_bank23[63:56]), .ADDR({ slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_2P ROM_090000( .CLK(clk_14M), .DATA(slv_bank23[55:48]), .ADDR({ slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_3N ROM_0A0000( .CLK(clk_14M), .DATA(slv_bank23[47:40]), .ADDR({ slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_2L ROM_0B0000( .CLK(clk_14M), .DATA(slv_bank23[39:32]), .ADDR({ slv_VADDR[16],slv_VADDR[14:0]}) );

	// Bank 4/5
	ROM_4S ROM_180000( .CLK(clk_14M), .DATA(slv_bank45[63:56]), .ADDR({ slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_3R ROM_190000( .CLK(clk_14M), .DATA(slv_bank45[55:48]), .ADDR({ slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_4N ROM_1A0000( .CLK(clk_14M), .DATA(slv_bank45[47:40]), .ADDR({ slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_3M ROM_1B0000( .CLK(clk_14M), .DATA(slv_bank45[39:32]), .ADDR({ slv_VADDR[16],slv_VADDR[14:0]}) );

	// Bank 7/6
	ROM_4R ROM_280000( .CLK(clk_14M), .DATA(slv_bank76[63:56]), .ADDR({~slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_3P ROM_290000( .CLK(clk_14M), .DATA(slv_bank76[55:48]), .ADDR({~slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_4M ROM_2A0000( .CLK(clk_14M), .DATA(slv_bank76[47:40]), .ADDR({~slv_VADDR[16],slv_VADDR[14:0]}) );
	ROM_3L ROM_2B0000( .CLK(clk_14M), .DATA(slv_bank76[39:32]), .ADDR({~slv_VADDR[16],slv_VADDR[14:0]}) );

	// System BIOS ROM
	ROM_11J mp_rom0_hi(     .CLK(clk_14M), .DATA(slv_ROM0_loc[15:8]), .ADDR(slv_MADEC[14:1]) );
	ROM_10J mp_rom0_lo(     .CLK(clk_14M), .DATA(slv_ROM0_loc[ 7:0]), .ADDR(slv_MADEC[14:1]) );

	// MAIN CPU ROMs
	ROM_11C mp_rom1_hi(     .CLK(clk_14M), .DATA(slv_ROM1_loc[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_11A mp_rom1_lo(     .CLK(clk_14M), .DATA(slv_ROM1_loc[ 7:0]), .ADDR(slv_MADEC[15:1]) );
	ROM_13C mp_rom2_hi(     .CLK(clk_14M), .DATA(slv_ROM2_loc[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_13A mp_rom2_lo(     .CLK(clk_14M), .DATA(slv_ROM2_loc[ 7:0]), .ADDR(slv_MADEC[15:1]) );
	ROM_7L  mp_rom5_hi(     .CLK(clk_14M), .DATA(slv_ROM5[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_8L  mp_rom5_lo(     .CLK(clk_14M), .DATA(slv_ROM5[ 7:0]), .ADDR(slv_MADEC[15:1]) );
	ROM_7M  mp_rom6_hi(     .CLK(clk_14M), .DATA(slv_ROM6[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_8M  mp_rom6_lo(     .CLK(clk_14M), .DATA(slv_ROM6[ 7:0]), .ADDR(slv_MADEC[15:1]) );
	ROM_7N  mp_rom7_hi(     .CLK(clk_14M), .DATA(slv_ROM7[15:8]), .ADDR(slv_MADEC[15:1]) );
	ROM_8N  mp_rom7_lo(     .CLK(clk_14M), .DATA(slv_ROM7[ 7:0]), .ADDR(slv_MADEC[15:1]) );

	// SLAPSTIC controlled ROMs
	ROM_7K  mp_rom_slap_hi( .CLK(clk_14M), .DATA(slv_SLAP[15:8]), .ADDR(slv_MADEC[14:1]) );
	ROM_8K  mp_rom_slap_lo( .CLK(clk_14M), .DATA(slv_SLAP[ 7:0]), .ADDR(slv_MADEC[14:1]) );

	// AUDIO CPU ROMs
	ROM_14E   ap_srom0 (    .CLK(clk_14M), .DATA(slv_SROM0),      .ADDR(slv_SBA  ) );
	ROM_1516E ap_srom1 (    .CLK(clk_14M), .DATA(slv_SROM1),      .ADDR(slv_SBA  ) );
	ROM_17E   ap_srom2 (    .CLK(clk_14M), .DATA(slv_SROM2),      .ADDR(slv_SBA  ) );

	// PROMs
	ROM_5F   rom_alpha (    .CLK(clk_14M), .DATA(slv_PD2B),       .ADDR(slv_PA2B[12:0] ) );
	ROM_2D   rom_color (    .CLK(clk_14M), .DATA(slv_PD4A),       .ADDR(slv_PADDR) );
	ROM_12D  rom_remap (    .CLK(clk_14M), .DATA(slv_PD7A),       .ADDR(slv_PADDR) );
`endif
