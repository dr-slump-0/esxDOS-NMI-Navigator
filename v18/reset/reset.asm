;==============================================================================
; Project: reset.zdsp
; Main File: reset.asm
; Date: 30/10/2017 10:02:04
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

; -----
; reset
; -----
;
; taken from NMI.sys of ub880d
;
reset		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msg0001
		call prStr

		di			; VER DONDE UBICAR LOS EI Y LOS DI !!!
		ld sp, (savedSP)
		ld a, $fe
		rst $08
		db M_AUTOLOAD

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

; --------
; messages
; --------
;
msg0001		db $16,23,1,'RESETING...',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

