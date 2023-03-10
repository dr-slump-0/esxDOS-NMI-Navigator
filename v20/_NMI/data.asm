;==============================================================================
; Project: NMI.zDSp
; File: data.asm
; Date: 29/08/2017 13:29:18
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; DATA
;==============================================================================

; -----------------------
; navigator actions table
; -----------------------
;
dbdwTbActions	DB 'A'			; attach TRD to drive A
		DW trd2drv.start0
		DB 'B'			; attach TRD to drive B
		DW trd2drv.start1
		DB 'C'			; attach TRD to drive C
		DW trd2drv.start2
		DB 'D'			; attach TRD to drive D
		DW trd2drv.start3
		DB 'E'			; erase file
		DW delFile.start
		DB K_DELETE		; CS+0 erase file
		DW delFile.start
		DB 'F'			; fast-ramp load
		DW fastLoad.start
		DB K_TO			; SS+F fast-ramp config
		DW fastcfg.start
		DB 'G'			; load mon dot command
		DW debug.start
		DB 'H'			; show help
		DW help.start
		DB 'I'			; attach TAP to tapein
		DW tapein.start
		DB K_AT			; SS+I detach TAP from tapein
		DW tapein.start
		DB 'J'			; load old NMI handler
		DW loadOld.start
		DB 'K'			; config navigation keys
		DW config.start
		DB 'L'			; paging register lock, ROM 1 select
		DW lock.start
		//DB 'M'		; load module
		//DW loadmod
		DB 'N'			; rename file
		DW rename.start
		DB 'O'			; attach TAP to tapeout
		DW tapeout.start
		DB ';'			; SS+O detach TAP from tapeout
		DW tapeout.start
		DB 'P'			; poke memory
		DW poke.start
		DB 'R'			; reset
		DW reset.start
		DB 'S'			; create snapshot
		DW savSNA.start
		DB 'T'			; autostart vdisk, if no boot, loads TR-DOS Navigator
		DW startTRDOS
		DB '>'			; SS+T load TR-DOS Navigator
		DW startTRDOS
		DB K_MERGE		; CS+T enter TR-DOS mode
		DW startTRDOS
		DB 'U'			; change to next valid drive (cycling)
		DW seldrv.start
		DB 'V'			; view screen
		DW view.start
		DB '/'			; SS+V view with hexview
		DW viewHex
		DB K_EDIT		; CS+1 up dir
		DW upDir
kLeft		DB K_LEFT		; CS+5 prev page
		DW prevPg
kDown		DB K_DOWN		; CS+6 line down
		DW nextLn
kUp		DB K_UP			; CS+7 line up
		DW prevLn
kRight		DB K_RIGHT		; CS+8 next page
		DW nextPg
kEnter		DB K_ENTER		; do action
		DW doAct.start
		DB K_SS_ENTER		; SS+ENTER do action
		DW doAct.start
		DB K_CS_ENTER		; CS+ENTER do action
		DW doAct.start
		DB K_BREAK		; CS+SPACE exit navigator
		DW exitNMI
		DB 0

; ------------------------------------------
; ext actions table (do action and fastload)
; ------------------------------------------
;
dbdwTbExtAct	DB 'SNA'
		DW loadSNA
		DB 'TAP'
		DW loadTAP
		DB 'Z80'
		DW loadSNA
		DB 'BAS'
		DW loadBAS
		DB 'ROM'
		DW loadROM
extTRD		DB 'TRD'
		DW loadTRD
extSCL		DB 'SCL'
		DW loadTRD	; All functions for TRD runs with SCL
		; ------
		; viewer
		; ------
dbdwTbExtView	DB 'SCR'
		DW viewSCR
		DB 'SNA'	; Are different actions, ENTER and fastload
		DW viewSNA	; use the first in extTbl and V use this one in extTblV
		DB 0

; ==============================================================================
; MESSAGES
; ==============================================================================
;
msgErr		DB $16,12,32-8,'ESXDOS error ', 0

msgTop1		DB $16,0,1
msgDrv		DB ' d :'
msgPath		DB '/'
		DS 62-5
		DB 0

msgBot1		DB $16,23,1,'[',0
msgBot3		DB '/',0
msgBot4		DB ']',0
msgBot5		DB $16,23,19
msgLock		DB '         '
msgRAM1		DB '     '
		DB '| '
msgVer		DB '              '
msgRAM2		DB '     '
		DB '| '
		M_VERSION
		DB 0

msgMid1		DB $16,1,0,0
msgMid2		DB '<DIR>',0
msgMid4		DB $16,1,8+1+3+1,0

; ***

msgSaveFC 	DB $16,23,1,'SAVING FILE...', 0

msgOkDel	DB $16,23,1, 'DELETE (Y/N)? ',0
msgDel		DB $16,23,1, 'DELETING FILES...',0

msgStat		DB $16,23,1,'LOADING DEBUGGER...',0

msgLocking	DB $16,23,1,'LOCKING...',0

msgPok1		DB $16,23,1, 'POKE? ',0
msgPok2		DB $16,23,1, 'POKE ',0
msgPok3		DB ',',0
msgPok4		DB ' APPLY (Y/N)? ',0

msgNewN		DB $16,23,1, 'NEW NAME? ',0

msgReseting	DB $16,23,1,'RESETING...',0

msgSave		DB $16,23,1,'SAVING SNAPSHOT...',0

msgDir		DB $16,23,1,'LOADING DIRECTORY...',0
msgFile		DB $16,23,1,'LOADING FILE...',0

msgTypeErr	DB $16,23,1,'FILE TYPE NOT SUPPORTED, PRESS A KEY',0


msgOkSelDrv	DB $16,23,1,'SET DEFAULT DRIVE TO '
drvName		DB ' d :...',0

msgAttIn	DB $16,23,1, 'TAP ATTACHED TO INPUT, PRESS ANY KEY',0
msgDetIn	DB $16,23,1, 'TAP DETACHED FROM INPUT, PRESS ANY KEY',0

msgAttOut	DB $16,23,1, 'TAP ATTACHED TO OUTPUT, PRESS ANY KEY',0
msgDetOut	DB $16,23,1, 'TAP DETACHED FROM OUTPUT, PRESS ANY KEY',0

msgOk		DB $16,23,1, 'TRD ATTACHED TO UNIT '
unitLet		DB 'A, PRESS ANY KEY',0

msg0001		DB $16,12,1,'DR SLUMP NMI NAVIGATOR'
msg0002		DB $16,12,56
		M_VERSION
		DB 0
//msg0003		DB $16,4,1,'DEFINE KEYS: '//,0
//msg0004		DB $16,6,1,'KEY FOR UP? ',0
//msg0005		DB $16,7,1,'KEY FOR DOWN? ',0
//msg0006		DB $16,8,1,'KEY FOR LEFT? ',0
//msg0007		DB $16,9,1,'KEY FOR RIGHT? ',0
//msg0008		DB $16,10,1,'KEY FOR ENTER? ',0
//msgHapp		DB $16,12,1,'HAPPY (Y/N)? ',0

;==============================================================================
; ACTIONS DATA
;==============================================================================

msg16k		DB '16K'
msg48k		DB '48K'
msg128k		DB '128K'

msgUnlocked	DB 'UNLOCKED  '

dbFnBackupFile	DB '/TMP/_NMI_BAK.SCR', 0

dbFnConfigFile	DB '/SYS/NMI/NMI.CNF',0
dbFnFastFile	DB '/SYS/NMI/FASTCFG.TXT',0

//dbFnHelFile1	DB '/SYS/NMI/HELP1.SCR',0
//dbFnHelFile2	DB '/SYS/NMI/HELP2.SCR',0
//dbFnHelFile3	DB '/SYS/NMI/HELP3.SCR',0

dbStrPokeValue	DB '12345,123',0

dbFnNewFileName	DB '12345678.123',0
dbFnSnapName	DB 'SNAP0000.SNA',0

//unavail	DB 'ABCDEFGHIJKLMNOPRSUV',K_DELETE,K_TO,K_EDIT
//		DB K_AT,';',K_SS_ENTER,K_CS_ENTER
//usedK		DB 0,0,0,0,0

trdBas		DB '/SYS/NMI/TRDN.BAS', 0

prefix		DB ' GMK'		; prefixes for filesizes

; ---------
; key names
; ---------
;
//mDelete		DB 'DELETE',0
//mSpace		DB 'SPACE',0
//mEnter		DB 'ENTER',0
//mBreak		DB 'BREAK',0
//mLeft		DB 'LEFT',0
//mRight		DB 'RIGHT',0
//mUp		DB 'UP',0
//mDown		DB 'DOWN',0
//mEdit		DB 'EDIT',0
//mTo		DB 'SS+F',0
//mSSEnt		DB 'SS+ENTER',0
//mCSEnt		DB 'CS+ENTER',0
//mAt		DB 'SS+I',0

; ---------------
; other variables
; ---------------
;
flgLOCK		DB $ff			; flag to signal LOCK 48k mode
flgROOT		DB 0			; flag to signal root dir reached

;
; Order must be the same as in loader.asm
;-------------------
savedSP		DW 0			; SP register saved on NMI navigator entry
divRAM		DW 0			; number of 8k RAM pages found
speccyRAM	DB 0			; flag to signal 128k speccy
savRAM		DB 0			; flag to signal screen saved to RAM
esxDOSv		DB 0			; version of esxDOS
NMIbuf_org	DW 0			; necessary for load old NMI handler
;-------------------
NMIbuf		DS 31			; NMI buffer

; ----------------------------------
; variables for NMI navigator paging
; ----------------------------------
;
curLn		DW 0			; current selected line (cursor line)
pCurPg		DW pPrvDir		; pointer to current page first dir entry
Xof		DW 0			; current dir entry (cursor line)
Xlim		DW 0			; current page max dir entry (line number)
ofY		DW 0			; total dir entries

; -----------------------------------
; pointers to dir entry, current page
; -----------------------------------
;
; there are 23 entries because I need an additional pointer to the first dir
; entry of the next page
;
; chaged pointers from 4 bytes to 3 bytes long, on this version of esxDOS works
;
		IFDEF _POINTER4BYTES
pCurDir		DS 4*23,0
		ELSE
pCurDir		DS 3*23,0
		ENDIF

; -------------------------------------
; pointers to dir entry, previous pages
; -------------------------------------
;
		IFDEF _POINTER4BYTES
pPrvDir		DS (MAXENTR/22)*4,0
		ELSE
pPrvDir		DS (MAXENTR/22)*3,0
		ENDIF

ldInit		DB $ff			; flag to signal do initialization
ldConf		DB $ff			; flag to signal load config from file
ldDir		DB $ff			; flag to signal load dir

flgPopUp	DB 0			; 0 not show popup
flgOut		DB 0			; 0 not set default graphic mode
flgHidden	DB 0			; 0 not show hidden

strLen		DB 0			; current working directory string length

; ------------
; dot commands
; ------------
;
dotCommOwnrom	DB 'OWNROM', 0

dotCommMon	DB 'MON',0

dotCommRm	DB 'RM -fr '		; -fr must be in lower case
bDName2		DS 8+1+3+1

dotCommHexview	DB 'HEXVIEW '
bDName3		DS 8+1+3+1

dotCommSnapload	DB 'SNAPLOAD '
dbStrPathName	DS 127+8+1+3+1		; A continuacion de dotCommSnapload	UNIFICABLE COMO DS

endData

; ----------------------------------
; not initialized temporal variables
; ----------------------------------
;
		//ORG dbStrPathName

pDSizeL		DW 0			; pointer to filesize on dir entry buffer L
pDSizeH		DW 0			; pointer to filesize on dir entry buffer H
prefixCnt	DB 0			; counter for filesize prefix
pokeAdd		DW 0			; poke address				UNIFICABLE COMO DS
pokeVal		DW 0			; poke value				UNIFICABLE COMO DS

		//ORG dbStrPathName

dbDrive		DB 0			; virtual drive number			UNIFICABLE COMO DS
dwPtrExt	DW 0			; pointer to extension			UNIFICABLE COMO DS

		//ORG dbStrPathName

flagT		DB 0			; init popup window			UNIFICABLE COMO DS

bufConf					; config buffer				UNIFICABLE COMO DS
cfPopUp		DB 0
cfLeft		DB 0
cfRight		DB 0
cfDown		DB 0
cfUp		DB 0
cfEnter		DB 0
cfOut		DB 0
cfHidden	DB 0

; ----------------------------------

		//ORG endData

