;==============================================================================
; Project: delete.zdsp
; Main File: delete.asm
; Date: 18/09/2017 9:55:43
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin delete.asm delete
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; ---------------
; delete file/dir
; ---------------
;
delFile		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		ld hl, msgOk
		call prStr
		;
		; confirm delete
		;
		call waitKey
		cp 'Y'
		ld a, 4			; reprint bottom and cursor
		ret nz
		;
		ld hl, msgDel
		call prStr
		;
		ld hl, bDName
		ld de, bDName2
		ld bc, 13
		ldir

		ld hl, rm
		call fExecCMD

		ld a, 1			; reload dir and reprint all
		ret

		_FEXECCMD

; --------
; messages
; --------
;
msgOk		db $16,23,1, 'DELETE (Y/N)? ',0
msgDel		db $16,23,1, 'DELETING FILES...',0

; -------------------------------
; dot command for remove file/dir
; -------------------------------
;
rm		db 'RM -fr '
bDName2		db '12345678.123', 0

		;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
		;------------------------------------------------------------------------------

