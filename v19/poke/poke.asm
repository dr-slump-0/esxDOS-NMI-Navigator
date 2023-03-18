;==============================================================================
; Project: poke.zdsp
; Main File: poke.asm
; Date: 14/09/2017 18:40:19
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin poke.asm poke
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; ----
; poke
; ----
;
; try a FSM? at first it seems that it may need more code...
;
poke		ld hl, 0
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
		ld hl, pokeStr
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
		ld a, (col)
		dec a
		ld (col), a
		ld a, ' '		;
		push bc			;
		push hl			;
		call pr_64		;
		pop hl			;
		pop bc			; print a space at cursor position
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
		ld a, (col)
		dec a
		ld (col), a
		ld a, ' '		;
		push bc			;
		push hl			;
		call pr_64		;
		pop hl			;
		pop bc			; print a space at cursor position
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
		ld hl, pokeStr
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
		;ld      hl, (pokeAdd)
		;ld      l, (hl)
		;ld      h, 0
		;call    utoa
		;ld      hl, msgPok4
		;call    prStr
		;ld      hl, (pokeVal)
		;ld      h, 0
		;call    utoa
		;ld      hl, msgPok5
		;call    prStr
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
retPoke		ld a, 2			; reprint all (top, mid, bottom and cursor)
		ret

; --------
; messages
; --------
;
msgPok1		db $16,23,1, 'POKE? ',0
;msgPok2 db      $16,23,1, 'ADDRESS: ',0
msgPok2		db $16,23,1, 'POKE ',0
;msgPok3 db      $16,23,16,'OLD VALUE: ',0
msgPok3		db ',',0
;msgPok4 db      $16,23,32,'NEW VALUE: ',0
msgPok4		db ' APPLY (Y/N)? ',0
;msgPok5 db      $16,23,47,'APPLY (Y/N)? ',0

; ---------------------------
; variables for poke function
; ---------------------------
;
msgDbg		db $16,23,1
pokeStr		db '12345,123',0
pokeAdd		dw 0
pokeVal		dw 0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

		end

