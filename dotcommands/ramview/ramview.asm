;==============================================================================
; Project: ramview.zDSp
; Main File: ramview.asm
; Date: 09/06/2020 11:44:03
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

		INCLUDE "../esxdos.inc"
		INCLUDE "../errors.inc"

;==============================================================================
; D E F I N I T I O N S
;==============================================================================
;
		MACRO VERSION
		DB '0.1'
		ENDM

LINES		EQU 23
BYTES		EQU 16

BORDCR		EQU $5C48 ; 23624 Border colour * 8; also contains the attributes normally used for the lower half of the screen.
ATTR_P		EQU $5C8D ; 23693 Permanent current colours, etc (as set up by colour statements).
ATTR_T		EQU $5C8F ; 23695 Temporary current colours, etc (as set up by colour items).
RAMTOP		EQU $5CB2

CLS		EQU $0D6B

; -----------------------------------------------------------------------------
; Colors and attributes
; -----------------------------------------------------------------------------
BLACK		EQU 0
BLUE		EQU 1
RED		EQU 2
MAGENTA		EQU 3
GREEN		EQU 4
CYAN		EQU 5
YELLOW		EQU 6
WHITE		EQU 7

BRIGHT		EQU $40
FLASH		EQU $80

; -----------------------------------------------------------------------------
; Colors used in GUI
; -----------------------------------------------------------------------------
COL_MID		EQU BLACK*8+WHITE	; black paper, white ink
COL_TOP		EQU WHITE*8+BLACK	; white paper, black ink
;COL_BOT	EQU WHITE*8+BLACK	; white paper, black ink
;COL_CUR	EQU BRIGHT+BLUE*8+WHITE	; blue paper, bright white ink
;COL_ERR	EQU BRIGHT+RED*8+WHITE	; red paper, bright white ink

; -----------------------------------------------------------------------------
; Key table
; -----------------------------------------------------------------------------
K_EDIT		EQU $07
K_LEFT		EQU $08
K_RIGHT		EQU $09
K_DOWN		EQU $0A
K_UP		EQU $0B
K_DELETE	EQU $0C
K_ENTER		EQU $0D

K_TO		EQU $CC			; SS+F

; no mapping on speccy BASIC

K_BREAK		EQU $1C

K_SS_ENTER	EQU $1D

; -----------------------------------------------------------------------------
; current drive (missing from esxdos.inc)
; -----------------------------------------------------------------------------
;CUR_DRIVE	EQU '*'

; -----------------------------------------------------------------------------
; DivIDE/DivMMC and esxDOS parameters
; -----------------------------------------------------------------------------

RAM_PAGE	EQU $3df9
START_ADDR	EQU $2000
END_ADDR	EQU $3fff

;==============================================================================
; R E L O C A T O R - Load address $2000, destination address 35000
;==============================================================================

		ORG $2000

dest_addr	EQU 35000
bytes		EQU argStr-main

		ld (_savedSP), sp
		ld (_ptrArgs), hl	; save pointer to args
		;
		ld hl, orig_addr
		ld de, dest_addr
		ld bc, bytes
		ldir
		;
		ld hl, (RAMTOP)
		ld (_savedRAMTOP), hl
		ld hl, dest_addr
		ld (RAMTOP), hl
		ld sp, hl
		;
		call main
		;
		; must preserve CF, A register, HL register
		;
		push hl
		ld hl, (_savedRAMTOP)
		ld (RAMTOP), hl
		pop hl
		ld sp, (_savedSP)
		;
		ret

orig_addr	DISP dest_addr

;==============================================================================
; M A I N
;==============================================================================

main		MODULE main

		ld a, (RAM_PAGE)
		ld (RAMpg), a		; save current RAM PAGE

		xor a			; C is reset, a set to 0
		ld hl, $4000
		sbc hl, sp
		jr nc, main_1		; if sp <= $4000 then loaded from NMI
		inc a			; if sp > $4000 then loaded from BASIC
main_1		ld (fromBAS), a		; 0-Loaded from NMI, 1-Loaded from BASIC

		ld hl, (ptrArgs)
		ld a, h
		or l
		jp nz, scanArg		; process args

view_main	call view

exit_main	or a			; clear CF (no error)
		ret

error		ld a, (fromBAS)
		or a
		jr z, custErr

		ld hl, msg0001		; if called from BASIC, show help
		call prStr1
		ld hl, msg0002
		call prStr1
		or a			; clear CF (no error)
		ret

custErr		ld hl, msg0003		; HL=pointer to custom error message
		xor a			; A=0 custom error message
		scf			; set CF (error)
		ret

		ENDMODULE

; ------------
; process args
; ------------

scanArg		MODULE scanArg

		call getArg
		or a
		jr z, main.view_main	; =0, no more args, exit
isOpt		cp 1
		jr z, getOpts		; =1, is a option, get it
		jr main.custErr		; >=2, is a arg or error, error
		;cp 2
		;jr nz, errArgs		; >2, imposible state, error
		;
		; =2, HL pointer to file/directory name
		;
		;ld hl, argStr
		;call view		; is a file/directory name, view
		;
		;jr scanArg		; next arg

getOpts		call getArg		; get option value
		cp 2
		jr nz, main.custErr	; no value, error

		ld hl, argStr
readOpt		ld a, (hl)		; get opt
		or a
		jr z, scanArg		; no more options in current arg, next arg
		cp '?'
		jr z, main.error	; help         ; help, show it and exit

;		cp 'f'
;		jr nz, opt01
;		ld a, $ff		; force
;		ld (flgForce), a
;		jr nextOpt
;opt01		cp 'i'
;		jr nz, opt02
;		ld a, $ff		; prompt
;		ld (flgPrompt), a
;		jr nextOpt
;opt02		cp 'r'
;		jr nz, opt03
;		ld a, $ff		; recurse directories
;		ld (flgRecurse), a
;		jr nextOpt
;opt03		cp 'd'
;		jr nz, opt04
;		ld a, $ff		; remove empty directorires
;		ld (flgDirectories), a
;		jr nextOpt
;opt04		cp 'v'
;		jr nz, errOpts		; unknown option, error
;		ld a, $ff		; verbose
;		ld (flgVerbose), a

		jr main.custErr

nextOpt		inc hl
		jr readOpt		; next opt

		ENDMODULE

; --------
; get args
; --------
;
; HL=Pointer to args or HL=0 if no args
; HL is typically pointing directly to BASIC line, so for END marker
; you should check for $0D, ":" as well as 0.

getArg		MODULE getArg

		ld hl, (ptrArgs)
		ld de, argStr
getChr		ld a, (hl)
		or a
		jr z, getEnd
		cp $0D
		jr z, getEnd
		cp ':'
		jr z, getEnd
		inc hl
		cp '-'
		jr z, getOpt
		cp ' '
		jr nz,getStr
		jr getChr

getOpt		ld a, 1			; A=1 option arg
		jr savPtr
getEnd		xor a			; A=0 no more args
savPtr		ld (ptrArgs), hl
		ret

getStr		ld (de), a
		inc de
		ld a, (hl)
		or a
		jr z, endStr
		cp $0D
		jr z, endStr
		cp ':'
		jr z, endStr
		cp '-'
		jr z, endStr
		cp ' '
		jr z, endStr
		inc hl
		jr getStr
endStr		xor a
		ld (de), a
		ld a, 2			; A=2 string arg
		jr savPtr

		ENDMODULE

/*
	-----------------------------------------------------------------------

	DivMMC:

	Version	$05e5	$0721	$0dd1	$0de2	RAM_PAGE
	-------	-----	-----	-----	-----	--------
	0.8.5	$05d3	$0711	$0dd4	$0de5	$3df9
	0.8.6	$05e5	$0721	$0dc2	$0dd3	$3df9
	0.8.7	$05e5	$0721	$0dca	$0ddb	$3df9
	0.8.8	$05e5	$0721	$0dd1	$0de2	$3df9
	0.8.9

	DivIDE:

	Version	$05e5	$0721	$0dd1	$0de2	RAM_PAGE
	-------	-----	-----	-----	-----	--------
	0.8.5	$05d3	$0711	$0dd4	$0de5	$3df9
	0.8.6	$05e5	$0721	$0dc2	$0dd3	$3df9
	0.8.7	$05e5	$0721	$0dca	$0ddb	$3df9
	0.8.8	$05e5	$0721	$0dd1	$0de2	$3df9
	0.8.9

	RAM_PAGE	Description
	--------	------------
	0		System + NMI
	1		FAT Driver
	2		CommanDS
	3		TR-DOS+
	4		RST $30 : DB $0A
	5 - 63		Available

	$2000-$3fff	Address where pages are mapped

	$5bff-$5b8c	Espacio libre para la pila (SP=$5c00), 116 bytes
	$5bff-$5b7c	Espacio libre para la pila (si necesario), 132 bytes

	-----------------------------------------------------------------------

init_page5:
	ld	hl,$0de2		; return to page 0
	push	hl
	ld	hl,$0721		; ld (hl),a; or a; ret
	push	hl
	ld	hl,$05e5		; out (SRAM),a
	push	hl
	ld	a,5			; pagina 5
	ld	hl,$3df9		; RAM_PAGE
	ret

load_exec_page5:
	; first open file to load, seek if needed
	ld	b,FILE_HANDLE
	call	load
	ld	hl,$0de2		; return to page 0
	push	hl
	ld	hl,$2000		; exec address
	push	hl
	ld	a,5			; pagina 5
	ld	hl,$05e5		; out (SRAM),a
	push	hl
	ret

load:
	ld	hl,$0dd1		; load to $2000 (max size 7K), and close file
	push	hl
	ret

	----------------------------------------------------------------------

$05e5	out ($e3), a	; d3 e3
	ret		; c9

$0721	ld (hl), a	; 77
	or a		; b7
	ret		; c9

$0dd1	ld a, b		; 78
	push bc		; c5
	ld hl, $2000	; 21 00 20
	ld bc, $1c00	; 01 00 1c
	rst $08		; cf
	db $9d		; 9d		; F_READ
	pop bc		; c1
	push af		; f5
	ld a, b		; 78
	rst $08		; cf
	db $9b		; 9b		; F_CLOSE
	pop af		; f1
	ld b, a		; 47
$0de2	ld a, 0		; 3e 00
	out ($e3), a	; d3 e3		; return to page 0
	ld a, b		; 78
	ret		; c9

	-----------------------------------------------------------------------
*/

; ----------
; hex viewer
; ----------

view		MODULE view

		call atstart

		;
		; Si BASIC, utilizar variables de color y borde
		;
		ld a, (fromBAS)
		or a
		jr z, fNMI

fBAS		ld a, (ATTR_P)
		bit 5, a
		jr z, setContrast1
		and %00111000
		jr setContrast2
setContrast1	or %00000111
setContrast2	ld (colMid), a
		rrca
		rrca
		rrca
		ld b, a
		rrca
		rrca
		and %00111000
		ld c, a
		ld a, b
		and %00000111
		or c
		ld (colTop), a
		;
		rst $18
		DW CLS
		;
		jr view_1

fNMI		ld bc, 24*256+0
		ld a, (colMid)
		call clrScr

view_1		//jp Home

view_2		call prTop

		call prMid

view_3		call waitKey		; wait for key or mouse

		ld c, a			; C = key pressed
		ld hl, actTbl
view_4		ld a, (hl)		; A = key to check, 0 = end of table
		or a
		jr z, view_3		; if end of table, repeat again
		inc hl
		ld e, (hl)		;
		inc hl			;
		ld d, (hl)		; DE = address of action routine
		inc hl
		cp c			; key pressed = key to check ?
		jr nz, view_4		; no, check next key
		ex de, hl		; HL = address of action routine
		jp (hl)			; yes, jump to action routine

exit		call atend
		;
		;
		; Si BASIC, utilizar variables de color y borde
		;
		ld a, (fromBAS)
		or a
		jr z, fNMI2

fBAS2		rst $18
		DW CLS
		;
		ret

fNMI2		ld bc, 24*256+0
		ld a, (colMid)
		call clrScr
		;
		ret

; --------
; at start
; --------

atstart		ld hl, START_ADDR
		ld (pos), hl

		ld a, (RAM_PAGE)
		ld (RAMpg), a

		xor a
		ld (currRAMpg), a
		out ($e3), a		; puerto 227

		ret
; --------
; at end
; --------

atend		ld a, (RAMpg)
		ld (currRAMpg), a
		out ($e3), a		; puerto 227

		ret

; --------------
; print top line
; --------------

prTop		MODULE prTop

		ld bc, 1*256+0		; 1 line from line 0
		ld a, (colTop)		; color
		call clrScr
		;
		ld hl, msgTop1
		call prStr
		;
		ld a, (currRAMpg)
		ld l, a
		call bin2hex8
		;
		ld hl, msgTop2
		call prStr
		;
		//ld hl, (savedSP)
		//call bin2hex16		; utoa
		ld a, (RAM_PAGE)
		ld l, a
		call bin2hex8
		;
		ld hl, msgTop3
		call prStr
		ld hl, (pos)
		call bin2hex16		; utoa
		ld hl, msgSlash
		call prStr
		ld hl, END_ADDR
		call bin2hex16		; utoa
		;
		; FALTA IMPRIMIR DivIDE/DivMMC RAM page !!!
		;
		ret

		ENDMODULE

; -------------------
; print mid of screen
; -------------------

prMid		MODULE prMid

		ld bc, LINES*256+1	; LINES lines from line 1
		ld a, (colMid)
		call clrScr

		ld hl, msgMid
		call prStr

		ld hl, (pos)
		ld b, LINES
prMid1		push bc			; 1
		push hl			; 2
		push hl			; 3

		;
		; print address
		;
		call bin2hex16
		ld hl, msgAdd
		call prStr

		;
		; print hex dump
		;
		ld b, BYTES
prMid2		pop hl			; 2
		ld a, (hl)
		inc hl
		push hl			; 3
		push bc			; 4

		ld l, a
		call bin2hex8


		pop bc			; 3
		push bc			; 4
		ld a, BYTES/2+1
		cp b
		jr nz, prMid3

		ld hl, msgSP		;
		call prStr		; print spacer

prMid3		pop bc			; 3
		djnz prMid2		; repeat BYTES

		ld hl, msgSP		;
		call prStr		; print spacer

		;
		; print ascii dump
		;
		ld b, BYTES
		pop hl			; 2
prMid4		pop hl			; 1
		ld a, (hl)
		inc hl
		push hl			; 2
		push bc			; 3

		cp $80
		jr nc, prMid5		; greater or EQUal than 128?
		cp $20
		jr nc, prMid6		; greater or EQUal than 32?
prMid5		ld a, $80
prMid6		call prChr		; print it
		;
		pop bc			; 2
		djnz prMid4		; repeat BYTES

		ld hl, msgCR		;
		call prStr		; print new line

		pop hl			; 1
		push hl			; 2
		or a
		ld de, END_ADDR
		sbc hl, de
		pop hl			; 1
		pop bc			; 0
		ret nc			; si >= $3FFF, retornar

		djnz prMid1		; repeat LINES

		ret

		ENDMODULE

; ---------------------
; move to previous page
; ---------------------

PgUp		MODULE PgUp

		ld hl, (pos)
		ld bc, START_ADDR
		or a
		sbc hl, bc
		jp z, view.view_3	; si pos = $2000, retornar
		jp c, view.view_3	; si pos < $2000, retornar

PgUp_1		ld hl, (pos)
		ld bc, LINES*BYTES
		or a
		sbc hl, bc
		ld (pos), hl		; si no pos = pos - LINES*BYTES,

		jp view.view_2		; print top, mid

		ENDMODULE

; -----------------
; move to next page
; -----------------

PgDn		MODULE PgDn

		ld hl, (pos)
		ld bc, LINES*BYTES
		add hl, bc
		ld d,h
		ld e,l			; DE = pos + LINES*BYTES

		or a
		ld bc, END_ADDR
		sbc hl, bc
		jp nc, view.view_3	; si pos + LINES*BYTES >= $3FFF, retornar


		ld (pos), de

		jp view.view_2		; print top, mid

		ENDMODULE

; ------------------
; move to first page
; ------------------

Home		MODULE Home

		ld hl, START_ADDR
		ld (pos), hl

		jp view.view_2		; print top, mid

		ENDMODULE

; ------------------
;
; ------------------

PrevPg		MODULE PrevPg

		ld a, (currRAMpg)
		or a
		jr z, PrevPg_end

		dec a
		ld (currRAMpg), a
		out ($e3), a		; port 227

PrevPg_end	jp view.view_2		; print top, mid

		ENDMODULE

; ------------------
;
; ------------------

NextPg		MODULE NextPg

		ld a, (currRAMpg)
		cp 63
		jr nc, NextPg_end	; page >= 63

		inc a
		ld (currRAMpg), a
		out ($e3), a		; port 227

NextPg_end	jp view.view_2		; print top, mid

		ENDMODULE

; ------------------
;
; ------------------

FirstPg		MODULE FirstPg

		xor a
		ld (currRAMpg), a
		out ($e3), a		; puerto 227

		jp view.view_2		; print top, mid

		ENDMODULE

; ------------------
;
; ------------------

LastPg		MODULE FirstPg

		ld a, 63
		ld (currRAMpg), a
		out ($e3), a		; puerto 227

		jp view.view_2		; print top, mid

		ENDMODULE

		ENDMODULE		; view

;==============================================================================
; F U N C T I O N S
;==============================================================================

; -----------------------------------------------------------------------------
; wait for key or mouse
;
; input:    -
; output:   a - key pressed
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------

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
		call ckMoDS		; checks CAPS SHIFT and SYMBOL SHIFT
		;
		ld hl, keyTbl
nextRow		ld a, (hl)
		or a
		ret z
		inc hl
		ld b, %00010000		; b <- col to test
		in a, ($FE)
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
ckMoDS		ld a, $FE
		in a, ($FE)
		ld b, %00000001
		cpl
		and b
		ld (flagCS), a

		ld a, $7F
		in a, ($FE)
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
		ld bc, $1F		; 31
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
		ld hl, $C9AF
		ld (readJoy), hl
joy5		;
		; no key pressed
		;
		xor a
		ret

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
		jr nz, prStr	;prStr1		; if not EQUal to '0', print it
ignCero		inc hl
		ld a, (hl)
		cp '0'
		jr z, ignCero		; if next digit EQUal to '0', skip '0' on the left
		jr c, impCero		; if next digit below '0', print almost one '0'

		cp '9'
		jr z, prStr	;prStr1		; if EQUal
		jr c, prStr	;prStr1		; or below than '9', print it

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
		cp $18			; greater or EQUal than 24?
		jr nc, err_b		; error if so

		ld (row), a		; store it in row
		ld hl, flgAT		; AT flag
		dec (hl)		; indicates next character is col
		ret			; return

getcol		ld a, b			; restore character
		cp $40			; greater or EQUal than 64?
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
		cp $80 // $84			; greater or EQUal than 132?
		jr nc, prErr		;
		cp $20			; greater or EQUal than 32?
		jr nc, prOk		;
prErr		ld a, ' ' // $80
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
		add hl, de		; HL holDS address of first byte of
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
; C holDS the offset to the routine

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
font		DB $02,$02,$02,$02,$00,$02,$00; SPACE !
		DB $52,$57,$02,$02,$07,$02,$00; " #
		DB $25,$71,$62,$32,$74,$25,$00; $ %
		DB $22,$42,$30,$50,$50,$30,$00; & '
		DB $14,$22,$41,$41,$41,$22,$14; ( )
		DB $20,$70,$22,$57,$02,$00,$00; * +
		DB $00,$00,$00,$07,$00,$20,$20; , -
		DB $01,$01,$02,$02,$04,$14,$00; . /
		DB $22,$56,$52,$52,$52,$27,$00; 0 1
		DB $27,$51,$12,$21,$45,$72,$00; 2 3
		DB $57,$54,$56,$71,$15,$12,$00; 4 5
		DB $17,$21,$61,$52,$52,$22,$00; 6 7
		DB $22,$55,$25,$53,$52,$24,$00; 8 9
		DB $00,$00,$22,$00,$00,$22,$02; : ;
		DB $00,$10,$27,$40,$27,$10,$00; < =
		DB $02,$45,$21,$12,$20,$42,$00; > ?
		DB $23,$55,$75,$77,$45,$35,$00; @ A
		DB $63,$54,$64,$54,$54,$63,$00; B C
		DB $67,$54,$56,$54,$54,$67,$00; D E
		DB $73,$44,$64,$45,$45,$43,$00; F G
		DB $57,$52,$72,$52,$52,$57,$00; H I
		DB $35,$15,$16,$55,$55,$25,$00; J K
		DB $45,$47,$45,$45,$45,$75,$00; L M
		DB $62,$55,$55,$55,$55,$52,$00; N O
		DB $62,$55,$55,$65,$45,$43,$00; P Q
		DB $63,$54,$52,$61,$55,$52,$00; R S
		DB $75,$25,$25,$25,$25,$22,$00; T U
		DB $55,$55,$55,$55,$27,$25,$00; V W
		DB $55,$55,$25,$22,$52,$52,$00; X Y
		DB $73,$12,$22,$22,$42,$72,$03; Z [
		DB $46,$42,$22,$22,$12,$12,$06; \ ]
		DB $20,$50,$00,$00,$00,$00,$0F; ^ _
		DB $20,$10,$03,$05,$05,$03,$00; sterling_pound a
		DB $40,$40,$63,$54,$54,$63,$00; b c
		DB $10,$10,$32,$55,$56,$33,$00; d e
		DB $10,$20,$73,$25,$25,$43,$06; f g
		DB $42,$40,$66,$52,$52,$57,$00; h i
		DB $14,$04,$35,$16,$15,$55,$20; j k
		DB $60,$20,$25,$27,$25,$75,$00; l m
		DB $00,$00,$62,$55,$55,$52,$00; n o
		DB $00,$00,$63,$55,$55,$63,$41; p q
		DB $00,$00,$53,$66,$43,$46,$00; r s
		DB $00,$20,$75,$25,$25,$12,$00; t u
		DB $00,$00,$55,$55,$27,$25,$00; v w
		DB $00,$00,$55,$25,$25,$53,$06; x y
		DB $01,$02,$72,$34,$62,$72,$01; z {
		DB $24,$22,$22,$21,$22,$22,$04; | }
		DB $56,$A9,$06,$04,$06,$09,$06; ~ copyright

		//DB $00,$30,$30,$30,$30,$35,$00; [?] [..]      128, 129

; ---------
; key table
; ---------
;
; (5 x 3 + 1) x 8 + 1 = 129 bytes
; (5 x 4 + 1) x 8 + 1 = 169 bytes
;
keyTbl		DB $F7
		DB '5', '4', '3', '2', '1'; NORMAL
		DB '%', '$', '#', '@', '!'; SS
		DB K_LEFT, $00, $00, $00, K_EDIT; CS
		;DB      $00, $00, $00, $00, $00         ; E+SS
		DB $EF
		DB '6', '7', '8', '9', '0'
		DB '&', $27, '(', ')', '_'
		DB K_DOWN, K_UP, K_RIGHT, $00, K_DELETE
		;DB      $00, $00, $00, $00, $00
		DB $FB
		DB 'T', 'R', 'E', 'W', 'Q'
		DB '>', '<', $00, $00, $00
		DB $00, $00, $00, $00, $00
		;DB      $00, $00, $00, $00, $00
		DB $DF
		DB 'Y', 'U', 'I', 'O', 'P'
		DB $00, $00, $00, ';', '"'
		;DB      $00, $00, $00, $00, $00
		DB '[', ']', $00, $00, $7F
		DB $FD
		DB 'G', 'F', 'D', 'S', 'A'
		DB $00, K_TO, $00, $00, $00
		;DB      $00, $00, $00, $00, $00
		DB '}', '{', '\', '|', '~'
		DB $BF
		DB 'H', 'J', 'K', 'L', K_ENTER
		DB '^', '-', '+', '=', K_SS_ENTER
		DB $00, $00, $00, $00, $00
		;DB      $00, $00, $00, $00, $00
		DB $FE
		DB 'V', 'C', 'X', 'Z', $00; CS IGNORED
		DB '/', '?', $60, ':', $00
		DB $00, $00, $00, $00, $00
		;DB      $00, $00, $00, $00, $00
		DB $7F
		DB 'B', 'N', 'M', $00, ' '; SS IGNORED
		DB '*', ',', '.', $00, $00
		DB $00, $00, $00, $00, K_BREAK
		;DB      $00, $00, $00, $00, $00
		DB 0

; -------------
; actions table
; -------------
;
actTbl		DB K_BREAK		; exit
		DW view.exit
kEnter		DB K_ENTER
		DW view.exit
		DB '0'			; cursor joy
		;DB      '0'             ; sinclair 2 joy
		;DB      '5'             ; sinclair 1 joy
		DW view.exit
kUp		DB K_UP			; prev page
		DW view.PgUp
		DB '7'			; cursor joy
		;DB      '9'             ; sinclair 2 joy
		;DB      '4'             ; sinclair 1 joy
		DW view.PgUp
kLeft		DB K_LEFT
		DW view.PgUp
		DB '5'			; cursor joy
		;DB      '6'             ; sinclair 2 joy
		;DB      '1'             ; sinclair 1 joy
		DW view.PgUp
kDown		DB K_DOWN		; next page
		DW view.PgDn
		DB '6'			; cursor joy
		;DB      '8'             ; sinclair 2 joy
		;DB      '3'             ; sinclair 1 joy
		DW view.PgDn
kRight		DB K_RIGHT
		DW view.PgDn
		DB '8'			; cursor joy
		;DB      '7'             ; sinclair 2 joy
		;DB      '2'             ; sinclair 1 joy
		DW view.PgDn
		DB K_EDIT		; first page
		DW view.Home
		DB '1'			; first page
		DW view.Home

		DB '-'
		DW view.PrevPg
		DB 'J'
		DW view.PrevPg
		DB '+'
		DW view.NextPg
		DB 'K'
		DW view.NextPg
		DB '^'
		DW view.FirstPg
		DB 'H'
		DW view.FirstPg
		DB '='
		DW view.LastPg
		DB 'L'
		DW view.LastPg

		DB 0

; --------
; messages
; --------
;
msg0001		DB 13
		DB 'RAMview v'
		VERSION
		DB ' By Dr. Slump 2020',13,0
msg0002		DB 13
		DB 'Usage: RAMview [-?]',13;,0
		DB 13
		DB 'Shows DivIDE/MMC RAM pages',13
		DB 13
		DB 'Navigation keys:',13
		DB 13
		DB ' ENTER BREAK    - Exit',13
		DB ' 7 UP 5 LEFT    - Prev screen',13
		DB ' 6 DOWN 8 RIGHT - Next screen',13
		DB ' 1 EDIT         - First screen',13
		DB ' - J            - Prev RAM page',13
		DB ' + K            - Next RAM page',13
		DB ' ^ H            - First RAM page',13
		DB ' * L            - Last RAM page',13,13
		DB ' Kempston & Cursor joysticks',13,0
msg0003		DB 'Invalid command lin', 'e'+$80

msgErr		DB 13
		DB 'esxDOS error ',0

msgTop1		DB $16,0,1,'Page: ',0
//msgTop2		DB $16,0,11,'SP: ',0
msgTop2		DB $16,0,11,'RAM_PAGE: ',0
msgTop3		DB $16,0,43,'Address: ',0
msgMid		DB $16,1,0,0
msgSP		DB '  ',0
msgAdd		DB ':  ',0
msgSlash	DB ' / ',0
msgCR		DB 13,0

colTop		DB COL_TOP		; top screen color
colMid		DB COL_MID		; mid screen color

; --------------------------------
; variables for keyboard functions
; --------------------------------
;
flagCS		DB 0			; CS pressed
flagSS		DB 0			; SS pressed

; -------------------------------------------
; variables for 64 columns printing functions
; -------------------------------------------
;
flgAT		DB 0			; AT flag
row		DB 0			; row
col		DB 0			; col

; -----------------------
; buffer to utoa function
; -----------------------
;
utoaBuf		DS 7, 0

; ---------------
; used on waitKey
; ---------------
;
prevJoy		DB 0			; previous joystroke
prevKey		DB 0			; previous keystroke

; ---------------
; hex viewer vars
; ---------------
;
fromBAS		DB 0
		;
_savedSP	EQU $$$
savedSP		DW 0
		;
_savedRAMTOP	EQU $$$
savedRAMTOP	DW 0
		;
RAMpg		DB 0

pos		DW 0
currRAMpg	DB 0

; ---------------------
; line arguments parser
; ---------------------

_ptrArgs	EQU $$$
ptrArgs		DW 0
		;
argStr		EQU $
;argStr		DS 127, 0		; DEJAR COMO ULTIMA VARIABLE PARA QUE TENGA
					; EL MAYOR TAMANO POSIBLE
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
		ENT

;------------------------------------------------------------------------------
		IF $ > $2000+7000
		LUA
		sj.error("Resulting code too long")
		ENDLUA
		ENDIF
;------------------------------------------------------------------------------

		END

