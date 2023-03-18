;==============================================================================
; Project: fastmenu.zdsp
; Main File: fastmenu.asm
; Date: 19/09/2017 13:45:39
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin fastmenu.asm fastmenu
;
;==============================================================================

        include ..\_nmi\nmi.inc
        include ..\_nmi\api.inc
        include ..\esxdos.inc
        include ..\errors.inc
        include ..\_nmi\nmi.publics

        org     ovrBuf

; ----------------
; fast-ramp config
; ----------------
;
fastcfg ld      a, (bDAttr)
        and     A_DIR           ; check if is dir
        jr      z, isFile

isDir   ld      a, 5            ; reprint nothing
        ret

isFile  ld      bc, 1*256+23    ; 1 line from line 23
        ld      a, COL_BOT      ; color
        call    clrScr

        ld      hl, msgSave
        call    prStr

        ld      hl, fnConf      ; asciiz string containg path and/or filename
        ld      b, FA_CREATE_AL|FA_WRITE
                                ; create if not exists, else open and truncate
                                ; read access
        ld      a, SYS_DRIVE    ; system/boot drive
        call    fOpen1

getCDrv xor     a               ; current drive
        rst     $08
        db      M_GETSETDRV
        ld      hl, drvName
        call    convDrv
        ld      hl, drvName     ; dest
        ld      bc, 4
        call    fWrite

getCWD  ld      hl, cwdBuf
        call    fGetCWD

        ld      hl, cwdBuf
        xor     a
        ld      bc, 128
        cpir
        ld      a, 127
        sub     c
        ld      c, a
        ld      hl, cwdBuf      ; dest
        call    fWrite

        ld      hl, bDName
        xor     a
        ld      bc, 8+1+3+1
        cpir
        ld      a, 8+1+3+1-1
        sub     c
        ld      c, a
        ld      hl, bDName      ; dest
        call    fWrite

        call    fClose

        ld      a, 1            ; reload dir and reprint all
        ret

        _FGETCWD

;
; converts drive number to 'hd0' format
;
convDrv push    af
        and     %11111000
        rrca
        rrca
        rrca
        add     a, 'a'-1
        ld      (hl), a
        inc     hl
        inc     hl
        pop     af
        and     %00000111
        add     a, '0'
        ld      (hl), a
        ret

; --------
; messages
; --------
;
msgSave db      $16,23,1,'SAVING FILE...',0

; ---------
; variables
; ---------
;
fnConf  db      '/sys/nmi/fastcfg.txt',0
drvName db      'hd0:'

cwdBuf  ds      127,0

;------------------------------------------------------------------------------
IF $ > ovrBuf+SIZ_OVR
        .ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

