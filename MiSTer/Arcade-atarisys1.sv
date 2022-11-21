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
`define MODELSIM
`undef MODELSIM_INDYTEMP
`define MODELSIM_PETERPAK

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

///////// Default values for ports not used in this core /////////

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

integer     slap_type = 105; // Slapstic type: marble=103, indytemp=105, peterpak=107, roadrunn=108, roadb109=109, roadb110=110

wire        clk_7M;
wire        clk_14M;
wire        clk_sys;
wire        clk_vid;
reg         ce_pix;
wire        pll_locked;
wire        hblank, vblank;
wire        hs, vs;
wire [ 3:0] r,g,b, gvid_I, gvid_R, gvid_G, gvid_B;
wire [15:0] aud_l, aud_r;
wire [127:0] status;
wire [ 1:0] buttons;
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

wire [31:0] joy0;
wire [31:0] joy1;
wire [31:0] joy2;
wire [31:0] joy3;

wire [10:0] ps2_key;

wire [21:0] gamma_bus;
wire sl_reset = RESET | status[0] | buttons[1] | ioctl_download;

reg [7:0]   p1 = 8'h0;
reg [7:0]   p2 = 8'h0;

reg  m_coin_aux = 1'b0;
reg  m_coin_l   = 1'b0;
reg  m_coin_r   = 1'b0;
wire m_service = status[7];

//assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

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

/* Slapstic Types:
    marble  =103 (x67)
    indytemp=105 (x69)
    peterpak=107 (x6B)
    roadrunn=108 (x6C)
    roadb109=109 (x6D)
    roadb110=110 (x6E)
*/
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

`ifndef MODELSIM
screen_rotate screen_rotate (.*);
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

	.joystick_0(joy0),
	.joystick_1(joy1),
	.joystick_2(joy2),
	.joystick_3(joy3),
	.ps2_key(ps2_key)
);
`else
	assign ioctl_download = 0;
`endif

// convert input video from 16bit IRGB to 12 bit RGB
RGBI RCONV (.ADDR({gvid_I,gvid_R}), .DATA(r));
RGBI GCONV (.ADDR({gvid_I,gvid_G}), .DATA(g));
RGBI BCONV (.ADDR({gvid_I,gvid_B}), .DATA(b));

// ###################################################
// # This section loads the ROM files through HPS_IO #
// ###################################################

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

//wire gp_wr;
wire sl_wr_13D, sl_wr_14D, sl_wr_16D;
wire sl_wr_10B_10A, sl_wr_12B_12A, sl_wr_14B_14A, sl_wr_16B_16A, sl_wr_11J_10J;
wire sl_wr_23B, sl_wr_5A , sl_wr_7A;

wire [19:1] slv_MGRA;
wire [15:1] slv_MA;
wire [15:1] slv_MADDR;
wire [15:0] slv_MDATA;
wire [15:0] slv_ROM_12B_12A, slv_ROM_14B_14A, slv_ROM_16B_16A, slv_ROM_11J_10J, slv_ROM_10B_10A, slv_ROM_11B_11A;
wire [13:0] slv_SBA;
wire [13:0] s_snd;
wire [12:0] slv_PA5F;
wire [ 8:0] slv_PADDR;
wire [ 7:0] slv_ROM_13D, slv_ROM_14D, slv_ROM_16D, slv_ROM_5A, slv_ROM_7A;
wire [ 7:0] slv_SDATA, slv_PD4A, slv_PD7A, slv_PD5F;
wire [ 7:0] slv_SMDO, slv_SMDI, slv_PFSR;
wire [ 6:0] slv_MOSR;
wire [ 3:0] slv_ROMn;
wire [ 2:0] slv_SROMn;

wire sl_SLAPn, sl_BLDSn, sl_BASn, sl_BW_Rn, sl_INT1n, sl_INT3n, sl_WAITn, sl_MA18n;
wire sl_MATCHn, sl_MGHF, sl_GLDn, sl_MO_PFn, sl_SNDEXTn, sl_SNDRSTn, sl_SNDBW_Rn, sl_B02;

`ifdef MODELSIM
// hardcoded ROMs for testing, use SDRAM/DPRAM for release
wire [31:0] slv_ROM_1C_6C_1B_6B, slv_ROM_2C_7C_2B_7B, slv_ROM_3C_8C_3B_8B, slv_ROM_4C_9C_4B_9B;

assign slv_VDATA =
	(slv_VADDR[16:15] == 2'b00)?slv_ROM_1C_6C_1B_6B:
	(slv_VADDR[16:15] == 2'b01)?slv_ROM_2C_7C_2B_7B:
	(slv_VADDR[16:15] == 2'b10)?slv_ROM_3C_8C_3B_8B:
	(slv_VADDR[16:15] == 2'b11)?slv_ROM_4C_9C_4B_9B:
	32'h0;
`endif

assign slv_MDATA =
	(~slv_ROMn[0])?slv_ROM_11J_10J:
	(~slv_ROMn[1])?slv_ROM_10B_10A:
//	(~slv_ROMn[1] && ~slv_MADDR[15])?slv_ROM_10B_10A:
//	(~slv_ROMn[1] &&  slv_MADDR[15])?slv_ROM_11B_11A:
	(~slv_ROMn[2])?slv_ROM_12B_12A:
	(~slv_ROMn[3])?slv_ROM_14B_14A:
	(~sl_SLAPn   )?slv_ROM_16B_16A:
	16'h0;

assign slv_SDATA =
	(~slv_SROMn[0])?slv_ROM_13D:
	(~slv_SROMn[1])?slv_ROM_14D:
	(~slv_SROMn[2])?slv_ROM_16D:
	8'h0;

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
assign sl_wr_5A      = (ioctl_wr && !ioctl_index && ioctl_addr[24:9] ==16'h630) ? 1'b1 : 1'b0;
//  C6200: file: /media/fat/_Arcade/mame/indytemp.zip/136036.152, start=0, len=0
assign sl_wr_7A      = (ioctl_wr && !ioctl_index && ioctl_addr[24:9] ==16'h631) ? 1'b1 : 1'b0;
// 0xC6400 bytes sent to FPGA

`ifndef MODELSIM
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

// 256 M10K blocks (not used, replaced with sdram above due to size constraints)
//dpram #(16,32) gp_ram
//(.clock_a(clk_sys    ), .enable_a(), .wren_a(gp_wr        ), .address_a(ioctl_addr[17:2]), .data_a({acc_bytes[23:0],ioctl_dout}), .q_a(               ),
// .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_VADDR[15:0]), .data_b(                            ), .q_b(slv_VDATA      ));

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

// 8 M10K blocks
dpram  #(13,8) cp_ram_23B
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_23B    ), .address_a(ioctl_addr[12:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b(  slv_PA5F[12:0]), .data_b(                            ), .q_b(slv_PD5F       ));

// 1 M10K blocks
dpram  #(9,8) cp_ram_5A
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_5A     ), .address_a(ioctl_addr[ 8:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_PADDR[ 8:0]), .data_b(                            ), .q_b(slv_PD4A       ));

// 1 M10K blocks
dpram  #(9,8) cp_ram_7A
(.clock_a(clk_sys    ), .enable_a(), .wren_a(sl_wr_7A     ), .address_a(ioctl_addr[ 8:0]), .data_a(                 ioctl_dout ), .q_a(               ),
 .clock_b(clk_sys    ), .enable_b(), .wren_b(             ), .address_b( slv_PADDR[ 8:0]), .data_b(                            ), .q_b(slv_PD7A       ));
`endif

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
	// Video ROMs
	ROM_143 ROM_1C( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_147 ROM_6C( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_135 ROM_1B( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_139 ROM_6B( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_144 ROM_2C( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_148 ROM_7C( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_136 ROM_2B( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_140 ROM_7B( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_145 ROM_3C( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_149 ROM_8C( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_137 ROM_3B( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_141 ROM_8B( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_146 ROM_4C( .CLK(clk_14M), .DATA(slv_ROM_4C_9C_4B_9B[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_150 ROM_9C( .CLK(clk_14M), .DATA(slv_ROM_4C_9C_4B_9B[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_138 ROM_4B( .CLK(clk_14M), .DATA(slv_ROM_4C_9C_4B_9B[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_142 ROM_9B( .CLK(clk_14M), .DATA(slv_ROM_4C_9C_4B_9B[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	// MAIN CPU ROMs
	ROM_432 ROM_10B( .CLK(clk_14M), .DATA(slv_ROM_10B_10A[15:8]), .ADDR(slv_MADDR[15:1]) ); // /ROM1
	ROM_431 ROM_10A( .CLK(clk_14M), .DATA(slv_ROM_10B_10A[ 7:0]), .ADDR(slv_MADDR[15:1]) ); // /ROM1
	ROM_434 ROM_12B( .CLK(clk_14M), .DATA(slv_ROM_12B_12A[15:8]), .ADDR(slv_MADDR[15:1]) ); // /ROM2
	ROM_433 ROM_12A( .CLK(clk_14M), .DATA(slv_ROM_12B_12A[ 7:0]), .ADDR(slv_MADDR[15:1]) ); // /ROM2
	ROM_456 ROM_14B( .CLK(clk_14M), .DATA(slv_ROM_14B_14A[15:8]), .ADDR(slv_MADDR[14:1]) ); // /ROM3
	ROM_457 ROM_14A( .CLK(clk_14M), .DATA(slv_ROM_14B_14A[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /ROM3

	// SLAPSTIC controlled ROMs
	ROM_358 ROM_16B( .CLK(clk_14M), .DATA(slv_ROM_16B_16A[15:8]), .ADDR(slv_MADDR[14:1]) ); // /SLAP
	ROM_359 ROM_16A( .CLK(clk_14M), .DATA(slv_ROM_16B_16A[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /SLAP

	// System ROM
	ROM_11J ROM_11J( .CLK(clk_14M), .DATA(slv_ROM_11J_10J[15:8]), .ADDR(slv_MADDR[14:1]) ); // /ROM0
	ROM_10J ROM_10J( .CLK(clk_14M), .DATA(slv_ROM_11J_10J[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /ROM0

	// AUDIO CPU ROMs
	ROM_153 ROM_13D ( .CLK(clk_14M), .DATA(slv_ROM_13D), .ADDR(slv_SBA) );
	ROM_154 ROM_14D ( .CLK(clk_14M), .DATA(slv_ROM_14D), .ADDR(slv_SBA) );
	ROM_155 ROM_16D ( .CLK(clk_14M), .DATA(slv_ROM_16D), .ADDR(slv_SBA) );

	// PROMs
	ROM_5F ROM_23B ( .CLK(clk_14M), .DATA(slv_PD5F), .ADDR(slv_PA5F ) );
	ROM_151 ROM_5A ( .CLK(clk_14M), .DATA(slv_PD4A), .ADDR(slv_PADDR) );
	ROM_152 ROM_7A ( .CLK(clk_14M), .DATA(slv_PD7A), .ADDR(slv_PADDR) );
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
	// Video ROMs
	ROM_140 ROM_1C( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_141 ROM_6C( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_138 ROM_1B( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_139 ROM_6B( .CLK(clk_14M), .DATA(slv_ROM_1C_6C_1B_6B[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_152 ROM_2C( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[31:24]), .ADDR(slv_VADDR[14:0]) );
	ROM_153 ROM_7C( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[23:16]), .ADDR(slv_VADDR[14:0]) );
	ROM_150 ROM_2B( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[15:8 ]), .ADDR(slv_VADDR[14:0]) );
	ROM_151 ROM_7B( .CLK(clk_14M), .DATA(slv_ROM_2C_7C_2B_7B[ 7:0 ]), .ADDR(slv_VADDR[14:0]) );

	ROM_111 ROM_3C( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[31:24]), .ADDR(slv_VADDR[13:0]) );
	ROM_114 ROM_8C( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[23:16]), .ADDR(slv_VADDR[13:0]) );
	ROM_105 ROM_3B( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[15:8 ]), .ADDR(slv_VADDR[13:0]) );
	ROM_108 ROM_8B( .CLK(clk_14M), .DATA(slv_ROM_3C_8C_3B_8B[ 7:0 ]), .ADDR(slv_VADDR[13:0]) );

	// unpopulated video ROMs
	assign slv_ROM_4C_9C_4B_9B = 32'h0000;

	// MAIN CPU ROMs
	ROM_142 ROM_10B( .CLK(clk_14M), .DATA(slv_ROM_10B_10A[15:8]), .ADDR(slv_MADDR[14:1]) ); // /ROM1 lo
	ROM_143 ROM_10A( .CLK(clk_14M), .DATA(slv_ROM_10B_10A[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /ROM1 lo
	ROM_144 ROM_11B( .CLK(clk_14M), .DATA(slv_ROM_11B_11A[15:8]), .ADDR(slv_MADDR[14:1]) ); // /ROM1 hi
	ROM_145 ROM_11A( .CLK(clk_14M), .DATA(slv_ROM_11B_11A[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /ROM1 hi
	ROM_146 ROM_12B( .CLK(clk_14M), .DATA(slv_ROM_12B_12A[15:8]), .ADDR(slv_MADDR[14:1]) ); // /ROM2 lo
	ROM_147 ROM_12A( .CLK(clk_14M), .DATA(slv_ROM_12B_12A[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /ROM2 lo

	// SLAPSTIC controlled ROMs
	ROM_148 ROM_16B( .CLK(clk_14M), .DATA(slv_ROM_16B_16A[15:8]), .ADDR(slv_MADDR[14:1]) ); // /SLAP
	ROM_149 ROM_16A( .CLK(clk_14M), .DATA(slv_ROM_16B_16A[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /SLAP

	// System ROM
	ROM_11J ROM_11J( .CLK(clk_14M), .DATA(slv_ROM_11J_10J[15:8]), .ADDR(slv_MADDR[14:1]) ); // /ROM0
	ROM_10J ROM_10J( .CLK(clk_14M), .DATA(slv_ROM_11J_10J[ 7:0]), .ADDR(slv_MADDR[14:1]) ); // /ROM0

	// AUDIO CPU ROMs
	ROM_101 ROM_14D ( .CLK(clk_14M), .DATA(slv_ROM_14D), .ADDR(slv_SBA) );
	ROM_102 ROM_16D ( .CLK(clk_14M), .DATA(slv_ROM_16D), .ADDR(slv_SBA) );

	// PROMs
	ROM_5F ROM_23B ( .CLK(clk_14M), .DATA(slv_PD5F), .ADDR(slv_PA5F ) );
	ROM_137 ROM_5A ( .CLK(clk_14M), .DATA(slv_PD4A), .ADDR(slv_PADDR) );
	ROM_136 ROM_7A ( .CLK(clk_14M), .DATA(slv_PD7A), .ADDR(slv_PADDR) );
`endif

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

// ##################################################################################
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

// Slapstic type: marble=103, indytemp=105, peterpak=107, roadrunn=108, roadb109=109, roadb110=110
// for some reason the ADC index is shifted by 1 for indy
// confirmed in MAME IRQ handler, ADC indexes are 4=UP 3=DN 2=LT 1=RT for Indy and 3=UP 2=DN 1=LT 0=RT for Peter Packrat
wire [7:0] inputs;
// for Indy (105) shift inputs by one (000UDLR0) else (0000UDLR)
assign inputs = (slap_type==105)?({3'b0, (p2[7:4] | p1[7:4] | joy1[3:0] | joy0[3:0]),1'b0})  :  ({4'b0, (p2[7:4] | p1[7:4] | joy1[3:0] | joy0[3:0])});

FPGA_ATARISYS1 atarisys1
(
	.I_SLAP_TYPE(slap_type),
	.I_CLK_7M(clk_7M),
	.I_CLK_14M(clk_14M),

	.I_RESET(sl_reset),

	// SELFTEST, COIN_AUX, COIN_L, COIN_R, SW[5:1] active low
	.I_SELFTESTn(~m_service),
	.I_COIN({~m_coin_aux, ~(m_coin_r), ~(m_coin_l | joy0[8])}),
	.I_PB({2'b11, ~(p2[0] | p1[0] | joy1[5] | joy0[5]), ~(p2[1] | joy1[5] | joy0[5]), ~(p1[1] | joy1[4] | joy0[4])}), // Whip2/Start2 Whip1/Start1

	.I_JOY(inputs),  // P2-U,D,L,R P1-U,D,L,R active high
	.I_CLK(4'b1111), // LETA trackball inputs active low
	.I_DIR(4'b1111), // LETA trackball inputs active low

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
