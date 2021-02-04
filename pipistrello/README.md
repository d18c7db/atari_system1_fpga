# Atari System 1 FPGA Arcade  

## Work In Progress  
Video section produces correct Video in simulation, with pre-initialized Video and Color RAM.  
Main 68K CPU executes code and has successfully run until initial game screen in simulation  
Audio section 6502 executes code correctly, audio chip output currently unconnected.  
Everything so far has been run in ISIM simulation but not on FPGA hardware yet.  

## About  
FPGA implementation of Atari's System 1 (LSI version) arcade platform from 1984 for the Pipistrello FPGA development board  
Based primarily on the SP-280, SP-286 schematics with additional support from SP-277, SP-298  

Supported game cartridges  
* Marble Madness (1984)  
* Peter Pack Rat (1985)  
* Road Runner (1985)  
* Indiana Jones and the Temple of Doom (1985)  
* Relief Pitcher (1986) (unreleased prototype)  
* RoadBlasters (1987)  

