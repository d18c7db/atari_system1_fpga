# Atari System-1 FPGA Arcade  

## Work In Progress  
* Indiana Jones - Playable, no obvious issues.  
* Peter Pack Rat - Playable, no obvious issues.  
* Marble Madness - Playable with joystick or mouse as trackball control.  
* Road Runner - Playable, no obvious issues.  
* Road Blasters - Playable but has a permanent vertical green line on the left of the screen.  

### NOTE on Road Blasters  
The earlier schematics SP-282/SP-286 can address only four graphic ROM banks and this works well for Indy, Marble and Peter but Road Runner and Road Blasters need a total of seven graphic ROM banks and the chip select decoding has been updated in schematic SP-299  

However for some reason this decoding simply does not work at all for any games and just produces garbled graphics so due to this, I have looked at MAME source code and implemented their style of chip select decoding which is nothing like SP-299 and closer to SP-282 with some extra tweaks.  

I have spent hours simulating the hardware and everything seems to work as designed but still the issue remains where Road Blasters has a vertical green line (pixel data supplied from ROM bank 7). I believe this is because the ROM bank decoding is still not fully sorted but I'm unable to find the proper way to do it.  

## About  
FPGA implementation of Atari's System 1 (LSI version) arcade platform from 1984.  
Based primarily on the SP-280, SP-286 schematics with additional support from SP-277, SP-298  

System-1 supported game cartridges according to MAME  
* Marble Madness (1984)  
* Peter Pack Rat (1985)  
* Road Runner (1985)  
* Indiana Jones and the Temple of Doom (1985)  
* RoadBlasters (1987)  

## Building  

### Pipistrello  
The project files are under `/pipistrello` and are setup for Xilinx ISE 14.7  
On a [Pipistrello](http://pipistrello.saanlima.com/index.php?title=Welcome_to_Pipistrello) FPGA board, a [SRAM expansion](https://oshpark.com/profiles/d18c7db) daughterboard is needed.  

### MiSTer
The project files are under folder `/MiSTer` and are setup for Quartus 17  
