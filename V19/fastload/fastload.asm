;==============================================================================
; Project: fastload.zdsp
; Main File: fastload.asm
; Date: 19/09/2017 13:45:39
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin fastload.asm fastload
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; --------------
; fast-ramp load
; --------------
;
fastLd		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgLoad
		call prStr

		ld hl, fnConf		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, drvLoad		; dest
		ld bc, 4		; size
		call fRead

		ld hl, fnLoad		; dest
		ld bc, 127+8+1+3	; size
		call fRead

		xor a
		ld (hl), a		; null terminate string

		call fClose

chgDrv		ld a, (drvLoad)
		sub 'a'-1
		and %00011111
		rlca
		rlca
		rlca
		ld b, a
		ld a, (drvLoad+2)
		and %00000111
		or b
		rst $08
		db M_GETSETDRV
		jp c, printError

updDrv		xor a			; default drive
		rst $08
		db M_GETSETDRV		; get current drive

		ld hl, msgDrv
		push af			; converts current drive to 'hd0' format
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

findExt		ld hl, fnLoad
		ld bc, 127+8+1+3+1
		ld a, 0
		cpir
		ld bc, 127+8+1+3+1
		ld a, '.'
		cpdr
		inc hl
		inc hl

noDot		ld a, 4			; reprint bottom and cursor
		ret nz

yesDot		ld de, extTbl
		ex de, hl

compStr		ld a, (hl)
		or a
		jr z, loadErr		; not recognized file type

		push de
		push hl
		ld b, 3
strcmp		ld a, (de)
		cp (hl)
		inc hl
		inc de
		jr z, otra

		dec hl
		sub 'a'-'A'
		cp (hl)
		inc hl
		jr z, otra

		pop hl
		pop de
		ld bc, 5
		add hl, bc
		jr compStr

otra		djnz strcmp

		pop hl
		pop de
		ld bc, 3
		add hl, bc

		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl

		jp (hl)

loadErr		ld hl, msgErr
		call prStr
		call waitKey
		ld a, 4			; reprint bottom and cursor
		ret

; -------------
; load sna, z80
; -------------
;
; uses snapload dot command
;
loadSNA		ld hl, snapCmd
		call fExecCMD

		ld a, 1			; reload dir and reprint all  (should not return)
		ret

; --------
; load tap
; --------
;
loadTAP		ld b, 0
		ld hl, fnLoad
		call fTapeIn
		ld a, 0
		call fAutoLoad

		ld a, 1			; reload dir and reprint all  (should not return)
		ret

; --------
; load BAS
; --------
;
loadBAS		ld a, CUR_DRIVE		; current drive
		ld hl, fnLoad
		call fAutoLoad

		ld a, 2			; reprint all (top, mid, bottom and cursor)
		ret

; --------
; load TRD
; --------
;
loadTRD		;
		; attach TRD to drive A
		;
		ld a, $60		; virtual unit A
		rst $08
		db $85			; EJECT VDISK
		;jr      c, retMnt      ; error if no disk attached, ignore it

		ld hl, fnLoad
		ld a, $60		; virtual unit A
		ld de, buffer		; BUFFER
		ld b, 0
		ld c, CUR_DRIVE		; current drive
		rst $08
		db DISK_STATUS		; MOUNT VDISK   ; $80
		;jr      c, retLoad
		jp c, printError

		;
		; tapein TR-DOS Navigator
		;
		ld b, 0			; in_open
					; Attaches .tap file
					; A=drive
					; HL=Pointer to null-terminated string containg path and/or filename
		ld hl, TRDNtap
		ld a, SYS_DRIVE		; system/boot drive
		rst $08
		db M_TAPEIN
		jp c, printError

		; now decide if load navigator or autoboot

		call ckMods
		ld a, (flagSS)
		or a
		ld hl, basBoot
		jr z, openNav		; z no SS pressed, nz SS pressed
		ld hl, basLoad
openNav		;
		; autoload BASIC loader
		;
		ld a, SYS_DRIVE		; system/boot drive
		call fAutoLoad

retLoad		ld a, 1			; reload dir and reprint all  (should not return)
		ret

		_FEXECCMD
		_FTAPEIN
		_FAUTOLOAD

; --------
; messages
; --------
;
msgLoad		db $16,23,1,'LOADING FILE...',0
msgErr		db $16,23,1,'FILE TYPE NOT SUPPORTED, PRESS A KEY',0

; -----------------
; ext actions table
; -----------------
;
extTbl		db 'SNA'
		dw loadSNA
		db 'TAP'
		dw loadTAP
		db 'Z80'
		dw loadSNA
		db 'TRD'
		dw loadTRD
		db 'BAS'
		dw loadBAS
		db 0

;-------------------
; load TRD variables
;-------------------
;
TRDNtap		db '/sys/nmi/TRDN.tap',0
basBoot		db '/sys/nmi/boot.bas',0
basLoad		db '/sys/nmi/load.bas',0

; ---------
; variables
; ---------
;
fnConf		db '/sys/nmi/fastcfg.txt',0
snapCmd		db 'snapload '
fnLoad		ds 127+8+1+3,0
drvLoad		ds 4

;-------------------
; buffer lo load TRD
;-------------------
;
buffer		equ $

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

		end

