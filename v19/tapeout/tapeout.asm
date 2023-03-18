;==============================================================================
; Project: tapeout.zdsp
; Main File: tapeout.asm
; Date: 20/09/2017 19:14:49
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin tapeout.asm tapeout
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; -------
; tapeout
; -------
;
tapeout		call ckMods
		ld a, (flagSS)
		or a
		jr z, attach		; z no SS pressed, nz SS pressed

detach		ld b, 1			; out_close
					; No args, just closes and detaches .tap file
		rst $08
		db M_TAPEOUT

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgDet
		call prStr
		call waitKey

		ld a, 4			; reprint bottom and cursor
		ret

attach		ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, isFile

isDir		ld a, 5			; reprint nothing
		ret

isFile		ld b, 0			; out_open
					; Creates/opens .tap file for appending
					; A=drive
					; HL=Pointer to null-terminated string containg path and/or filename
		ld hl, bDName
		ld a, CUR_DRIVE		; current drive
		rst $08
		db M_TAPEOUT

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgAtt
		call prStr
		call waitKey

		ld a, 4			; reprint bottom and cursor
		ret

; --------
; messages
; --------
;
msgAtt		db $16,23,1, 'TAP ATTACHED TO OUTPUT, PRESS ANY KEY',0
msgDet		db $16,23,1, 'TAP DETACHED FROM OUTPUT, PRESS ANY KEY',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

