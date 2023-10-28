# Atari System-1 FPGA Arcade  

## About  
FPGA implementation of Atari's System 1 (LSI version) arcade platform from 1984.  
Based primarily on the SP-280, SP-286 schematics with additional support from SP-277, SP-298  

System-1 supported game cartridges according to MAME  
* Marble Madness (1984)  
* Peter Pack Rat (1985)  
* Road Runner (1985)  
* Indiana Jones and the Temple of Doom (1985)  
* RoadBlasters (1987)  

## Known Issues
The following mra files don't work as expected.
* Indiana Jones (cocktail).mra graphics tiles incorrectly offset, directional controls not working.
* Indiana Jones (set 3).mra upside down corrupt or missing graphics, text is OK.

## Building  

### Pipistrello  
The project files are under `/pipistrello` and are setup for Xilinx ISE 14.7  
On a [Pipistrello](http://pipistrello.saanlima.com/index.php?title=Welcome_to_Pipistrello) FPGA board, a [SRAM expansion](https://oshpark.com/profiles/d18c7db) daughterboard is needed.  

### MiSTer
The project files are under folder `/MiSTer` and are setup for Quartus 17  
