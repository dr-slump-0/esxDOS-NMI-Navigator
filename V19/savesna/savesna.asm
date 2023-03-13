;==============================================================================
; Project: rename.zdsp
; Main File: rename.asm
; Date: 14/09/2017 18:57:15
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin savesna.asm savesna
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; -------------
; save snapshot
; -------------
;
saveSNA		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgSave
		call prStr

		; check if file exists

fileExt		ld hl, fname		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; Open if exists, else error
					; Read access
		ld a, CUR_DRIVE		; current drive
		rst $08			;
		db F_OPEN		; open file
		jr c, saveL1		; file don't exists
		call fClose		; file exists
		;
		; increments file name
		;
		; e.g. SNAP0000.SNA -> SNAP0001.SNA and so on
		;
		ld hl, fname+7
		ld b, 4
saveL0		ld a, (hl)
		inc a
		ld (hl), a
		cp '9'+1
		jr nz, fileExt
		ld a, '0'
		ld (hl), a
		dec hl
		djnz saveL0

saveL1		call restoreScreen

		ld hl, fname		; asciiz string containg path and/or filename
		ld b, FA_CREATE_NEW|FA_WRITE
					; create if not exists, if exists error
					; write access
		call fOpen

		; SNA 48k

		ld hl, (NMIbuf)		; source
		ld bc, 27		; size
		call fWrite

		ld hl, 16384		; source
		ld bc, 49152		; size
		call fWrite

		ld a, (flg128k)		; check if 128k machine
		cp 2
		jr nz, saveL4

		; SNA 128k

; Version       RAM SIZE        PC      RAM pg act      TR-DOS
; 0.8.5         +30             +27     +29             +30
; 0.8.6         +27             +28     +30             +31

		ld hl, (NMIbuf)		; source
		ld de, 27
		ld a, (esxDOSv)
		cp '5'
		jr z, v085_L1
		ld de, 28
v085_L1		add hl, de
		ld bc, 4		; size
		call fWrite

		; Save RAM pages. Taken from NMI.sys of ub880d

		ld hl, (NMIbuf)		; source
		ld de, 29
		ld a, (esxDOSv)
		cp '5'
		jr z, v085_L2
		ld de, 30
v085_L2		add hl, de

		ld a, (hl)		; NMI_BUFFER+30: RAM bank paged in @ $c000
		ld bc, $7FFD
		out (c), a
		ld b, $10		; Select ROM 1, contains 48K BASIC
		or b
		ld c, a
		ld a, b
saveL2		cp $12			; discard RAM bank 2
		jr z, saveL3
		cp $15			; discard RAM bank 5
		jr z, saveL3
		cp c			; discard RAM bank paged in @ $c000
		jr z, saveL3
		push bc
		ld bc, $7FFD		; select RAM bank
		out (c), a		; page RAM bank
		ld hl, 49152
		ld bc, 16384
		call fWrite		; OJO, hay 2 bytes en la pila
		pop bc
saveL3		inc b
		ld a, b
		cp $18
		jr nz, saveL2		; repeat for all RAM banks

		;

saveL4		call fClose

		ld a, 1			; reload dir and reprint all
		ret

; --------
; messages
; --------
;
msgSave		db $16,23,1,'SAVING SNAPSHOT...',0

; ------------------------------------
; variables for save snapshot function
; ------------------------------------
;
fname		db 'snap0000.sna',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

