;==============================================================================
; Project: init.zdsp
; Main File: init.asm
; Date: 02/10/2017 11:29:11
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; ---------
; init file
; ---------
;
init		ld a, (ldConf)		;
		or a			;
		jr nz, doInit		; first time we call NMI navigator

		ld a, 1			; return to mainL1 (reload dir and reprint all)
		ret			;

doInit		;
		; check ESXDOS version
		;
		; there are a syscall to check ESXDOS version?!
		; tests with M_DOSVERSION API call returns inconclusive results
		;
		; v0.8.5-DivIDE   $b8 (184)
		; v0.8.5-DivMMC   $b8 (184)
		; v0.8.6-DivIDE   $a8 (168)
		; v0.8.6-DivMMC   $a8 (168)
		; v0.8.7-DivIDE   $a7 (167)
		; v0.8.7-DivMMC   $a7 (167)
		; v0.8.8-DivIDE   $a8 (168)
		; v0.8.8-DivMMC   $a8 (168)
		; v0.8.9-DivIDE   $a8 (168)
		; v0.8.9-DivMMC   $a8 (168)
		;
		ld hl, $00a8
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

notV087		ld hl, $00a9
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
		jr z, ver086_8
		ld a, '8'
		cp (hl)
		jr z, ver086_8
		ld a, '9'
		cp (hl)
		jr z, ver086_8

notV086		ld hl, $00b9
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

notV085		ld hl, msgV086		; use printError when it works Ok?
		call prStr
		call waitKey
		jp exitNMI
		;ret
		;
		; En caso de error debe retornar, no cargar el navegador NMI
		;

		;
		; version is 0.8.5
		;
ver085		ld (esxDOSv), a
		ld hl, $00b8
		jr initL0
		;
		; version is 0.8.6 or 0.8.8 or 0.8.9
		;
ver086_8	ld (esxDOSv), a
		ld hl, $00a8
		jr initL0
		;
		; version is 0.8.7
		;
ver087		ld (esxDOSv), a
		ld hl, $00a7
		;
initL0		ld de, msgVer
		ld bc, 13
		ldir

		xor a
		ld (ldConf), a

		ld bc, 24*256+0
		ld a, 0
		call clrScr

		;
		; Obtain divXXX RAM size
		;
		ld hl, test
		ld de, 16384+6144+768	; 16384+6144-testLen-63
		ld bc, testLen
		ldir

		call 16384+6144+768	; 16384+6144-testLen-63

		ld (divRAM), hl

		;
		; Obtain speccy RAM size
		;
		; Version       RAM SIZE        PC      RAM pg act      TR-DOS
		; 0.8.5         +30             +27     +29             +30
		; 0.8.6         +27             +28     +30             +31
		;
		ld hl, (NMIbuf)
		ld de, 30
		ld a, (esxDOSv)
		cp '5'
		jr z, RAMsize
		ld de, 27
RAMsize		add hl, de
		ld a, (hl)
		ld (flg128k), a

		cp 0
		jr nz, noes16k
		ld hl, msg16k
		ld bc, 3
		jr initL1
noes16k		cp 1
		jr nz, noes48k
		ld hl, msg48k
		ld bc, 3
		jr initL1
noes48k		ld hl, msg128k
		ld bc, 4
initL1		ld de, msgRAM1
		ldir

		ld hl, (divRAM)
		sla l			;
		rl h			;
		sla l			;
		rl h			;
		sla l			;
		rl h			; hl = hl * 8 = kB RAM encontrada

		ld bc, 16*256+0		; handle 16 bits, one bit per iteration
		ld de, 0
cvtLoop		add hl, hl
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
bcd2hex		ld de, msgRAM2
		ld a, c
		and $f0
		jr z, _L1
		call cvtUpperNibble
_L1		ld a, c
		and $0f
		jr z, _L2
		call cvtLowerNibble
_L2		ld a, h
		and $f0
		jr z, _L3
		call cvtUpperNibble
_L3		ld a, h
		and $0f
		jr z, _L4
		call cvtLowerNibble
_L4		ld a, l
		and $f0
		jr z, _L5
		call cvtUpperNibble
_L5		ld a, l
		call cvtLowerNibble
		ld a, 'k'
		ld (de), a

		ld hl, msg0001
		call prStr

		; ***

		call readCnf

		ld a, (cfLeft)
		ld (kLeft), a
		ld a, (cfRight)
		ld (kRight), a
		ld a, (cfUp)
		ld (kUp), a
		ld a, (cfDown)
		ld (kDown), a
		ld a, (cfEnter)
		ld (kEnter), a

		ld a, (PopUp)
		or a
		jr z, chOut

		; ***

		ld b, 56
		ld c, BRIGHT+BLACK*8+WHITE
		xor a
waitE		push af
		push bc
		add a, c
		ld bc, 3*256+11
		call clrAttr
		pop bc
		ld a, (flagT)
		or a
		jr z, wait3
		pop af
		sub 8
		jr wait2
wait3		pop af
		add a, 8
wait2		or a
		jr nz, wait0
		ld (flagT), a
		jr wait1
wait0		cp 56
		jr nz, wait1
		ld (flagT), a
wait1		ei
		halt
		djnz waitE

		; ***

chOut		ld a, (flgOut)
		or a
		jr z, return

		xor a			;
		out ($ff), a		; set standard graphic zx mode on computers
					; Timex2048,Timex2068 and on SLAM
					; Thanks to Velesoft

return		;xor     a               ; return (continues normal workflow)

		ld a, 1			; return to mainL1 (reload dir and reprint all)
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

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
;
clrAttr		ex af, af'		; guardamos atributos
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
		;
		inc c
		djnz clrAttr
		;
		ret

;------------------------------------------------------------------------------
; Solucion de velesoft para comprobar la RAM de los divXXX
;------------------------------------------------------------------------------

testAdd		equ $3FFF

test		di
		ld hl, 16384+6144+768+testLen	; 16384+6144-63
		ld b, 00111111b		; 3Fh (63)

_1		ld a, b
		or 10000000b		; 80h (128) CONMEM = 1, MAPRAM = 0
		out (0E3h), a
		ld a, (testAdd)		; 16383
		ld (hl), a
		inc hl
		ld a, b
		ld (testAdd), a		; 16383
		djnz _1
		;
		; Empieza a contar de 63 a 0
		; cambia pagina = contador, con CONMEM = 1, MAPRAM = 0
		; guarda en (49223+63-contador) lo que hay en (3FFF)
		; guarda en (3FFF) el contador
		;

		ld a, 10111111b		; 0BFh (191) CONMEM = 1, MAPRAM = 0, BANK = 63
		out (0E3h), a
		ld a, (testAdd)		; 16383
		ld e, a
		ld hl, 16384+6144+768+testLen	; 16384+6144-63
		ld b, 00111111b		; 3Fh (63)
		;
		; activa la pagina 63 con CONMEM = 1 y MAPRAM = 0
		; guarda en e lo que hay en (3FFF)
		; que es el valor mas alto de pagina existente!
		;

_2		ld a, b
		or 10000000b		; 80h (128) CONMEM = 1, MAPRAM = 0
		out (0E3h), a
		ld a, (hl)
		ld (testAdd), a		; 16383
		inc hl
		djnz _2
		;
		; Empieza a contar de 63 a 0
		; cambia pagina = contador, con CONMEM = 1, MAPRAM = 0
		; guarda en (3FFF) lo que hay en (49223+63-contador)
		;

		inc e
		ld h, 0
		ld l, e
		;ld     a, %00000010             ; CONMEM = 0, MAPRAM = 0, BANK = 2 -> dot command
		ld a, %00000000		; CONMEM = 0, MAPRAM = 0, BANK = 0 -> NMI code
		out (0E3h), a
		;
		; Devuelve en hl el valor mas alto de pagina existente
		;

		ei
		ret

testLen		equ $-test

; -----------------------
; read configuration file
; -----------------------
;
readCnf		ld hl, fnConf		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, bufConf		; dest
		ld bc, 7		; size
		call fRead

		call fClose

		ret

; --------
; messages
; --------
;
msg0001		db $16,12,1,'Dr Slump NMI Navigator'
		db $16,12,56
		M_VERSION
		db 0

msgV086		db $16,0,0,'Only works with versions 0.8.5-0.8.9',0

msg16k		db '16k'
msg48k		db '48k'
msg128k		db '128k'

flagT		db 0

fnConf		db '/SYS/NMI/NMI.CNF',0

bufConf
PopUp		db 0
cfLeft		db 0
cfRight		db 0
cfDown		db 0
cfUp		db 0
cfEnter		db 0
flgOut		db 0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

