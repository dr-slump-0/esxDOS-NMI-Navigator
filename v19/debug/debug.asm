;==============================================================================
; Project: debug.zdsp
; Main File: debug.asm
; Date: 08/01/2018 15:44:47
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

; -----
; debug
; -----
;
debug		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgStat
		call prStr

		ld hl, mon
		call fExecCMD

		ld a, 4			; reprint bottom and cursor (should not return)
		ret

		_FEXECCMD

; --------
; messages
; --------
;
msgStat		db $16,23,1,'LOADING DEBUGGER...',0

; ---------------------
; dot command for debug
; ---------------------
;
mon		db 'MON',0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

		end

