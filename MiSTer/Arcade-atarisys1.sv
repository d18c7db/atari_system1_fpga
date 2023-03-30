//============================================================================
//  Arcade: Atari System-1
//
//  Port to MiSTer
//  Copyright (C) 2020 d18c7db
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================
//`define MODELSIM
//`define MODELSIM_INDYTEMP
//`define MODELSIM_PETERPAK
//`define MODELSIM_MARBLEMAD
//`define MODELSIM_ROADRUN
//`define MODELSIM_ROADBLAST

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
`ifndef MISTER_DUAL_SDRAM
	output        VGA_DISABLE,
`endif
	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for all ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

//assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

`ifndef MISTER_DUAL_SDRAM
	assign VGA_DISABLE = 0;
`endif

// Slapstic Types: marble=103 (x67), indytemp=105 (x69), peterpak=107 (x6B), roadrunn=108 (x6C), roadb109=109 (x6D), roadb110=110 (x6E)
integer     slap_type = 105;

wire         clk_7M;
wire         clk_14M;
wire         clk_sys;
wire         clk_vid;
reg          ce_pix;
wire         pll_locked;
wire         hblank, vblank;
wire         hs, vs;
wire [  3:0] r,g,b, gvid_I, gvid_R, gvid_G, gvid_B;
wire [ 15:0] aud_l, aud_r;
wire [127:0] status;
wire [  1:0] buttons;
wire         forced_scandoubler;
wire         direct_video;
wire         ioctl_download;
wire         ioctl_wr;
wire         ioctl_wait;
wire  [ 7:0] ioctl_index;
wire  [24:0] ioctl_addr;
wire  [ 7:0] ioctl_dout;

assign AUDIO_S = 1'b1; // signed samples
assign AUDIO_L = aud_l;
assign AUDIO_R = aud_r;
assign AUDIO_MIX = 0;

assign LED_USER  = ioctl_download;
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

wire [31:0] joystick_0;
wire [15:0] joystick_l_analog_0;
wire [15:0] joystick_r_analog_0;

wire [10:0] ps2_key;
wire [24:0]	ps2_mouse;
reg mouse_L = 1'b0; // left
reg mouse_R = 1'b0; // right

wire [21:0] gamma_bus;
wire sl_reset = RESET | status[0] | buttons[1] | ioctl_download;

reg [7:0] kbd1 = 8'h0;
reg [7:0] kbd2 = 8'h0;

reg  m_coin_aux = 1'b0;
reg  m_coin_l   = 1'b0;
reg  m_coin_r   = 1'b0;

wire m_service = status[13];

//assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

wire [1:0] ar = status[7:6];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"A.ATARISYS1;;",
	"-;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O67,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"-;",
	"O8,Mouse Buttons,Normal,Swapped;",
	"O9A,Mouse speed,100%,200%,400%,800%;",
	"OB,Joystick mode,Digital,Analog;",
	"OC,Joystick speed,High,Low;",
	"-;",
	"OD,Service,Off,On;",
	"R0,Reset;",
	"-;",
	"J1,Button1,Button2,Button3,Button4,Coin,VStart;",
	"jn,A,B,X,Y,R,Start;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////
pll pll
(
	.refclk(CLK_50M),
	.rst(1'b0),
	.outclk_0(clk_7M),    //  7.15909 MHz
	.outclk_1(clk_14M),   // 14.31818 MHz
	.outclk_2(clk_vid),   // 57.27272 MHz
	.outclk_3(clk_sys),   // 93.06817 MHz
	.outclk_4(SDRAM_CLK), // 93.06817 MHz
	.locked(pll_locked)
);

// Slapstic Types: marble=103 (x67), indytemp=105 (x69), peterpak=107 (x6B), roadrunn=108 (x6C), roadb109=109 (x6D), roadb110=110 (x6E)
always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==1)) slap_type <= ioctl_dout;

// keyboard controls - map keycodes to actions
wire pressed = ps2_key[9];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];

	if(old_state != ps2_key[10]) begin
		casex(ps2_key[8:0])
			// Default MAME Controls Assignment
			'h175: kbd1[7]        <= pressed; // up         (up_arrow)
			'h172: kbd1[6]        <= pressed; // down       (down_arrow)
			'h16B: kbd1[5]        <= pressed; // left       (left_arrow)
			'h174: kbd1[4]        <= pressed; // right      (right_arrow)
			'h014: kbd1[1]        <= pressed; // start/whip (left ctrl)
			'h011: kbd1[0]        <= pressed; // jump       (left alt)

			'h02D: kbd2[7]        <= pressed; // up         (R)
			'h02B: kbd2[6]        <= pressed; // down       (F)
			'h023: kbd2[5]        <= pressed; // left       (D)
			'h034: kbd2[4]        <= pressed; // right      (G)
			'h01C: kbd2[1]        <= pressed; // start/whip (A)
			'h01B: kbd2[0]        <= pressed; // jump       (S)

			'h02E: m_coin_l     <= pressed; // coin_l     (5)
			'h036: m_coin_r     <= pressed; // coin_r     (6)
			'h03D: m_coin_aux   <= pressed; // coin_aux   (7)
		endcase
	end
end

// ps2_mouse(0)=1 L button pressed
// ps2_mouse(1)=1 R buttin pressed
// ps2_mouse(2)=1 M button pressed
// mouse controls - allow remap of mouse button order
always @(posedge clk_sys)
begin
	case(status[8])
	1'b0: // normal
	begin
		mouse_L <= ps2_mouse[0];
		mouse_R <= ps2_mouse[1];
	end
	1'b1: // swap
	begin
		mouse_R <= ps2_mouse[0];
		mouse_L <= ps2_mouse[1];
	end
	endcase
end

///////////////////////////////////////////////////
always @(posedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_pix <= !div;
end

// convert input video from 16bit IRGB to 12 bit RGB
RGBI RCONV (.ADDR({gvid_I,gvid_R}), .DATA(r));
RGBI GCONV (.ADDR({gvid_I,gvid_G}), .DATA(g));
RGBI BCONV (.ADDR({gvid_I,gvid_B}), .DATA(b));

// ###################################################
// # This section loads the ROM files through HPS_IO #
// ###################################################

wire [17:0] slv_VADDR;
wire [63:0] slv_VDATA;
wire [22:0] sdram_addr;
reg  [21:0] addr_new=0;
reg  [63:0] sdram_data=0;
reg         sdram_we=0;
wire        sdram_ready;

// the order in which the files are listed in the .mra file determines the order in which they appear here on the HPS bus
// some files are interleaved as DWORD, some are interleaved as WORD and some are not interleaved and appear as BYTE
// acc_bytes collects previous bytes so that when a WORD or DWORD is complete it is written to the RAM as appropriate
reg [55:0] acc_bytes = 0;
always @(posedge clk_sys)
	if (ioctl_wr && (!ioctl_index) && ioctl_download )
		acc_bytes<={acc_bytes[47:0],ioctl_dout}; // accumulate previous bytes

always @(posedge clk_sys)
begin
	sdram_we <= 1'b0;
	if (ioctl_wr && (!ioctl_index) && ioctl_download && ioctl_addr[2] && ioctl_addr[1] && ioctl_addr[0])
	begin
		sdram_data <= {acc_bytes,ioctl_dout};
		addr_new <= ioctl_addr[24:3];
		sdram_we <= 1'b1;
	end
end

assign sdram_addr = ioctl_download?{1'b0,addr_new}:{5'd0,slv_VADDR};
assign ioctl_wait = ~(pll_locked && sdram_ready);

//wire gp_wr;
wire sl_wr_SROM0, sl_wr_SROM1, sl_wr_SROM2;
wire sl_wr_ROM0, sl_wr_ROM1, sl_wr_ROM2, sl_wr_ROM5, sl_wr_ROM6, sl_wr_ROM7;
wire sl_wr_2B, sl_wr_5A , sl_wr_7A, sl_wr_SLAP, sl_MA18n;

wire [15:1] slv_MADEC;
wire [15:0] slv_MDATA;
wire [15:0] slv_ROM0, slv_ROM1, slv_ROM2, slv_ROM5, slv_ROM6, slv_ROM7, slv_SLAP;
wire [13:0] slv_SBA;
wire [12:0] slv_PA2B;
wire [ 8:0] slv_PADDR;
wire [ 7:0] slv_SROM0, slv_SROM1, slv_SROM2;
wire [ 7:0] slv_SDATA, slv_PD4A, slv_PD7A, slv_PD2B;
wire [ 4:0] slv_ROMn;
wire [ 2:0] slv_SROMn;

// 0x000000 [24:21]=4'b0   8 banks [20:18] X 64KB [17:2] x 8 planes [1:0] = 0x400000
//assign gp_wr       = (ioctl_wr && !ioctl_index && ioctl_addr[24:21]== 4'h00  && ioctl_addr[1:0]==2'b11) ? 1'b1 : 1'b0;
// 0x400000 - 0x407fff
assign sl_wr_ROM0    = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h80  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0; // x4000
// 0x410000 - 0x41ffff
assign sl_wr_ROM1    = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h41  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0; // x8000
// 0x420000 - 0x42ffff
assign sl_wr_ROM2    = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h42  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0; // x8000
// 0x430000 - 0x437fff
//assign sl_wr_ROM3  = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h86  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0; // x4000
// 0x450000 - 0x45ffff
assign sl_wr_ROM5    = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h45  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0; // x8000
// 0x460000 - 0x46ffff
assign sl_wr_ROM6    = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h46  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0; // x8000
// 0x470000 - 0x47ffff
assign sl_wr_ROM7    = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h47  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0; // x8000
// 0x480000 - 0x487fff
assign sl_wr_SLAP    = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h90  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0; // x4000
// 0x488000 - 0x48bfff
assign sl_wr_SROM0   = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h122  ) ? 1'b1 : 1'b0; // x4000
// 0x48C000 - 0x48ffff
assign sl_wr_SROM1   = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h123  ) ? 1'b1 : 1'b0; // x4000
// 0x490000 - 0x493fff
assign sl_wr_SROM2   = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h124  ) ? 1'b1 : 1'b0; // x4000
// 0x494000 - 0x495fff
assign sl_wr_2B      = (ioctl_wr && !ioctl_index && ioctl_addr[24:13]==12'h24A ) ? 1'b1 : 1'b0; // x2000
// 0x496000 - 0x4961ff
assign sl_wr_5A      = (ioctl_wr && !ioctl_index && ioctl_addr[24:9] ==16'h24B0) ? 1'b1 : 1'b0; // x200
// 0x496200 - 0x4963ff
assign sl_wr_7A      = (ioctl_wr && !ioctl_index && ioctl_addr[24:9] ==16'h24B1) ? 1'b1 : 1'b0; // x200
// 0x496400

`ifndef MODELSIM
	arcade_video #(.WIDTH(320), .DW(12)) arcade_video
	(
		.*,

		.clk_video(clk_vid),
		.ce_pix(ce_pix),

		.RGB_in({r,g,b}),
		.HBlank(~hblank),
		.VBlank(~vblank),
		.HSync(~hs),
		.VSync(~vs),

		.fx(status[5:3])
	);

	hps_io #(.CONF_STR(CONF_STR)) hps_io
	(
		.clk_sys(clk_sys),
		.HPS_BUS(HPS_BUS),
		.EXT_BUS(),
		.gamma_bus(gamma_bus),

		.forced_scandoubler(forced_scandoubler),

		.buttons(buttons),
		.status(status),
		.status_menumask({1'b0,direct_video}),
		.direct_video(direct_video),

		.ioctl_download(ioctl_download),
		.ioctl_wr(ioctl_wr),
		.ioctl_addr(ioctl_addr),
		.ioctl_dout(ioctl_dout),
		.ioctl_index(ioctl_index),
		.ioctl_wait(ioctl_wait),

		.joystick_0(joystick_0),
		.joystick_l_analog_0(joystick_l_analog_0),
		.joystick_r_analog_0(joystick_r_analog_0),
		.ps2_mouse(ps2_mouse),
		.ps2_key(ps2_key)
	);

	// 1536 M10K blocks gp_rom (6 x 32K x 64bits not used, replaced with sdram above due to size constraints)
	sdram #(.tCK_ns(1000/93.06817)) sdram
	(
		.I_RST(~pll_locked),
		.I_CLK(clk_sys),

		// controller interface
		.I_ADDR(sdram_addr),
		.I_DATA(sdram_data),
		.I_WE(sdram_we),
		.O_RDY(sdram_ready),
		.O_DATA(slv_VDATA),

		// SDRAM interface
		.SDRAM_DQ(SDRAM_DQ),
		.SDRAM_A(SDRAM_A),
		.SDRAM_BA(SDRAM_BA),
		.SDRAM_DQML(SDRAM_DQML),
		.SDRAM_DQMH(SDRAM_DQMH),
		.SDRAM_CLK(),
		.SDRAM_CKE(SDRAM_CKE),
		.SDRAM_nCS(SDRAM_nCS),
		.SDRAM_nRAS(SDRAM_nRAS),
		.SDRAM_nCAS(SDRAM_nCAS),
		.SDRAM_nWE(SDRAM_nWE)
	);

	// 32 M10K blocks
	// ROM0 BIOS 0x000000, 0x4000
	dpram #(14,16) mp_rom0
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_ROM0 ), .address_a(ioctl_addr[14:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b( slv_MADEC[14:1]), .data_b(                            ), .q_b(slv_ROM0    ));

	// 64 M10K blocks
	// ROM1 0x10000, 0x08000
	dpram #(15,16) mp_rom1
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_ROM1 ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b( slv_MADEC[15:1]), .data_b(                            ), .q_b(slv_ROM1    ));

	// 64 M10K blocks
	// ROM2 0x20000, 0x08000
	dpram #(15,16) mp_rom2
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_ROM2 ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b( slv_MADEC[15:1]), .data_b(                            ), .q_b(slv_ROM2    ));

	// 32 M10K blocks
	// ROM3 0x30000, INDIANA JONES only region, remapped to 0x070000 instead.
//	dpram #(14,16) mp_rom3
//	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_ROM3 ), .address_a(ioctl_addr[14:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(            ),
//	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b( slv_MADEC[14:1]), .data_b(                            ), .q_b(slv_ROM3    ));

	// 64 M10K blocks
	// ROM5 0x50000, 0x08000
	dpram #(15,16) mp_rom5
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_ROM5 ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b( slv_MADEC[15:1]), .data_b(                            ), .q_b(slv_ROM5    ));

	// 64 M10K blocks
	// ROM6 0x60000, 0x08000
	dpram #(15,16) mp_rom6
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_ROM6 ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b( slv_MADEC[15:1]), .data_b(                            ), .q_b(slv_ROM6    ));

	// 64 M10K blocks
	// ROM7 0x70000, 0x08000
	dpram #(15,16) mp_rom7
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_ROM7 ), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b( slv_MADEC[15:1]), .data_b(                            ), .q_b(slv_ROM7    ));

	// 32 M10K blocks
	// Slapstic 0x80000, 0x04000
	dpram #(14,16) mp_rom_slap
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_SLAP ), .address_a(ioctl_addr[14:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b( slv_MADEC[14:1]), .data_b(                            ), .q_b(slv_SLAP    ));

	// 16 M10K blocks
	// Audiocpu 0x4000, 0x4000
	dpram #(14, 8) ap_srom0
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_SROM0), .address_a(ioctl_addr[13:0]), .data_a(                 ioctl_dout ), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b(   slv_SBA[13:0]), .data_b(                            ), .q_b(slv_SROM0   ));

	// 16 M10K blocks
	// Audiocpu 0x8000, 0x4000
	dpram #(14, 8) ap_srom1
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_SROM1), .address_a(ioctl_addr[13:0]), .data_a(                 ioctl_dout ), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b(   slv_SBA[13:0]), .data_b(                            ), .q_b(slv_SROM1   ));

	// 16 M10K blocks
	// Audiocpu 0xC000, 0x4000
	dpram #(14, 8) ap_srom2
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_SROM2), .address_a(ioctl_addr[13:0]), .data_a(                 ioctl_dout ), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b(   slv_SBA[13:0]), .data_b(                            ), .q_b(slv_SROM2   ));

	// 8 M10K blocks
	// Alphanumerics ROM
	dpram  #(13,8) al_rom_2B
	(.clock_a(clk_sys), .enable_a(), .wren_a(sl_wr_2B   ), .address_a(ioctl_addr[12:0]), .data_a(                 ioctl_dout ), .q_a(            ),
	 .clock_b(clk_sys), .enable_b(), .wren_b(           ), .address_b(  slv_PA2B[12:0]), .data_b(                            ), .q_b(slv_PD2B    ));

	// 1 M10K blocks
	// Color PROM
	dpram  #(9,8) cp_rom_5A
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_5A   ), .address_a(ioctl_addr[ 8:0]), .data_a(                 ioctl_dout ), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(           ), .address_b( slv_PADDR[ 8:0]), .data_b(                            ), .q_b(slv_PD4A       ));

	// 1 M10K blocks
	// Remap PROM
	dpram  #(9,8) cp_rom_7A
	(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_7A   ), .address_a(ioctl_addr[ 8:0]), .data_a(                 ioctl_dout ), .q_a(               ),
	 .clock_b(clk_sys    ), .enable_b(), .wren_b(           ), .address_b( slv_PADDR[ 8:0]), .data_b(                            ), .q_b(slv_PD7A       ));
`else
	assign sdram_ready = 0;

	// hps_io outputs
	assign buttons = 0;
	assign ioctl_download = 0;
	assign ioctl_wr = 0;
	assign ioctl_addr = 0;
	assign ioctl_dout = 0;
	assign ioctl_index = 0;
	assign joystick_0 = 0;
	assign ps2_key = 0;
	assign gamma_bus = 0;
	assign forced_scandoubler = 0;
	assign status = 0; // 1 is reset, 0 is free run
	assign direct_video = 0;

	`include "tb/debug_roms.v"

`endif

// Note: to save some memory we alias ROM3 with ROM7.
// Tweak .mra file accordingly and upload ROM3 into ROM7 slot.
// ROM3 is only used by Indy and nothing else while ROM7 region is unused by Indy.
assign slv_MDATA =
	(~slv_ROMn[0] &  sl_MA18n)?slv_ROM0:
	(~slv_ROMn[1] &  sl_MA18n)?slv_ROM1:
	(~slv_ROMn[2] &  sl_MA18n)?slv_ROM2:
	(~slv_ROMn[3] &  sl_MA18n)?slv_ROM7:

	(~slv_ROMn[1] & ~sl_MA18n)?slv_ROM5:
	(~slv_ROMn[2] & ~sl_MA18n)?slv_ROM6:
	(~slv_ROMn[3] & ~sl_MA18n)?slv_ROM7:
	(~slv_ROMn[4]            )?slv_SLAP:
	16'h0;

assign slv_SDATA =
	(~slv_SROMn[0])?slv_SROM0:
	(~slv_SROMn[1])?slv_SROM1:
	(~slv_SROMn[2])?slv_SROM2:
	8'h0;

// SP-282 ##################################################################################
// J102         J103        P104            P105               J106
//  1 +5         1 +5        1 +5           1 Self Test         1 +5
//  2 P2 Up      2 H_CLK2    2 Coin Ctr 1   2 Right Audio GND   2 N/C
//  3 P2 Down    3 H_DIR2    3 Coin Ctr 2   3 Right Audio       3 LED2
//  4 P2 Left    4 V_CLK2    4              4 Left  Audio GND   4 LED1
//  5 P1 Right   5 V_DIR2    5              5 KEY               5 KEY
//  6 P2 Right   6 H_CLK1    6              6 Left  Audio       6 SW5
//  7 P1 Left    7 H_DIR1    7                                  7 SW2   P2 Start/Whip
//  8 P1 Up      8 V_CLK1    8 KEY                              8 SW4
//  9 P1 Down    9 KEY       9 Left Coin                        9 SW1   P1 Start/Whip
// 10 KEY       10 V_DIR1   10 Right Coin                      10 SW3
// 11 GND       11 GND      11 GND                             11 GND

// Slapstic Types: marble=103 (x67), indytemp=105 (x69), peterpak=107 (x6B), roadrunn=108 (x6C), roadb109=109 (x6D), roadb110=110 (x6E)

wire [7:0] inputs;
wire [7:0] adc_bit7, adc_bit6;
wire [7:0] switches;

// direction control inputs
// J102 2,3,4,6,8,9,7,5 = P2-U,D,L,R P1-U,D,L,R active high
assign inputs =
	// for Indy (105) shift them by one (000UDLR0) else default to (0000UDLR)
	(slap_type==105)?({3'b0, (kbd1[7:4] | joystick_0[3:0]), 1'b0}) :
                    ({4'b0, (kbd1[7:4] | joystick_0[3:0])      });

always @(posedge clk_sys) begin
	// default state of ADC inputs at VCC/2
	adc_bit7 = 8'd255;
	adc_bit6 = 8'd0;
	// ########################################
	// marblemad ##############################
	// ########################################
	if (slap_type==103)
	begin
		// NC NC NC Action Action
		switches = ({3'b111, ~(kbd1[0] | joystick_0[4] | mouse_L), ~(kbd1[1] | joystick_0[5] | mouse_R)});
	end
	// ########################################
	// indytemp ###############################
	// ########################################
	if (slap_type==105)
	begin
		// on/off style control
		adc_bit7 = inputs;
		adc_bit6 = inputs;
		// NC NC NC Whip Whip
		switches = ({3'b111, ~(kbd1[0] | joystick_0[4]), ~(kbd1[1] | joystick_0[5])});
	end
	// ########################################
	// peterpak ###############################
	// ########################################
	else if (slap_type==107)
	begin
		// on/off style control
		adc_bit7 = inputs;
		adc_bit6 = inputs;
		// NC NC Jump NC Throw
		switches = ({2'b11,  ~(kbd1[0] | joystick_0[4]), 1'b1, ~(kbd1[1] | joystick_0[5])});
	end
	// ########################################
	// roadrunn ###############################
	// ########################################
	else if ( slap_type==108 )
	begin
		// NC NC NC Action Action
		switches = ({3'b111, ~(kbd1[0] | joystick_0[4]), ~(kbd1[1] | joystick_0[5])});

		// tristate type of control
		// -128 10_000000 max negative movement
		//   -1 11_111111 on  value
		//    0 00_000000 off value / idle / center of range
		//  127 01_111111 max positive movement
		if (inputs[2]) // Down
		begin
			adc_bit7[7] = 1;
			adc_bit6[7] = 1;
		end
		else if (inputs[3]) // Up
		begin
			adc_bit7[7] = 0;
			adc_bit6[7] = 0;
		end
		else // center
		begin
			adc_bit7[7] = 1;
			adc_bit6[7] = 0;
		end

		if (inputs[0]) // Right
		begin
			adc_bit7[0] = 0;
			adc_bit6[0] = 0;
		end
		else if (inputs[1]) // Left
		begin
			adc_bit7[0] = 1;
			adc_bit6[0] = 1;
		end
		else // center
		begin
			adc_bit7[0] = 1;
			adc_bit6[0] = 0;
		end

	end
	// ########################################
	// roadblasters ###########################
	// ########################################
	else if ( (slap_type==109) || (slap_type==110) )
	begin
		// NC NC NC Fire NC
		switches = ({3'b111, ~(kbd1[0] | joystick_0[4]), 1'b1}) ;

		// uses trackball X for L R

		// throttle
		adc_bit7[3] = 0;
		adc_bit6[3] = (kbd1[1] | joystick_0[5]);
	end
end

wire [3:0]	clks, dirs;

trackball tb1
(
	.clk                  (clk_7M),
	.flip                 (), // unused
	.ps2_mouse            (ps2_mouse),
	.mouse_speed          ( status[10:9]), // 00=100%, 01=200%, 10=400%, 11=800%
	.joystick_mode        ( status[11]),   // 0 = digital, 1 = analog
	.joystick_sensitivity (~status[12]),   // 0 = low, 1 = high
	.joystick_analog      (joystick_l_analog_0),
	.joystick             (inputs[3:0]),   // UDLR active high
	.v_dir                (dirs[0]), // v dir 1
	.v_clk                (clks[0]), // v clk 1
	.h_dir                (dirs[1]), // h dir 1
	.h_clk                (clks[1])  // h clk 1
);

trackball tb2
(
	.clk                  (clk_7M),
	.flip                 (), // unused
	.ps2_mouse            (),
	.mouse_speed          ( status[10:9]), // 00=100%, 01=200%, 10=400%, 11=800%
	.joystick_mode        ( status[11]),   // 0 = digital, 1 = analog
	.joystick_sensitivity (~status[12]),   // 0 = low, 1 = high
	.joystick_analog      (joystick_r_analog_0),
	.joystick             (kbd2[7:4]), // UDLR active high
	.v_dir                (dirs[2]), // v dir 2
	.v_clk                (clks[2]), // v clk 2
	.h_dir                (dirs[3]), // h dir 2
	.h_clk                (clks[3])  // h clk 2
);

FPGA_ATARISYS1 atarisys1
(
	.I_SLAP_TYPE (slap_type),
	.I_CLK_7M    (clk_7M),
	.I_CLK_14M   (clk_14M),

	.I_RESET     (sl_reset),

	// SELFTEST, COIN_AUX, COIN_L, COIN_R, SW[5:1] active low
	.I_SELFTESTn (~m_service),
	.I_COIN      ({~m_coin_aux, ~(m_coin_r), ~(m_coin_l | joystick_0[8])}),
	// J106 SW5,4,3,2,1 = NC, NC, Jump (NC), Whip2/Start2, Whip1/Start1
	.I_SW        (switches),

// when button is pressed ADC value goes full scale, else ADC value is VCC/2
// we present 0xFF for button press and 0x7F for button release

	// Each ADC input is biased to VCC/2 with resistors and can be pulled high or low or any value in between for analog controllers

	// Some  games use an ADC channel as up/idle/down or left/idle/right control (0xF0 / 0x80 / 0x00)
	// Other games use an ADC channel as a simple on/off (0xFF / 0x00)
	// So with just the top two bits we can present the following values to each ADC channel
	// -128 10_000000 max negative movement
	//   -1 11_111111 on  value
	//    0 00_000000 off value / idle / center of range
	//  127 01_111111 max positive movement
	.I_ADCB7     (adc_bit7),
	.I_ADCB6     (adc_bit6),

	// P103 LETA trackball inputs active low
	.I_CLK(clks), // HCLK2,VCLK2,HCLK1,VCLK1
	.I_DIR(dirs), // HDIR2,VDIR2,HDIR1,VDIR1

	.O_LEDS      (),

	.O_AUDIO_L   (aud_l),
	.O_AUDIO_R   (aud_r),

	.O_VIDEO_I   (gvid_I),
	.O_VIDEO_R   (gvid_R),
	.O_VIDEO_G   (gvid_G),
	.O_VIDEO_B   (gvid_B),
	.O_HSYNC     (hs),
	.O_VSYNC     (vs),
	.O_CSYNC     (),
	.O_HBLANK    (hblank),
	.O_VBLANK    (vblank),

	.O_ADDR2B    (slv_PA2B),
	.I_DATA2B    (slv_PD2B),

	// CART memory interface
	.O_ROMn      (slv_ROMn),  // maincpu ROM selects
	.O_MA18n     (sl_MA18n),
	.I_MDATA     (slv_MDATA),
	.O_SROMn     (slv_SROMn), // sound ROM selects
	.O_SBA       (slv_SBA),
	.O_MADEC     (slv_MADEC), // SLAPSTIC decoded mem addr

	// PROMs
	.O_PADDR     (slv_PADDR),
	.I_PD4A      (slv_PD4A),
	.I_PD7A      (slv_PD7A),

	// sound ROMs
	.I_SDATA     (slv_SDATA),

	// video ROMs
	.O_VADDR     (slv_VADDR),
	.I_VDATA     (slv_VDATA)
);

// pragma translate_off
bmp_out #( "BI" ) bmp_out
(
	.clk_i(clk_7M),
	.dat_i({r,4'b0,g,4'b0,b,4'b0}),
	.hs_i(hs),
	.vs_i(vs)
);
// pragma translate_on
endmodule
