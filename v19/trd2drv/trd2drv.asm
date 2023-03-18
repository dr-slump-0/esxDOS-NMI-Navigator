;==============================================================================
; Project: trd2drv.zdsp
; Main File: trd2drv.asm
; Date: 20/09/2017 19:12:49
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin trd2drv.asm trd2trv
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; --------------------------
; attach TRD to virtual disk
; --------------------------
;
trd2drv		ld (unit), a		; proccess args
		add a, 'A'
		ld (unitLet), a

		ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, isFile

isDir		ld a, 5			; reprint nothing
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

noDot		ld a, 5			; reprint nothing
		ret nz

yesDot		ld de, extTRD
		ex de, hl
		ld b, 3
strcmp		ld a, (de)
		cp (hl)
		inc hl
		inc de
		ld a, 5			; reprint nothing
		ret nz
		djnz strcmp

isTRD		ld hl, bDName
		ld de, bDName2
		ld bc, 13
		ldir

attTRD		ld a, (unit)
		add a, a
		add a, a
		add a, a
		or $60
		rst $08
		db $85			; EJECT VDISK
		;jr      c, retMnt      ; error if no disk attached, ignore it

		ld hl, bDName2
		ld a, (unit)
		add a, a
		add a, a
		add a, a
		or $60
		ld de, buffer		; BUFFER
		ld b, 0
		ld c, CUR_DRIVE		; current drive
		rst $08
		db DISK_STATUS		; MOUNT VDISK   ; $80
		jr c, retMnt

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgOk
		call prStr
		call waitKey

retMnt		ld a, 4			; reprint bottom and cursor
		ret

; --------
; messages
; --------
;
msgOk		db $16,23,1, 'TRD ATTACHED TO UNIT '
unitLet		db 'A, PRESS ANY KEY',0

; ---------
; variables
; ---------
;
extTRD		db 'TRD'
unit		db 0
bDName2		db '12345678.123', 0
buffer		equ $

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

