;==============================================================================
; Project: loadold.zdsp
; Main File: loadold.asm
; Date: 19/09/2017 13:28:19
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin loadold.asm loadold
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; --------------------
; load old NMI handler
; --------------------
;
loadold		call restoreScreen
		call deleteScreen

		ld hl, (NMIbuf)
		ld (copyHL), hl
		ld hl, (savedSP)
		ld (copySP), hl

		ld a, (esxDOSv)
		ld (fnv), a

		ld hl, loader
		ld de, 16384
		ld bc, last-loader
		ldir

		jp 16384

loader		;
		; loader runs at address 16384
		;
msgFn		ld hl, 16384+fn-loader	; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system drive
		rst $08			;
		db F_OPEN		; open file
		ld (16384+fh-loader), a	; file handle

		ld hl, NMI_OVERLAY
		ld bc, $0e00
		ld a, (16384+fh-loader)	; file handle
		rst $08			;
		db F_READ		; read buffer from file

		ld a, (16384+fh-loader)	; file handle
		rst $08			;
		db F_CLOSE		; close file

		ld hl, (16384+copyHL-loader)
		ld sp, (16384+copySP-loader)

		jp NMI_OVERLAY

; ---------
; variables
; ---------
;
fn		db '/sys/nmi/old08'
fnv		db '5.sys',0
fh		db 0
copyHL		dw 0
copySP		dw 0

last		equ $

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

