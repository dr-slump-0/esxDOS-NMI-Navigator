;==============================================================================
; Project: prueba.zdsp
; File: dotcmd.asm
; Date: 02/06/2020 18:19:05
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================


		INCLUDE "..\esxdos.inc"
		INCLUDE "..\errors.inc"

;==============================================================================
; M A I N
;==============================================================================

		ORG $2000

;
; esxDOS  call   return
; version method address   SP
; ------- ------ --------- ----
; v0.8.0  BASIC  4042 0FCA
;         NMI    4069 0FE5
; v0.8.5  BASIC  3495 0DA7
;         NMI    3522 0DC2
; v0.8.6  BASIC  3503 0DAF
;         NMI    3530 0DCA
; v0.8.6  BASIC  3477 0D95
; b5.1    NMI    3504 0DB0
; v0.8.7  BASIC
;         NMI
; v0.8.8  BASIC  3492 0DA4 FF4C
;         NMI    3519 0DBF 3DD6

main		MODULE main

		ld (savedSP), sp

		ex (sp), hl
		ld (retAddr),hl
		ex (sp), hl

		ld hl, msg01
		call F_print		; prStr
		ld hl, savedSP		; (savedSP)
		ld b, 2
		call F_hexdump		; utoa
		ld hl, msgCr
		call F_print		; prStr

		ld hl, msg02
		call F_print		; prStr
		ld hl, retAddr		; (retAddr)
		ld b, 2
		call F_hexdump		; utoa
		ld hl, msgCr
		call F_print		; prStr

		ld hl, dotcmd
		rst $08
		DB $8F			; M_EXECCMD
		jr c, main_1
		ld hl, msg03
		jr main_2
main_1		ld hl, msg04
main_2		call F_print		; prStr

		ret

		ENDMODULE

;==============================================================================
; F U N C T I O N S
;==============================================================================



; Simple cls routine
F_clear
		ld hl, 16384
		ld de, 16385
		ld bc, 6144
		ld (hl), 0
		ldir
		ld (hl), 56		; attribute for white
		ld bc, 767
		ldir
		xor a
		ld (v_column), a
		ld (v_rowcount), a
		ld hl, 16384
		ld (v_row), hl
		ret

; Print utility routine.
F_print
		ld a, (hl)
		and a			; test for NUL termination
		ret z			; NUL encountered
		call putc_5by8		; print it
		inc hl
		jr F_print

; hl = start address, b = byte count
F_hexdump
		push hl
		ld a, (hl)
		call F_inttohex8
		call F_print
		ld a, ' '
		call putc_5by8
		pop hl
		inc hl
		djnz F_hexdump
		ret

; F_inttohex8 - convert 8 bit number in A. On return hl=ptr to string
F_inttohex8
		push af
		push bc
		ld hl, v_workspace
		ld b, a
		call .Num1
		ld a, b
		call .Num2
		xor a
		ld (hl), a		; add null
		pop bc
		pop af
		ld hl, v_workspace
		ret

.Num1		rra
		rra
		rra
		rra
.Num2		or $F0
		daa
		add a,$A0
		adc a,$40

		ld (hl),a
		inc hl
		ret

/*
F_regdump
		push hl
		push de
		push bc
		push af

		ld a, 13
		call putc_5by8

		push hl
		ld a, h
		call F_inttohex8
		call F_print
		pop hl
		ld a, l
		call F_inttohex8
		call F_print
		ld a, ','
		call putc_5by8

		ld a, d
		call F_inttohex8
		call F_print
		ld a, e
		call F_inttohex8
		call F_print
		ld a, ','
		call putc_5by8

		ld a, b
		call F_inttohex8
		call F_print
		ld a, c
		call F_inttohex8
		call F_print
		ld a, ','
		call putc_5by8

		pop af
		push af
		call F_inttohex8
		call F_print
		pop bc
		push bc
		ld a, c
		call F_inttohex8
		call F_print
		ld a, 13
		call putc_5by8

		pop af
		pop bc
		pop de
		pop hl
		ret
*/

; a = char to print

; print 5x8 font on the Spectrum, because I so liked the VTX5000 teletext
; font :-) There is probably room for improvement in this routine.
; The character cells are actually 6x8 (5 pixels wide, plus a column of
; blank pixels)

putc_5by8
		push hl
		push bc
		push de
		cp 13			; carriage return?
		jr z, .nextrow

		; find the address of the character in the bitmap table
		sub 32			; space = offset 0
		ld hl, 0
		ld l, a

		; multiply by 8 to get the byte offset
		add hl, hl
		add hl, hl
		add hl, hl

		; add the offset
		ld bc, char_space
		add hl, bc

		; Now find the address in the frame buffer to be written.
		ex de, hl
		ld hl, col_lookup
		ld a, (v_column)
		ld b, a
		add a, l
		ld l, a			; hl = pointer to byte in lookup table
		ld a, (hl)		; a = lookup table value
		ld hl, (v_row)		; hl = framebuffer pointer for start of row
		add a, l
		ld l, a			; hl = frame buffer address

; de contains the address of the char bitmap
; hl contains address in the frame buffer
.paintchar
		ld a, b			; retrieve column
		and 3			; find out how much we need to rotate
		jr z, .norotate		; no need to rotate, character starts at MSB
		rla			; multipy by 2
		ld (v_pr_wkspc), a	; save A
		ld b, 8			; byte copy count for outer loop
.fbwriterotated
		push bc			; save outer loop count
		ld a, (v_pr_wkspc)
		ld b, a			; set up rotate loop count
		ld a, (de)		; get character bitmap
		ld c, a			; C contains rightmost fragment of bitmap
		xor a			; set a=0 to accept lefmost fragment of bitmap
.rotloop
		rl c
		rla			; suck out leftmost bit from the carry flag
		djnz .rotloop
.writerotated
		or (hl)			; merge with existing character
		ld (hl), a
		ld a, c
		cp 0
		jr z, .writerotated.skip; nothing to do
		inc l			; next char cell
		or (hl)
		ld (hl), a
		dec l			; restore l
.writerotated.skip
		inc h			; next line
		inc de			; next line of character bitmap
		pop bc			; retrieve outer loop count
		djnz .fbwriterotated
.nextchar
		ld a, (v_column)
		inc a
		cp 42
		jr nz, .nextchar.done
.nextrow
		ld a, (v_rowcount)	; check the row counter
		cp 23			; 24th line?
		jr nz, .noscroll
		call F_jumpscroll
		ld a, 16
		ld (v_rowcount), a
		ld hl, $5000		; address of first row of bottom 1/3rd
		jr .nextchar.saverow	; save row addr and complete
.noscroll
		inc a
		ld (v_rowcount), a
		ld hl, (v_row)		; advance framebuffer pointer to next character row
		ld a, l
		add a, 32
		jr c, .nextthird
		ld l, a
		jr .nextchar.saverow
.nextthird
		ld l, 0
		ld a, h
		add a, 8
		ld h, a
.nextchar.saverow
		ld (v_row), hl
		xor a			; a = 0
.nextchar.done
		ld (v_column), a

		pop de
		pop bc
		pop hl
		ret

.norotate
		ld b, 8
.norotate.loop
		ld a, (de)		; move bitmap into the frame buffer
		ld (hl), a
		inc de			; next line of bitmap
		inc h			; next line of frame buffer
		djnz .norotate.loop
		jr .nextchar

; a simple 'jump scroll' which scrolls the screen by 1/3rd. Simpler
; than scrolling one line.
F_jumpscroll
		push hl
		push de
		push bc
		ld hl, $4800		; start of 2nd 1/3rd of screen
		ld de, $4000		; first third
		ld bc, $1000		; copy 2/3rDS of the screen up by 1/3rd
		ldir
		ld hl, $5000		; clear out last 2k
		ld de, $5001
		ld bc, $07FF
		ld (hl), 0
		ldir
		pop bc
		pop de
		pop hl
		ret

;------------------------------------------
; Uncompacted charmap       96x8=768 bytes
; Compacted           96x8x(6/8)=576 bytes
; Compacted           96x8x(5/8)=480 bytes
; Compacted           96x7x(6/8)=504 bytes
; Compacted           96x7x(5/8)=420 bytes
;------------------------------------------

char_space
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0

char_pling
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB 0
		DB %00100000
		DB 0

char_quote
		DB %01010000
		DB %01010000
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0

char_octothorpe
		DB 0
		DB %01010000
		DB %11111000
		DB %01010000
		DB %01010000
		DB %11111000
		DB %01010000
		DB 0

char_buck
		DB %00100000
		DB %11111000
		DB %10100000
		DB %11111000
		DB %00101000
		DB %11111000
		DB %00100000
		DB 0

char_percent
		DB %11001000
		DB %11001000
		DB %00010000
		DB %00100000
		DB %01000000
		DB %10011000
		DB %10011000
		DB 0

char_ampersand
		DB %01110000
		DB %10001000
		DB %01010000
		DB %00100000
		DB %01010000
		DB %10001000
		DB %01110100
		DB 0

char_singlequote
		DB %00010000
		DB %00100000
		DB %01000000
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0

char_obrace
		DB %00100000
		DB %01000000
		DB %10000000
		DB %10000000
		DB %10000000
		DB %01000000
		DB %00100000
		DB 0

char_cbrace
		DB %00100000
		DB %00010000
		DB %00001000
		DB %00001000
		DB %00001000
		DB %00010000
		DB %00100000
		DB 0

char_asterisk
		DB 0
		DB %01010000
		DB %00100000
		DB %11111000
		DB %00100000
		DB %01010000
		DB 0
		DB 0

char_plus
		DB 0
		DB %00100000
		DB %00100000
		DB %11111000
		DB %00100000
		DB %00100000
		DB 0
		DB 0

char_comma
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB %00100000
		DB %00100000
		DB %01000000

char_minus
		DB 0
		DB 0
		DB 0
		DB %11111000
		DB 0
		DB 0
		DB 0
		DB 0

char_period
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB %00110000
		DB %00110000
		DB 0

char_slash
		DB %00001000
		DB %00001000
		DB %00010000
		DB %00100000
		DB %01000000
		DB %10000000
		DB %10000000
		DB 0

char_zero
		DB %01110000
		DB %10001000
		DB %10011000
		DB %10101000
		DB %11001000
		DB %10001000
		DB %01110000
		DB 0

char_one
		DB %00100000
		DB %01100000
		DB %10100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %11111000
		DB 0

char_two
		DB %01110000
		DB %10001000
		DB %00001000
		DB %00110000
		DB %01000000
		DB %10000000
		DB %11111000
		DB 0

char_three
		DB %01110000
		DB %10001000
		DB %00001000
		DB %00110000
		DB %00001000
		DB %10001000
		DB %01110000
		DB 0

char_four
		DB %00010000
		DB %00110000
		DB %01010000
		DB %11111000
		DB %00010000
		DB %00010000
		DB %00010000
		DB 0

char_five
		DB %11111000
		DB %10000000
		DB %10000000
		DB %11110000
		DB %00001000
		DB %10001000
		DB %01110000
		DB 0

char_six
		DB %00111000
		DB %01000000
		DB %10000000
		DB %11110000
		DB %10001000
		DB %10001000
		DB %01110000
		DB 0

char_seven
		DB %11111000
		DB %00001000
		DB %00010000
		DB %00100000
		DB %01000000
		DB %10000000
		DB %10000000
		DB 0

char_eight
		DB %01110000
		DB %10001000
		DB %10001000
		DB %01110000
		DB %10001000
		DB %10001000
		DB %01110000
		DB 0

char_nine
		DB %01110000
		DB %10001000
		DB %10001000
		DB %01111000
		DB %00001000
		DB %00001000
		DB %01110000
		DB 0

char_colon
		DB 0
		DB %00100000
		DB 0
		DB 0
		DB 0
		DB %00100000
		DB 0
		DB 0

char_semicolon
		DB 0
		DB %00100000
		DB 0
		DB 0
		DB %00100000
		DB %00100000
		DB %01000000
		DB 0

char_lessthan
		DB %00010000
		DB %00100000
		DB %01000000
		DB %10000000
		DB %01000000
		DB %00100000
		DB %00010000
		DB 0

char_equals
		DB 0
		DB 0
		DB %11110000
		DB 0
		DB %11110000
		DB 0
		DB 0
		DB 0

char_gtthan
		DB %10000000
		DB %01000000
		DB %00100000
		DB %00010000
		DB %00100000
		DB %01000000
		DB %10000000
		DB 0

char_quest
		DB %01110000
		DB %10001000
		DB %00001000
		DB %00110000
		DB %00100000
		DB 0
		DB %00100000
		DB 0

char_at
		DB %01110000
		DB %10001000
		DB %10111000
		DB %10101000
		DB %10010000
		DB %10000000
		DB %01111000
		DB 0

char_A		DB %00100000
		DB %01010000
		DB %10001000
		DB %11111000
		DB %10001000
		DB %10001000
		DB %10001000
		DB 0

char_B		DB %11110000
		DB %10001000
		DB %10001000
		DB %11110000
		DB %10001000
		DB %10001000
		DB %11110000
		DB 0

char_C		DB %01110000
		DB %10001000
		DB %10000000
		DB %10000000
		DB %10000000
		DB %10001000
		DB %01110000
		DB 0

char_D
		DB %11100000
		DB %10010000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10010000
		DB %11100000
		DB 0

char_E
		DB %11111000
		DB %10000000
		DB %10000000
		DB %11111000
		DB %10000000
		DB %10000000
		DB %11111000
		DB 0

char_F
		DB %11111000
		DB %10000000
		DB %10000000
		DB %11111000
		DB %10000000
		DB %10000000
		DB %10000000
		DB 0

char_G		DB %01111000
		DB %10001000
		DB %10001000
		DB %10000000
		DB %10011000
		DB %10001000
		DB %01111000
		DB 0

char_H		DB %10001000
		DB %10001000
		DB %10001000
		DB %11111000
		DB %10001000
		DB %10001000
		DB %10001000
		DB 0

char_I
		DB %01110000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %01110000
		DB 0

char_J
		DB %00001000
		DB %00001000
		DB %00001000
		DB %00001000
		DB %00001000
		DB %10001000
		DB %01110000
		DB 0

char_K
		DB %10001000
		DB %10010000
		DB %10100000
		DB %11000000
		DB %10100000
		DB %10010000
		DB %10001000
		DB 0

char_L
		DB %10000000
		DB %10000000
		DB %10000000
		DB %10000000
		DB %10000000
		DB %10000000
		DB %11111000
		DB 0

char_M
		DB %10001000
		DB %11011000
		DB %10101000
		DB %10101000
		DB %10001000
		DB %10001000
		DB %10001000
		DB 0

char_N
		DB %10001000
		DB %10001000
		DB %11001000
		DB %10101000
		DB %10011000
		DB %10001000
		DB %10001000
		DB 0

char_O
		DB %01110000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %01110000
		DB 0

char_P
		DB %11110000
		DB %10001000
		DB %10001000
		DB %11110000
		DB %10000000
		DB %10000000
		DB %10000000
		DB 0

char_Q
		DB %01110000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10101000
		DB %10010000
		DB %01101000
		DB 0

char_R
		DB %11110000
		DB %10001000
		DB %10001000
		DB %11110000
		DB %10010000
		DB %10001000
		DB %10001000
		DB 0

char_S
		DB %01110000
		DB %10001000
		DB %10000000
		DB %01110000
		DB %00001000
		DB %10001000
		DB %01110000
		DB 0

char_T
		DB %11111000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB 0

char_U
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %01110000
		DB 0

char_V
		DB %10001000
		DB %10001000
		DB %10001000
		DB %01010000
		DB %01010000
		DB %00100000
		DB %00100000
		DB 0

char_W
		DB %10001000
		DB %10001000
		DB %10101000
		DB %10101000
		DB %10101000
		DB %11011000
		DB %10001000
		DB 0

char_X
		DB %10001000
		DB %10001000
		DB %01010000
		DB %00100000
		DB %01010000
		DB %10001000
		DB %10001000
		DB 0

char_Y
		DB %10001000
		DB %10001000
		DB %01010000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB 0

char_Z
		DB %11111000
		DB %00001000
		DB %00010000
		DB %00100000
		DB %01000000
		DB %10000000
		DB %11111000
		DB 0

char_osqb
		DB %01110000
		DB %01000000
		DB %01000000
		DB %01000000
		DB %01000000
		DB %01000000
		DB %01110000
		DB 0

char_backslash
		DB %10000000
		DB %10000000
		DB %01000000
		DB %00100000
		DB %00010000
		DB %00001000
		DB %00001000
		DB 0

char_csqb
		DB %01110000
		DB %00010000
		DB %00010000
		DB %00010000
		DB %00010000
		DB %00010000
		DB %01110000
		DB 0

char_power
		DB %00100000
		DB %01010000
		DB %10001000
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0

char_underscore
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB %11111100
		DB 0

char_quid
		DB %00110000
		DB %01001000
		DB %01000000
		DB %11110000
		DB %01000000
		DB %01000000
		DB %11111000
		DB 0

char_a
		DB 0
		DB 0
		DB %01110000
		DB %00001000
		DB %01111000
		DB %10001000
		DB %01111000
		DB 0

char_b
		DB %10000000
		DB %10000000
		DB %11110000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %11110000
		DB 0

char_c
		DB 0
		DB 0
		DB %01111000
		DB %10000000
		DB %10000000
		DB %10000000
		DB %01111000
		DB 0

char_d
		DB %00001000
		DB %00001000
		DB %01111000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %01111000
		DB 0

char_e
		DB 0
		DB 0
		DB %01110000
		DB %10001000
		DB %11110000
		DB %10000000
		DB %01111000
		DB 0

char_f
		DB 0
		DB %01110000
		DB %10000000
		DB %11100000
		DB %10000000
		DB %10000000
		DB %10000000
		DB 0

char_g
		DB 0
		DB 0
		DB %01111000
		DB %10001000
		DB %10001000
		DB %01111000
		DB %00001000
		DB %01110000

char_h
		DB %10000000
		DB %10000000
		DB %10000000
		DB %11110000
		DB %10001000
		DB %10001000
		DB %10001000
		DB 0

char_i
		DB %00100000
		DB 0
		DB %01100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %01110000
		DB 0

char_j
		DB %00100000
		DB 0
		DB %01100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %11000000

char_k
		DB 0
		DB %10000000
		DB %10010000
		DB %10100000
		DB %11000000
		DB %10100000
		DB %10010000
		DB 0

char_l		DB %01100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %00100000
		DB %01110000
		DB 0

char_m
		DB 0
		DB 0
		DB %11010000
		DB %10101000
		DB %10101000
		DB %10101000
		DB %10001000
		DB 0

char_n
		DB 0
		DB 0
		DB %11110000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10001000
		DB 0

char_o
		DB 0
		DB 0
		DB %01110000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %01110000
		DB 0

char_p
		DB 0
		DB 0
		DB %11110000
		DB %10001000
		DB %10001000
		DB %11110000
		DB %10000000
		DB %10000000

char_q
		DB 0
		DB 0
		DB %01111000
		DB %10001000
		DB %10001000
		DB %01111000
		DB %00001000
		DB %00001100

char_r
		DB 0
		DB 0
		DB %01110000
		DB %10000000
		DB %10000000
		DB %10000000
		DB %10000000
		DB 0

char_s
		DB 0
		DB 0
		DB %01111000
		DB %10000000
		DB %01110000
		DB %00001000
		DB %11110000
		DB 0

char_t
		DB %01000000
		DB %01000000
		DB %11110000
		DB %01000000
		DB %01000000
		DB %01000000
		DB %00111000
		DB 0

char_u
		DB 0
		DB 0
		DB %10001000
		DB %10001000
		DB %10001000
		DB %10001000
		DB %01110000
		DB 0

char_v
		DB 0
		DB 0
		DB %10001000
		DB %10001000
		DB %01010000
		DB %01010000
		DB %00100000
		DB 0

char_w
		DB 0
		DB 0
		DB %10101000
		DB %10101000
		DB %10101000
		DB %10101000
		DB %01010000
		DB 0

char_x
		DB 0
		DB 0
		DB %10001000
		DB %01010000
		DB %00100000
		DB %01010000
		DB %10001000
		DB 0

char_y
		DB 0
		DB 0
		DB %10001000
		DB %10001000
		DB %01111000
		DB %00001000
		DB %01110000
		DB 0

char_z
		DB 0
		DB 0
		DB %11111000
		DB %00010000
		DB %00100000
		DB %01000000
		DB %11111000
		DB 0

char_ocbk
		DB %00111000
		DB %01000000
		DB %01000000
		DB %10000000
		DB %01000000
		DB %01000000
		DB %00111000
		DB 0

char_ccbk
		DB %11100000
		DB %00010000
		DB %00010000
		DB %00001000
		DB %00010000
		DB %00010000
		DB %11100000
		DB 0

char_tilde
		DB %01010000
		DB %10100000
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0
		DB 0

char_copy
		DB %01110000
		DB %10001000
		DB %11101000
		DB %11001000
		DB %11101000
		DB %10001000
		DB %01110000
		DB 0

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

v_column	DB 0			; Current column for print routine
v_row		DW $4800		; Current row address for print routine
v_rowcount	DB 8			; Current row number for print routine
v_pr_wkspc	DB 0			; Print routine workspace
v_workspace	DS 10,0

; lookup table shouldn't overlap 256 byte page boundary
col_lookup	DB 0,0,1,2,3,3,4,5,6,6,7,8,9,9,10,11,12,12,13,14,15,15
		DB 16,17,18,18,19,20,21,21,22,23,24,24,25,26,27,27,28,29,30,30,31

; ---------------
; hex viewer vars
; ---------------

savedSP		DW 0
retAddr		DW 0

dotcmd		DB 'PRUEBA2',0
msg03		DB 'Dot command loaded Ok',0
msg04		DB 'Error loading dot command',0

; --------
; messages
; --------

msg01		DB 'Stack Pointer:  ',0
msg02		DB 'Return Address: ',0
msgCr		DB 13,0

;------------------------------------------------------------------------------
		IF $ > $2000+$1c00
		LUA
		sj.error("Resulting code too long")
		ENDLUA
		ENDIF
;------------------------------------------------------------------------------

		END main

