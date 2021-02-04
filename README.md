# Atari System-1 FPGA Arcade  

## Work In Progress  
Main 68K CPU executes code and successfully runs to initial game screen  
Video produces correct Video in simulation, but when run on FPGA, shows incorrect colors.  
Audio section 6502 executes code correctly, the YM2151 shows some signs of life but speech and pokey are not good.  
No player controls connected yet.  

## About  
FPGA implementation of Atari's System 1 (LSI version) arcade platform from 1984.  
Based primarily on the SP-280, SP-286 schematics with additional support from SP-277, SP-298  

Supported game cartridges  
* Marble Madness (1984)  
* Peter Pack Rat (1985)  
* Road Runner (1985)  
* Indiana Jones and the Temple of Doom (1985)  
* Relief Pitcher (1986) (unreleased prototype)  
* RoadBlasters (1987)  

## Building

### Pipistrello
The project files are under `/pipistrello` and are setup for Xilinx ISE 14.7  
On a [Pipistrello](http://pipistrello.saanlima.com/index.php?title=Welcome_to_Pipistrello) FPGA board, a [SRAM expansion](https://oshpark.com/profiles/d18c7db) daughterboard is needed.  

### MiSTer

The project files are under folder `/MiSTer` and are setup for Quartus 17  
