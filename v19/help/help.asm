;==============================================================================
; Project: help.zdsp
; Main File: help.asm
; Date: 19/09/2017 17:20:29
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin help.asm help
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; -----------------------------------------------------------------------------

;		ld (spVal), sp
;		ld sp, $5c00
;
;		rst $18
;		dw $0daf		; clear the screen, open channel 2
;
;		ld hl, dotcmd		; hl, dotcmd
;		rst $08
;		DB $8F			; M_EXECCMD
;		jr c, main_1
;		ld hl, msg03
;		jr main_2
;main_1		ld hl, msg04
;main_2		call prStr
;
;		call waitKey
;
;		ld sp, (spVal)
;		ld a, 1			; reload dir and reprint all
;		ret
;
;spVal		dw 0
;
;dotcmd		DB 'PRUEBA2',0
;msg03		DB $16,23,0,'Dot command loaded Ok',0
;msg04		DB $16,23,0,'Error loading dot command',0


; -----------------------------------------------------------------------------

; ----
; help
; ----

help		ld bc, 24*256+0
		ld a, COL_MID
		call clrScr

helpL1		ld hl, fnHelp1
		call viewSCR
		cp K_UP
		jr z, helpL1
		cp K_DOWN
		jr z, helpL2
		cp K_BREAK
		jr z, helpEnd

helpL2		ld hl, fnHelp2
		call viewSCR
		cp K_UP
		jr z, helpL1
		cp K_DOWN
		jr z, helpL3
		cp K_BREAK
		jr z, helpEnd

helpL3		ld hl, fnHelp3
		call viewSCR
		cp K_UP
		jr z, helpL2
		cp K_DOWN
		jr z, helpEnd
		cp K_BREAK
		jr z, helpEnd

helpEnd		ld a, 1			; reload dir and reprint all
		ret

; -----------
; view screen
; -----------
;
viewSCR		ld b, FA_OPEN_EX|FA_READ
		ld a, SYS_DRIVE
		call fOpen1
		ld hl, 16384
		ld bc, 6144+768
		call fRead
		call fClose

		call waitKey

		ret

; ---------
; variables
; ---------
;
fnHelp1		db '/sys/nmi/help1.scr',0
fnHelp2		db '/sys/nmi/help2.scr',0
fnHelp3		db '/sys/nmi/help3.scr',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

