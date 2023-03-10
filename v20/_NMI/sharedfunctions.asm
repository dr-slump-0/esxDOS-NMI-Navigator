;==============================================================================
; Project: NMI.zdsp
; File: sharedfunctions.asm
; Date: 03/11/2022 19:30:44
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; SPEAKER, KEYBOARD AND SCREEN FUNCTIONS
;==============================================================================

; -----------------------------------------------------------------------------
; beep
;
; input:    -
; output:   -
; destroys: a, b
; -----------------------------------------------------------------------------
;
beep		ld b, 2
beep01		push bc
		ld a, %00010000
		out (0xfe), a
		ld b, 30
beep02		djnz beep02
		ld a, %00000000
		out (0xfe), a
		ld b, 30
beep03		djnz beep03
		pop bc
		djnz beep01
		ret

; -----------------------------------------------------------------------------
; wait for key or mouse
;
; input:    -
; output:   a - key pressed
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------
;
waitKey		ld a, (prevJoy)
		ld b, 6
_L1		ld c, a
		push bc
		call readJoy		; read joystick
		pop bc
		ld (prevJoy), a
		or a
		jr z, _L2		; no joystroke
		cp c
		ret nz			; previous joystroke != actual joystroke
		djnz _L1
		ret
_L2		ld a, (prevKey)
		ld b, 6
_L3		ld c, a
		push bc
		call readKey		; read keyboard
		pop bc
		ld (prevKey), a
		or a
		jr z, waitKey		; no keystroke
		cp c
		ret nz			; previous keystroke != actual keystroke
		djnz _L3
		ret

; -----------------------------------------------------------------------------
; Read key
;
; input:    -
; output:   a - key pressed, 0 if none
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------
;
readKey		ei
		halt
		di
		call ckMods		; checks CAPS SHIFT and SYMBOL SHIFT
		;
		ld hl, dbTbKeys
nextRow		ld a, (hl)
		or a
		ret z
		inc hl
		ld b, %00010000		; b <- col to test
		in a, ($fe)
		cpl
		ld c, a
nextCol		ld a, c
		and b
		jr nz, pressed
ignCol		inc hl			; no key pressed
		rr b
		jr nc, nextCol		; next col to test
		;
		ld de, 10		;15
		add hl, de
		jr nextRow		; next half-row

pressed		ld a, (hl)		; key pressed
		or a
		jr z, ignCol		; if CS o SS, ignore it
		;
		; Check modifiers
		;
		ld b, (hl)
		;
		ld de, 5
		add hl, de
		ld a, (flagSS)		; SS pressed
		or a
		jr z, paso1
		ld b, (hl)
paso1		add hl, de
		ld a, (flagCS)		; CS pressed
		or a
		jr z, paso2
		ld b, (hl)
paso2		ld a, b
		;
		ret

; ----------------------------------
; checks CAPS SHIFT and SYMBOL SHIFT
; ----------------------------------
;
ckMods		ld a, $fe
		in a, ($fe)
		ld b, %00000001
		cpl
		and b
		ld (flagCS), a

		ld a, $7f
		in a, ($fe)
		ld b, %00000010
		cpl
		and b
		ld (flagSS), a

		ret

; -----------------------------------------------------------------------------
; Read joystick - based on Velesoft suggestions
;
; input:    -
; output:   a - key pressed, 0 if none
; destroys: af,bc,hl
; -----------------------------------------------------------------------------
;
readJoy		ei
		halt
		di
		ld bc, $1f		; 31
		in a, (c)
		and 31			; %00011111
		ld b, a
		and 3			; %00000011
		cp 3
		jr z, joy6		; detected incorrect state right+left
		ld a, b
		and 12			; %00001100
		cp 12
		jr z, joy6		; detected incorrect state up+down
		ld a, b
		;
		; check directions and fire button
		;
		cp 1
		jr nz, joy1
		ld a, (kRight)
		ret
joy1		cp 2
		jr nz, joy2
		ld a, (kLeft)
		ret
joy2		cp 4
		jr nz, joy3
		ld a, (kDown)
		ret
joy3		cp 8
		jr nz, joy4
		ld a, (kUp)
		ret
joy4		cp 16
		jr nz, joy5
		ld a, (kEnter)
		ret
joy6		;
		; disable joystick, xor a : ret
		;
		ld hl, $c9af
		ld (readJoy), hl
joy5		;
		; no key pressed
		;
		xor a
		ret

; -----------------------------------------------------------------------------
; Waits 26*(hl-1)+27 T states
;
; 3,55 Mhz => T state = 281,7 nseg
; n = 0     => ~480 mseg
; n = 32768 => ~240 mseg
; n = 24576 => ~180 mseg
; n = 16384 => ~120 mseg
;
; input:    -
; output:   -
; destroys: af,de
; -----------------------------------------------------------------------------
;
;wait    ld      de, 8192
;waitLp  dec     de
;        ld      a, d
;        or      e
;        jr      nz, waitLp
;        ret

; -----------------------------------------------------------------------------
; Waits ~ b * 20 mseg
;
; input:    -
; output:   -
; destroys: b
; -----------------------------------------------------------------------------
;
wait		ld b, 12
waitL0		ei
		halt
		di
		djnz waitL0
		ret

; -----------------------------------------------------------------------------
; clear screen lines
;
; input:    a = attribute
;           b = number of lines
;           c = from line
; output:   -
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------
;
;    7  6  5  4  3  2  1  0
;    F  B P2 P1 P0 I2 I1 I0
;
;    F sets the attribute FLASH mode
;    B sets the attribute BRIGHTNESS mode
;    P2 to P0 is the PAPER colour
;    I2 to I0 is the INK colour
;
;    0 black
;    1 blue
;    2 red
;    3 magenta
;    4 green
;    5 cyan
;    6 yellow
;    7 white
;
;             H                         L
;  15 14 13 12 11 10  9  8    7  6  5  4  3  2  1  0
;   0  1  0  1  1  0 Y7 Y6   Y5 Y4 Y3 X7 X6 X5 X4 X3    attr
;   0  1  0 Y7 Y6 Y2 Y1 Y0   Y5 Y4 Y3 X7 X6 X5 X4 X3    bitmap
;
; input:
;
;  A = attr
;  B = number of lines to clear
;  C = start line
;
;      0 0 0 Y7 Y6 Y5 Y4 Y3   (0 to 23)
;      0 0 0  0  0  0  0  0   (0)
;      0 0 0  1  0  1  1  1   (23)
;
clrScr		ex af, af'		; guardamos atributos
		;
		; attr
		;
		ld a, c			; Calculate Y7, Y6
		rrca			; Shift to position
		rrca
		rrca
		and %00000011		; Mask out unwanted bits
		or %01011000		; Set attr address of screen
		ld h, a			; Store in H
		ld d, a
		ld a, c
		rrca			; Shift to position
		rrca
		rrca
		and %11100000		; Calculate Y5, Y4, Y3
		ld l, a			; Store in L
		ld e, a
		inc e
		;
		ex af, af'		; recuperamos atributos
		push bc			; guardamos BC
		;
		ld (hl), a
		ld bc, 32-1
		ldir
		;
		pop bc			; recuperamos BC
		ex af, af'		; guardamos atributos
		;
		; bitmap
		;
		ld a, c			; Calculate Y7, Y6
		and %00011000		; Mask out unwanted bits
		or %01000000		; Set base address of screen
		ld h, a			; Store in H
		ld d, a
		ld a, c
		rrca			; Shift to position
		rrca
		rrca
		and %11100000		; Calculate Y5, Y4, Y3
		ld l, a			; Store in L
		ld e, a
		inc e
		;
		push bc			; guardamos BC
		;
		xor a
		ld b, 8			; B pixel rows to clear
clScrL0		push hl
		push de
		push bc
		ld (hl), a
		ld bc, 32-1
		ldir
		pop bc
		pop de
		pop hl
		inc h
		inc d
		djnz clScrL0
		;
		ex af, af'		; recuperamos atributos
		pop bc			; recuperamos BC
		;
		inc c
		djnz clrScr
		;
		ret

; -----------------------------------------------------------------------------
; Converts an unsigned int to an 6 char ASCII string
; Skip '0' on the left
;
; input:    hl = unigned int to convert
;           de = pointer to ASCII string
; output:   c:hl = 6 digits BCD number
;           de = pointer to end of string
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------
_utoa		push de
		ld bc, 16*256+0		; handle 16 bits, one bit per iteration
		ld de, 0
cvtLoop
		add hl, hl
		ld a, e
		adc a, a
		daa
		ld e, a
		ld a, d
		adc a, a
		daa
		ld d, a
		ld a, c
		adc a, a
		daa
		ld c, a
		djnz cvtLoop
		ex de, hl		; C:HL = numero BCD de 6 digitos

bcd2hex
		pop de
		//ld de, utoaBuf	//
		push de
		//
		ld a, c			// skip left zeroes
		and $f0
		jr nz, _1_
		ld a, c
		and $0f
		jr nz, _2_
		ld a, h
		and $f0
		jr nz, _3_
		ld a, h
		and $0f
		jr nz, _4_
		ld a, l
		and $f0
		jr nz, _5_
		jr _6_

_1_		call cvtUpperNibble
		ld a, c
_2_		call cvtLowerNibble
		ld a, h
_3_		call cvtUpperNibble
		ld a, h
_4_		call cvtLowerNibble
		ld a, l
_5_		call cvtUpperNibble
_6_		ld a, l
		call cvtLowerNibble
		xor a
		ld (de), a
		pop hl
		//jr prtDec		//
		ret

cvtUpperNibble
		rra			; move upper nibble into lower nibble
		rra
		rra
		rra
cvtLowerNibble
		and $0F			; isolate lower nibble
		or %00110000		; convert to ASCII
		ld (de), a
		inc de
		ret

utoa		ld de, utoaBuf
		call _utoa
		//jr prStr

; -----------------------------------------------------------------------------
; Print a asciiz string at cursor position
; Updates cursor coordinates
;
; input:    hl = pointer to asciiz string
; output:   hl = pointer to end of string
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------
prStr		ld a, (hl)
		ld b, a
		ld a, (flgAT)
		and a
		ld a, b
		jr nz, notChk
		or a
		ret z
notChk		push hl
		call prChr
		pop hl
		inc hl
		jr prStr

; -----------------------------------------------------------------------------
; Print a character at cursor
; Updates cursor coordinates
;
; The source code for 64 column printing was originally provided by Andrew Owen
; in a thread on WoSF.
;
; Based on code by Tony Samuels from Your Spectrum issue 13, April 1985.
; A channel wrapper for the 64-column display driver.
;
; input:    a = char to print
; output:   -
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------

prChr		ld b,a			; save character
		ld a,(flgAT)		; value of AT flag
		and a			; test against zero
		jr nz,getrow		; jump if not
		ld a,b			; restore character

atchk		cp $16			; test for AT
		jr nz,crchk		; if not test for CR
		ld a,$ff		; set the AT flag
		ld (flgAT),a		; next character will be row
		ret			; return

getrow		cp $fe			; test AT flag
		jr z,getcol		; jump if setting col
		ld a,b			; restore character
		cp $18			; greater or equal than 24?
		jr nc,err_b		; error if so

		ld (row),a		; store it in row
		ld hl,flgAT		; AT flag
		dec (hl)		; indicates next character is col
		ret			; return

getcol		ld a,b			; restore character
		cp $40			; greater or equal than 64?
		jr nc,err_b		; error if so
		ld (col),a		; store it in col
		xor a			; set a to zero
		ld (flgAT),a		; store in AT flag
		ret			; return

err_b		xor a			; set a to zero
		ld (flgAT),a		; clear AT flag
		;rst	08h		;
		;defb	$0a		; ERROR, PENSAR QUE HACER AQUI
		ret

crchk		cp $0d			; check for return
		jr z,do_cr		; to carriage return if so
		;cp      $84             ; greater or equal than 132?
		cp $80			; greater or equal than 128?
		jr nc,prErr		;
		cp $20			; greater or equal than 32?
		jr nc,prOk		;
prErr		;ld      a,$80
		ld a, '?'
prOk		call pr_64		; print it

		ld hl,col		; increment
		inc (hl)		; the column
		ld a,(hl)		;

		cp $40			; column 64?
		ret nz			;

do_cr		xor a			; set A to zero
		ld (col),a		; reset column
		ld a,(row)		; get the row
		inc a			; increment it
		cp $18			; row 24?
		jr z,wrap		;

zend		ld (row),a		; write it back
		ret

wrap		xor a			;
		jr zend			;

; ------------------------
; 64 COLUMN DISPLAY DRIVER
; ------------------------

pr_64		or a			; clear C flag
		rra			; divide by two with remainder in carry flag

		ld h,$00		; clear H
		ld l,a			; CHAR to low byte of HL

		ex af,af'		; save the carry flag

		push hl			;
		pop de			;
		add hl,hl		; multiply
		add hl,de		; by
		add hl,hl		; seven
		add hl,de		; character map in FONT
		ld de,dbTbFont-32*7/2	; offset to FONT
		add hl,de		; HL holds address of first byte of
		push hl			; save font address

; convert the row to the base screen address

		ld a,(row)		; get the row
		ld b,a			; save it
		and $18			; mask off bit 3-4
		ld d,a			; store high byte of offset in D
		ld a,b			; retrieve it
		and $07			; mask off bit 0-2
		rlca			; shift
		rlca			; five
		rlca			; bits
		rlca			; to the
		rlca			; left
		ld e,a			; store low byte of offset in E

; add the column

		ld a,(col)		; get the column
		rra			; divide by two with remainder in carry flag
		push af			; store the carry flag

		ld h,$40		; base location
		ld l,a			; plus column offset

		add hl,de		; add the offset

		ex de,hl		; put the result back in DE

		xor a			; the upper bits of char are always 0
		ld (de),a		; set to 0 and reduce font from 8x4 to
		inc d			; 7x4

; HL now points to the location of the first byte of char data in FONT_1
; DE points to the first screen byte in SCREEN_1
; C holds the offset to the routine

		pop af			; restore column carry flag
		pop hl			; restore the font address

		jr nc,odd_col		; jump if odd column

even_col
		ex af,af'		; restore char position carry flag
		jr c,l_on_l		; left char on left col
		jr r_on_l		; right char on left col

odd_col
		ex af,af'		; restore char position carry flag
		jr nc,r_on_r		; right char on right col
		jr l_on_r		; left char on right col

; -------------------------------
; WRITE A CHARACTER TO THE SCREEN
; -------------------------------
;
; There are four separate routines

; HL points to the first byte of a character in FONT
; DE points to the first byte of the screen address

; left nibble on left hand side

l_on_l		ld c,$07		; 7 bytes to write
ll_lp		ld a,(de)		; read byte at destination
		and $f0			; mask area used by new character
		ld b,a			; store in b
		ld a,(hl)		; get byte of font
		and $0f			; mask off unused half
		or b			; combine with background
		ld (de),a		; write it back
		inc d			; point to next screen location
		inc hl			; point to next font data
		dec c			; adjust counter
		jr nz,ll_lp		; loop 7 times
		ret			; done

; right nibble on right hand side

r_on_r		ld c,$07		; 7 bytes to write
rr_lp		ld a,(de)		; read byte at destination
		and $0f			; mask area used by new character
		ld b,a			; store in b
		ld a,(hl)		; get byte of font
		and $f0			; mask off unused half
		or b			; combine with background
		ld (de),a		; write it back
		inc d			; point to next screen location
		inc hl			; point to next font data
		dec c			; adjust counter
		jr nz,rr_lp		; loop 7 times
		ret			; done

; left nibble on right hand side

l_on_r		ld c,$07		; 7 bytes to write
lr_lp		ld a,(de)		; read byte at destination
		and $0f			; mask area used by new character
		ld b,a			; store in b
		ld a,(hl)		; get byte of font
		rrca			; shift right
		rrca			; four bits
		rrca			; leaving 7-4
		rrca			; empty
		and $f0			;
		or b			; combine with background
		ld (de),a		; write it back
		inc d			; point to next screen location
		inc hl			; point to next font data
		dec c			; adjust counter
		jr nz,lr_lp		; loop 7 times
		ret			; done

; right nibble on left hand side

r_on_l		ld c,$07		; 7 bytes to write
rl_lp		ld a,(de)		; read byte at destination
		and $f0			; mask area used by new character
		ld b,a			; store in b
		ld a,(hl)		; get byte of font
		rlca			; shift left
		rlca			; four bits
		rlca			; leaving 3-0
		rlca			; empty
		and $0f			;
		or b			; combine with background
		ld (de),a		; write it back
		inc d			; point to next screen location
		inc hl			; point to next font data
		dec c			; adjust counter
		jr nz,rl_lp		; loop 7 times
		ret			; done

