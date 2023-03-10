;==============================================================================
; Project: NMI.zdsp
; File: page6functions.asm
; Date: 03/11/2022 18:38:20
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

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

; --------------
; print key name
; --------------
;
prKeyName	ld hl, mDelete
		cp K_DELETE
		jr z, prSelL1
		ld hl, mEnter
		cp K_ENTER
		jr z, prSelL1
		ld hl, mSpace
		cp ' '
		jr z, prSelL1
		ld hl, mBreak
		cp K_BREAK
		jr z, prSelL1
		ld hl, mLeft
		cp K_LEFT
		jr z, prSelL1
		ld hl, mRight
		cp K_RIGHT
		jr z, prSelL1
		ld hl, mUp
		cp K_UP
		jr z, prSelL1
		ld hl, mDown
		cp K_DOWN
		jr z, prSelL1
		ld hl, mEdit
		cp K_EDIT
		jr z, prSelL1
		ld hl, mTo
		cp K_TO
		jr z, prSelL1
		ld hl, mAt
		cp K_AT
		jr z, prSelL1
		ld hl, mSSEnt
		cp K_SS_ENTER
		jr z, prSelL1
		ld hl, mCSEnt
		cp K_CS_ENTER
		jr z, prSelL1
		;
chrNorm		call prChr
		ret

prSelL1		call prStr
		ret

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

		//ld sp, (savedSP)
		//jp mainL1
		jp helpEnd

