;==============================================================================
; Project: seldrv.zdsp
; Main File: seldrv.asm
; Date: 02/11/2017 18:58:17
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

; ------------------------------
; change current drive (cycling)
; ------------------------------
;
seldrv		xor a			; default drive
		rst $08
		db M_GETSETDRV
		inc a			; try to change to next drive

		rst $08
		db M_GETSETDRV
		jp nc, noErr		; if no error, print drive name and exit

		call findDrv
		rst $08
		db M_GETSETDRV		; if error, change to system/boot drive

noErr		ld hl, drvName
		call convDrv

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgOk
		call prStr

		ld a, 1			; reload dir and reprint all
		ret

;
; search first drive unit (system/boot) testing all ones from 1 to 255
;
findDrv		ld a, 1
Otro		or a
		ret z			; end reached, not found drive unit
		cp SYS_DRIVE
		jr z, Nuevo		; skip system/boot drive
		cp CUR_DRIVE
		jr z, Nuevo		; skip default drive
		ld b, a
		rst $08
		db M_GETSETDRV
		ld a, b
		ret nc			; if CF=0 find first drive unit
Nuevo		inc a
		jr Otro

;
; converts drive number to 'hd0' format
;
convDrv		push af
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
		ret

; --------
; messages
; --------
;
msgOk		db $16,23,1,'SET DEFAULT DRIVE TO '
drvName		db 'hd0...',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

