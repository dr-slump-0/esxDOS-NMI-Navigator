;==============================================================================
; Project: prueba.zDSp
; Main File: hexview.asm
; Date: 31/05/2020 11:50:00
;
; Created with zDevStudio - Z80 Development Studio.
;
; sjasmplus --nologo --syntax=bFLw prueba.asm
;
;==============================================================================

		INCLUDE "..\esxdos.inc"
		INCLUDE "..\errors.inc"

//	PRUEBA
//	PRUEBA2
//	PRUEBA.TAP

		DEFINE PRUEBA.TAP

;==============================================================================
; M A I N
;==============================================================================

	IFDEF PRUEBA
		ORG $2000
		DEFINE _HL hl
	ENDIF
	IFDEF PRUEBA2
		ORG $2000
		DEFINE _HL hl
	ENDIF
	IFDEF PRUEBA.TAP
		ORG 32896
		DEFINE _HL ix
	ENDIF

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

; RST $10 funciona con SP por encima de $3FFF

; Se modifica HELP, restaurarlo cuando terminemos las pruebas

main		MODULE main

		//xor a			;
	        //ld ($5c3c), a		; set TVFLAG to 0

		//ld a, 2			;
	        //call $1601		; open channel 2

		//call    $0daf		; clear the screen, open channel 2

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

		ld _HL, dotcmd		; hl, dotcmd
		rst $08
		DB $8F			; M_EXECCMD
		jr c, main_1
		ld hl, msg03
		jr main_2
main_1		ld hl, msg04
main_2		call F_print		; prStr

	/*IFDEF PRUEBA.TAP		; 16
		ld a, 22
		rst $10
		ld a, 19		; Y
		rst $10
		ld a, 0			; X
		rst $10
	ENDIF
	IFDEF PRUEBA			; 8
		ld a, 22
		rst $10
		ld a, 11		; Y
		rst $10
		ld a, 0			; X
		rst $10
	ENDIF
	IFDEF PRUEBA2			; 0
		ld a, 22
		rst $10
		ld a, 3			; Y
		rst $10
		ld a, 0			; x
		rst $10
	ENDIF*/
		ld hl, msg05
		call F_print_rst10

		ret

		ENDMODULE

;==============================================================================
; F U N C T I O N S
;==============================================================================

read_2_bytes
		ld a, (hl)
		rst $10
		inc hl
read_1_byte
		ld a, (hl)
		rst $10
		inc hl
F_print_rst10
		ld a,(hl)
		and a
		ret z
		rst $10
		inc hl
		cp $16
		jr z, read_2_bytes	; == $16
		jr nc, F_print_rst10	; >= $16
		cp $10
		jr nc, read_1_byte	; >= $10
		jr F_print_rst10

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

/*; Simple cls routine
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
		ret*/

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

		INCLUDE "charmap.asm"

;------------------------------------------------------------------------------
; $4000, $1800 (6144) 0  32x24 colxrow  32x192 bytes  256x192 pixels (bits)
; $4000, $800  (2048) 0  32x8
; $4800, $800  (2048) 8  32x8
; $5000, $800  (2048) 16 32x8
; $5800, $300  (768)     32x24 colxrow  32x24 bytes
;------------------------------------------------------------------------------

v_column	DB 0			; Current column for print routine
v_pr_wkspc	DB 0			; Print routine workspace
v_workspace	DS 10,0

	IFDEF PRUEBA.TAP
v_row		DW $5000		; Current row address for print routine
v_rowcount	DB 16			; Current row number for print routine
	ENDIF
	IFDEF PRUEBA
v_row		DW $4800		; Current row address for print routine
v_rowcount	DB 8			; Current row number for print routine
	ENDIF
	IFDEF PRUEBA2
v_row		DW $4000		; Current row address for print routine
v_rowcount	DB 0			; Current row number for print routine
	ENDIF


; lookup table shouldn't overlap 256 byte page boundary
col_lookup	DB 0,0,1,2,3,3,4,5,6,6,7,8,9,9,10,11,12,12,13,14,15,15
		DB 16,17,18,18,19,20,21,21,22,23,24,24,25,26,27,27,28,29,30,30,31

; ---------------
; hex viewer vars
; ---------------

savedSP		DW 0
retAddr		DW 0

dotcmd		DB 'PRUEBA',0

; --------
; messages
; --------

msg01		DB 'Stack Pointer:  ',0
msg02		DB 'Return Address: ',0
msg03		DB 'Dot command loaded Ok',0
msg04		DB 'Error loading dot command',0
msg05		DB 22
	IFDEF PRUEBA.TAP
		DB 19,0 ; 0
	ENDIF
	IFDEF PRUEBA
		DB 11,0 ; 0
	ENDIF
	IFDEF PRUEBA2
		DB 3,0 ; 0
	ENDIF
		DB 'Using RST $10 '
	IFDEF PRUEBA.TAP
		DB 'PRUEBA.TAP'
	ENDIF
	IFDEF PRUEBA
		DB 'PRUEBA'
	ENDIF
	IFDEF PRUEBA2
		DB 'PRUEBA2'
	ENDIF

msgCr		DB 13,0

;------------------------------------------------------------------------------
	IFDEF PRUEBA
		IF $ > $2000+$1c00
		LUA
		sj.error("Resulting code too long")
		ENDLUA
		ENDIF
	ENDIF
	IFDEF PRUEBA2
		IF $ > $2000+$1c00
		LUA
		sj.error("Resulting code too long")
		ENDLUA
		ENDIF
	ENDIF
;------------------------------------------------------------------------------

length		EQU $-main

		//END main

; -----------------------------------------------------------------------------
; SET DEVICE
; -----------------------------------------------------------------------------

		DEVICE ZXSPECTRUM48

	IFDEF PRUEBA
		SAVEBIN "prueba",main,length
	ENDIF
	IFDEF PRUEBA2
		SAVEBIN "prueba2",main,length
	ENDIF
	IFDEF PRUEBA.TAP
BAS_CODE	= $AF
BAS_USR		= $C0
BAS_LOAD	= $EF
BAS_CLEAR	= $FD
BAS_RANDOMIZE	= $F9

		//ORG $5C00		; 23552
baszac		DB 0,1			; Line number (MSB first)
		DW linlen		; Line length (plus ENTER)
linzac		DB BAS_CLEAR,'32895',$0E,0,0
		DW main-1
		DB 0,':'
		DB BAS_LOAD,'"'
		DB '"',BAS_CODE,':'
		DB BAS_RANDOMIZE,BAS_USR,'32896',$0E,0,0
		DW main
		DB 0,$0D
linlen		= $-linzac
baslen		= $-baszac

		EMPTYTAP "prueba.tap"
		SAVETAP "prueba.tap", BASIC, "PRUEBA", baszac, baslen, 1
		SAVETAP "prueba.tap", CODE, "PRUEBA", main, length, main
	ENDIF

