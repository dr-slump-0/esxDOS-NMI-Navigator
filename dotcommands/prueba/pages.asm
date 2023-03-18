;==============================================================================
; Project: prueba.zdsp
; File: pages.asm
; Date: 05/06/2020 23:07:57
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

/*
	é para 0.8.8, para outras talvez alguns endereços mudem
	tanto para pagina 5, como 6, como 7, etc...
	em divMMC, claro
	a versão 0.9.x ja inicializa todas as paginas
*/

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

/*
	en ROM, versión 0.8.8:
*/

$3df9	db 0
RAM_PAGE equ $3df9

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
/*
	DivMMC:

	Version	$05e5	$0721	$0dd1	$0de2	RAM_PAGE
	-------	-----	-----	-----	-----	--------
	0.8.5	$05d3	$0711	$0dd4	$0de5	$3df9
	0.8.6	$05e5	$0721	$0dc2	$0dd3	$3df9
	0.8.7	$05e5	$0721	$0dca	$0ddb	$3df9
	0.8.8	$05e5	$0721	$0dd1	$0de2	$3df9

	DivIDE:

	Version	$05e5	$0721	$0dd1	$0de2	RAM_PAGE
	-------	-----	-----	-----	-----	--------
	0.8.5	$05d3	$0711	$0dd4	$0de5	$3df9
	0.8.6	$05e5	$0721	$0dc2	$0dd3	$3df9
	0.8.7	$05e5	$0721	$0dca	$0ddb	$3df9
	0.8.8	$05e5	$0721	$0dd1	$0de2	$3df9

	RAM_PAGE	Description
	--------	------------
	0		System + NMI
	1		FAT Driver
	2		Commands
	3		TR-DOS
	4		RST $30 : DB $0A
	5 - 63		Available

	$2000-$3fff	Address where pages are mapped

	$5bff-$5b8c	Espacio libre para la pila (SP=$5c00), 116 bytes
	$5bff-$5b7c	Espacio libre para la pila (si necesario), 132 bytes

	Reescribir hexview, opción de ver RAM pages. -discriminar si se llama
	desde ROM o RAM en función del valor de SP.

*/

