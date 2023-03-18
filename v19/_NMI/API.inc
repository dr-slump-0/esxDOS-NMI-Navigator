;==============================================================================
; Project: NMI.zdsp
; File: NMI.inc
; Date: 29/07/2017 10:58:43
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

		PUBLIC ovrBuf, clrScr, kUp, kDown, kLeft, kRight, kEnter
		PUBLIC prStr, waitKey, prChr, bDAttr, bDName
		PUBLIC fUnlink, fChDir, fOpen, fRead, fClose
		PUBLIC ckMods, flagSS, flagCS, printError1, fOpen1, fWrite
		PUBLIC esxDOSv, msgVer, divRAM, NMIbuf, flg128k
		PUBLIC msgRAM1, msgRAM2, restoreScreen, deleteScreen, savedSP
		PUBLIC col, pr_64, utoa, saveScreen, fhandle, flgLOCK
		PUBLIC curLn, Xof, msgLock, msgDrv, flgROOT, msgPath
		PUBLIC fOpenDir, fReadDir, ofY, printError, fTellDir, pTable
		PUBLIC readKey, prtDec, wait, ldConf, ldDir, exitNMI

;==============================================================================
; DEFINITIONS
;==============================================================================

; -----------------------------------------------------------------------------
; max number of entries in dir, it must be multiple of 22
; -----------------------------------------------------------------------------
;MAXENTR         equ     116*22          ; 116*22=2552
;MAXENTR         equ     54*22           ; 54*22=1188
MAXENTR		equ 46*22		; 46*22=1012


; -----------------------------------------------------------------------------
; directory attribute (missing from esxdos.inc)
; -----------------------------------------------------------------------------
A_DIR		equ %00010000

; -----------------------------------------------------------------------------
; current drive (missing from esxdos.inc)
; -----------------------------------------------------------------------------
CUR_DRIVE	equ '*'

;==============================================================================
; MACROS
;==============================================================================
;
; TODO: For reasons of ease of code maintenance,
;       define here as macros API calls not necessary for navigator
;       (called into overlays)
;       enter.asm
;               EJECT VDISK
;               DISK_STATUS (MOUNT VDISK)
;               M_TAPEIN
;       fastcfg.asm
;               M_GETSETDRV
;       fastload.asm
;               M_GETSETDRV
;               EJECT VDISK
;               DISK_STATUS (MOUNT VDISK)
;               M_TAPEIN
;       loadold.asm
;               F_OPEN  (without error control)
;               F_READ  (without error control)
;               F_CLOSE (without error control)
;       reload.asm
;               M_GETSETDRV
;       reset.asm
;               M_AUTOLOAD (RESET)
;       savesna.asm
;               F_OPEN  (without error control)
;       seldrv.asm
;               M_GETSETDRV     (without error control)
;       tapein.asm
;               M_TAPEIN        -> FALTA COMPROBAR ERRORES!!!
;       tapeout.asm
;               M_TAPEOUT       -> FALTA COMPROBAR ERRORES!!!
;       trd2drv.asm
;               EJECT VDISK
;               DISK_STATUS (MOUNT VDISK)       -> FALTA COMPROBAR ERRORES!!!
;

; -------
; fGetCWD
; -------
;
_FGETCWD	MACRO
fGetCWD		ld a, CUR_DRIVE		; current drive
		rst $08
		db F_GETCWD		; get current working directory
		jp c, printError1	; QUE SE HACE CON ESTO !!!
		ret
		ENDM

; -----
; fSeek
; -----
;
_FSEEK		MACRO
fSeek		ld a, (fhandle)		; file handle
		ld l, 0			; 0 from start of file
					; 1 fwd from current pos
					; 2 bak from current pos
		rst $08
		db F_SEEK
		jp c, printError1	; QUE SE HACE CON ESTO !!!
		ret
		ENDM

; -------
; fRename
; -------
;
_FRENAME	MACRO
fRename		ld a, CUR_DRIVE		; current drive
		rst $08
		db F_RENAME
		jp c, printError1	; QUE SE HACE CON ESTO !!!
		ret
		ENDM

; --------
; fExecCMD
; --------
;
_FEXECCMD	MACRO
fExecCMD	rst $08
		db M_EXECCMD
		jp c, printError1	; QUE SE HACE CON ESTO !!!
		ret
		ENDM

; --------
; fTapeIn
; --------
;
_FTAPEIN	MACRO
fTapeIn		ld a, CUR_DRIVE		; current drive
		rst $08
		db M_TAPEIN
		jp c, printError1	; QUE SE HACE CON ESTO !!!
		ret
		ENDM

; ---------
; fAutoLoad
; ---------
;
_FAUTOLOAD	MACRO
fAutoLoad
		rst $08
		db M_AUTOLOAD
		jp c, printError1	; QUE SE HACE CON ESTO !!!
		ret
		ENDM

;
; TODO: For reasons of ease of code maintenance,
;       define here as macros functions to
;       enter.asm:
;               loadSNA
;               loadTAP
;               viewSCR
;               loadBAS
;               loadTRD
;               attTAP
;               attTRD
;       fastcfg.asm
;               getCDrv
;               getCWD
;               convDrv
;       fastload.asm
;               chgDrv
;               updDrv
;               loadSNA
;               loadTAP
;               loadBAS
;               loadTRD
;               attTAP
;               attTRD
;       init.asm
;               clrAttr
;       seldrv.asm
;               findDrv
;               convDrv
;       reload.asm
;               getCDrv
;               getCWD
;               convDrv
;       tapein.asm
;               attTAP
;       tr2drv.asm
;               attTRD
;       view.asm
;               viewSCR
;               viewSNA
;

