1. Installation
==============================================================================

First, make a backup of /sys/nmi.sys, for example, renaming it to nmi.sys.old
Then, you must decompress nmi_v0.0.XX.zip into /sys folder. After doing it,
there should be an nmi.sys file and an nmi folder inside the /sys folder.
    nmi.sys
    nmi
The nmi folder must contain the following files:
    config
    custom
    debug
    delete
    enter
    fastcfg
    fastload
    help
    init
    loadold
    lock
    poke
    reload
    rename
    reset
    savesna
    seldrv
    tapein
    tapeout
    trd2drv
    view
    nmi.cnf
    help1.scr
    help2.scr
    help3.scr
    TRDN.tap
    fastcfg.txt
    old085.sys
    old086.sys
    old087.sys
All are necessary to use the new NMI navigator.

You also need the following files in the /bin folder:
    hexview
    mon
    ownrom
    rm
    snapload
They are dot commands called from the NMI navigator.

If you are using a non MMC device (IDE device), you must create the tmp folder
at / directory.

2. Running it
==============================================================================

Once installed, use it as the original version: press NMI button to load NMI
navigator.

Default navigation keys are EDIT (shifted 1), cursors (shifted 5,6,7,8) and
ENTER, and Kempston joystick. It's possible to redefine navigation keys.

    EDIT        Up directory
    LEFT        Previous page
    DOWN        Cursor down
    UP          Cursor up
    RIGHT       Next page

    ENTER       Enter directory
    
    BREAK       Exit

Functions keys are the following:
 
    A           TRD to drive A
    B           TRD to drive B
    C           TRD to drive C
    D           TRD to drive D
    E           Erase file/directory
    DELETE      Erase file/directory
    F           Fast-ramp loader
    SS+F (TO)   Set fast-ramp   
    G           Debug
    H           Help
    I           TAP to tapein
    SS+I (AT)   Detach tapein
    J           Load old NMI navigator
    K           Configure navigator keys
    L           Lock paging register
    M           Load custom module
    N           New file/directory name
    O           TAP to tapeout
    SS+O (;)    Detach tapeout
    P           Poke memory
    R           Reset
    S           Create snapshot
    U           Change active drive
    V           View screen SCR SNA

    ENTER       Run Z80 SNA TAP TRD BAS ROM, view SCR
    SS+ENTER    Load TRD and run TR-DOS Navigator
    CS+ENTER    Load TRD and enter TR-DOS mode

3. Keys
==============================================================================

3.1 K                                                 Configure navigator keys
------------------------------------------------------------------------------
Allow redefine navigator keys. Shows a wizard to do it:

 Dr Slump NMI Navigator                                v0.0.16
 
 Define keys:
 
 Key for UP?
 Key for DOWN?
 Key for LEFT?
 Key for RIGHT?
 Key for ENTER?
 
 Happy (Y/N)?

BREAK key are allowed in any point and aborts configuration, returning to
navigation panel. If you answer Y to last question, keys configuration are
saved to /sys/nmi/nmi.cnf. This file is loaded every hard reset to maintain
last configuration. If you answer anything else Y, configuration process
starts again.

Not all keys are available to use, used function keys and already redefined
keys are not available.

Internals
·········
nmi.cnf format (binary file of 7 bytes):
addr 0 (byte): flag to control splash screen. 0-skip splash screen, anything
               else, show splash screen.
addr 1 (byte): default left key. 08h (CURSOR LEFT).
addr 2 (byte): default right key. 09h (CURSOR RIGHT).
addr 3 (byte): default down key. 0Ah (CURSOR DOWN).
addr 4 (byte): default up key. 0Bh (CURSOR UP).
addr 5 (byte): default intro key. 0dh (ENTER).
addr 6 (byte): (v0.0.16 and up) flag to control OUT 255, (0). 0-skip OUT,
               anything else, do OUT.

It loads /sys/nmi/config and uses /sys/nmi/nmi.cnf

3.2 H                                                                     Help
------------------------------------------------------------------------------
Shows a set of help screens with navigation info, functions and greetings.
BREAK key are allowed in any point and returns to navigation panel.
UP moves to previous help screen. Another key moves to next help screen; if
last screen, then backs to navigation panel.

Internals
·········
It loads /sys/nmi/help and uses /sys/nmi/help1.scr to /sys/nmi/help3.scr

3.3 ENTER                                Run Z80 SNA TAP TRD BAS ROM, view SCR
------------------------------------------------------------------------------
ENTER over a folder changes to it; over '..' folder, returns to parent
directory; over '.' folder, reload current directory.

ENTER over a .Z80, .SNA, .TAP, .TRD, .BAS or .ROM load and run it. ENTER over
a .SCR load screen. ENTER over a no extension file treat it as .BAS file.
ENTER over other file type opens it with HEXVIEW dot command.

Internals
·········
ENTER over a file do the following:
    .Z80: uses SNAPLOAD dot command to load and run file.
    .SNA: uses SNAPLOAD dot command to load and run file.
    .TAP: attaches tape image to IN and loads it.
    .TRD: attaches disk image to drive A and try to boot it. If boot is not
          possible, then runs TR-DOS Navigator (/sys/trdos54t.ko).
    .BAS: loads BASIC program (fails with version v0.8.6 beta 5.1).
    .ROM: loads ROM image at 49152 address and runs OWNROM dot command to run
          it.
    .SCR: loads screen.
Other extension: loads HEXVIEW dot command to view it.

It loads /sys/nmi/enter and uses /bin/snapload, /bin/ownrom, or /bin/hexview

3.4 SS+ENTER                                 Load TRD and run TR-DOS Navigator
------------------------------------------------------------------------------
SS+ENTER over a .TRD file load it and open TR-DOS Navigator.

Internals
·········
SS+ENTER over a .TRD file attaches disk image to drive A, attaches
/sys/nmi/TRDN.tap to IN and loads it, then loads TR-DOS Navigator.

It loads /sys/nmi/enter and uses /sys/nmi/TRDN.tap

3.4 CS+ENTER                                    Load TRD and enter TR-DOS mode
------------------------------------------------------------------------------
CS+ENTER over a .TRD file attaches disk image to drive A and enter TR-DOS mode
(like RANDOMIZE USR 15616).

Internals
·········
It loads /sys/nmi/enter and uses /sys/trdos54t.ko

3.5 A B C D                                               TRD to drive A B C D
------------------------------------------------------------------------------
A, B, C or D over a .TRD file attaches it to drive A, B, C, D, respectively.
Shows "TRD ATTACHED TO UNIT X, PRESS ANY KEY" on bottom line and waits for a
key press.

Internals
·········
It loads /sys/nmi/trd2drv

3.6 E DELETE                                              Erase file/directory
------------------------------------------------------------------------------
E, DELETE erases file or directory using RM dot command. It uses -f and -r
options:
    -f  ignore nonexistent files and arguments, never prompt
    -r  remove directories and their contents recursively
Shows "DELETE (Y/N)?" on bottom line and waits for confirmation. Press Y to
confirm, another key to discard.
The process can be aborted pressing BREAK while "DELETING FILES..." is showed
on bottom line.
Use with CAUTION over folders!!!

Internals
·········
It loads /sys/nmi/delete and uses /bin/rm

3.7 F                                                         Fast-ramp loader      
------------------------------------------------------------------------------
F loads file previously selected with SS+F. It's a fast-ramp loader. Valid
file types are .SNA, .Z80, .TAP, .BAS and .TRD.

Internals
·········
File is stored on /sys/nmi/fast.cfg. It's a text file containing drive and
file path, e.g. hd0:/GAMES/GAME.TRD

It loads /sys/nmi/fastload and uses /sys/nmi/fast.cfg

3.8 SS+F (TO)                                                    Set fast-ramp  
------------------------------------------------------------------------------
SS+F sets selected file for fast-ramp load.

Internals
·········
It loads /sys/nmi/fastload and uses /sys/nmi/fast.cfg

3.9 G                                                                    Debug
------------------------------------------------------------------------------
G loads dot command MON, a monitor/debugger.

Internals
·········
It loads /sys/nmi/debug and uses /bin/mon

3.10 I                                                           TAP to tapein
------------------------------------------------------------------------------
I attach selected .TAP file to TAPEIN. Then, it's possible read from it from
BASIC with LOAD.
Shows TAP ATTACHED TO INPUT, PRESS ANY KEY 

Internals
·········
It loads /sys/nmi/tapein 

3.11 SS+I (AT)                                                   Detach tapein
------------------------------------------------------------------------------
SS+I detach current attached file from TAPEIN.
Shows TAP DETACHED FROM INPUT, PRESS ANY KEY

Internals
·········
It loads /sys/nmi/tapein 

3.12 J                                                  Load old NMI navigator
------------------------------------------------------------------------------
J loads old NMI navigator. Hard reset is necessary to return to new.

Internals
·········
It loads /sys/nmi/loadold and uses /sys/nmi/old085.sys to /sys/nmi/old087.sys

3.13 L                                                    Lock paging register
------------------------------------------------------------------------------
L locks paging register of 128K or compatible machine (bit 5 of port 0x7ffd)
It's similar to SNAPLOAD -l option. It's necessary to run ULTIMATE games and
others than Sly Spy: Secret Agent. To unlock paging register is necessary
reset the machine.

Internals
·········
It loads /sys/nmi/lock

3.14 M                                                      Load custom module
------------------------------------------------------------------------------
M load custom module in /sys/nmi/custom. See readme.txt on custom distribution
for more info. Default module shows Hello world! message.

Internals
·········
It loads /sys/nmi/custom 

3.15 N                                                 New file/directory name
------------------------------------------------------------------------------
N rename a file or a directory. Enter up to 8 characters, press '.', enter up
to 3 characters and press ENTER. Note: you can enter up to 11 characters,
esxDOS automatically uses first 8 characters to name and last 3 to extension.

Internals
·········
It loads /sys/nmi/rename

3.16 O                                                          TAP to tapeout
------------------------------------------------------------------------------
I attach selected .TAP file to TAPEOUT. Then, it's possible write to it from
BASIC with SAVE.
Shows TAP ATTACHED TO OUTPUT, PRESS ANY KEY 

Internals
·········
It loads /sys/nmi/tapeout 

3.17 SS+O (;)                                                   Detach tapeout
------------------------------------------------------------------------------
SS+O detach current attached file from TAPEOUT.
Shows TAP DETACHED FROM OUTPUT, PRESS ANY KEY

Internals
·········
It loads /sys/nmi/tapeout 

3.18 P                                                             Poke memory
------------------------------------------------------------------------------
P allow POKE memory easily. Only allow POKE 48K area. To POKE press P, then
enter up to 5 digits, press ',', enter up to 3 digits and press ENTER. Then
press Y to apply or another key to discard.

e.g: POKE? 54321,123
     POKE 54321,123 APPLY (Y/N)?

Internals
·········
After enter POKE, saved screen is restored, POKE applied, and screen saved
again. Then, POKE screen area is possible.

It loads /sys/nmi/poke and uses saved screen.

3.19 R                                                                   Reset
------------------------------------------------------------------------------
R resets speccy (soft reset).

Internals
·········
Reset it's done via esxDOS API.

It loads /sys/nmi/reset

3.20 S                                                         Create snapshot
------------------------------------------------------------------------------
S creates a snapshot of current speccy state. Snapshot is in .SNA format and
it's 48K or 128K version depending of type of machine running. Snapshot is
saved on current unit/current dir. Snapshots numbering it's automatically
increased and detect if exists previous snapshots: NO MORE ERROR 18 :-)

Internals
·········
Snapshot uses .SNA information supplied by esxDOS. There are esxDOS versions
with bugs on it.

S restore saved screen and then dump .SNA header, RAM, and if 128K machine,
extra header info and additional RAM banks.

It loads /sys/nmi/savesna

3.21 U                                                     Change active drive
------------------------------------------------------------------------------
U change active drive, cycling available ones.

Internals
·········
It loads /sys/nmi/seldrv

3.22 V                                                     View screen SCR SNA
------------------------------------------------------------------------------
V shows screen of .SNA snapshot or .SCR file. Load HEXVIEW in any other case.

Internals
·········
It loads /sys/nmi/view and uses /bin/hexview

4. Compatibility
==============================================================================

New NMI navigator works on esxDOS versions from v0.8.5 to v0.8.7
On v0.8.6 beta 5.1 load BASIC programs fails due a esxDOS bug.

A. Credits
==============================================================================

Based on original NMI.sys code from ub880d (aka Dusky).

Joystick code based on velesoft suggestions.

The source code for 64 column printing is based on code originally provided by
Andrew Owen in a thread on WoSF, based on code by Tony Samuels from Your
Spectrum issue 13, April 1985: "A channel wrapper for the 64-column display
driver".

The rest, including bugs and errors, are exclusively my fault ;-)

B. esxDOS error numbers
==============================================================================

1  O.K. ESXDOS
2  Nonsense in ESXDOS
3  Statement END error
4  Wrong file TYPE
5  No such FILE or DIR
6  I/O ERROR
7  Invalid FILENAME
8  Access DENIED
9  Drive FULL
10 Invalid I/O REQUEST   ; Request beyond the limits of the device
11 No such DRIVE
12 Too many OPEN FILES
13 Bad file DESCRIPTOR
14 No such DEVICE
15 File pointer OVERFLOW
16 Is a DIRECTORY
17 Not a DIRECTORY
18 File already EXISTS
19 Invalid PATH
20 No SYS
21 Path too LONG
22 No such COMMAND
23 File in USE
24 File is READ ONLY
25 Verify FAILED
26 Loading .KO FAILED
27 Directory NOT EMPTY
28 MAPRAM is ACTIVE
   Drive is BUSY
   Unknown FILESYSTEM
   Device is BUSY

C. Files used
==============================================================================

/bin
    HEXVIEW
    MON
    OWNROM
    RM
    SNAPLOAD

/sys
    nmi.sys
    nmi

/sys/nmi
    config
    custom
    debug
    delete
    enter
    fastcfg
    fastload
    help
    init
    loadold
    lock
    poke
    reload
    rename
    reset
    savesna
    seldrv
    tapein
    tapeout
    trd2drv
    view
    nmi.cnf
    help1.scr
    help3.scr
    help2.scr
    TRDN.tap
    fastcfg.txt
    old085.sys
    old086.sys
    old087.sys
    
D. Greetings
==============================================================================

Thanks to lordcoxis for esxDOS, ub880d for his great work on original NMI
Navigator, to velesoft for his contributions, and the people of esxDOS BBS:
Luzie, Spezzi63, Alcoholics Anonymous, matofesi, NuClear235, bracula80, Hood,
bverstee, Uto and mcleod_ideafix.

    Dr. Slump (aka David Pesqueira Souto)
