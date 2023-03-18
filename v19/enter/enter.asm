;==============================================================================
; Project: enter.zdsp
; Main File: enter.asm
; Date: 18/09/2017 10:43:17
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin enter.asm enter
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; ---------------------
; do action over cursor
; ---------------------
;
doAct		ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, isFile

isDir		ld hl, bDName
		call fChDir
		;
		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgDir
		call prStr
		;
		ld a, 0ffh		;
		ld (ldDir), a		;
		;
		ld a, 1			; reload dir and reprint all
		ret

isFile		ld hl, bDName
		ld bc, 8+1+3+1
		ld a, 0
		cpir
		ld bc, 8+1+3+1
		ld a, '.'
		cpdr
		inc hl
		inc hl

noDot		;ld      a, 5            ; reprint nothing
		;ret     nz
		;jr      nz, view        ; hexview
		jp nz, loadBAS		; load as BASIC

yesDot		ld de, extTbl
		ex de, hl

compStr		ld a, (hl)
		or a
		;ld      a, 5            ; reprint nothing
		;ret     z
		jr z, view

		push de
		push hl
		ld b, 3
strcmp		ld a, (de)
		cp (hl)
		inc hl
		inc de
		jr z, otra
		pop hl
		pop de
		ld bc, 5
		add hl, bc
		jr compStr

otra		djnz strcmp

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgFile
		call prStr

		pop hl
		pop de
		ld bc, 3
		add hl, bc

		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl

		jp (hl)

; -------------
; load sna, z80
; -------------
;
; uses snapload dot command
;
loadSNA		ld hl, bDName
		ld de, bDName2
		ld bc, 13
		ldir

		ld hl, snapload
		call fExecCMD

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

; -------
; hexview
; -------
;
; uses hexview dot command
;
view		ld hl, bDName
		ld de, bDName3
		ld bc, 13
		ldir

		ld hl, hexview
		call fExecCMD

		ld a, 2			; reprint all (top, mid, bottom and cursor)
		ret

; --------
; load tap
; --------
;
loadTAP		ld b, 0
		ld hl, bDName
		call fTapeIn
		ld a, 0
		call fAutoLoad

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

; -----------
; view screen
; -----------
;
viewSCR		ld hl, bDName		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		call fOpen

		ld hl, 16384		; dest
		ld bc, 6144+768		; size  ; 7*1024
		call fRead

		call fClose

		call waitKey

		ld a, 2			; reprint all (top, mid, bottom and cursor)
		ret

; --------
; load BAS
; --------
;
loadBAS		;
		; Falla con la version v086b51
		;
		ld a, CUR_DRIVE		; current drive
		ld hl, bDName
		call fAutoLoad

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

; --------
; load TRD
; --------
;
loadTRD		;
		; attach TRD to drive A
		;
		ld a, $60		; virtual unit A
		rst $08
		db $85			; EJECT VDISK
		;jr      c, retMnt      ; error if no disk attached, ignore it

		ld hl, bDName
		ld a, $60		; virtual unit A
		ld de, buffer		; BUFFER
		ld b, 0
		ld c, CUR_DRIVE		; current drive
		rst $08
		db DISK_STATUS		; MOUNT VDISK   ; $80
		;jr      c, retLoad
		jp c, printError

		call ckMods
		ld a, (flagSS)
		or a
		jr nz, ldTRD01		; z no SS pressed, nz SS pressed
		ld a, (flagCS)
		or a
		jr nz, ldTRD02		; z no CS pressed, nz CS pressed

		; Enter
		;
		; Autoload from vdisk, if no boot, loads TR-DOS Navigator
		;
		;ld      a, $fe          ; reset
		;ld      a, $fc          ; Enter TR-DOS mode
		ld a, $fd		; Autoload from vdisk, if no boot, loads TR-DOS Navigator
		call fAutoLoad

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

ldTRD02		; CS+Enter
		;
		; Enter TR-DOS mode
		;
		ld a, $fc		; Enter TR-DOS mode
		call fAutoLoad

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

ldTRD01		; SS+Enter
		;
		; tapein TR-DOS Navigator
		;
		ld b, 0			; in_open
					; Attaches .tap file
					; A=drive
					; HL=Pointer to null-terminated string containg path and/or filename
		ld hl, TRDNtap
		ld a, SYS_DRIVE		; system/boot drive
		rst $08
		db M_TAPEIN
		jp c, printError

		;
		; autoload attached .tap file (TRDN.tap)
		;
		ld a, 0			; LOAD ""
		call fAutoLoad

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

; --------
; load ROM
; --------
;
; 10 CLEAR 49151
; 20 LOAD *"FILE.ROM"CODE 49152
; 30 .ownrom
;
loadROM		ld hl, bDName		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		call fOpen

		ld hl, 49152		; dest
		ld bc, 16384		; size
		call fRead

		call fClose

		ld hl, ownrom
		call fExecCMD

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

		_FEXECCMD
		_FTAPEIN
		_FAUTOLOAD

; --------
; messages
; --------
;
msgDir		db $16,23,1,'LOADING DIRECTORY...',0
msgFile		db $16,23,1,'LOADING FILE...',0

; -----------------
; ext actions table
; -----------------
;
extTbl		db 'SNA'
		dw loadSNA
		db 'TAP'
		dw loadTAP
		db 'Z80'
		dw loadSNA
		db 'SCR'
		dw viewSCR
		db 'TRD'
		dw loadTRD
		db 'BAS'
		dw loadBAS
		db 'ROM'
		dw loadROM
		db 0

; ------------------------------
; dot command for load snapshots
; ------------------------------
;
snapload
		db 'SNAPLOAD '
bDName2		db '12345678.123', 0

hexview		db 'HEXVIEW '
bDName3		db '12345678.123', 0

ownrom		db 'OWNROM', 0

;-------------------
; load TRD variables
;-------------------
;
TRDNtap		db '/sys/nmi/TRDN.tap',0

;-------------------
; buffer lo load TRD
;-------------------
;
buffer		equ $

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

		end

