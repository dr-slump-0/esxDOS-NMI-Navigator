;==============================================================================
; Project: NMI.zdsp
; File: NMI.inc
; Date: 29/07/2017 10:58:43
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; DEFINITIONS
;==============================================================================

M_VERSION	MACRO
		//db 'v0.0.20'
		db 'v-.-.--'
		ENDM

; -----------------------------------------------------------------------------
; DivIDE and DivMMC paging definitions
; -----------------------------------------------------------------------------
PAGE_START	EQU $2000
PAGE_LENGTH	EQU $1c00
RAM_PAGE	EQU $3df9		; Page number

NMI_STACK	EQU $5c00
BACKED_UP_RAM	EQU $5b00		; Size: 57 + 64 = 121

; -----------------------------------------------------------------------------
; max number of entries in dir, it must be multiple of 22
; -----------------------------------------------------------------------------
		//DEFINE _POINTER4BYTES
		IFDEF _POINTER4BYTES
MAXENTR		equ 322*22	// 7084
		ELSE
MAXENTR		equ 100*22 //436*22	// 9592
		ENDIF

; -----------------------------------------------------------------------------
; Overlay system
; -----------------------------------------------------------------------------
SIZ_OVR		equ 693			; size of overlay buffer

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
; Key table
; -----------------------------------------------------------------------------
K_EDIT		equ $07
K_LEFT		equ $08
K_RIGHT		equ $09
K_DOWN		equ $0a
K_UP		equ $0b
K_DELETE	equ $0c
K_ENTER		equ $0d

K_AT		equ $ac			; SS+I
K_TO		equ $cc			; SS+F
K_MERGE		equ $d5			; SS+T

; no mapping on speccy BASIC

K_BREAK		equ $1c

K_SS_ENTER	equ $1d

K_CS_ENTER	equ $1e

; -----------------------------------------------------------------------------
; Colors used in GUI
; -----------------------------------------------------------------------------
COL_MID		equ BLACK*8+WHITE	; black paper, white ink
COL_TOP		equ WHITE*8+BLACK	; white paper, black ink
COL_BOT		equ WHITE*8+BLACK	; white paper, black ink
COL_CUR		equ BRIGHT+BLUE*8+WHITE	; blue paper, bright white ink
COL_ERR		equ BRIGHT+RED*8+WHITE	; red paper, bright white ink

;==============================================================================
; MACROS
;==============================================================================

; -----------------------------------------------------------------------------
; MACRO	CHECK_VERSION
; Return esxDOS version into register a
;
; v0.8.5-DivIDE   $00b8 (184)
; v0.8.5-DivMMC   $00b8 (184)
; v0.8.6-DivIDE   $00a8 (168)
; v0.8.6-DivMMC   $00a8 (168)
; v0.8.7-DivIDE   $00a7 (167)
; v0.8.7-DivMMC   $00a7 (167)
; v0.8.8-DivIDE   $00a8 (168)
; v0.8.8-DivMMC   $00a8 (168)
; v0.8.9-DivIDE   $00a8 (168)
; v0.8.9-DivMMC   $00a8 (168)
; -----------------------------------------------------------------------------

		MACRO CHECK_VERSION

		ld hl, $00b8+1
		ld a, '0'
		cp (hl)
		jr nz, notV085
		inc hl
		inc hl
		ld a, '8'
		cp (hl)
		jr nz, notV085
		inc hl
		inc hl
		ld a, '5'
		cp (hl)
		jr z, ver085

notV085		ld hl, $00a7+1
		ld a, '0'
		cp (hl)
		jr nz, notV087
		inc hl
		inc hl
		ld a, '8'
		cp (hl)
		jr nz, notV087
		inc hl
		inc hl
		ld a, '7'
		cp (hl)
		jr z, ver087

notV087		ld hl, $00a8+1
		ld a, '0'
		cp (hl)
		jr nz, notV086
		inc hl
		inc hl
		ld a, '8'
		cp (hl)
		jr nz, notV086
		inc hl
		inc hl
		ld a, '6'
		cp (hl)
		jr z, ver086
		ld a, '8'
		cp (hl)
		jr z, ver088
		ld a, '9'
		cp (hl)
		jr z, ver089

notV086		xor a
ver085
ver087
ver086
ver088
ver089
		ENDM

;==============================================================================
; MACROS TO WORK WITH DIVXXX PAGES AND ESXDOS
;==============================================================================

; -----------------------------------------------------------------------------
; MACRO	INITPG numPg
; Initialize page numPg writing numPg at RAM_PAGE
;
; $05e5	out ($e3), a	; d3 e3		; return to page a
;	ret		; c9
;
; $0721	ld (hl), a	; 77
;	or a		; b7
;	ret		; c9
;
; $0dea	ld a, 0		; 3e 00
;	out ($e3), a	; d3 e3		; return to page 0
;	ld a, b		; 78
;	ret		; c9

; -----------------------------------------------------------------------------

		MACRO	INITPG numPg

		ld	a, numPg
.InitPagesL1	cp	6
		jr	c, .InitPagesL2		; end if a < 6

		dec	a
		ld	b, a

		ld	hl, .InitPagesL1
		push	hl
		ld	hl, $0dea		; ld a, 0; out ($e3), a; ld a, b; ret; return to page 0
		push	hl
		ld	hl, $0721		; ld (hl), a; or a; ret; mark page a
		push	hl
		ld	hl, $05e5		; out ($e3), a; ret; switch to page a
		push	hl
		ld	hl, RAM_PAGE
		ret
.InitPagesL2

		ENDM

; -----------------------------------------------------------------------------
; MACRO LOADPG pgNum, offset, file
; LOAD 7168 bytes of code from file into page pgNum at address offset
;
; $05e5	out ($e3), a	; d3 e3		; return to page a
;	ret		; c9
;
; $0dd9	ld a, b		; 78
;	push bc		; c5
;	ld hl, $2000	; 21 00 20	; START OF PAGE
;	ld bc, $1c00	; 01 00 1c	; 7168 bytes (7K)
; 	rst $08		; cf
;	db $9d		; 9d		; F_READ
;	pop bc		; c1
;	push af		; f5
;	ld a, b		; 78
;	rst $08		; cf
;	db $9b		; 9b		; F_CLOSE
;	pop af		; f1
;	ld b, a		; 47
; $0dea	ld a, 0		; 3e 00
;	out ($e3), a	; d3 e3		; return to page 0
;	ld a, b		; 78
;	ret		; c9
; -----------------------------------------------------------------------------

		MACRO	LOADPG pgNum, offset, file

		ld	hl, .LoadPageL1
		push	hl

		ld	hl, file
		ld	b, FA_OPEN_EX|FA_READ
		ld	a, SYS_DRIVE
		rst	$08
		db	F_OPEN

		ld	b, a			; a = HANDLE
		push	bc
		ld	bc, 0
		ld	de, offset
		ld	l, 0			; 0 from start of file
		rst	$08
		db	F_SEEK
		pop	bc			; b = HANDLE

		ld	hl, $0dd9		; ld a, b; push bc; ld hl, $2000; ld bc, $1c00; rst $08; db F_READ; pop bc; push af; ld a, b; rst $08; db F_CLOSE; popaf; ld b, a; ld a, 0; out ($e3), a; ld a, b; ret
		push	hl

		ld	hl, $05e5		; out ($e3), a; ret; switch to page a
		push	hl
		ld	a, pgNum
		ret
.LoadPageL1
		ENDM

; -----------------------------------------------------------------------------
; MACRO CALLPG pgNum, addr
; CALL to address addr on page pgNum
;
; $05e5	out ($e3), a	; d3 e3		; return to page a
;	ret		; c9
;
; $0dea	ld a, 0		; 3e 00
;	out ($e3), a	; d3 e3		; return to page 0
;	ld a, b		; 78
;	ret		; c9
; -----------------------------------------------------------------------------

		MACRO	JUMPPG pgNum, addr

		//ld	hl, .RunPgL1
		//push	hl
		//ld	hl, $0dea		; ld a, 0; out ($e3), a; ld a, b; ret; switch to page 0
		//push	hl
		ld	hl, addr
		push	hl
		ld	hl, $05e5		; out ($e3), a; ret; switch to page a
		push	hl
		ld	a, pgNum
		ret
//.RunPgL1
		ENDM

; -----------------------------------------------------------------------------
; MACRO	RETPG0
; RETURN to page 0 address on stack
;
; $0dea	ld a, 0		; 3e 00
;	out ($e3), a	; d3 e3		; return to page 0
;	ld a, b		; 78
;	ret		; c9
; -----------------------------------------------------------------------------

		//MACRO	RETPG0

		//ld	hl, $0dea		; ld a, 0; out ($e3), a; ld a, b; ret; return to page 0
		//push	hl
		//ret

		//ENDM


