;==============================================================================
; Project: reload.zdsp
; Main File: init.asm
; Date: 02/10/2017 11:29:11
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; ------
; reload
; ------
;
reload		;
		;  Get CWD
		;
		call getCWD

		ld a, (ldDir)		;
		or a			;
		jr nz, doInit		; first time we call NMI navigator

		;
		; Compare old WD with CWD
		;
		call testWD
		jr z, initL2		; current working directory not changed
					; preserves previous navigation page and line

doInit		xor a
		ld (ldDir), a
		;
		; Init navigator variables
		;
		ld hl, 0
		ld (curLn), hl
		ld (Xof),hl
		;
		; Obtain number of dir entries
		;
		call calcNumDirEntries

initL2		;
		; Show CWD
		;
		call copyWD
		;
		; Show lock status
		;
		ld a, (flg128k)
		cp 2
		jr nz, L2

		ld hl, msgUnlo		; UNLOCK
		ld bc, 8
		ld a, (flgLOCK)
		or a
		jr nz, L1
		ld hl, msgUnlo+2	; LOCK
		ld bc, 8

L1		ld de, msgLock
		ldir

L2		;xor     a               ; return (continues normal workflow)
		ld a, 2			; return to mainL2 (reprint all)
		ret

; -----------------------------
; get current working directory
; -----------------------------
;
getCWD		;
		; get drive
		;
		xor a			; default drive
		rst $08
		db M_GETSETDRV		; get current drive

		;
		; pretty printer for drive
		;
		ld hl, drvBuf
		push af			; converts current drive to 'hd0' format
		and %11111000
		rrca
		rrca
		rrca
		add a, 'a'-1
		ld (hl), a
		inc hl
		inc hl
		pop af
		and %00000111
		add a, '0'
		ld (hl), a

		;
		; get CWD
		;
		ld hl, cwdBuf
		call fGetCWD

		;
		; pretty printer for CWD
		;
		xor a
		ld (flgROOT), a		; reset some flags
		ld bc, 128
		ld hl, cwdBuf+1		; skip initial '/'
		cpir			; search end of string
		ld a, 128
		sub c			; calculates string length
		cp 2			; greater or equal than 2 cols -> greater than 1 cols
		jr nc, notRoot		; if less than 1 -> root directory
		ld (flgROOT), a

notRoot		cp 58			; 64 minus 2 (margins) minus 5 ('hd0:/') plus 2 (cpir) = 59 cols
		jr c, itsOk		; less than 59 cols -> less or equal than 58 cols

		ld a, 58		; crop string to 58 cols

itsOk		or a			; clear CF
		ld d, 0
		ld e, a
		sbc hl, de		; set hl to the beginning of string

		cp 58
		jr nz, noCrop
		;ld      (hl), $81       ; '..'
		ld (hl), '.'
		inc hl
		ld (hl), '.'
		inc hl
		ld (hl), '.'
		dec hl
		dec hl			; set hl to the beginning of string
		;
		; crop string
		;
		ld de, cwdBuf+1
		ld b, 0
		ld c, a
		ldir

noCrop		add a, 5
		ld (strLen), a
		ret

; --------------------------------------
; copy drive and CWD to top message area
; --------------------------------------
;
copyWD		ld hl, drvBuf
		ld de, msgDrv
		ld a, (strLen)
		ld b, 0
		ld c, a
		ldir
		;
		ret

; ------------------------------------------
; compare old working directory with current
; ------------------------------------------
;
testWD		ld hl, drvBuf
		ld de, msgDrv
		ld b, 0
		ld a, (strLen)
		ld b, a
testWD1		ld a, (de)
		inc de
		cpi
		ret nz			; ZF=0 (NZ) -> not the same
		djnz testWD1
		ld a, b
		or a			; ZF=1 (Z) -> si B=0 -> end of string
		ret

; ------------------------------------------
; calculate number of entries on current dir
; ------------------------------------------
;
calcNumDirEntries
		call fOpenDir

		ld hl, 0
nDirL0		push hl
		call fReadDir
		pop hl
		jr c, nDirL1
		or a			;
		jr z, nDirL1		; a==0 if end of dir
		inc hl
		ld de, MAXENTR		;
		ld a, h			;
		cp d			;
		jr nz, nDirL0		;
		ld a, l			;
		cp e			;
		jr nz, nDirL0		; limit to pTable2 max dir entries
		;jr      nDirL0

nDirL1		;or      a               ; clear CF
		;ld      de, MAXENTR
		;sbc     hl, de
		;add     hl, de
		;jr      c, nDirL2
		;ex      de, hl          ; limit to pTable2 max dir entries
nDirL2		ld (ofY), hl

		ld a, (fhandle)
		rst $08
		db F_REWINDDIR
		jp c, printError

		call fTellDir
		;ld      (pTable), bc
		;ld      (pTable+2), de
		ld a, c
		ld (pTable), a
		ld (pTable+1), de

		call fClose

		ret

		_FGETCWD

; --------
; messages
; --------
;
msgUnlo		db 'UNLOCKED  '

; ---------
; variables
; ---------
;
drvBuf		db ' d :'
cwdBuf		ds 128,0

strLen		db 0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

