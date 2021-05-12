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
// these defines needed for simulation
`define USE_FB=0
`define USE_DDRAM=0
`define USE_SDRAM=0
`define DUAL_SDRAM=0

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

`ifdef USE_FB
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

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
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

`ifdef USE_DDRAM
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
`endif

`ifdef USE_SDRAM
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
`endif

`ifdef DUAL_SDRAM
	//Secondary SDRAM
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

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
//assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 'Z;  

//assign VGA_SL = 0;

assign VGA_F1 = 0;
assign VGA_SCALER = 0;

integer     slap_type = 105; // Slapstic type: marble=103, indytemp=105, peterpak=107, roadrunn=108, roadb109=109, roadb110=110

wire        clk_7M;
wire        clk_14M;
wire        clk_sys;
wire        clk_vid;
reg         ce_pix;
wire        pll_locked;
wire        hblank, vblank;
wire        hs, vs;
//reg  [ 7:0] sw[8];
wire [ 3:0] r,g,b, gvid_I, gvid_R, gvid_G, gvid_B;
wire [15:0] aud_l, aud_r;
wire [31:0] status;
wire [ 1:0] sl_buttons;
wire        forced_scandoubler;
wire        direct_video;
wire        ioctl_download;
wire        ioctl_wr;
wire        ioctl_wait;
wire [ 7:0] ioctl_index;
wire [24:0] ioctl_addr;
wire [ 7:0] ioctl_dout;

assign AUDIO_S = 1'b1; // signed samples
assign AUDIO_L = aud_l;
assign AUDIO_R = aud_r;
assign AUDIO_MIX = 0;

assign LED_USER  = ioctl_download;
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

wire [15:0] joy0;
wire [15:0] joy1;
wire [15:0] joy2;
wire [15:0] joy3;

wire [10:0] ps2_key;

wire [21:0] gamma_bus;
wire sl_reset = RESET | status[0] | sl_buttons[1] | ioctl_download;

reg [7:0]   p1 = 8'h0;
reg [7:0]   p2 = 8'h0;

reg  m_coin_aux = 1'b0;
reg  m_coin_l   = 1'b0;
reg  m_coin_r   = 1'b0;
wire m_service = status[7];

assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

wire [1:0] ar = status[9:8];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"A.ATARISYS1;;",
	"-;",
	"O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"DIP;",
	"-;",
	"O7,Service,Off,On;",
	"R0,Reset;",
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

//always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;
always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==1)) slap_type <= ioctl_dout;

wire pressed = ps2_key[9];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];

	if(old_state != ps2_key[10]) begin
		casex(ps2_key[8:0])
			// Default MAME Controls Assignment
			'h175: p1[7]        <= pressed; // up         (up_arrow)
			'h172: p1[6]        <= pressed; // down       (down_arrow)
			'h16B: p1[5]        <= pressed; // left       (left_arrow)
			'h174: p1[4]        <= pressed; // right      (right_arrow)
			'h014: p1[1]        <= pressed; // start/whip (left ctrl)
			'h011: p1[0]        <= pressed; // jump       (left alt)

			'h02D: p2[7]        <= pressed; // up         (R)
			'h02B: p2[6]        <= pressed; // down       (F)
			'h023: p2[5]        <= pressed; // left       (D)
			'h034: p2[4]        <= pressed; // right      (G)
			'h01C: p2[1]        <= pressed; // start/whip (A)
			'h01B: p2[0]        <= pressed; // jump       (S)

			'h02E: m_coin_l     <= pressed; // coin_l     (5)
			'h036: m_coin_r     <= pressed; // coin_r     (6)
			'h03D: m_coin_aux   <= pressed; // coin_aux   (7)
//			'h03E: m_           <= pressed; //            (8)
		endcase
	end
end

///////////////////////////////////////////////////
always @(posedge clk_vid) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_pix <= !div;
end

//screen_rotate screen_rotate (.*);
//arcade_video #(.WIDTH(320), .DW(12)) arcade_video
//(
//	.*,
//
//	.clk_video(clk_vid),
//	.ce_pix(ce_pix),
//
//	.RGB_in({r,g,b}),
//	.HBlank(~hblank),
//	.VBlank(~vblank),
//	.HSync(~hs),
//	.VSync(~vs),
//
//	.fx(status[5:3])
//);
//
hps_io_emu #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),

	.conf_str(CONF_STR),
	.forced_scandoubler(forced_scandoubler),

	.buttons(sl_buttons),
	.status(status),
	.status_menumask({1'b0,direct_video}),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),

	.joystick_0(joy0),
	.joystick_1(joy1),
	.joystick_2(joy2),
	.joystick_3(joy3),
	.ps2_key(ps2_key)
);

// convert input video from 16bit IRGB to 12 bit RGB
RGBI RCONV (.ADDR({gvid_I,gvid_R}), .DATA(r));
RGBI GCONV (.ADDR({gvid_I,gvid_G}), .DATA(g));
RGBI BCONV (.ADDR({gvid_I,gvid_B}), .DATA(b));

// ###################################################
// # This section loads the ROM files through HPS_IO #
// ###################################################

/*************************************************************/
wire [16:0] slv_VADDR;
wire [31:0] slv_VDATA;
wire [22:0] sdram_addr;
reg  [22:0] addr_new;
reg  [31:0] sdram_data=0;
reg         sdram_we=0;
wire        sdram_ready;

// the order in which the files are listed in the .mra file determines the order in which they appear here on the HPS bus
// some files are interleaved as DWORD, some are interleaved as WORD and some are not interleaved and appear as BYTEs
// acc_bytes collects previous bytes so that when a WORD or DWORD is complete it is written to the RAM as appropriate
reg [23:0] acc_bytes = 0;
always @(posedge clk_sys)
	if (ioctl_wr && (!ioctl_index) && ioctl_download )
		acc_bytes<={acc_bytes[15:0],ioctl_dout}; // accumulate previous bytes

always @(posedge clk_sys)
begin
	sdram_we <= 1'b0;
	if (ioctl_wr && (!ioctl_index) && ioctl_download && ioctl_addr[1] && ioctl_addr[0])
	begin
		sdram_data <= {acc_bytes,ioctl_dout};
		addr_new <= ioctl_addr[24:2];
		sdram_we <= 1'b1;
	end
end

assign sdram_addr = ioctl_download?addr_new:{6'd0,slv_VADDR};
assign ioctl_wait = ~(pll_locked && sdram_ready);

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

// hardcoded ROMs for testing, use SDRAM/DPRAM for release
//wire gp_wr;
wire sl_wr_13D, sl_wr_14D, sl_wr_16D;
wire sl_wr_10B_10A, sl_wr_12B_12A, sl_wr_14B_14A, sl_wr_16B_16A, sl_wr_11J_10J;
wire sl_wr_23B, sl_wr_4A , sl_wr_7A;

//wire [31:0] slv_ROM_1C_6C_1B_6B, slv_ROM_2C_7C_2B_7B, slv_ROM_3C_8C_3B_8B, slv_ROM_4C_9C_4B_9B;
wire [19:1] slv_MGRA;
wire [15:1] slv_MA;
wire [15:1] slv_MADDR;
wire [15:0] slv_MDATA;
wire [15:0] slv_ROM_10B_10A, slv_ROM_12B_12A, slv_ROM_14B_14A, slv_ROM_16B_16A, slv_ROM_11J_10J;
wire [13:0] slv_SBA;
wire [13:0] s_snd;
wire [12:0] slv_PA5F;
wire [ 8:0] slv_PADDR;
wire [ 7:0] slv_ROM_13D, slv_ROM_14D, slv_ROM_16D, slv_ROM_4A, slv_ROM_7A;
wire [ 7:0] slv_SDATA, slv_PD4A, slv_PD7A, slv_PD5F;
wire [ 7:0] slv_SMDO, slv_SMDI, slv_PFSR;
wire [ 6:0] slv_MOSR;
wire [ 3:0] slv_ROMn;
wire [ 2:0] slv_SROMn;

wire sl_SLAPn, sl_BLDSn, sl_BASn, sl_BW_Rn, sl_INT1n, sl_INT3n, sl_WAITn, sl_MA18n;
wire sl_MATCHn, sl_MGHF, sl_GLDn, sl_MO_PFn, sl_SNDEXTn, sl_SNDRSTn, sl_SNDBW_Rn, sl_B02;

// Video ROMs
//  00000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.143, start=0, len=0, map(4)=0001
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.147, start=0, len=0, map(4)=0010
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.135, start=0, len=0, map(4)=0100
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.139, start=0, len=0, map(4)=1000
//  20000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.144, start=0, len=0, map(4)=0001
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.148, start=0, len=0, map(4)=0010
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.136, start=0, len=0, map(4)=0100
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.140, start=0, len=0, map(4)=1000
//  40000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.145, start=0, len=0, map(4)=0001
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.149, start=0, len=0, map(4)=0010
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.137, start=0, len=0, map(4)=0100
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.141, start=0, len=0, map(4)=1000
//  60000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.146, start=0, len=0, map(4)=0001
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.150, start=0, len=0, map(4)=0010
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.138, start=0, len=0, map(4)=0100
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.142, start=0, len=0, map(4)=1000
//assign gp_wr         = (ioctl_wr && !ioctl_index && ioctl_addr[24:17] < 8'h03 && ioctl_addr[1:0]==2'b11) ? 1'b1 : 1'b0;
//  80000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.431, start=0, len=0, map(2)=01
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.432, start=0, len=0, map(2)=10
assign sl_wr_10B_10A = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h08  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
//  90000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.433, start=0, len=0, map(2)=01
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.434, start=0, len=0, map(2)=10
assign sl_wr_12B_12A = (ioctl_wr && !ioctl_index && ioctl_addr[24:16]== 9'h09  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
//  A0000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.457, start=0, len=0, map(2)=01
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.456, start=0, len=0, map(2)=10
assign sl_wr_14B_14A = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h14  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
//  A8000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.358, start=0, len=0, map(2)=01
//         file: /media/fat/_Arcade/mame/indytemp.zip/136036.359, start=0, len=0, map(2)=10
assign sl_wr_16B_16A = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h15  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
//  B0000: file: /media/fat/_Arcade/mame/atarisy1.zip/136032.115.j10, start=0, len=0, map(2)=01
//         file: /media/fat/_Arcade/mame/atarisy1.zip/136032.114.j11, start=0, len=0, map(2)=10
assign sl_wr_11J_10J = (ioctl_wr && !ioctl_index && ioctl_addr[24:15]==10'h16  && ioctl_addr[0]==1'b1) ? 1'b1 : 1'b0;
//  B8000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.153, start=0, len=0
assign sl_wr_13D     = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h2E ) ? 1'b1 : 1'b0;
//  BC000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.154, start=0, len=0
assign sl_wr_14D     = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h2F ) ? 1'b1 : 1'b0;
//  C0000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.155, start=0, len=0
assign sl_wr_16D     = (ioctl_wr && !ioctl_index && ioctl_addr[24:14]==11'h30 ) ? 1'b1 : 1'b0;
//  C4000: file: /media/fat/_Arcade/mame/atarisy1.zip/136032.104.f5, start=0, len=0
assign sl_wr_23B     = (ioctl_wr && !ioctl_index && ioctl_addr[24:13]==12'h62 ) ? 1'b1 : 1'b0;
//  C6000: file: /media/fat/_Arcade/mame/indytemp.zip/136036.151, start=0, len=0
assign sl_wr_4A      = (ioctl_wr && !ioctl_index && ioctl_addr[24:9] ==16'h630) ? 1'b1 : 1'b0;
//  C6200: file: /media/fat/_Arcade/mame/indytemp.zip/136036.152, start=0, len=0
assign sl_wr_7A      = (ioctl_wr && !ioctl_index && ioctl_addr[24:9] ==16'h631) ? 1'b1 : 1'b0;
// 0xC6400 bytes sent to FPGA

//	assign slv_VDATA =
//	(slv_VADDR[16:15] == 2'b00)?slv_ROM_1C_6C_1B_6B:
//	(slv_VADDR[16:15] == 2'b01)?slv_ROM_2C_7C_2B_7B:
//	(slv_VADDR[16:15] == 2'b10)?slv_ROM_3C_8C_3B_8B:
//	(slv_VADDR[16:15] == 2'b11)?slv_ROM_4C_9C_4B_9B:
//	32'h0;

//	ROM_143 ROM_1C( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[31:24]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_147 ROM_6C( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[23:16]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_135 ROM_1B( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[15:8 ]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_139 ROM_6B( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[ 7:0 ]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_144 ROM_2C( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[31:24]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_148 ROM_7C( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[23:16]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_136 ROM_2B( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[15:8 ]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_140 ROM_7B( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[ 7:0 ]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_145 ROM_3C( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[31:24]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_149 ROM_8C( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[23:16]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_137 ROM_3B( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[15:8 ]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_141 ROM_8B( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[ 7:0 ]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_146 ROM_4C( .CLK(clk_14M), .DATA(slv_ROM_4C_9C_4B_9B[31:24]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_150 ROM_9C( .CLK(clk_14M), .DATA(slv_ROM_4C_9C_4B_9B[23:16]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_138 ROM_4B( .CLK(clk_14M), .DATA(slv_ROM_4C_9C_4B_9B[15:8 ]), .ADDR(slv_VADDR(14 downto 0)) );
//	ROM_142 ROM_9B( .CLK(clk_14M), .DATA(slv_ROM_4C_9C_4B_9B[ 7:0 ]), .ADDR(slv_VADDR(14 downto 0)) );

	// 256 M10K blocks
//	dpram #(16,32) gp_ram
//	(.clock_a(clk_sys    ), .enable_a(), .wren_a(gp_wr        ), .address_a(ioctl_addr[17:2]), .data_a({acc_bytes[23:0],ioctl_dout}), .q_a(               ),
//	 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_VADDR[15:0]), .data_b(                            ), .q_b(slv_VDATA      ));

assign slv_MDATA =
	(~slv_ROMn[0])?slv_ROM_11J_10J:
	(~slv_ROMn[1])?slv_ROM_10B_10A:
	(~slv_ROMn[2])?slv_ROM_12B_12A:
	(~slv_ROMn[3])?slv_ROM_14B_14A:
	(~sl_SLAPn   )?slv_ROM_16B_16A:
	16'h0;

//// MAIN CPU ROMs
//ROM_432 ROM_10B( .CLK(clk_14M), .DATA(slv_ROM_10B_10A[15:8]), .ADDR(slv_MADDR[15:1]) ); // /ROM1
//ROM_431 ROM_10A( .CLK(clk_14M), .DATA(slv_ROM_10B_10A[ 7:0]), .ADDR(slv_MADDR[15:1]) ); // /ROM1
//ROM_434 ROM_12B( .CLK(clk_14M), .DATA(slv_ROM_12B_12A[15:8]), .ADDR(slv_MADDR[15:1]) ); // /ROM2
//ROM_433 ROM_12A( .CLK(clk_14M), .DATA(slv_ROM_12B_12A[ 7:0]), .ADDR(slv_MADDR[15:1]) ); // /ROM2
//ROM_456 ROM_14B( .CLK(clk_14M), .DATA(slv_ROM_14B_14A[15:8]), .ADDR(slv_MADDR[14:1]) ); // /ROM3
//ROM_457 ROM_14A( .CLK(clk_14M), .DATA(slv_ROM_14B_14A[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /ROM3
//
//// SLAPSTIC controlled ROMs
//ROM_358 ROM_16B( .CLK(clk_14M), .DATA(slv_ROM_16B_16A[15:8]), .ADDR(slv_MADDR[14:1]) ); // /SLAP
//ROM_359 ROM_16A( .CLK(clk_14M), .DATA(slv_ROM_16B_16A[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /SLAP
//
//// System ROM
//ROM_11J ROM_11J( .CLK(clk_14M), .DATA(slv_ROM_11J_10J[15:8]), .ADDR(slv_MADDR[14:1]) ); // /ROM0
//ROM_10J ROM_10J( .CLK(clk_14M), .DATA(slv_ROM_11J_10J[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /ROM0

// 32 M10K blocks
dpram #(15,16) mp_ram_10B_10A
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_10B_10A), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_MADDR[15:1]), .data_b(                            ), .q_b(slv_ROM_10B_10A));

// 32 M10K blocks
dpram #(15,16) mp_ram_12B_12A
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_12B_12A), .address_a(ioctl_addr[15:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_MADDR[15:1]), .data_b(                            ), .q_b(slv_ROM_12B_12A));

// 16 M10K blocks
dpram #(14,16) mp_ram_14B_14A
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_14B_14A), .address_a(ioctl_addr[14:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_MADDR[14:1]), .data_b(                            ), .q_b(slv_ROM_14B_14A));

// 16 M10K blocks
dpram #(14,16) mp_ram_16B_16A
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_16B_16A), .address_a(ioctl_addr[14:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_MADDR[14:1]), .data_b(                            ), .q_b(slv_ROM_16B_16A));

// 16 M10K blocks
dpram #(14,16) mp_ram_11J_10J
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_11J_10J), .address_a(ioctl_addr[14:1]), .data_a({acc_bytes[ 7:0],ioctl_dout}), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_MADDR[14:1]), .data_b(                            ), .q_b(slv_ROM_11J_10J));

assign slv_SDATA =
	(~slv_SROMn[0])?slv_ROM_13D:
	(~slv_SROMn[1])?slv_ROM_14D:
	(~slv_SROMn[2])?slv_ROM_16D:
	8'h0;

//// AUDIO CPU ROMs
//ROM_153 ROM_13D ( .CLK(clk_14M), .DATA(slv_ROM_13D), .ADDR(slv_SBA) );
//ROM_154 ROM_14D ( .CLK(clk_14M), .DATA(slv_ROM_14D), .ADDR(slv_SBA) );
//ROM_155 ROM_16D ( .CLK(clk_14M), .DATA(slv_ROM_16D), .ADDR(slv_SBA) );

// 16 M10K blocks
dpram #(14, 8) ap_ram_13D
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_13D    ), .address_a(ioctl_addr[13:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   slv_SBA[13:0]), .data_b(                            ), .q_b(slv_ROM_13D    ));

// 16 M10K blocks
dpram #(14, 8) ap_ram_14D
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_14D    ), .address_a(ioctl_addr[13:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   slv_SBA[13:0]), .data_b(                            ), .q_b(slv_ROM_14D    ));

// 16 M10K blocks
dpram #(14, 8) ap_ram_16D
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_16D    ), .address_a(ioctl_addr[13:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(   slv_SBA[13:0]), .data_b(                            ), .q_b(slv_ROM_16D    ));

//// PROMs
//ROM_5F ROM_23B ( .CLK(clk_14M), .DATA(slv_PD5F), .ADDR(slv_PA5F ) );
//ROM_151 ROM_4A ( .CLK(clk_14M), .DATA(slv_PD4A), .ADDR(slv_PADDR) );
//ROM_152 ROM_7A ( .CLK(clk_14M), .DATA(slv_PD7A), .ADDR(slv_PADDR) );

	// 8 M10K blocks
dpram  #(13,8) cp_ram_23B
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_23B    ), .address_a(ioctl_addr[12:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(  slv_PA5F[12:0]), .data_b(                            ), .q_b(slv_PD5F       ));

	// 1 M10K blocks
dpram  #(9,8) cp_ram_4A
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_4A     ), .address_a(ioctl_addr[ 8:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_PADDR[ 8:0]), .data_b(                            ), .q_b(slv_PD4A       ));

	// 1 M10K blocks
dpram  #(9,8) cp_ram_7A
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_7A     ), .address_a(ioctl_addr[ 8:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_PADDR[ 8:0]), .data_b(                            ), .q_b(slv_PD7A       ));

/*************************************************************/
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

FPGA_ATARISYS1 atarisys1
(
	.I_SLAP_TYPE(slap_type),
	.I_CLK_7M(clk_7M),
	.I_CLK_14M(clk_14M),

	.I_RESET(sl_reset),

	.I_JOY({(p2[7:4] | joy1[3:0]), (p1[7:4] | joy0[3:0])}), // P2-U,D,L,R P1-U,D,L,R active high
	.I_CLK(4'b1111), // LETA trackball inputs active low
	.I_DIR(4'b1111), // LETA trackball inputs active low

	// SELFTEST, COIN_AUX, COIN_L, COIN_R, SW[5:1] active low
	.I_SYS({~m_service, ~m_coin_aux, ~(m_coin_r | joy1[8]), ~(m_coin_l | joy0[8]), 2'b11, ~(p2[0] | p1[0] | joy1[4] | joy0[4]), ~(p2[1] | joy1[5]), ~(p1[1] | joy0[5])}),

	.O_LEDS(),

	.O_AUDIO_L(aud_l),
	.O_AUDIO_R(aud_r),

	.O_VIDEO_I(gvid_I),
	.O_VIDEO_R(gvid_R),
	.O_VIDEO_G(gvid_G),
	.O_VIDEO_B(gvid_B),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_CSYNC(),
	.O_HBLANK(hblank),
	.O_VBLANK(vblank),

	.O_ADDR5F(slv_PA5F),
	.I_DATA5F(slv_PD5F),

	// CART interface
	.O_SLAPn     (sl_SLAPn),
	.O_MEXTn     (),
	.O_BLDSn     (sl_BLDSn),
	.O_BASn      (sl_BASn),
	.O_BW_Rn     (sl_BW_Rn),
	.I_INT1n     (sl_INT1n),
	.I_INT3n     (sl_INT3n),
	.I_WAITn     (sl_WAITn),

	.O_ROMn      (slv_ROMn), // main ROM selects
	.O_MA18n     (sl_MA18n),
	.O_MADDR     (slv_MA), // addr from CPU
	.I_MDATA     (slv_MDATA),

	.O_SROMn     (slv_SROMn), // sound ROM selects
	.O_SMD       (slv_SMDO),
	.I_SMD       (slv_SMDI),
	.O_SBA       (slv_SBA),

	.O_MGRA      (slv_MGRA),
	.O_MATCHn    (sl_MATCHn),
	.O_MGHF      (sl_MGHF),
	.O_GLDn      (sl_GLDn),
	.O_MO_PFn    (sl_MO_PFn),
	.O_SNDEXTn   (sl_SNDEXTn),
	.O_SNDRSTn   (sl_SNDRSTn),
	.O_SNDBW_Rn  (sl_SNDBW_Rn),
	.O_B02       (sl_B02),

	// from video shifters
	.I_MOSR      (slv_MOSR),
	.I_PFSR      (slv_PFSR),

	// sound L and R are the same
	.I_SND       (s_snd)
);

ATARI_CART u_cart
(
	.I_SLAP_TYPE (slap_type),
	.I_MCKR      (clk_7M),
	.I_XCKR      (clk_14M),

	.I_BLDSn     (sl_BLDSn),
	.I_BASn      (sl_BASn),
	.I_BW_Rn     (sl_BW_Rn),
	.O_INT1n     (sl_INT1n),
	.O_INT3n     (sl_INT3n),
	.O_WAITn     (sl_WAITn),

	.I_SLAPn     (sl_SLAPn),
	.I_MA18n     (sl_MA18n),
	.I_MADDR     (slv_MA), // addr from CPU

	.I_SMD       (slv_SMDO),
	.O_SMD       (slv_SMDI),
	.I_SBA       (slv_SBA),

	.I_MGRA      (slv_MGRA),
	.I_MATCHn    (sl_MATCHn),
	.I_MGHF      (sl_MGHF),
	.I_GLDn      (sl_GLDn),
	.I_MO_PFn    (sl_MO_PFn),
	.I_SNDEXTn   (sl_SNDEXTn),
	.I_SNDRSTn   (sl_SNDRSTn),
	.I_SNDBW_Rn  (sl_SNDBW_Rn),
	.I_B02       (sl_B02),

	// video shifters
	.O_MOSR      (slv_MOSR),
	.O_PFSR      (slv_PFSR),

	// sound L and R are the same
	.O_SND       (s_snd),

	.O_MADDR(slv_MADDR), // addr after slapstic

	// PROMs
	.O_PADDR(slv_PADDR),
	.I_PD4A(slv_PD4A),
	.I_PD7A(slv_PD7A),

	// sound ROMs
	.I_SDATA(slv_SDATA),

	// video ROMs
	.O_VADDR(slv_VADDR),
	.I_VDATA(slv_VDATA)
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
