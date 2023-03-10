;==============================================================================
; Project: NMI.zdsp
; File: actions.asm
; Date: 03/11/2022 21:31:17
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; ACTIONS
;==============================================================================

; =============================================================================
; startup --- revisado
; =============================================================================
;
startup.start	ld a, (ldInit)		;
		or a			;
		jp z, skipInit		; first time we call NMI navigator

doInit		xor a
		ld (ldInit), a

		ld a, (esxDOSv)
		cp '5'
		jr z, ver085
		cp '7'
		jr z, ver087
		;
		; version is 0.8.6 or 0.8.8 or 0.8.9
		;
ver086_8	ld hl, $00a8
		jr copyVersion
		;
		; version is 0.8.5
		;
ver085		ld hl, $00b8
		jr copyVersion
		;
		; version is 0.8.7
		;
ver087		ld hl, $00a7
		;
copyVersion	ld de, msgVer
		ld bc, 13
		ldir

		ld a, (speccyRAM)
		cp 0
		jr nz, noes16k
		ld hl, msg16k
		ld bc, 3
		jr copyRAM
noes16k		cp 1
		jr nz, noes48k
		ld hl, msg48k
		ld bc, 3
		jr copyRAM
noes48k		ld hl, msg128k
		ld bc, 4
copyRAM		ld de, msgRAM1
		ldir

		ld hl, (divRAM)		; hl = 8 kB pages found
		sla l			;
		rl h			;
		sla l			;
		rl h			;
		sla l			;
		rl h			; hl = hl * 8 = kB RAM found

		ld de, msgRAM2
		call _utoa
		ld a, 'K'
		ld (de), a

skipInit	ld a, (ldConf)
		or a
		jr z, skipLoadConfig
		xor a
		ld (ldConf), a

		call readCnf	; read config file

		ld a, (cfLeft)
		ld (kLeft), a
		ld a, (cfRight)
		ld (kRight), a
		ld a, (cfUp)
		ld (kUp), a
		ld a, (cfDown)
		ld (kDown), a
		ld a, (cfEnter)
		ld (kEnter), a
		ld a, (cfPopUp)
		ld (flgPopUp), a
		ld a, (cfOut)
		ld (flgOut), a
		ld a, (cfHidden)
		ld (flgHidden), a

		ld a, (flgPopUp)
		or a
		jr z, skipLoadConfig

		ld bc, 24*256+0
		ld a, 0
		call clrScr

		ld hl, msg0001
		call prStr

		;
		; popup window
		;
		ld b, 56
		ld c, BRIGHT+BLACK*8+WHITE
		xor a
waitE		push af
		push bc
		add a, c
		ld bc, 3*256+11
		call clrAttr
		pop bc
		ld a, (flagT)
		or a
		jr z, wait3
		pop af
		sub 8
		jr wait2
wait3		pop af
		add a, 8
wait2		or a
		jr nz, wait0
		ld (flagT), a
		jr wait1
wait0		cp 56
		jr nz, wait1
		ld (flagT), a
wait1		ei
		halt
		djnz waitE

skipLoadConfig	ld a, (flgOut)
		or a
		jr z, skipSetStdGr

		xor a			;
		out ($ff), a		; set standard graphic zx mode on computers
					; Timex2048,Timex2068 and on SLAM
					; Thanks to Velesoft
skipSetStdGr		;
		;  Get CWD
		;
		call getCWD

		ld a, (ldDir)		;
		or a			;
		jr nz, doReload		; first time we call NMI navigator

		;
		; Compare old WD with CWD
		;
		call testCWD
		jr z, skipReload	; current working directory not changed
					; preserves previous navigation page and line

doReload	xor a
		ld (ldDir), a
		;
		; Init navigator variables
		;
		ld hl, 0
		ld (curLn), hl
		ld (Xof),hl
		ld (ofY), hl
		;
		; skip '.' dir entry and saves dir entry pointer
		;
		call skipDotSavePtr

skipReload	;
		; Copy CWD msg
		;
		call copyCWD
		;
		; Copy lock status msg
		;
		ld a, (speccyRAM)
		cp 2
		jr nz, notToastrack

		ld hl, msgUnlocked	; UNLOCKED
		ld bc, 8
		ld a, (flgLOCK)
		or a
		jr nz, isUnlocked
		ld hl, msgUnlocked+2	; LOCKED
		ld bc, 8

isUnlocked	ld de, msgLock
		ldir

notToastrack	xor a			;
		out ($fe), a		; black border

		//jp mainL2		; reprint all (top, mid, bottom and cursor)
		ret

;--------
; clrAttr
;--------
;
clrAttr		ex af, af'		; guardamos atributos
		;
		; attr
		;
		ld a, c			; Calculate Y7, Y6
		rrca			; Shift to position
		rrca
		rrca
		and %00000011		; Mask out unwanted bits
		or %01011000		; Set attr address of screen
		ld h, a			; Store in H
		ld d, a
		ld a, c
		rrca			; Shift to position
		rrca
		rrca
		and %11100000		; Calculate Y5, Y4, Y3
		ld l, a			; Store in L
		ld e, a
		inc e
		;
		ex af, af'		; recuperamos atributos
		push bc			; guardamos BC
		;
		ld (hl), a
		ld bc, 32-1
		ldir
		;
		pop bc			; recuperamos BC
		;
		inc c
		djnz clrAttr
		;
		ret

; =============================================================================
; 'ENTER' do action over cursor --- revisado
; =============================================================================
;
doAct.start	ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		;
		ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, doAct.isFile

doAct.isDir	ld hl, msgDir
		call prStr		; LOADING DIRECTORY...
		;
		ld hl, bDName
		call fChDir
		;
		ld a, $ff
		ld (ldDir), a
		;
		jp mainL1		; reload dir and reprint all

doAct.isFile	ld hl, msgFile
		call prStr		; LOADING FILE...
		;
		ld hl, bDName		;
		ld de, dbStrPathName	;
		ld bc, 8+1+3+1		;
		ldir			; copy filename

doAct.exeAction1 ld de, dbdwTbExtAct

doAct.exeAction	ld hl, dbStrPathName
		//ld bc, 8+1+3+1
		ld bc, 127+8+1+3
		ld a, 0
		cpir
		//ld bc, 8+1+3+1
		ld bc, 127+8+1+3
		ld a, '.'
		cpdr
		//inc hl
		//inc hl

doAct.noDot	;jp nz, mainL5		; if no extension, skip
		;jp nz, viewSCR		; if no extension, treat as SCR
		;jp nz, viewHex		; if no extension, view with hexview
		jp nz, loadBAS		; if no extension, load as BASIC

doAct.yesDot	inc hl
		inc hl
		ex de, hl

doAct.compStr	ld a, (hl)
		or a
		;jp z, mainL5		; all other extensions skipped
		;jr z, viewSCR		; all other extensions treated as SCR
		;jp z, loadBAS		; all other extensions loaded as BASIC
		jp z, viewHex		; all other extensions viewed with hexview

		//call prStr
		//call waitKey
		//jp mainL2		; reprint all (top, mid, bottom and cursor)

		push de
		push hl
		ld b, 3
doAct.strcmp	ld a, (de)
		cp (hl)
		inc hl
		inc de
		jr z, doAct.otra

		dec hl
		sub 'a'-'A'		; insensitive comparation
		cp (hl)
		inc hl
		jr z, doAct.otra

		pop hl
		pop de
		ld bc, 5
		add hl, bc
		jr doAct.compStr

doAct.otra	djnz doAct.strcmp

		;
		; extension found!
		;
		pop hl
		pop de
		ld bc, 3
		add hl, bc

		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl

		jp (hl)

; *****************************************************************************

; -----------
; view screen
; -----------
;
viewSCR		ld hl, dbStrPathName	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		call fOpen

readSCR		ld hl, 16384		; dest
		ld bc, 6144+768		; size  ; 7*1024
		call fRead

		call fClose

		call waitKey

		jp page5.mainL2		; reprint all (top, mid, bottom and cursor)

; -----------------------
; view screen of SNA file
; -----------------------
;
viewSNA		ld hl, dbStrPathName	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		call fOpen

		ld bc, 0
		ld de, 27
		call fSeek		; skip SNA header

		jp readSCR

; -------
; hexview
; -------
;
; uses hexview dot command
;
viewHex		ld hl, bDName
		ld de, bDName3
		ld bc, 13
		ldir

		ld hl, dotCommHexview
		call fExecCMD	; Should not return

		jp page5.mainL1		; reload dir and reprint all

; -------------
; load sna, z80
; -------------
;
; uses snapload dot command
;
loadSNA		ld hl, dotCommSnapload
		call fExecCMD	; Should not return

		jp page5.mainL1		; reload dir and reprint all

; --------
; load tap
; --------
;
loadTAP		ld hl, dbStrPathName
		call fAttachTapeIn
		ld a, 0			; LOAD ""
		call fAutoLoad	; Should not return

		jp page5.mainL1		; reload dir and reprint all

; --------
; load BAS
; --------
;
loadBAS		;
		; Falla con la version v086b51
		;
		ld a, CUR_DRIVE		; current drive
		ld hl, dbStrPathName
		call fAutoLoad	; Should not return

		jp page5.mainL1		; reload dir and reprint all

; =============================================================================
; 'T', 'SS'+'T', 'CS'+'T' start TR-DOS Emulator --- revisado (startTRDOS)
; =============================================================================
;

; --------
; load TRD
; --------
;
loadTRD		;
		; attach TRD to drive A
		;
		ld a, $60		; virtual unit A
		call fEjectVDisk

		ld hl, dbStrPathName
		ld a, $60		; virtual unit A
		call fMountVDisk

startTRDOS	call ckMods
		ld a, (flagSS)
		or a
		jr nz, ldTRD01		; z no SS pressed, nz SS pressed
		ld a, (flagCS)
		or a
		jr nz, ldTRD02		; z no CS pressed, nz CS pressed

		; Enter
		;
		; Autoload from vdisk. If no boot, loads TR-DOS Navigator
		;
		ld a, $fd		; Autoload from vdisk, if no boot, loads TR-DOS Navigator
		call fAutoLoad		; Should not return

		jp page5.mainL1		; reload dir and reprint all

ldTRD02		; CS+Enter
		;
		; Enter TR-DOS mode
		;
		ld a, $fc		; Enter TR-DOS mode
		call fAutoLoad		; Should not return

		jp page5.mainL1		; reload dir and reprint all

; ----------
; load TR-DOS
; ----------
;
; 10 REM There must be a disk inserted in drive A
; 20 RANDOMIZE USR 15619: REM: LIST
; 30 CLEAR 31732
; 40 LOAD *"/SYS/TRDBOOT.BIN" CODE 31733
; 50 RANDOIMIZE USR 31733
;
ldTRD01		; SS+Enter
		;
		; load TR-DOS Navigator
		;

		ld a, SYS_DRIVE		; current drive
		ld hl, trdBas
		call fAutoLoad	; Should not return

		jp page5.mainL1		; reload dir and reprint all

; --------
; load ROM
; --------
;
; 10 CLEAR 49151
; 20 LOAD *"FILE.ROM"CODE 49152
; 30 .ownrom
;
loadROM		ld hl, dbStrPathName	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		call fOpen

		ld hl, 49152		; dest
		ld bc, 16384		; size
		call fRead

		call fClose

		ld hl, dotCommOwnrom
		call fExecCMD	; Should not return

		jp page5.mainL1		; reload dir and reprint all

; =============================================================================
; 'A'-'D' attach TRD to virtual disk --- revisado
; =============================================================================
;
trd2drv.start0	xor a
		jr trd2drv.trd2drv

trd2drv.start1	ld a, 1
		jr trd2drv.trd2drv

trd2drv.start2	ld a, 2
		jr trd2drv.trd2drv

trd2drv.start3	ld a, 3

trd2drv.trd2drv	ld (dbDrive), a		; proccess args
		add a, 'A'
		ld (unitLet), a

		ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, trd2drv.isFile

trd2drv.isDir	jp mainL5		; reprint nothing

trd2drv.isFile	ld hl, bDName
		ld bc, 8+1+3+1
		ld a, 0
		cpir
		ld bc, 8+1+3+1
		ld a, '.'
		cpdr
		inc hl
		inc hl

trd2drv.noDot	jp nz, mainL5		; reprint nothing

trd2drv.yesDot	ld (dwPtrExt), hl
		ld de, extTRD
		ex de, hl
		ld b, 3
trd2drv.strcmp	ld a, (de)
		cp (hl)
		inc hl
		inc de
		jr nz, trd2drv.chkSCL
		djnz trd2drv.strcmp
		jr trd2drv.attTRD

trd2drv.chkSCL	ld hl, extSCL
		ld de, (dwPtrExt)
		ex de, hl
		ld b, 3
trd2drv.strcmp2	ld a, (de)
		cp (hl)
		inc hl
		inc de
		jp nz, mainL5		; not TRD or SCL, reprint nothing
		djnz trd2drv.strcmp2

trd2drv.attTRD	ld a, (dbDrive)
		add a, a
		add a, a
		add a, a
		or $60
		call fEjectVDisk

		ld hl, bDName		//bDName2
		ld a, (dbDrive)
		add a, a
		add a, a
		add a, a
		or $60
		call fMountVDisk

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgOk
		call prStr
		call waitKey

trd2drv.retMnt	jp mainL4		; reprint bottom and cursor

; =============================================================================
; 'E','DEL' delete file/dir  --- revisado
; =============================================================================
;
delFile.start	ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgOkDel
		call prStr
		;
		; confirm delete
		;
		call waitKey
		cp 'Y'
		jp nz, mainL4		; reprint bottom and cursor
		;
		ld hl, msgDel
		call prStr

		ld hl, bDName
		ld de, bDName2
		ld bc, 13
		ldir

		ld hl, dotCommRm
		call fExecCMD

		jp mainL1		; reload dir and reprint all

; =============================================================================
; 'SS'+'F' fast-ramp config --- revisado
; =============================================================================
;
fastcfg.start	ld a, (bDAttr)
	        and A_DIR		; check if is dir
        	jr z, fastcfg.isFile

fastcfg.isDir  	jp mainL5		; reprint nothing

fastcfg.isFile  ld bc, 1*256+23   	; 1 line from line 23
        	ld a, COL_BOT     	; color
        	call clrScr

        	ld hl, msgSaveFC
        	call prStr

        	ld hl, dbFnFastFile	; asciiz string containg path and/or filename
        	ld b, FA_CREATE_AL|FA_WRITE
                                	; create if not exists, else open and truncate
                                	; read access
        	ld a, SYS_DRIVE		; system/boot drive
        	call fOpen1

fastcfg.getCDrv	call fGetSetDrv1	; get current drive
        	ld hl, drvName
        	call convDrv
        	ld hl, drvName		; dest
        	ld bc, 4
        	call fWrite

fastcfg.getCWD 	ld hl, dbStrPathName
        	call fGetCWD

        	ld hl, dbStrPathName
        	xor a
        	ld bc, 128
        	cpir
        	ld a, 127
        	sub c
        	ld c, a
        	ld hl, dbStrPathName	; dest
        	call fWrite

        	ld hl, bDName
        	xor a
        	ld bc, 8+1+3+1
        	cpir
        	ld a, 8+1+3+1-1
        	sub c
        	ld c, a
        	ld hl, bDName		; dest
        	call fWrite

        	call fClose

		jp mainL1		; reload dir and reprint all

; =============================================================================
; 'F' fast-ramp load --- revisado
; =============================================================================
;
fastLoad.start	ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgFile
		call prStr		; LOADING FILE...

		ld hl, dbFnFastFile	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, drvName		; dest
		ld bc, 4		; size
		call fRead

		ld hl, dbStrPathName	; dest
		ld bc, 127+8+1+3	; size
		call fRead

		xor a
		ld (hl), a		; null terminate string

		call fClose

fastLoad.chgDrv	ld a, (drvName)
		sub 'a'-1
		and %00011111
		rlca
		rlca
		rlca
		ld b, a
		ld a, (drvName+2)
		and %00000111
		or b
		call fGetSetDrv		; change drive

fastLoad.updDrv	call fGetSetDrv1	; get current drive

		ld hl, drvName
		call convDrv

		//ld de, dbdwTbExtAct
		//jp doAct.exeAction
		jp doAct.exeAction1

; =============================================================================
; 'G' debug --- revisado
; =============================================================================
;
debug.start	ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgStat
		call prStr

		ld hl, dotCommMon
		call fExecCMD	; (should not return)

		jp mainL1		; reload dir and reprint all

; =============================================================================
; 'H' help --- revisado, view_SCR tiene un ret, viewSCR un jp mainL2. REMODELAR?
; =============================================================================
;
help.start	ld sp, NMI_STACK		; necessary to use MACROS
		JUMPPG 6, page6.help

; =============================================================================
; 'I',''SS'+'I' tapein --- revisado
; =============================================================================
;
tapein.start	call ckMods
		ld a, (flagSS)
		or a
		jr z, tapein.attach	; z no SS pressed, nz SS pressed

tapein.detach	call fDetachTapeIn

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgDetIn
		call prStr
		call waitKey

		jp mainL4		; reprint bottom and cursor

tapein.attach	ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, tapein.isFile

tapein.isDir	jp mainL5		; reprint nothing

tapein.isFile	ld hl, bDName
		call fAttachTapeIn

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgAttIn
		call prStr
		call waitKey

		jp mainL4		; reprint bottom and cursor

; =============================================================================
; 'J' load old NMI handler --- revisado
; =============================================================================
;
loadOld.start	call restoreScreen
		call deleteScreen

		ld hl, (NMIbuf_org)
		ld (copyHL), hl
		ld hl, (savedSP)
		ld (copySP), hl

		ld a, (esxDOSv)
		ld (fnv), a

		ld hl, loader
		ld de, BACKED_UP_RAM	; $5b00
		ld bc, loaderEnd-loader
		ldir

		jp BACKED_UP_RAM	; $5b00

		; No permite DISP anidados

fn_reloc	EQU BACKED_UP_RAM+fn-loader
fh_reloc	EQU BACKED_UP_RAM+fh-loader
hl_reloc	EQU BACKED_UP_RAM+copyHL-loader
sp_reloc	EQU BACKED_UP_RAM+copySP-loader
loadOld_reloc	EQU BACKED_UP_RAM+loadOld-loader

loader		;
		; loader runs at address MEM_TEST $5b00
		;

		ld sp, NMI_STACK	; $5c00

		//ld hl, loadOld_reloc	;
		//push hl		;
		//RETPG0		; return to page 0
		JUMPPG 0, loadOld_reloc

loadOld		//
		// these system calls should be as is, not change
		//
		ld hl, fn_reloc		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system drive
		rst $08			;
		db F_OPEN		; open file
		ld (fh_reloc), a	; file handle

		ld hl, NMI_OVERLAY	; $2f00
		ld bc, NMI_SIZE		; $0e00
		ld a, (fh_reloc)	; file handle
		rst $08			;
		db F_READ		; read buffer from file

		ld a, (fh_reloc)	; file handle
		rst $08			;
		db F_CLOSE		; close file

		di
		ld sp, (sp_reloc)
		ld hl, (hl_reloc)
		jp NMI_OVERLAY		; $2f00

; ---------
; variables
; ---------
;
fn		DB '/SYS/NMI/OLD08'
fnv		DB '5.SYS',0
fh		DB 0
copyHL		DW 0
copySP		DW 0

loaderEnd	EQU $

; =============================================================================
; 'K' configure navigation keys --- revisado
; =============================================================================
;
config.start	ld a, $ff
		ld (ldConf), a			; force reload config

		ld sp, NMI_STACK		; necessary to use MACROS
		JUMPPG 6, page6.config

; =============================================================================
; 'L' lock paging register --- revisado
; =============================================================================
;

/* ----------------------------------------------------------------------------
  The additional memory features of the 128K/+2 are controlled to by writes to
  port 0x7ffd

  Bits 0-2: RAM page (0-7) to map into memory at 0xc000.
  Bit 3: Select normal (0) or shadow (1) screen to be displayed. The normal
         screen is in bank 5, whilst the shadow screen is in bank 7. Note that
         this does not affect the memory between 0x4000 and 0x7fff, which is
         always bank 5.
  Bit 4: ROM select. ROM 0 is the 128k editor and menu system; ROM 1 contains
         48K BASIC.
  Bit 5: If set, memory paging will be disabled and further output to this port
         will be ignored until the computer is reset.

  Like -l option of SNAPload dot command
---------------------------------------------------------------------------- */

lock.start	ld a, (flgLOCK)
		or a
		jp z, mainL5		; reprint nothing

		ld a, (speccyRAM)
		cp 2
		jp nz, mainL5		; reprint nothing
		xor a
		ld (flgLOCK), a

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgLocking
		call prStr

		ld a, %00110000		; paging register locked, ROM 1 selected
		ld bc, $7ffd
		out (c), a

		jp mainL1		; reprint bottom and cursor

; =============================================================================
; 'N' rename file --- revisado
; =============================================================================
;
rename.start	ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgNewN
		call prStr
		;
		; enter new name
		;
		ld b, 12
		ld hl, dbFnNewFileName
renL2		push bc
		push hl
		call waitKey
		pop hl
		pop bc
		cp K_BREAK
		jp z, mainL4		; BREAK, reprint bottom and cursor
		cp K_ENTER
		jr z, renL3		; ENTER
		cp K_DELETE
		jr nz, renL4		; DEL
		ld a, b
		cp 12
		jr z, renL2
		inc b
		dec hl
		ld a, (col)
		dec a
		ld (col), a
		ld a, ' '		;
		push bc			;
		push hl			;
		call pr_64		;
		pop hl			;
		pop bc			; print a space at cursor position
		jr renL2
renL4		cp $80			; SPECIAL KEYS
		jr nc, renL2
		cp ' '			; SPECIAL KEYS
		jr c,  renL2
		;
		ld c, a
		ld a, b
		or a
		ld a, c
		jr z, renL2
		;
		ld (hl), a
		inc hl
		;
		push bc
		push hl
		call prChr
		pop hl
		pop bc
		;
		dec b
		jr renL2
		;
renL3		xor a
		ld (hl), a		; null terminate name string
		;
		ld hl, bDName		; asciiz string containg source path and/or filename
		ld de, dbFnNewFileName	; asciiz string containg target path and/or filename
		call fRename

		jp mainL1		; reload dir and reprint all

; =============================================================================
; 'O','SS'+'O' tapeout --- revisado
; =============================================================================
;
tapeout.start	call ckMods
		ld a, (flagSS)
		or a
		jr z, tapeout.attach	; z no SS pressed, nz SS pressed

tapeout.detach	call fDetachTapeOut

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgDetOut
		call prStr
		call waitKey

		jp mainL4		; reprint bottom and cursor

tapeout.attach	ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, tapeout.isFile

tapeout.isDir	jp mainL5		; reprint nothing

tapeout.isFile	ld hl, bDName
		call fAttachTapeOut

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgAttOut
		call prStr
		call waitKey

		jp mainL4		; reprint bottom and cursor

; =============================================================================
; 'P' poke --- revisado
; =============================================================================
;
; try a FSM? at first it seems that it may need more code...

poke.start	ld hl, 0
		ld (pokeAdd), hl
		ld (pokeVal), hl
		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgPok1
		call prStr

		;
		; get poke
		;
		;
		; get address
		;
		ld hl, dbStrPokeValue
		ld b, 5
pokeG0		push hl
		push bc
		call waitKey
		pop bc
		pop hl
		cp K_BREAK		; BREAK
		jp z, retPoke
		cp ','
		jr z, pokeG3		; ','

		cp K_DELETE
		jr nz, pokeG2		; DEL
		ld a, b
		cp 5
		jr z, pokeG0
pokeG1		inc b
		dec hl
		push bc
		push hl
		ld hl, col
		dec (hl)
		ld a, ' '		;
		call pr_64		; print a space at cursor position
		pop hl
		pop bc
		jr pokeG0

pokeG2		cp '0'
		jr c, pokeG0		;
		cp '9'+1		;
		jr nc, pokeG0		; key between 0 and 9
		;
		ld c, a
		ld a, b
		or a
		ld a, c
		jr z, pokeG0
		;
		ld (hl), a
		inc hl
		dec b
		;
		push hl
		push bc
		call prChr
		pop bc
		pop hl
		;
		jr pokeG0
		;
pokeG3		ld a, ','		;
		;                       ;
		ld (hl), a		;
		inc hl			; OPTIMIZAR
		;
		push hl
		call prChr
		pop hl
		;
		; get value
		;
		ld b, 3
pokeG4		push hl
		push bc
		call waitKey
		pop bc
		pop hl
		cp K_BREAK		; BREAK
		jp z, retPoke
		cp K_ENTER
		jr z, pokeG7		; ENTER

		cp K_DELETE
		jr nz, pokeG6		; DEL
		ld a, b
		cp 3
		jr nz, pokeG5
		ld b, $ff
		jr pokeG1
pokeG5		inc b
		dec hl
		push bc
		push hl
		ld hl, col
		dec (hl)
		ld a, ' '		;
		call pr_64		; print a space at cursor position
		pop hl
		pop bc
		jr pokeG4

pokeG6		cp '0'
		jr c, pokeG4		;
		cp '9'+1		;
		jr nc, pokeG4		; key between 0 and 9
		;
		ld c, a
		ld a, b
		or a
		ld a, c
		jr z, pokeG4
		;
		ld (hl), a
		inc hl
		dec b
		;
		push hl
		push bc
		call prChr
		pop bc
		pop hl
		;
		jr pokeG4

pokeG7		xor a
		ld (hl), a		; null terminate string

		;
		; convert
		;
		;
		; convert address
		;
		ld hl, dbStrPokeValue
pokeC0		ld a, (hl)
		cp ','
		jr z, pokeC1
		;
		push hl
		ld hl, (pokeAdd)
		add hl, hl
		ld d, h
		ld e, l
		add hl, hl
		add hl, hl
		add hl, de
		sub '0'
		ld d, 0
		ld e, a
		add hl, de
		ld (pokeAdd), hl
		pop hl
		;
		inc hl
		jr pokeC0
		;
pokeC1		inc hl
		;
		; convert value
		;
pokeC2		ld a, (hl)
		or a
		jr z, pokeC3		; NULL
		;
		push hl
		ld hl, (pokeVal)
		add hl, hl
		ld d, h
		ld e, l
		add hl, hl
		add hl, hl
		add hl, de
		sub '0'
		ld d, 0
		ld e, a
		add hl, de
		ld (pokeVal), hl
		pop hl
		;
		inc hl
		jr pokeC2
pokeC3		;
		; confirm poke
		;
		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgPok2
		call prStr
		ld hl, (pokeAdd)
		call utoa
		ld hl, msgPok3
		call prStr
		ld hl, (pokeVal)
		ld h, 0
		call utoa
		ld hl, msgPok4
		call prStr
		;
		call waitKey
		cp 'Y'
		jr nz, retPoke
		;
		call restoreScreen
		;
		ld a, (pokeVal)
		ld hl, (pokeAdd)
		ld (hl), a
		;
		call saveScreen
		;
retPoke		jp mainL2		; reprint all (top, mid, bottom and cursor)

; =============================================================================
; 'R' reset --- revisado
; =============================================================================
;
; taken from NMI.sys of ub880d

reset.start	ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgReseting
		call prStr

		di
		ld sp, (savedSP)
		ld a, $fe		; a = $fe reset
		call fAutoLoad	; (should not return)

		jp mainL1		; reload dir and reprint all

; =============================================================================
; 'S' save snapshot --- revisado
; =============================================================================
;
savSNA.start	ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgSave
		call prStr

		; check if file exists

savSNA.fileExt	ld hl, dbFnSnapName	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; Open if exists, else error
					; Read access
		ld a, CUR_DRIVE		; current drive
		rst $08			;
		db F_OPEN		; open file
		jr c, savSNA.saveL1	; file don't exists
		call fClose		; file exists
		;
		; increments file name
		;
		; e.g. SNAP0000.SNA -> SNAP0001.SNA and so on
		;
		ld hl, dbFnSnapName+7
		ld b, 4
savSNA.saveL0	ld a, (hl)
		inc a
		ld (hl), a
		cp '9'+1
		jr nz, savSNA.fileExt
		ld a, '0'
		ld (hl), a
		dec hl
		djnz savSNA.saveL0

savSNA.saveL1	call restoreScreen

		ld hl, dbFnSnapName	; asciiz string containg path and/or filename
		ld b, FA_CREATE_NEW|FA_WRITE
					; create if not exists, if exists error
					; write access
		call fOpen

		; SNA 48k

		ld hl, NMIbuf		; source
		ld bc, 27		; size
		call fWrite

		ld hl, 16384		; source
		ld bc, 49152		; size
		call fWrite

		ld a, (speccyRAM)	; check if 128k machine
		cp 2
		jr nz, savSNA.saveL4

		; SNA 128k

; Version       RAM SIZE        PC      RAM pg act      TR-DOS
; 0.8.5         +30             +27     +29             +30
; 0.8.6         +27             +28     +30             +31

		ld hl, NMIbuf		; source
		ld de, 27
		ld a, (esxDOSv)
		cp '5'
		jr z, savSNA.v085_L1
		ld de, 28
savSNA.v085_L1	add hl, de
		ld bc, 4		; size
		call fWrite

		; Save RAM pages. Taken from NMI.sys of ub880d

		ld hl, NMIbuf		; source
		ld de, 29
		ld a, (esxDOSv)
		cp '5'
		jr z, savSNA.v085_L2
		ld de, 30
savSNA.v085_L2	add hl, de

		ld a, (hl)		; NMI_BUFFER+30: RAM bank paged in @ $c000
		push af
		ld bc, $7FFD
		out (c), a
		ld b, $10		; Select ROM 1, contains 48K BASIC
		or b
		ld c, a
		ld a, b
savSNA.saveL2	cp $12			; discard RAM bank 2
		jr z, savSNA.saveL3
		cp $15			; discard RAM bank 5
		jr z, savSNA.saveL3
		cp c			; discard RAM bank paged in @ $c000
		jr z, savSNA.saveL3
		push bc
		ld bc, $7FFD		; select RAM bank
		out (c), a		; page RAM bank
		ld hl, 49152
		ld bc, 16384
		call fWrite		; OJO, hay 2 bytes en la pila
		pop bc
savSNA.saveL3	inc b
		ld a, b
		cp $18
		jr nz, savSNA.saveL2	; repeat for all RAM banks

		;

savSNA.saveL4	pop af			;
		ld bc, $7FFD		;
		out (c), a		; repage original bank

		call fClose

		jp mainL1		; reload dir and reprint all

; =============================================================================
; 'U' change current drive (cycling) --- revisado
; =============================================================================
;
seldrv.start	call fGetSetDrv1	; get current drive
		inc a			; try to change to next drive

		rst $08
		db M_GETSETDRV
		jp nc, seldrv.noErr	; if no error, print drive name and exit

		call findDrv
		call fGetSetDrv

seldrv.noErr	ld hl, drvName
		call convDrv

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgOkSelDrv
		call prStr
		call waitKey

		jp mainL1		; reload dir and reprint all

; =============================================================================
; 'V', 'SS'+'V' view screen SCR SNA --- revisado
; =============================================================================
;
view.start	ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, view.isFile

view.isDir	jp mainL5		; reprint nothing

view.isFile	ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgFile
		call prStr		; LOADING FILE...

		ld hl, bDName		;
		ld de, dbStrPathName	;
		ld bc, 8+1+3+1		;
		ldir			; copy filename

		ld de, dbdwTbExtView
		jp doAct.exeAction

