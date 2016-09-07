# missioncontrol
KSP Mission Control

To compile, you'll need a working copy of VBCC (http://sun.hasenbraten.de/vbcc/) set up with a M68k compiler and TOS target. This doesn't use anything external other than the include files located in INCLUDE.

Run make.sh to build from scratch. A working build is located in the bin folder.

# System Requirements
- Atari ST with 512K of RAM and TOS 1.04 or better (2.06 recommended)
- For best results in Hatari, set your emulation to 32MHz 68000

# Usage
You'll need to install the KSPIO plugin through CKAN or its forum thread (http://forum.kerbalspaceprogram.com/index.php?/topic/60281-hardware-plugin-arduino-based-physical-display-serial-port-io-tutorial-22-april/). Configure it to use the correct COM port at a speed of 9600 baud and disable the handshake checking. I've left it out for plugin compatibility reasons.

To use it with a real Atari ST, you should just be able to connect it to your PC's RS-232-compatible serial port or USB-to-serial adapter. Configure the plugin for the right COM port and 9600 baud.

To use it with an emulator such as Hatari, you'll need a virtual serial port driver. I used com0com (http://com0com.sourceforge.net/) for development. Hatari requires a Linux host in order to perform RS-232 emulation but I believe other emulators may not. Configure com0com to provide a loopback serial port that emulates the actual transmission rate. Tell the emulator to use one end of the loopback and tell KSPIO to use the other end.

Once you have the serial connection configured, run KSPSERL.PRG. You'll see a bunch of labels appear on the screen. You can now begin a flight in KSP. Once the Atari ST is receiving data from KSP, the data fields will populate, updating every second or so. You can watch your flight's progress on your Atari computer! :D

# Screenshots
http://i.imgur.com/p41c0C0.gif

# Known Problems
You can't quit the application for some reason!
Some of the data fields will freak out now and then, I'm still working on that.
