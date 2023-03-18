;==============================================================================
; Project: prueba.zdsp
; File: 64cols.asm
; Date: 02/06/2020 11:36:55
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; F U N C T I O N S
;==============================================================================


; -----------------------------------------------------------------------------
; Converts and print an unsigned int (unsigned char) to an 4 (2) char asciiz
; string
;
; input:    hl = unigned int to convert (l = unsigned char to convert)
; output:   -
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------
bin2hex8
		ld de, utoaBuf+4
		push de
		jr bin2hex_2
bin2hex16
		ld de, utoaBuf+2
		push de
		ld a, h
		call cvtUpperNibble2
		ld a, h
		call cvtLowerNibble2
bin2hex_2
		ld a, l
		call cvtUpperNibble2
		ld a, l
		call cvtLowerNibble2
		pop hl
		jp prStr
cvtUpperNibble2
		rra			; move upper nibble into lower nibble
		rra
		rra
		rra
cvtLowerNibble2
		and $0F			; isolate lower nibble
		add a,'0'
		cp ':'
		jr c, cvtStoreVal
		add a,'A'-'0'-10
cvtStoreVal
		ld (de), a
		inc de
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
clrScr		ex af, af'                 ; guardamos atributos
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
		ex af, af'                 ; guardamos atributos
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
; Converts an unsigned int to an 6 char ASCII string -> PRINT IT
; Don't deletes '0' on the left
;
; input:    hl = unigned int to convert
;           de = pointer to ASCII string -> NO, ACTUALLY NOT USED
; output:   c:hl = 6 digits BCD number
;           de = pointer to end of string
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------
utoa
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
		ld de, utoaBuf
		push de
		ld a, c
		call cvtUpperNibble
		ld a, c
		call cvtLowerNibble
		ld a, h
		call cvtUpperNibble
		ld a, h
		call cvtLowerNibble
		ld a, l
		call cvtUpperNibble
		ld a, l
		call cvtLowerNibble
		pop hl
		jr prtDec
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

; -----------------------------------------------------------------------------
; Print a asciiz string representing a number at cursor position
; Skips '0' on the left
;
; input:    hl = pointer to asciiz string
; output:   hl = pointer to end of string
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------
prtDec		ld a, (hl)
		cp '0'
		jr nz, prStr1		; if not equal to '0', print it
ignCero		inc hl
		ld a, (hl)
		cp '0'
		jr z, ignCero		; if next digit equal to '0', skip '0' on the left
		jr c, impCero		; if next digit below '0', print almost one '0'

		cp '9'
		jr z, prStr1		; if equal
		jr c, prStr1		; or below than '9', print it

impCero		dec hl			; print almost one '0'

prStr1		ld a, (hl)
		or a
		ret z
		push hl
		rst $10
		pop hl
		inc hl
		jr prStr1

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

prChr		ld b, a			; save character
		ld a, (flgAT)		; value of AT flag
		and a			; test against zero
		jr nz, getrow		; jump if not
		ld a, b			; restore character

atchk		cp $16			; test for AT
		jr nz, crchk		; if not test for CR
		ld a, $FF		; set the AT flag
		ld (flgAT), a		; next character will be row
		ret			; return

getrow		cp $FE			; test AT flag
		jr z, getcol		; jump if setting col
		ld a, b			; restore character
		cp $18			; greater or equal than 24?
		jr nc, err_b		; error if so

		ld (row), a		; store it in row
		ld hl, flgAT		; AT flag
		dec (hl)		; indicates next character is col
		ret			; return

getcol		ld a, b			; restore character
		cp $40			; greater or equal than 64?
		jr nc, err_b		; error if so
		ld (col), a		; store it in col
		xor a			; set a to zero
		ld (flgAT), a		; store in AT flag
		ret			; return

err_b		xor a			; set a to zero
		ld (flgAT), a		; clear AT flag
		;rst	08h		;
		;defb	$0a		; ERROR, PENSAR QUE HACER AQUI
		ret

crchk		cp $0D			; check for return
		jr z, do_cr		; to carriage return if so
		cp $84			; greater or equal than 132?
		jr nc, prErr		;
		cp $20			; greater or equal than 32?
		jr nc, prOk		;
prErr		ld a, $80
prOk		call pr_64		; print it

		ld hl, col		; increment
		inc (hl)		; the column
		ld a, (hl)		;
		cp $40			; column 64?
		ret nz			;

do_cr		xor a			; set A to zero
		ld (col), a		; reset column
		ld a, (row)		; get the row
		inc a			; increment it
		cp $18			; row 24?
		jr z, wrap		;

zend		ld (row), a		; write it back
		ret

wrap		xor a			;
		jr zend			;

; ------------------------
; 64 COLUMN DISPLAY DRIVER
; ------------------------

pr_64		rra			; divide by two with remainder in carry flag

		ld h, $00		; clear H
		ld l, a			; CHAR to low byte of HL

		ex af, af'		; save the carry flag

		push hl			;
		pop de			;
		add hl, hl		; multiply
		add hl, de		; by
		add hl, hl		; seven
		add hl, de		; character map in FONT
		ld de, font-32*7/2	; offset to FONT
		add hl, de		; HL holds address of first byte of
		push hl			; save font address

; convert the row to the base screen address

		ld a, (row)		; get the row
		ld b, a			; save it
		and $18			; mask off bit 3-4
		ld d, a			; store high byte of offset in D
		ld a, b			; retrieve it
		and $07			; mask off bit 0-2
		rlca			; shift
		rlca			; five
		rlca			; bits
		rlca			; to the
		rlca			; left
		ld e, a			; store low byte of offset in E

; add the column

		ld a, (col)		; get the column
		rra			; divide by two with remainder in carry flag
		push af			; store the carry flag

		ld h, $40		; base location
		ld l, a			; plus column offset

		add hl, de		; add the offset

		ex de, hl		; put the result back in DE
		xor a			; the upper bits of char are always 0
		ld (de), a		; set to 0 and reduce font from 8x4 to
		inc d			; 7x4

; HL now points to the location of the first byte of char data in FONT_1
; DE points to the first screen byte in SCREEN_1
; C holds the offset to the routine

		pop af			; restore column carry flag
		pop hl			; restore the font address

		jr nc, odd_col		; jump if odd column

even_col
		ex af, af'		; restore char position carry flag
		jr c, l_on_l		; left char on left col
		jr r_on_l		; right char on left col

odd_col
		ex af, af'		; restore char position carry flag
		jr nc, r_on_r		; right char on right col
		jr l_on_r		; left char on right col

; -------------------------------
; WRITE A CHARACTER TO THE SCREEN
; -------------------------------
;
; There are four separate routines

; HL points to the first byte of a character in FONT
; DE points to the first byte of the screen address

; left nibble on left hand side

l_on_l		ld c, $07		; 7 bytes to write
ll_lp		ld a, (de)		; read byte at destination
		and $F0			; mask area used by new character
		ld b, a			; store in b
		ld a, (hl)		; get byte of font
		and $0F			; mask off unused half
		or b			; combine with background
		ld (de), a		; write it back
		inc d			; point to next screen location
		inc hl			; point to next font data
		dec c			; adjust counter
		jr nz, ll_lp		; loop 7 times
		ret			; done

; right nibble on right hand side

r_on_r		ld c, $07		; 7 bytes to write
rr_lp		ld a, (de)		; read byte at destination
		and $0F			; mask area used by new character
		ld b, a			; store in b
		ld a, (hl)		; get byte of font
		and $F0			; mask off unused half
		or b			; combine with background
		ld (de), a		; write it back
		inc d			; point to next screen location
		inc hl			; point to next font data
		dec c			; adjust counter
		jr nz, rr_lp		; loop 7 times
		ret			; done

; left nibble on right hand side

l_on_r		ld c, $07		; 7 bytes to write
lr_lp		ld a, (de)		; read byte at destination
		and $0F			; mask area used by new character
		ld b, a			; store in b
		ld a, (hl)		; get byte of font
		rrca			; shift right
		rrca			; four bits
		rrca			; leaving 7-4
		rrca			; empty
		and $F0			;
		or b			; combine with background
		ld (de), a		; write it back
		inc d			; point to next screen location
		inc hl			; point to next font data
		dec c			; adjust counter
		jr nz, lr_lp		; loop 7 times
		ret			; done

; right nibble on left hand side

r_on_l		ld c, $07		; 7 bytes to write
rl_lp		ld a, (de)		; read byte at destination
		and $F0			; mask area used by new character
		ld b, a			; store in b
		ld a, (hl)		; get byte of font
		rlca			; shift left
		rlca			; four bits
		rlca			; leaving 3-0
		rlca			; empty
		and $0F			;
		or b			; combine with background
		ld (de), a		; write it back
		inc d			; point to next screen location
		inc hl			; point to next font data
		dec c			; adjust counter
		jr nz, rl_lp		; loop 7 times
		ret			; done

;==============================================================================
; V A R I A B L E S   &   D A T A
;==============================================================================

; -------------------
; half width 4x7 font
; -------------------
;
; 50 x 7 = 350 bytes
;
font		db $02,$02,$02,$02,$00,$02,$00; SPACE !
		db $52,$57,$02,$02,$07,$02,$00; " #
		db $25,$71,$62,$32,$74,$25,$00; $ %
		db $22,$42,$30,$50,$50,$30,$00; & '
		db $14,$22,$41,$41,$41,$22,$14; ( )
		db $20,$70,$22,$57,$02,$00,$00; * +
		db $00,$00,$00,$07,$00,$20,$20; , -
		db $01,$01,$02,$02,$04,$14,$00; . /
		db $22,$56,$52,$52,$52,$27,$00; 0 1
		db $27,$51,$12,$21,$45,$72,$00; 2 3
		db $57,$54,$56,$71,$15,$12,$00; 4 5
		db $17,$21,$61,$52,$52,$22,$00; 6 7
		db $22,$55,$25,$53,$52,$24,$00; 8 9
		db $00,$00,$22,$00,$00,$22,$02; : ;
		db $00,$10,$27,$40,$27,$10,$00; < =
		db $02,$45,$21,$12,$20,$42,$00; > ?
		db $23,$55,$75,$77,$45,$35,$00; @ A
		db $63,$54,$64,$54,$54,$63,$00; B C
		db $67,$54,$56,$54,$54,$67,$00; D E
		db $73,$44,$64,$45,$45,$43,$00; F G
		db $57,$52,$72,$52,$52,$57,$00; H I
		db $35,$15,$16,$55,$55,$25,$00; J K
		db $45,$47,$45,$45,$45,$75,$00; L M
		db $62,$55,$55,$55,$55,$52,$00; N O
		db $62,$55,$55,$65,$45,$43,$00; P Q
		db $63,$54,$52,$61,$55,$52,$00; R S
		db $75,$25,$25,$25,$25,$22,$00; T U
		db $55,$55,$55,$55,$27,$25,$00; V W
		db $55,$55,$25,$22,$52,$52,$00; X Y
		db $73,$12,$22,$22,$42,$72,$03; Z [
		db $46,$42,$22,$22,$12,$12,$06; \ ]
		db $20,$50,$00,$00,$00,$00,$0F; ^ _
		db $20,$10,$03,$05,$05,$03,$00; sterling_pound a
		db $40,$40,$63,$54,$54,$63,$00; b c
		db $10,$10,$32,$55,$56,$33,$00; d e
		db $10,$20,$73,$25,$25,$43,$06; f g
		db $42,$40,$66,$52,$52,$57,$00; h i
		db $14,$04,$35,$16,$15,$55,$20; j k
		db $60,$20,$25,$27,$25,$75,$00; l m
		db $00,$00,$62,$55,$55,$52,$00; n o
		db $00,$00,$63,$55,$55,$63,$41; p q
		db $00,$00,$53,$66,$43,$46,$00; r s
		db $00,$20,$75,$25,$25,$12,$00; t u
		db $00,$00,$55,$55,$27,$25,$00; v w
		db $00,$00,$55,$25,$25,$53,$06; x y
		db $01,$02,$72,$34,$62,$72,$01; z {
		db $24,$22,$22,$21,$22,$22,$04; | }
		db $56,$A9,$06,$04,$06,$09,$06; ~ copyright

		db $50,$20,$60,$50,$70,$55,$70; [?] [..]      128, 129


