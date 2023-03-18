;==============================================================================
; Project: pages.zdsp
; File: macros.inc
; Date: 07/10/2022 17:16:53
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

/*
	-----------------------------------------------------------------------

	DivMMC:

	Version	$05e5	$0721	$0dd1	$0de2	RAM_PAGE
	-------	-----	-----	-----	-----	--------
	0.8.5	$05d3	$0711	$0dd4	$0de5	$3df9
	0.8.6	$05e5	$0721	$0dc2	$0dd3	$3df9
	0.8.7	$05e5	$0721	$0dca	$0ddb	$3df9
	0.8.8	$05e5	$0721	$0dd1	$0de2	$3df9
	0.8.9	$05e5	$0721	$0dd9	$0dea	$3df9

	DivIDE:

	Version	$05e5	$0721	$0dd1	$0de2	RAM_PAGE
	-------	-----	-----	-----	-----	--------
	0.8.5	$05d3	$0711	$0dd4	$0de5	$3df9
	0.8.6	$05e5	$0721	$0dc2	$0dd3	$3df9
	0.8.7	$05e5	$0721	$0dca	$0ddb	$3df9
	0.8.8	$05e5	$0721	$0dd1	$0de2	$3df9
	0.8.9	$05e5	$0721	$0dd9	$0dea	$3df9

	RAM_PAGE	Description
	--------	------------
	0		System + NMI
	1		FAT Driver
	2		Commands
	3		TR-DOS+
	4		RST $30 : DB $0A
	5 - 63		Available

	$2000-$3fff	Address where pages are mapped

	$5bff-$5b8c	Espacio libre para la pila (SP=$5c00), 116 bytes
	$5bff-$5b7c	Espacio libre para la pila (si necesario), 132 bytes

	-----------------------------------------------------------------------

init_page5:
	ld	hl,$0dea		; return to page 0
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
	ld	hl,$0dea		; return to page 0
	push	hl
	ld	hl,$2000		; exec address
	push	hl
	ld	a,5			; pagina 5
	ld	hl,$05e5		; out (SRAM),a
	push	hl
	ret

load:
	ld	hl,$0dd9		; load to $2000 (max size 7K), and close file
	push	hl
	ret

	----------------------------------------------------------------------

$05e5	out ($e3), a	; d3 e3
	ret		; c9

$0721	ld (hl), a	; 77
	or a		; b7
	ret		; c9

$0dd9	ld a, b		; 78
	push bc		; c5
	ld hl, $2000	; 21 00 20
	ld bc, $1c00	; 01 00 1c
$0de1	rst $08		; cf
	db $9d		; 9d		; F_READ
	pop bc		; c1
	push af		; f5
	ld a, b		; 78
	rst $08		; cf
	db $9b		; 9b		; F_CLOSE
	pop af		; f1
	ld b, a		; 47
$0dea	ld a, 0		; 3e 00
	out ($e3), a	; d3 e3		; return to page 0
	ld a, b		; 78
	ret		; c9

	-----------------------------------------------------------------------
*/

;==============================================================================
; D E F I N I T I O N S
;==============================================================================
;
		MACRO VERSION
		DB '1.0'
		ENDM

; -----------------------------------------------------------------------------
; DivIDE/DivMMC and esxDOS parameters
; -----------------------------------------------------------------------------

RAM_PAGE	EQU $3df9
START_ADDR	EQU $2000
END_ADDR	EQU $3fff+1

; -----------------------------------------------------------------------------
; Macros
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; MACRO CHPAGE num, addr
; Change to page num and continue execution at retaddr
;
; $05e5	out ($e3), a	; d3 e3
;	ret		; c9
; -----------------------------------------------------------------------------

		MACRO CHPAGE num, retaddr

		ld	hl, retaddr
		push	hl
		ld	hl, $05e5
		push	hl
		ld	a, num
		ret


		ENDM

; -----------------------------------------------------------------------------
; MACRO
;
;
;$0dd9	ld a, b		; 78
;	push bc		; c5
;	ld hl, $2000	; 21 00 20	; START OF PAGE
;	ld bc, $1c00	; 01 00 1c	; 7168 bytes (7K)
;$0de1	rst $08		; cf
;	db $9d		; 9d		; F_READ
;	pop bc		; c1
;	push af		; f5
;	ld a, b		; 78
;	rst $08		; cf
;	db $9b		; 9b		; F_CLOSE
;	pop af		; f1
;	ld b, a		; 47
;$0dea	ld a, 0		; 3e 00
;	out ($e3), a	; d3 e3		; return to page 0
;	ld a, b		; 78
;	ret		; c9
; -----------------------------------------------------------------------------

		MACRO LDPAGE num, retaddr, filename, offset, bufsize

		ld	hl, retaddr
		push	hl
		ld	hl, $05e5
		push	hl

		; BUSCAR pop af; ret	f1 c9

		ld	hl, filename
		ld	b, FA_OPEN_EX|FA_READ
		ld	a, SYS_DRIVE
		rst	$08
		db	F_OPEN		; a = HANDLE
		ld	b, a
		push	bc
		ld	bc, 0
		ld	de, offset
		rst	$08
		db	F_SEEK
		pop	bc		; b = HANDLE
		ld	a, b
		ld	hl, $2000
		ld	bc, bufsize
		ld	hl, $0de1
		push	hl

		ret

		ENDM

