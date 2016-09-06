#!/bin/sh
#
echo "Compiling..."
vbccm68k -quiet "floatstr.c" -o= "floatstr.asm" -I$PWD/include  -O=1 -I$VBCC/targets/m68k-atari/include
echo "Assembling..."
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "floatstr.asm" -o "floatstr.o"
vasmm68k_mot -quiet -Faout -mid=0 -phxass -nowarn=62 "kspser.s" -o "kspser.o"
echo "Linking..."
vlink -EB -bataritos -x -Bstatic -Cvbcc -nostdlib $VBCC/targets/m68k-atari/lib/startup.o "floatstr.o" "kspser.o" -lm -L$VBCC/targets/m68k-atari/lib -lvc -o KSPSERL.PRG
