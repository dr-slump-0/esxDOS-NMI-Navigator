;==============================================================================
; Project: NMI.zdsp
; File: functions.asm
; Date: 29/08/2017 13:25:58
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

/* ----------------------------------------------------------------------------
	-----
	NOTES
	-----
	725 754		rst $30 DB $0a/$0b
	2650		rst $08 DB F_OPEN 	check if file exists
	1038 2766	rst $08 DB M_GETSETDRV	check if drive is valid
	2016 2023 2027	rst $08			load old NMI handler

---------------------------------------------------------------------------- */

;==============================================================================
; COMMON FUNCTIONS
;==============================================================================

; -------------------
; save screen to disk
; -------------------
;
saveScreen	ld a, (savRAM)
		or a
		jr nz, SavetoFile

		ld hl, 16384
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		rst $30
		db $0a
		ret nc

SavetoFile	ld hl, dbFnBackupFile	; asciiz string containing path and/or filename
		ld b, FA_CREATE_AL|FA_WRITE
					; create if not exists, else open and truncate
					; write access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, 16384		; source
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		call fWrite

		call fClose

		ret

; ------------------------
; restore screen from disk
; ------------------------
;
restoreScreen	ld a, (savRAM)
		or a
		jr nz, toFile

		ld de, 16384
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		rst $30
		db $0b
		ret

toFile		ld hl, dbFnBackupFile	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, 16384		; dest
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		call fRead


		call fClose

		ret

; -----------------------
; delete screen from disk
; -----------------------
;
deleteScreen	ld a, (savRAM)
		or a
		ret z

		ld hl, dbFnBackupFile	; null-terminated string containg path and/or filename
		ld a, SYS_DRIVE		; system/boot drive
		call fUnlink1
		ret

; -------------------------------------
; converts drive number to 'hd0' format
; -------------------------------------
convDrv		push af
		and %11111000
		rrca
		rrca
		rrca
		add a, 'a'-1
		ld (hl), a
		inc hl
		inc hl
		pop af
		and %00000111
		add a, '0'
		ld (hl), a
		ret

; -----------------------------
; get current working directory
; -----------------------------
;
getCWD		;
		; get current drive
		;
		call fGetSetDrv1	; get current drive

		;
		; pretty printer for drive
		;
		ld hl, drvName
		call convDrv

		;
		; get CWD
		;
		ld hl, dbStrPathName
		call fGetCWD

		;
		; pretty printer for CWD
		;
		xor a
		ld (flgROOT), a		; reset some flags
		ld bc, 128
		ld hl, dbStrPathName+1	; skip initial '/'
		cpir			; search end of string
		ld a, 128
		sub c			; calculates string length
		cp 2			; greater or equal than 2 cols -> greater than 1 cols
		jr nc, notRoot		; if less than 1 -> root directory
		ld (flgROOT), a

notRoot		cp 58			; 64 minus 2 (margins) minus 5 ('hd0:/') plus 2 (cpir) = 59 cols
		jr c, itsOk		; less than 59 cols -> less or equal than 58 cols

		ld a, 58		; crop string to 58 cols

itsOk		or a			; clear CF
		ld d, 0
		ld e, a
		sbc hl, de		; set hl to the beginning of string

		cp 58
		jr nz, noCrop
		ld (hl), '.'
		inc hl
		ld (hl), '.'
		inc hl
		ld (hl), '.'
		dec hl
		dec hl			; set hl to the beginning of string
		;
		; crop string
		;
		ld de, dbStrPathName+1
		ld b, 0
		ld c, a
		ldir

noCrop		inc a
		ld (strLen), a
		ret

; --------------------------------------
; copy drive and CWD to top message area
; --------------------------------------
;
copyCWD		ld hl, drvName
		ld de, msgDrv
		ld bc, 4
		ldir
		ld hl, dbStrPathName
		ld a, (strLen)
		ld b, 0
		ld c, a
		ldir
		;
		ret

; ------------------------------------------
; compare old working directory with current
; ------------------------------------------
;
testCWD		ld hl, drvName
		ld de, msgDrv
		ld b, 4
testCWD1	ld a, (de)
		inc de
		cpi
		ret nz			; ZF=0 (NZ) -> not the same
		djnz testCWD1
		; si llega aqui es que son iguales, no hace falta comprobar que B sea cero
		ld hl, dbStrPathName
		ld de, msgPath
		ld a, (strLen)
		ld b, a
testCWD2	ld a, (de)
		inc de
		cpi
		ret nz			; ZF=0 (NZ) -> not the same
		djnz testCWD2
		; si llega aqui es que son iguales, el flag Z estÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ activado del CPI
		ret

; ----------------------------------------------
; skip '.' dir entry and saves dir entry pointer
; ----------------------------------------------
;
skipDotSavePtr	call fOpenDir

		;
		; ignore '.' entry
		;
		call fReadDir
		jp c, prError
		;
		ld a, (bDName)
		cp '.'
		jr nz,label1
		ld a, (bDName+1)
		or a
		jr z,label2

label1		;
		; rebobina directorio
		;
		call fRewindDir

label2		;
		; guarda puntero al primer elemento
		;
		call fTellDir
		IFDEF _POINTER4BYTES
		  ld (pCurDir), bc
		  ld (pCurDir+2), de
		ELSE
		  ld a, c
		  ld (pCurDir), a
		  ld (pCurDir+1), de
		ENDIF

		call fClose

		ret

; ----------------------------
; pretty printer for file size
; ----------------------------
;
prtSize		xor a			;
		ld (prefixCnt), a	// e a cero es suficiente
		ld hl, bDName		;
		ld bc, 8+1+3+1		;
		cpir			; search end of string
		inc hl
		inc hl
		inc hl
		inc hl			; add 4 to hl, hl points to dword DSize
		ld (pDSizeL), hl
		inc hl
		inc hl
		ld (pDSizeH), hl

		ld b, 3
normL4		ld hl, (pDSizeH)
		ld a, (hl)
		inc hl
		or (hl)
		jr nz, normL5		// SizeH not zero
		ld hl, (pDSizeL)
		inc hl
		ld a, (hl)
		cp 40
		jr c, normL6		// SizeL >= 40*256=10240 (10K)

normL5		ld d, 0
		ld e, b
div1024		ld b, 10
divL0		ld hl, (pDSizeH)
		inc hl
		srl (hl)
		ex af, af'
		ld c, b
		ld b, 3
divL1		dec hl
		srl (hl)
		ex af, af'
		jr nc, divL2
		ld a, %10000000		;
		add a, (hl)		; set bit 7 of (hl) if carry set
		ld (hl), a		;
divL2		djnz divL1
		ld b, c
		djnz divL0
		//ld (prefixCnt), de
		ld a, e
		ld (prefixCnt), a
		ld b, e
normL6		djnz normL4

		ld hl, (pDSizeL)
		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl
		call utoa
		//ld de, (prefixCnt)
		xor a
		ld d, a
		ld a, (prefixCnt)
		ld e, a
		ld hl, prefix
		add hl, de
		ld a, (hl)
		call prChr
		ret

; --------------------------------------------------------------------
; search first drive unit (system/boot) testing all ones from 1 to 255
;---------------------------------------------------------------------
;
findDrv		ld a, 1
Otro		or a
		ret z			; end reached, not found drive unit
		cp SYS_DRIVE
		jr z, Nuevo		; skip system/boot drive
		cp CUR_DRIVE
		jr z, Nuevo		; skip default drive
		ld b, a
		rst $08
		db M_GETSETDRV
		ld a, b
		ret nc			; if CF=0 find first drive unit
Nuevo		inc a
		jr Otro

; -----------------------
; read configuration file
; -----------------------
;
readCnf		ld hl, dbFnConfigFile	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, bufConf		; dest
		ld bc, 8		; size
		call fRead

		call fClose

		ret

		/*
; ------------------------
; write configuration file
; ------------------------
;
writeCnf	ld hl, dbFnConfigFile	; asciiz string containg path and/or filename
		ld b, FA_OPEN_AL|FA_WRITE
					; open if exists, if not create
					; write access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, bufConf		; dest
		ld bc, 8		; size
		call fWrite

		call fClose

		ret
		*/

; -----------------------------------------------------------------------------
; Error handler
; -----------------------------------------------------------------------------
;
closeFilePrErr	push af
		ld a, (fhandle)		;
		rst $08			;
		db F_CLOSE		; close file
		pop af

prError		push af
		;ld      bc, 24*256+0    ; 24 lines from line 0
		;ld      a, COL_MID      ; color
		;call    clrScr
		ld bc, 3*256+11
		ld a, COL_ERR
		call clrScr
		ld hl, msgErr
		call prStr
		pop af

		ld h, 0			; esxDOS err
		ld l, a
		call utoa
		call waitKey

		ld sp, (savedSP)

		jp page5.mainL1
