;==============================================================================
; Project: rename.zdsp
; Main File: rename.asm
; Date: 14/09/2017 18:57:15
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin rename.asm rename
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; -----------
; rename file
; -----------
;
rename		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgNewN
		call prStr
		;
		; enter new name
		;
		ld b, 12
		ld hl, dfname
renL2		push bc
		push hl
		call waitKey
		pop hl
		pop bc
		cp K_BREAK
		jr z, retRen		; BREAK
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
		ld de, dfname		; asciiz string containg target path and/or filename
		call fRename
		ld a, 1			; reload dir and reprint all
		ret
retRen		ld a, 4			; reprint bottom and cursor
		ret

		_FRENAME

; --------
; messages
; --------
;
msgNewN		db $16,23,1, 'NEW NAME? ',0

; -----------------------------
; variables for rename function
; -----------------------------
;
dfname		db '12345678.123',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

