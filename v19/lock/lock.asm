;==============================================================================
; Project: lock.zdsp
; Main File: lock.asm
; Date: 30/10/2017 10:02:29
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

; --------------------
; lock paging register
; --------------------
;
; The additional memory features of the 128K/+2 are controlled to by writes to
; port 0x7ffd
;
; Bits 0-2: RAM page (0-7) to map into memory at 0xc000.
; Bit 3: Select normal (0) or shadow (1) screen to be displayed. The normal
;        screen is in bank 5, whilst the shadow screen is in bank 7. Note that
;        this does not affect the memory between 0x4000 and 0x7fff, which is
;        always bank 5.
; Bit 4: ROM select. ROM 0 is the 128k editor and menu system; ROM 1 contains
;        48K BASIC.
; Bit 5: If set, memory paging will be disabled and further output to this port
;        will be ignored until the computer is reset.
;
; Like -l option of SNAPload dot command
;
lock		ld a, (flgLOCK)
		or a
		jr z, lockL1

		ld a, (flg128k)
		cp 2
		jr nz, lockL1
		xor a
		ld (flgLOCK), a

		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msg0001
		call prStr

		ld a, %00110000		; paging register locked, ROM 1 selected
		ld bc, $7ffd
		out (c), a

		ld a, 1			; reprint bottom and cursor
		ret

lockL1		ld a, 5			; reprint nothing
		ret

; --------
; messages
; --------
;
msg0001		db $16,23,1,'LOCKING...',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

