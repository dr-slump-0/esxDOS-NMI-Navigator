;==============================================================================
; Project: tapein.zdsp
; Main File: tapein.asm
; Date: 20/09/2017 19:11:17
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin tapein.asm tapein
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; ------
; tapein
; ------
;
tapein		call ckMods
		ld a, (flagSS)
		or a
		jr z, attach		; z no SS pressed, nz SS pressed

detach		ld b, 1			; in_close
					; No args, just closes and detaches .tap file
		rst $08
		db M_TAPEIN

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

isFile		ld b, 0			; in_open
					; Attaches .tap file
					; A=drive
					; HL=Pointer to null-terminated string containg path and/or filename
		ld hl, bDName
		ld a, CUR_DRIVE		; current drive
		rst $08
		db M_TAPEIN

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
msgAtt		db $16,23,1, 'TAP ATTACHED TO INPUT, PRESS ANY KEY',0
msgDet		db $16,23,1, 'TAP DETACHED FROM INPUT, PRESS ANY KEY',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

