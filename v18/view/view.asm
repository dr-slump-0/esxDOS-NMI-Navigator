;==============================================================================
; Project: view.zdsp
; Main File: view.asm
; Date: 18/09/2017 10:14:21
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin view.asm view
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; -------------------
; view screen SCR SNA
; -------------------
;
view		ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, isFile

isDir		ld a, 5			; reprint nothing
		ret

isFile		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgFile
		call prStr

		ld hl, bDName
		ld bc, 8+1+3+1
		ld a, 0
		cpir
		ld bc, 8+1+3+1
		ld a, '.'
		cpdr
		inc hl
		inc hl

noDot		;ret     nz              ; a!=(hl)
		;jr      nz, viewSCR     ; if no extension, treat as SCR
		jr nz, viewHex

yesDot		ld de, extTbl
		ex de, hl

compStr		ld a, (hl)
		or a
		;ret     z               ; all extensions tested
		;jr      z, viewSCR      ; all other extensions treated as SCR
		jr z, viewHex

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
		jr compStr		; next extension

otra		djnz strcmp		; test current extension

		;
		; extension found!
		;

		ld bc, 24*256+0
		ld a, COL_MID
		call clrScr

		pop hl
		pop de
		ld bc, 3
		add hl, bc

		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl

		jp (hl)

		_FEXECCMD


; -----------------------
; view screen of SCR file
; -----------------------
;
viewSCR		ld hl, bDName		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		call fOpen

readSCR		ld hl, 16384		; dest
		ld bc, 6144+768		; size  ; 7*1024
		call fRead

		call fClose

		call waitKey

		ld a, 2			; reprint all (top, mid, bottom and cursor)
		ret

; -----------------------
; view screen of SNA file
; -----------------------
;
viewSNA		ld hl, bDName		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		call fOpen

		ld bc, 0
		ld de, 27
		call fSeek		; skip SNA header

		jp readSCR

		_FSEEK

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

		ld hl, hexview
		call fExecCMD

		ld a, 2			; reprint all (top, mid, bottom and cursor)
		ret

; --------
; messages
; --------
;
msgFile		db $16,23,1,'LOADING FILE...',0

; -----------------
; ext actions table
; -----------------
;
extTbl		db 'SNA'
		dw viewSNA
		db 'SCR'
		dw viewSCR
		db 0

; -----------------------
; dot command for hexview
; -----------------------
;
hexview		db 'HEXVIEW '
bDName3		db '12345678.123', 0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

