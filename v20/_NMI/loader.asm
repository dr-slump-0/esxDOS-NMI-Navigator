;==============================================================================
; Project: NMI.zdsp
; File: loader.asm
; Date: 18/10/2022 13:32:34
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

; ==============================================================================
; LOADER - divXXX page 0
; ==============================================================================

		ld (dwSavedSP), sp
		ld (dwPtrNMIbuf), hl

		; -------------------
		; save screen to disk
		; -------------------
		;
lbSaveScreen	xor a
		ld (dbSavRAM), a

		jr lbSkipErr		// ERROR J, P y S. Al estar en pagina 5 no va rst $30.

		ld hl, 16384
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		rst $30
		db $0a
		jr nc, lbChkFirstTime

lbSkipErr	ld a, $ff
		ld (dbSavRAM), a

		ld hl, dbFnBackupFile	; asciiz string containing path and/or filename
		ld b, FA_CREATE_AL|FA_WRITE
					; create if not exists, else open and truncate
					; write access
		ld a, SYS_DRIVE		; system/boot drive
		rst $08			; screen is saved allways in SYS_DRIVE
		db F_OPEN		; open file
		;jp c, printError1
		ld (dbFileHandle), a	; file handle

		ld hl, 16384		; source
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		ld a, (dbFileHandle)	; file handle
		rst $08			;
		db F_WRITE		; write buffer to file
		;jr c, closeFilePrintError1

		ld a, (dbFileHandle)	; file handle
		rst $08			;
		db F_CLOSE		; close file
		;jr c, printError1
		; -------------------

lbChkFirstTime	ld a, (dbFirstTime)
		or a
		jp z, lbStart

		CHECK_VERSION
		ld hl, msgUnkVer
		or a
		jp z, lbPrtErr			; unknown version
		ld (dbEsxDOSv), a

		;
		; Obtain speccy RAM size
		;
		; Version       RAM SIZE        PC      RAM pg act      TR-DOS
		; 0.8.5         +30             +27     +29             +30
		; 0.8.6+        +27             +28     +30             +31
		;
		ld hl, (dwPtrNMIbuf)
		ld de, 30
		ld a, (dbEsxDOSv)
		cp '5'
		jr z, lbRAMsize
		ld de, 27
lbRAMsize		add hl, de
		ld a, (hl)
		ld (dbSpeccyRAM), a

		;
		; Obtain divXXX RAM size
		;
		ld hl, lbTest
		ld de, BACKED_UP_RAM
		ld bc, lbTestLen
		ldir

		call BACKED_UP_RAM			; e=l=number of 8k pages
		ld (dwDivRAM), hl

		ld a, (dbEsxDOSv)
		ld hl, msgErrVer
		cp a, '9'			; minimum version supported
		jp nz, lbPrtErr

		ld a, (dwDivRAM)
		ld hl, msgErrRAM
		cp 6				; minimum divRAM supported
		jp c, lbPrtErr

		//
		// Initialize RAM pages and load page 5 with NMI navigator
		//
		ld sp, NMI_STACK		; necessary to use MACROS
		INITPG (dwDivRAM)
		LOADPG 5, offsetPg5, dbFnNMISys
		LOADPG 6, offsetPg6, dbFnNMISys

		xor a
		ld (dbFirstTime),a

		//
		// Cargamos NMI navigator en pagina 5 la primera vez que se produce una NMI
		// Seria deseable comprobar que la pagina 5 no ha sido alterada cada vez que se produce una NMI
		//

lbStart		//
		// Run NMI navigator on page 5
		//
		ld sp, NMI_STACK		; necessary to use MACROS
		ld hl, dwSavedSP
		ld de, BACKED_UP_RAM		; $5b00
		ld bc, 9
		ldir
		ld hl, (dwPtrNMIbuf)
		ld de, BACKED_UP_RAM+9		; $5b00+9
		ld bc, 31
		ldir
		JUMPPG 5, page5.mainNMI
lbBack		ld sp, (dwSavedSP)		; necessary to back to NMI handler

		; ------------------------
		; restore screen from disk
		; ------------------------
		;
lbRestoreScreen	ld a, (dbSavRAM)
		or a
		jr nz, lbToFile

		ld de, 16384
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		rst $30
		db $0b
		ret

lbToFile	ld hl, dbFnBackupFile	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		rst $08			; screen is saved allways in SYS_DRIVE
		db F_OPEN		; open file
		;jp c, printError1
		ld (dbFileHandle), a	; file handle

		ld hl, 16384		; dest
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		ld a, (dbFileHandle)	; file handle
		rst $08			;
		db F_READ		; read buffer from file
		;jr c, closeFilePrintError1

		ld a, (dbFileHandle)	; file handle
		rst $08			;
		db F_CLOSE		; close file
		;jr c, printError1
		; ------------------------

		; -----------------------
		; delete screen from disk
		; -----------------------
		;
lbDeleteScreen	ld hl, dbFnBackupFile	; null-terminated string containg path and/or filename
		ld a, SYS_DRIVE		; system/boot drive
		rst $08
		db F_UNLINK		; unlink file
		;jr c, printError1
		; -----------------------

		ret			; ret from NMI handler
					; state is restored and program execution resumed

lbPrtErr	ld sp, $5c00		; necessary to use rst $10
		//rst $18
		//DW $0d6b		; ROM CLS COMMAND
__1		ld a, (hl)
		inc hl
		or a
		jr z, __2
		push hl
		rst $10
		pop hl
		jr __1

__2		ld sp, (dwSavedSP)
		call lbDeleteScreen
		ret

; --------------------------------------------
; Velesoft's solution to check divXXX RAM size
; --------------------------------------------

dbTestedByte	equ $3FFF		; last byte of page

lbTest		DISP BACKED_UP_RAM

		//di
		ld hl, dbPtrTestBuf
		ld b, 00111111b		; 3Fh (63) Last possible page

__3		ld a, b
		or 10000000b		; 80h (128) CONMEM = 1, MAPRAM = 0
		out (0E3h), a
		ld a, (dbTestedByte)
		ld (hl), a
		inc hl
		ld a, b
		ld (dbTestedByte), a
		djnz __3
		;
		; Empieza a contar de 63 a 0
		; cambia pagina = contador, con CONMEM = 1, MAPRAM = 0
		; guarda en (49223+63-contador) lo que hay en (3FFF)
		; guarda en (3FFF) el contador
		;

		ld a, 10111111b		; 0BFh (191) CONMEM = 1, MAPRAM = 0, BANK = 63
		out (0E3h), a
		ld a, (dbTestedByte)
		ld e, a
		ld hl, dbPtrTestBuf
		ld b, 00111111b		; 3Fh (63)  Last possible page
		;
		; activa la pagina 63 con CONMEM = 1 y MAPRAM = 0
		; guarda en e lo que hay en (3FFF)
		; que es el valor mas alto de pagina existente!
		;

__4		ld a, b
		or 10000000b		; 80h (128) CONMEM = 1, MAPRAM = 0
		out (0E3h), a
		ld a, (hl)
		ld (dbTestedByte), a
		inc hl
		djnz __4
		;
		; Empieza a contar de 63 a 0
		; cambia pagina = contador, con CONMEM = 1, MAPRAM = 0
		; guarda en (3FFF) lo que hay en (49223+63-contador)
		;

		inc e
		ld h, 0
		ld l, e
		;ld a, %00000010	; CONMEM = 0, MAPRAM = 0, BANK = 2 -> dot command
		ld a, %00000000		; CONMEM = 0, MAPRAM = 0, BANK = 0 -> NMI code
		out (0E3h), a
		;
		; Devuelve en hl el valor mas alto de pagina existente
		;

		//ei
		ret

dbPtrTestBuf	ENT			; buffer of 64 bytes, 1 byte per page

lbTestLen	equ $-lbTest

; -----------------------------------------------------------------------------
; LOADER data
; -----------------------------------------------------------------------------

;
; Order must be the same as in data.asm
;-------------------
dwSavedSP	DW 0
dwDivRAM	DW 0
dbSpeccyRAM	DB 0
dbSavRAM	DB 0
dbEsxDOSv	DB 0
dwPtrNMIbuf	DW 0
;-------------------

dbFirstTime	DB $ff
dbFileHandle	DB 0

dbFnNMISys	DB '/SYS/NMI.SYS', 0
dbFnBackupFile	DB '/TMP/_NMI_BAK.SCR', 0

msgErrRAM	DB 13,'ERROR: Device with 32K or more RAM required', 0
msgErrVer	DB 13,'ERROR: Only works on esxDOS v0.8.9', 0
msgUnkVer	DB 13,'ERROR: Unknown esxDOS version',0

