;==============================================================================
; Project: hexview.zdsp
; Main File: hexview.asm
; Date: 14/11/2017 12:04:03
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

		include "../esxdos.inc"
		include "../errors.inc"

;==============================================================================
; D E F I N I T I O N S
;==============================================================================
;
VERSION		macro
		db '0.4'
		endm

LINES		equ 23
BYTES		equ 16

BORDCR		equ $5C48		; 23624 Border colour * 8; also contains the attributes normally used for the lower half of the screen.
ATTR_P		equ $5C8D		; 23693 Permanent current colours, etc (as set up by colour statements).
ATTR_T		equ $5C8F		; 23695 Temporary current colours, etc (as set up by colour items).

; -----------------------------------------------------------------------------
; Colors and attributes
; -----------------------------------------------------------------------------
BLACK		equ 0
BLUE		equ 1
RED		equ 2
MAGENTA		equ 3
GREEN		equ 4
CYAN		equ 5
YELLOW		equ 6
WHITE		equ 7

BRIGHT		equ $40
FLASH		equ $80

; -----------------------------------------------------------------------------
; Colors used in GUI
; -----------------------------------------------------------------------------
COL_MID		equ BLACK*8+WHITE	; black paper, white ink
COL_TOP		equ WHITE*8+BLACK	; white paper, black ink
		;COL_BOT         equ     WHITE*8+BLACK           ; white paper, black ink
		;COL_CUR         equ     BRIGHT+BLUE*8+WHITE     ; blue paper, bright white ink
		;COL_ERR         equ     BRIGHT+RED*8+WHITE      ; red paper, bright white ink

; -----------------------------------------------------------------------------
; Key table
; -----------------------------------------------------------------------------
K_EDIT		equ $07
K_LEFT		equ $08
K_RIGHT		equ $09
K_DOWN		equ $0A
K_UP		equ $0B
K_DELETE	equ $0C
K_ENTER		equ $0D

K_TO		equ $CC			; SS+F

; no mapping on speccy BASIC

K_BREAK		equ $1C

K_SS_ENTER	equ $1D

; -----------------------------------------------------------------------------
; current drive (missing from esxdos.inc)
; -----------------------------------------------------------------------------
;CUR_DRIVE	equ '*'

;==============================================================================
; M A I N
;==============================================================================
;
		org $2000

;
; esxDOS  call   return
; version method address       SP
; ------- ------ -----------   ----
; v0.8.0  BASIC  4042   0FCA
;         NMI    4069   0FE5
; v0.8.5  BASIC  3495   0DA7
;         NMI    3522   0DC2
; v0.8.6  BASIC  3503   0DAF
;         NMI    3530   0DCA
; v0.8.6  BASIC  3477   0D95
; b5.1    NMI    3504   0DB0
; v0.8.7  BASIC
;         NMI
; v0.8.8  BASIC  3492   0DA4   FF4C
;         NMI    3519   0DBF   3DD6

;
; To compare stuff, simply do a CP, and if the zero flag is set,
; A and the argument were equal, else if the carry is set the argument was
; greater, and finally, if neither is set, then A must be greater.
;
;       cp val                  cp val
;       ------------------      --------------
;       a==val  z       nc      nc      a>=val
;       a>val   nz      nc      c       a<val
;       a<val   nz      c       nz      a!=val
;                               z       a==val
;
; too much time working with x86 processors...
;

main		ld (savedSP), sp
		ld (ptrArgs), hl	; save pointer to args


		or a
		ld hl, $4000
		sbc hl, sp
		ld a, 1
		jr c, main_1		; sp > $4000 (loaded from BASIC)
		xor a
main_1		ld (fromBAS), a		; 0-Loaded from NMI, 1-Loaded from BASIC

; -----------------------------------------------------------------------------

		ld hl, (ptrArgs)
		ld a, h
		or l
		jr z, errArgs		; no args, show help

scanArg		call getArg
		or a
		jr z, Exit		; =0, no more args, exit
isOpt		cp 1
		jr z, getOpts		; =1, is a option, get it
		cp 2
		jr nz, errArgs		; >2, imposible state, error
		;
		; =2, HL pointer to file/directory name
		;
		ld hl, argStr
		call view		; is a file/directory name, view
		;
		jr scanArg		; next arg

getOpts		call getArg		; get option value
		cp 2
		jr nz, errArgs		; no value, error

		ld hl, argStr
readOpt		ld a, (hl)		; get opt
		or a
		jr z, scanArg		; no more options in current arg, next arg
		cp '?'
		jr z, errArgs		; help         ; help, show it and exit

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

nextOpt		inc hl
		jr readOpt		; next opt

; -----------------------------------------------------------------------------

; ----
; exit
; ----

Exit		or a			; clear CF (no error)
		ret

; ----
; help
; ----

errArgs		ld a, (fromBAS)
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

; ------------
; process args
; ------------
;
; HL=Pointer to args or HL=0 if no args
; HL is typically pointing directly to BASIC line, so for END marker
; you should check for $0D, ":" as well as 0.
;
getArg		ld hl, (ptrArgs)
		ld de, argStr
getChr		ld a, (hl)
		inc hl
		or a
		jr z, getEnd
		cp $0D
		jr z, getEnd
		cp ':'
		jr z, getEnd
		cp ' '
		jr z, getChr
		cp '-'
		jr nz, getStr
		ld a, 1			; A=1 option arg
		jr savPtr
getEnd		xor a			; A=0 no more args
savPtr		ld (ptrArgs), hl
		ret

getStr		ld (de), a
		inc de
		ld a, (hl)
		or a
		jr z, getStr1
		cp $0D
		jr z, getStr1
		cp ':'
		jr z, getStr1
		cp '-'
		jr z, getStr1
		cp ' '
		jr z, getStr1
		inc hl
		jr getStr
getStr1		xor a
		ld (de), a
		ld a, 2			; A=2 string arg
		jr savPtr

; ----------
; hex viewer
; ----------
;
view		call open
		;

		;
		; Si BASIC, utilizar variables de color y borde
		;
		ld a, (fromBAS)
		or a
		jr z, fNMI

fBAS		ld a, (ATTR_P)
		bit 5, a
		jr z, ______1
		and %00111000
		jr ______2
______1		or %00000111
______2		ld (colMid), a
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
		dw $0D6B		; CLS
		;
		jr mainL2

fNMI		ld bc, 24*256+0
		;ld      a, COL_MID
		ld a, (colMid)
		call clrScr

mainL2		call prTop

mainL3		call prMid

mainL5		call waitKey		; wait for key or mouse

mainL6		ld c, a			; C = key pressed
		ld hl, actTbl
mainL7		ld a, (hl)		; A = key to check, 0 = end of table
		or a
		jr z, mainL5		; if end of table, repeat again
		inc hl
		ld e, (hl)		;
		inc hl			;
		ld d, (hl)		; DE = address of action routine
		inc hl
		cp c			; key pressed = key to check ?
		jr nz, mainL7		; no, check next key
		ex de, hl		; HL = address of action routine
		jp (hl)			; yes, jump to action routine

exit		call close
		;
		;
		; Si BASIC, utilizar variables de color y borde
		;
		ld a, (fromBAS)
		or a
		jr z, fNMI2

fBAS2		rst $18
		dw $0D6B		; CLS
		;
		ret

fNMI2		ld bc, 24*256+0
		;ld      a, COL_MID
		ld a, (colMid)
		call clrScr
		;
		ret

; -----------------------
; error handling routines
; -----------------------
;
; A = esxDOS error number
;
closeFilePrintError
		push af
		ld a, (fhandle)		;
		rst $08			;
		db F_CLOSE		; close file
		pop af
printError
		push af
		ld a, (fromBAS)
		or a
		jr z, __L9
		;rst     $18
		;dw      $0D6B           ; CLS
		ld hl, msg0001
		call prStr1
		ld hl, msgErr
		call prStr1
		pop af
		push af
		ld h, 0
		ld l, a
		call utoa
		ld hl, msgCR
		call prStr1
		;or      a               ; clear CF (no error)
		;ld      sp, (savedSP)
		;ret
__L9		pop af
		scf			; set CF (error)
		ld sp, (savedSP)
		ret

; --------------
; print top line
; --------------
;
prTop		ld bc, 1*256+0		; 1 line from line 0
		;ld      a, COL_TOP      ; color
		ld a, (colTop)		; color
		call clrScr
		;
		ld hl, msgTop
		call prStr
		;
		ld hl, argStr
		call prStr
		;
		ld hl, msgBot
		call prStr
		ld hl, (posH)
		call bin2hex16
		ld hl, (posL)
		call bin2hex16
		ld hl, msgSlash
		call prStr
		ld hl, (bFSsizeH)
		call bin2hex16
		ld hl, (bFSsizeL)
		call bin2hex16
		;
		ret

; -------------------
; print mid of screen
; -------------------
;

posAuxH		dw 0
posAuxL		dw 0

prMid		ld bc, LINES*256+1	; LINES lines from line 1
		;ld      a, COL_MID      ; color
		ld a, (colMid)
		call clrScr

		ld hl, msgMid
		call prStr

		ld hl, (posH)
		ld (posAuxH), hl
		ld hl, (posL)
		ld (posAuxL), hl

		ld hl, 0
		ld (pos), hl

		ld b, LINES
		ld hl, buffer
prMid1		push bc			; 1
		push hl			; 2
		push hl			; 3

		;
		; print address
		;
		ld hl, (posAuxH)
		call bin2hex16
		ld hl, (posAuxL)
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
		;

		;
		; stop print if end of data.
		;
		ld hl, (pos)
		inc hl
		ld (pos), hl
		dec hl
		ld bc, (siz)
		or a
		sbc hl, bc
		;jr      nc, prMid21
		jr c, prMid22
		ld a, ' '
		call prChr
		ld a, ' '
		call prChr
		jr prMid23

		;
prMid22		ld l, a
		call bin2hex8
		;
prMid23		pop bc			; 3
		push bc			; 4
		ld a, BYTES/2+1
		cp b
		jr nz, prMid21
		;
		; print spacer
		;
		ld hl, msgSP
		call prStr
		;
prMid21		pop bc			; 3
		;
		djnz prMid2

		;
		; print spacer
		;
		ld hl, msgSP
		call prStr

		;
		; stop print if end of data.
		;
		ld hl, (pos)
		ld bc, 16
		or a
		sbc hl, bc
		ld (pos), hl

		;
		pop hl			; 2

		;
		; print ascii dump
		;
		ld b, BYTES
prMid3		pop hl			; 1
		ld a, (hl)
		inc hl
		push hl			; 2
		push bc			; 3
		;

		;
		; stop print if end of data.
		;
		ld hl, (pos)
		inc hl
		ld (pos), hl
		dec hl
		ld bc, (siz)
		or a
		sbc hl, bc
		;jr      nc, prMid6
		jr c, prMid7
		pop hl
		pop hl
		pop hl
		ret

prMid7		cp $80
		jr nc, prMid4		; greater or equal than 128?
		cp $20
		jr nc, prMid5		; greater or equal than 32?
prMid4		ld a, ' '
prMid5		call prChr		; print it
		;
prMid6		pop bc			; 2
		djnz prMid3

		;
		; print new line
		;
		ld hl, msgCR
		call prStr
		;
		; add BYTES to address
		;
		ld hl, (posAuxL)
		ld bc, BYTES
		add hl, bc
		push af			; 3
		ld (posAuxL), hl
		ld hl, (posAuxH)
		ld bc, 0
		pop af			; 2
		adc hl, bc
		ld (posAuxH), hl

		;
		; repeat LINES
		;
		pop hl			; 1
		pop bc			; 0
		;
		;djnz    prMid1
		dec b
		jp nz, prMid1

		ret

; ---------------------------------------------
; open file, get size & read first page of data
; ---------------------------------------------
;
open		;
		;
		;
		ld hl, 0
		ld (posL), hl
		ld (posH), hl

		ld hl, argStr		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
		; open if exists, else error
		; read access
		ld a, CUR_DRIVE		; current drive
		rst $08			; screen is saved allways in SYS_DRIVE
		db F_OPEN		; open file
		jp c, printError
		ld (fhandle), a		; file handle

		ld hl, bFStat		; F_STAT buffer
		ld a, (fhandle)		; file handle
		rst $08			;
		db F_FSTAT		; Get file info/status to buffer at HL
		jp c, closeFilePrintError

read		;
		; clear input buffer
		;
		ld hl, buffer
		ld de, buffer+1
		ld bc, LINES*BYTES-1
		xor a
		ld (hl), a
		ldir

		; si pos + LINES*BYTES >= size, leer size - pos bytes
		; sino leer LINES*BYTES bytes

		ld bc, (posH)
		ld de, (posL)
		ld l, 0			; mode (0 from start of file, 1 fwd from current pos, 2 bak from current pos)
		ld a, (fhandle)		; file handle
		rst $08			;
		db F_SEEK		; Seek BCDE bytes
		jp c, closeFilePrintError

		ld hl, (bFSsizeL)
		ld bc, (posL)
		or a
		sbc hl, bc
		ex de, hl
		ld hl, (bFSsizeH)
		ld bc, (posH)
		adc hl, bc
		push hl			; HL:DE = size - pos

		ld hl, LINES*BYTES
		or a
		sbc hl, de
		ld hl, 0
		pop bc
		sbc hl, bc		; si CF=1, resultado negativo, size - pos
		; si CF=0, resultado positivo, LINES*BYTES
		jr nc, read_1
		ld de, LINES*BYTES
read_1		push de
		pop bc
		ld (siz), bc

		;push    bc
		;pop     hl
		;call    bin2hex16
		;pop     hl
		;ret

		ld hl, buffer		; dest
		;ld      bc, LINES*BYTES       ; size
		ld a, (fhandle)		; file handle
		rst $08			;
		db F_READ		; read buffer from file
		jp c, closeFilePrintError

		ret

; ----------
; close file
; ----------
;
close		ld a, (fhandle)		; file handle
		rst $08			;
		db F_CLOSE		; close file
		jp c, printError
		;
		ret

; ---------------------
; move to previous page
; ---------------------
;
PgUp		ld hl, posL
		ld b, 4
PgUp_1		ld a, (hl)
		or a
		jr nz, PgUp_2
		inc hl
		djnz PgUp_1
		jp mainL5		; si pos = 0, retornar

PgUp_2		ld hl, (posL)
		ld bc, LINES*BYTES
		or a
		sbc hl, bc
		ld (posL), hl
		ld hl, (posH)
		ld bc, 0
		sbc hl, bc
		ld (posH), hl		; sino pos = pos - LINES*BYTES,
		; retroceder puntero LINES*BYTES
		; y leer
		call read

		jp mainL2

; -----------------
; move to next page
; -----------------
;
PgDn		ld hl, (posL)
		ld bc, LINES*BYTES
		add hl, bc
		ex de, hl
		ld hl, (posH)
		ld bc, 0
		adc hl, bc
		push hl			; HL:DE = pos + LINES*BYTES

		ld hl, (bFSsizeL)
		or a
		sbc hl, de
		ld hl, (bFSsizeH)
		pop bc
		sbc hl, bc		; si CF=1, resultado negativo
		jp c, mainL5		; si pos + LINES*BYTES >= size, retornar

		ld (posL), de
		ld (posH), bc		; sino pos = pos + LINES*BYTES,
		; avanzar puntero LINES*BYTES
		; y leer
		call read

		jp mainL2

; ------------------
; move to first page
; ------------------
;
Home		ld hl, 0
		ld (posL), hl
		ld (posH), hl		; sino pos = pos + LINES*BYTES,
		; avanzar puntero LINES*BYTES
		; y leer
		call read

		jp mainL2


;==============================================================================
; F U N C T I O N S
;==============================================================================
;
; -----------------------------------------------------------------------------
; wait for keystroke
; -----------------------------------------------------------------------------
;
;waitKey xor     a
;        in      a, ($fe)
;        cpl
;        and     %00011111
;        jr      z, waitKey
;        ret

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
		call ckMods		; checks CAPS SHIFT and SYMBOL SHIFT
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
ckMods		ld a, $FE
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

; ---------
; key table
; ---------
;
; (5 x 3 + 1) x 8 + 1 = 129 bytes
; (5 x 4 + 1) x 8 + 1 = 169 bytes
;
keyTbl		db $F7
		db '5', '4', '3', '2', '1'; NORMAL
		db '%', '$', '#', '@', '!'; SS
		db K_LEFT, $00, $00, $00, K_EDIT; CS
		;db      $00, $00, $00, $00, $00         ; E+SS
		db $EF
		db '6', '7', '8', '9', '0'
		db '&', $27, '(', ')', '_'
		db K_DOWN, K_UP, K_RIGHT, $00, K_DELETE
		;db      $00, $00, $00, $00, $00
		db $FB
		db 'T', 'R', 'E', 'W', 'Q'
		db '>', '<', $00, $00, $00
		db $00, $00, $00, $00, $00
		;db      $00, $00, $00, $00, $00
		db $DF
		db 'Y', 'U', 'I', 'O', 'P'
		db $00, $00, $00, ';', '"'
		;db      $00, $00, $00, $00, $00
		db '[', ']', $00, $00, $7F
		db $FD
		db 'G', 'F', 'D', 'S', 'A'
		db $00, K_TO, $00, $00, $00
		;db      $00, $00, $00, $00, $00
		db '}', '{', '\', '|', '~'
		db $BF
		db 'H', 'J', 'K', 'L', K_ENTER
		db '^', '-', '+', '=', K_SS_ENTER
		db $00, $00, $00, $00, $00
		;db      $00, $00, $00, $00, $00
		db $FE
		db 'V', 'C', 'X', 'Z', $00; CS IGNORED
		db '/', '?', $60, ':', $00
		db $00, $00, $00, $00, $00
		;db      $00, $00, $00, $00, $00
		db $7F
		db 'B', 'N', 'M', $00, ' '; SS IGNORED
		db '*', ',', '.', $00, $00
		db $00, $00, $00, $00, K_BREAK
		;db      $00, $00, $00, $00, $00
		db 0

; -------------
; actions table
; -------------
;
actTbl		db K_BREAK		; exit
		dw exit
kEnter		db K_ENTER
		dw exit
		db '0'			; cursor joy
		;db      '0'             ; sinclair 2 joy
		;db      '5'             ; sinclair 1 joy
		dw exit
kUp		db K_UP			; prev page
		dw PgUp
		db '7'			; cursor joy
		;db      '9'             ; sinclair 2 joy
		;db      '4'             ; sinclair 1 joy
		dw PgUp
kLeft		db K_LEFT
		dw PgUp
		db '5'			; cursor joy
		;db      '6'             ; sinclair 2 joy
		;db      '1'             ; sinclair 1 joy
		dw PgUp
kDown		db K_DOWN		; next page
		dw PgDn
		db '6'			; cursor joy
		;db      '8'             ; sinclair 2 joy
		;db      '3'             ; sinclair 1 joy
		dw PgDn
kRight		db K_RIGHT
		dw PgDn
		db '8'			; cursor joy
		;db      '7'             ; sinclair 2 joy
		;db      '2'             ; sinclair 1 joy
		dw PgDn
		db K_EDIT		; first page
		dw Home
		db 0

; --------
; messages
; --------
;
msg0001		db 13
		db 'hexview v'
		VERSION
		db ' By Dr. Slump 2020',13,0
msg0002		db 13
		db 'Usage: hexview [filename]...',13;,0
		db 13
		db 'Shows a hex dump of file(s)',13
		db 13
		db 'Navigation keys:',13
		db 13
		db '  ENTER, BREAK - Exit',13
		db '  UP,    LEFT  - Prev page',13
		db '  DOWN,  RIGHT - Next page',13
		db '         EDIT  - First page',13,13
		db '  Kempston & Cursor joysticks',13,0
msg0003		db 'Invalid command lin', 'e'+$80

msgErr		db 13
		db 'esxDOS error ',0

msgTop		db $16,0,1,0
msgBot		db $16,0,44,0
msgMid		db $16,1,0,0
msgSP		db '  ',0
msgAdd		db ':  ',0
msgSlash	db ' / ',0
msgCR		db 13,0

colTop		db COL_TOP
colMid		db COL_MID

; --------------------------------
; variables for keyboard functions
; --------------------------------
;
flagCS		db 0			; CS pressed
flagSS		db 0			; SS pressed

; -------------------------------------------
; variables for 64 columns printing functions
; -------------------------------------------
;
flgAT		db 0			; AT flag
row		db 0			; row
col		db 0			; col

; -----------------------
; buffer to utoa function
; -----------------------
;
utoaBuf		ds 7, 0

; ---------------
; used on waitKey
; ---------------
;
prevJoy		db 0			; previous joystroke
prevKey		db 0			; previous keystroke

; ---------------
; hex viewer vars
; ---------------
;
fromBAS		db 0
savedSP		dw 0

buffer		ds LINES*BYTES, 0
fhandle		db 0
posL		dw 0
posH		dw 0
siz		dw 0			; size current buffer
pos		dw 0			; position current buffer

; --------------
; F_FSTAT buffer
; --------------
;
bFStat
bFSdrive	db 0			; <byte>  drive
bFSdevice	db 0			; <byte>  device
bFSattrib	db 0			; <byte>  file attributes (like MSDOS)
bFSdateL	dw 0			;
bFSdateH	dw 0			; <dword> date
bFSsizeL	dw 0			;
bFSsizeH	dw 0			; <dword> file size

; ---------------------
; line arguments parser
; ---------------------
;
ptrArgs		dw 0
argStr		equ $
;argStr          ds      127, 0  ; DEJAR COMO ULTIMA VARIABLE PARA QUE TENGA
;                                ; EL MAYOR TAMANO POSIBLE

;------------------------------------------------------------------------------
		IF $ > $2000+7000
		.ERROR Resulting code too long
		ENDIF
;------------------------------------------------------------------------------

		end main

