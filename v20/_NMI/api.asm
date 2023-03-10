;==============================================================================
; Project: NMI.zdsp
; File: api.asm
; Date: 03/11/2022 20:41:05
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

; =============================================================================
; API calls and error handler
; =============================================================================

; -----------------------------------------------------------------------------
; API calls
; -----------------------------------------------------------------------------
;
fOpen		ld a, CUR_DRIVE		; current drive
fOpen1		rst $08			; screen is saved allways in SYS_DRIVE
		db F_OPEN		; open file
		jp c, prError
		ld (fhandle), a		; file handle
		ret

fRead		ld a, (fhandle)		; file handle
		rst $08			;
		db F_READ		; read buffer from file
		jp c, closeFilePrErr
		ret

fWrite		ld a, (fhandle)		; file handle
		rst $08			;
		db F_WRITE		; write buffer to file
		jp c, closeFilePrErr
		ret

fSeek		ld a, (fhandle)		; file handle
		ld l, 0			; 0 from start of file
					; 1 fwd from current pos
					; 2 bak from current pos
		rst $08
		db F_SEEK
		jp c, closeFilePrErr	; QUE SE HACE CON ESTO !!!
		ret

fClose		ld a, (fhandle)		; file handle
		rst $08			;
		db F_CLOSE		; close file
		jp c, prError
		ret

		;

fOpenDir	ld a, CUR_DRIVE		; current drive
		ld b, 0
		ld hl, dotDot+1		; '.'   ; cwdBuf is valid too
		rst $08
		db F_OPENDIR
		jp c, prError
		ld (fhandle), a
		ret

fReadDir	ld hl, bufDir
		ld a, (fhandle)		; file handle
		rst $08			;
		db F_READDIR		; read directory entry to buffer
		;jp c, closeFilePrErr
		ret			; error check is done in caller function
					; to detect end of directory

fSeekDir	ld a, (fhandle)		; file handle
		rst $08			;
		db F_SEEKDIR		; set offset of directory
		jp c, closeFilePrErr
		ret

fTellDir	ld a, (fhandle)		; file handle
		rst $08			;
		db F_TELLDIR		; get offset of directory
		jp c, closeFilePrErr
		ret

fRewindDir	ld a, (fhandle)
		rst $08
		db F_REWINDDIR
		jp c, closeFilePrErr
		ret

fRename		ld a, CUR_DRIVE		; current drive
		rst $08
		db F_RENAME
		jp c, prError		; QUE SE HACE CON ESTO !!!
		ret

//fUnlink	ld a, CUR_DRIVE		; current drive
fUnlink1	; screen is saved allways in SYS_DRIVE
		rst $08
		db F_UNLINK		; open file
		jp c, prError
		ret

fChDir		ld a, CUR_DRIVE		; current drive
		rst $08			;
		db F_CHDIR		; change directory
		jp c, prError
		ret

fGetCWD		ld a, CUR_DRIVE		; current drive
		rst $08
		db F_GETCWD		; get current working directory
		jp c, prError		; QUE SE HACE CON ESTO !!!
		ret

fExecCMD	//
		//
		//
		ld de, BACKED_UP_RAM	// $5b00
		ld bc, 128		// Para poder llamar desde la pagina 5
		ldir			//
		ld hl, BACKED_UP_RAM	// $5b00
		rst $08
		db M_EXECCMD
		jp c, prError		; QUE SE HACE CON ESTO !!!
		ret

fAutoLoad	; a = $00	LOAD "" (usually tapein)
		; a > $00	HL = asciiz to file name, autoload from disk
		; a = $fe	reset
		; a = $fd	autoload from vdisk. If no boot, loads TR-DOS Navigator
		; a = $fc	enter TR-DOS mode
		rst $08
		db M_AUTOLOAD
		jp c, prError		; QUE SE HACE CON ESTO !!!
		ret

fGetSetDrv1	xor a			; a = 0 get current drive
fGetSetDrv	rst $08
		DB M_GETSETDRV
		jp c, prError
		ret

fEjectVDisk	; a = drive 0, 1, 2, 3
		; add a, a
		; add a, a
		; add a, a
		; or $60
		; a = virtual drive $60 (A), $68 (B), $70 (C), $78 (D)
		rst $08
		db $85			; EJECT VDISK
		;jr c, prError		; error if no disk attached, ignore it
		ret

fMountVDisk	; hl = pointer to asciiz TRD o SCL disk image
		; a = virtual drive $60 (A), $68 (B), $70 (C), $78 (D)
		ld de, buffer		; BUFFER: returns 'Virtual Disk', 0
		ld b, 0
		ld c, CUR_DRIVE		; current drive
		rst $08
		db DISK_STATUS		; MOUNT VDISK   ; $80
		jp c, prError
		ret

fAttachTapeIn	ld b, 0			; in_open
					; Attaches .tap file
					; A=drive
					; HL=Pointer to null-terminated string containg path and/or filename
		ld a, CUR_DRIVE		; current drive
		rst $08
		db M_TAPEIN
		jp c, prError		; QUE SE HACE CON ESTO !!!
		ret

fDetachTapeIn	ld b, 1			; in_close
					; No args, just closes and detaches .tap file
		rst $08
		db M_TAPEIN
		;jr c, prError		; error if no file attached, ignore it
		ret

fAttachTapeOut	ld b, 0			; out_open
					; Creates/opens .tap file for appending
					; A=drive
					; HL=Pointer to null-terminated string containg path and/or filename
		ld a, CUR_DRIVE		; current drive
		rst $08
		db M_TAPEOUT
		jp c, prError		; QUE SE HACE CON ESTO !!!
		ret

fDetachTapeOut	ld b, 1			; out_close
					; No args, just closes and detaches .tap file
		rst $08
		db M_TAPEOUT
		;jr c, prError		; error if no file attached, ignore it
		ret

