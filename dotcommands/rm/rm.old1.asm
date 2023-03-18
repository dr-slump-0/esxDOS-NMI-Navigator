;==============================================================================
; Project: rm.zdsp
; Main File: rm.asm
; Date: 04/12/2017 11:46:20
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

                include esxdos.inc
                include errors.inc

VERSION         macro
                db      '0.1'
                endm

; -----------------------------------------------------------------------------
; current drive (missing from esxdos.inc)
; -----------------------------------------------------------------------------
CUR_DRIVE       equ     '*'

; -----------------------------------------------------------------------------
; directory attribute (missing from esxdos.inc)
; -----------------------------------------------------------------------------
A_DIR           equ     %00010000

; -----------------------------------------------------------------------------
; Counts scrolls: it is always 1 more than the number of scrolls that will be
; done before stopping with scroll? If you keep poking this with a number
; bigger than 1 (say 255), the screen will scroll on and on without asking you.
; -----------------------------------------------------------------------------
SCR_CT          equ     $5C8C   ; 23692

                org     $2000

; -----------------------------------------------------------------------------
; Main
; -----------------------------------------------------------------------------
;
main    ld      (savedSP), sp

        ld      a, h
        or      l
        jr      z, help         ; no args, show help

        ld      (ptrArgs), hl   ; save pointer to args

        call    getArg
        or      a
        jr      z, help         ; no args, show help

        jr      isOpt

scanArg call    getArg
        or      a
        jr      z, Exit         ; no more args, exit
isOpt   cp      1
        jr      z, getOpts      ; is a option, get it
        cp      2
        jr      nz, errArgs     ; imposible state, error
        ;
        ; HL pointer to file/directory name
        ;
        ld      hl, argStr
        call    delete          ; is a file/directory name, delete
        ;
        jr      scanArg         ; next arg

getOpts call    getArg          ; get option value
        cp      2
        jr      nz, errArgs     ; no value, error

        ld      hl, argStr
readOpt ld      a, (hl)         ; get opt
        or      a
        jr      z, scanArg      ; no more options in current arg, next arg
        cp      '?'
        jr      z, help         ; help, show it and exit
        cp      'f'
        jr      nz, opt01
        ld      a, $ff          ; force
        ld      (flgForce), a
        jr      nextOpt
opt01   cp      'i'
        jr      nz, opt02
        ld      a, $ff          ; prompt
        ld      (flgPrompt), a
        jr      nextOpt
opt02   cp      'r'
        jr      nz, opt03
        ld      a, $ff          ; recurse directories
        ld      (flgRecurse), a
        jr      nextOpt
opt03   cp      'd'
        jr      nz, opt04
        ld      a, $ff          ; remove empty directorires
        ld      (flgDirectories), a
        jr      nextOpt
opt04   cp      'v'
        jr      nz, errOpts     ; unknown option, error
        ld      a, $ff          ; verbose
        ld      (flgVerbose), a
nextOpt inc     hl
        jr      readOpt         ; next opt

; ----
; help
; ----
help    ld      hl, msg0001
        call    prStr
        ld      hl, msg0002
        call    prStr
Exit    or      a               ; clear CF (no error)
        ret

; -------------------------------
; error on command line arguments
; -------------------------------
errOpts ld      a, (flgForce)
        or      a
        jr      nz, nextOpt
        jr      errMsg
errArgs ld      a, (flgForce)
        or      a
        jr      nz, scanArg
        ;jr      errMsg
errMsg  ld      hl, msg0002
        call    prStr
        ld      hl, msg0003     ; HL=pointer to custom error message
        xor     a               ; A=0 custom error message
Err     scf                     ; set CF (error)
        ret

; ---------------------
; delete file/directory
; ---------------------
;
delete  ;
        ; HL pointer to file/directory name. Return if '.' or '..'
        ;
        ; argStr contains relative path from current dir plus file/directory name
        ;
        ld      a, (hl)
        cp      '.'
        jr      nz, fStat
        inc     hl
        ld      a, (hl)
        or      a
        ret     z               ; skip '.' directory
        cp      '.'
        jr      nz, fStat
        inc     hl
        ld      a, (hl)
        or      a
        ret     z               ; skip '..' directory

fStat   ld      a, $ff
        ld      (SCR_CT), a     ; avoid 'scroll?' prompt

        ld      hl, argStr
        ld      de, buffer
        ld      a, CUR_DRIVE
        rst     $08
        db      F_STAT
        ;
        ; F_STAT: Get file info/status to buffer at DE.
        ;
        ; A=handle
        ; HL=Pointer to null-terminated string containg path to dir/file
        ;
        ; Buffer format:
        ;
        ; <byte>  drive
        ; <byte>  device
        ; <byte>  file attributes (like MSDOS)
        ; <dword> date
        ; <dword> file size
        ;
        ;jr      c, isErr        ; error
        jp      c, isErr        ; error
        ld      a, (buffer+2)
        and     A_DIR           ; check if is dir
        ;jr      z, isFile
        jp      z, isFile

isDir   ld      a, (flgDirectories)
        or      a
        jr      nz, isDir01
        ld      a, (flgRecurse)
        or      a
        jr      nz, isDir01

        ld      a, (flgForce)
        or      a
        ld      a, EISDIR
        ;jr      z, retErr
        jp      z, retErr

        ld      a, (flgVerbose)
        or      a
        ret     z
        ld      hl, msg0011     ; cannot remove 'dirname': Is a directory
        call    prStr
        ld      hl, argStr
        call    prStr
        ld      hl, msg0012
        call    prStr
        ld      hl, msgCr
        call    prStr
        ret

isDir01 ld      a, (flgRecurse)
        or      a
        ;jr      z, isDir06
        jp      z, isDir06
        ld      a, (flgForce)
        or      a
        jr      nz, isDir02
        ld      a, (flgPrompt)
        or      a
        jr      z, isDir02
        ld      hl, msg0010     ; descend into directory 'dirname' (Y/N)?
        call    prStr
        ld      hl, argStr
        call    prStr
        ld      hl, msgAcc
        call    prStr
        ;
        call    kbYesNo
        ;jr      nc, isDir06     ; skip recurse if No
        jp      nc, isDir06     ; skip recurse if No
        ;

isDir02 ; ***********************
        ; BEGIN RECURSE DIRECTORY
        ; ***********************
        ;
        ld      hl, argStr
        ld      bc, $2000+7000-_end-4-4-1-8-1-3-1       ; available space
                                                        ; current file/directory name
                                                        ; F_READDIR buffer
        xor     a
        cpir                    ; search end of asciiz string
        jp      pe, isDir03     ; if sufficient space, recurse directory

        ld      a, (flgForce)
        or      a
        ret     z               ; if -f, return and continue

        ld      hl, msg0004     ; Out of memory
        xor     a
        scf
        ld      sp, (savedSP)
        ret

isDir03 xor     a               ;
        ld      (hl), a         ;
        dec     hl              ;
        ld      a, '/'          ;
        ld      (hl), a         ; add '/','\0' to end of string. HL points to '/'

        ;;
        ;ex      de, hl          ; save HL copy on DE
        ;;
        ;ld      hl, -3          ;
        ;add     hl, sp          ;
        ;ld      sp, hl          ; reserve 4 bytes for local variables
                                ; sp+0 <word> pointer to last directory separator '/'
                                ; sp+2 <byte> directory handle
        ;;
        ;ld      hl, 0           ;
        ;add     hl, sp          ;
        ;ld      (hl), d         ;
        ;inc     hl              ;
        ;ld      (hl), e         ; save pointer to current file/directory name

        push    hl              ;  save pointer to current file/directory name

        ld      hl, argStr
        ld      a, CUR_DRIVE
        rst     $08
        db      F_OPENDIR
        ;
        ; F_OPENDIR: Open dir.
        ;
        ; A=drive
        ; HL=Pointer to null-terminated string containg path to dir
        ; B=dir access mode (only BASIC header bit matters - if you want to read header info or not)
        ;
        ; On return if OK, A=dir handle.
        ;
        ;;jr      c, isErr        ; error
        pop     hl
        jp      c, isErr        ; error
        push    hl
        push    af              ; save directory handle

isDir04 ;ld      hl, 0           ;
        ;add     hl, sp          ;
        ;ld      d, (hl)         ;
        ;inc     hl              ;
        ;ld      e, (hl)         ;
        ;inc     hl              ;
        ;ld      a, (hl)         ; recover directory handle
        ;ex      de, hl          ; recover pointer to current file/directory name
        pop     af
        pop     hl
        push    hl
        push    af
        rst     $08
        db      F_READDIR
        ;
        ; F_READDIR: Read a dir entry to buffer pointed to by HL. A=handle. Buffer format:
        ;
        ; <byte>   attributes (like MSDOS)
        ; <asciiz> file/dirname
        ; <dword>  date
        ; <dword>  filesize
        ;
        ; If opened with BASIC header bit, after the normal entry follows the BASIC header (with type=$ff if headerless)
        ;
        ; On return, if A=1 theres more entries, if=0 then it's end of dir. FIXME-A should return size of entry, 0 if end of dir.
        ;
        jr      c, isDir05      ; no more entries on directory
        or      a
        jr      z, isDir05      ; no more entries on directory

        pop     af
        pop     hl
        push    hl
        push    af
        ld      a, '/'          ;
        ;ld      hl, 0           ;
        ;add     hl, sp          ;
        ;ld      d, (hl)         ;
        ;inc     hl              ;
        ;ld      e, (hl)         ;
        ;ex      de, hl          ; F_READDIR buffer, 1st byte is attributes
        ld      (hl), a         ; change attributes by '/'

        ; *********************************************************************
        ; *********************************************************************
        ; *********************************************************************
        ;
        ; HL, AF en la pila
        ;
        ; Save pointer to dir, close dir, to preserve handles.
        ;
        pop     af
        push    af
        rst     $08
        db      F_TELLDIR
        ;
        ; F_TELLDIR: Returns current offset of directory in BCDE. A=dir handle
        ;
        ; CHECK ERROR!!!       HL, AF en la pila
        ;jr      c, isErr        ; error

        ;;;
        pop     af
        push    bc
        push    de

        rst     $08
        db      F_CLOSE
        ;
        ; F_CLOSE: Close a file or dir handle. A=handle.
        ;
        ; CHECK ERROR!!!       HL, BC, DE en la pila
        ;jr      c, isErr        ; error
        pop     de
        pop     bc
        pop     hl
        push    hl
        push    bc
        push    de
        ; HL, BC, DE en la pila
        ;
        ;
        inc     hl
        call    delete
        ;
        ;
        ; HL, BC, DE en la pila

        ; Hay que hacer (HL)='\0' antes de F_OPENDIR y luego (HL)='/'
        pop     de
        pop     bc
        pop     hl
        push    hl
        push    bc
        push    de

        xor     a
        ld      (hl), a
        push    hl

        ; HL, BC, DE en la pila
        ld      hl, argStr
        ld      a, CUR_DRIVE
        rst     $08
        db      F_OPENDIR
        ;
        ; F_OPENDIR: Open dir.
        ;
        ; A=drive
        ; HL=Pointer to null-terminated string containg path to dir
        ; B=dir access mode (only BASIC header bit matters - if you want to read header info or not)
        ;
        ; On return if OK, A=dir handle.
        ;
        ; CHECK ERROR!!!       HL, BC, DE en la pila
        ;jr      c, isErr        ; error

        pop     hl
        push    af
        ld      a, '/'
        ld      (hl), a
        pop     af

        pop     de
        pop     bc
        pop     hl
        push    hl
        push    af
        rst     $08
        db      F_SEEKDIR
        ;
        ; F_SEEKDIR: Sets offset of directory. A=dir handle, BCDE=offset
        ;
        ; CHECK ERROR!!!       HL, AF en la pila
        ;
        ; Open dir, restores pointer to dir.
        ;
        ; HL, AF en la pila
        ;
        ; *********************************************************************
        ; *********************************************************************
        ; *********************************************************************

        jr      isDir04         ; next entry on directory

isDir05 ;ld      hl, 2           ;
        ;add     hl, sp          ;
        ;ld      a, (hl)         ; recover directory handle
        pop     af              ; recover directory handle
        rst     $08
        db      F_CLOSE
        ;
        ; F_CLOSE: Close a file or dir handle. A=handle.
        ;
        ;jr      c, isErr        ; error
        pop     hl
        jp      c, isErr        ; error

        ;;
        ;ld      hl, 0           ;
        ;add     hl, sp          ;
        ;ld      d, (hl)         ;
        ;inc     hl              ;
        ;ld      e, (hl)         ; recover pointer to current file/directory name
        ;;
        ;ld      hl, 3           ;
        ;add     hl, sp          ;
        ;ld      sp, hl          ; free reserved local space
        ;;
        ;ex      de, hl          ; restore HL copy from DE

        xor     a               ;
        ld      (hl), a         ; finalize asciiz string with '\0'
        ;
        ; *********************
        ; END RECURSE DIRECTORY
        ; *********************

isDir06 ld      a, (flgForce)
        or      a
        jr      nz, isDir07
        ld      a, (flgPrompt)
        or      a
        jr      z, isDir07
        ;
        ld      hl, msg0007     ; remove directory 'dirname' (Y/N)?
        call    prStr
        ld      hl, argStr
        call    prStr
        ld      hl, msgAcc
        call    prStr
        ;
        call    kbYesNo
        ret     nc              ; return if No
        ;
isDir07 ld      hl, argStr
        ld      a, CUR_DRIVE
        ;rst     $08
        ;db      F_RMDIR
        or      a
        ;
        ; F_RMDIR: Delete dir.
        ;
        ; A=drive
        ; HL=Pointer to null-terminated string containg path to dir
        ;
        jr      c, isErr        ; error
        ld      a, (flgVerbose)
        or      a
        ret     z
        ld      hl, msg0009     ; removed directory 'dirname'
        call    prStr
        ld      hl, argStr
        call    prStr
        ld      hl, msgApo
        call    prStr
        ret

isFile  ld      a, (flgForce)
        or      a
        jr      nz, isFil02
        ld      a, (flgPrompt)
        or      a
        jr      z, isFil02
        ;
        ld      hl, msg0006     ; remove file 'filename' (Y/N)?
        call    prStr
        ld      hl, argStr
        call    prStr
        ld      hl, msgAcc
        call    prStr
        ;
        call    kbYesNo
        ret     nc              ; return if No
        ;
isFil02 ld      hl, argStr
        ld      a, CUR_DRIVE
        ;rst     $08
        ;db      F_UNLINK
        or      a
        ;
        ; F_UNLINK: Delete a file
        ;
        ; A=drive
        ; HL=pointer to asciiz file/path
        ;
        jr      c, isErr        ; error
        ld      a, (flgVerbose)
        or      a
        ret     z
        ld      hl, msg0008     ; removed 'filename'
        call    prStr
        ld      hl, argStr
        call    prStr
        ld      hl, msgApo
        call    prStr
        ret

isErr   ld      b, a
        ld      a, (flgVerbose)
        or      a
        ld      a, b
        jr      z, retErr

        ld      b, a
        ld      hl, msg0011     ; cannot remove 'filename': esxDOS error
        call    prStr
        ld      hl, argStr
        call    prStr
        ld      hl, msg0013
        call    prStr
        ld      a, b

retErr  ld      b, a
        ld      a, (flgForce)
        or      a
        ret     nz              ; if -f, return and continue
        ;
        ld      sp, (savedSP)
        ld      a, b
        scf
        ret                     ; if not -f, abort

; ----------------------
; check if BREAK pressed
; ----------------------
;
kbBreak xor     $7f
        in      a, ($fe)
        cpl
        and     %00001000
        jr      nz, isNo
        ;
        xor     $df
        in      a, ($fe)
        cpl
        and     %00010000
        jr      nz, isYes
        ;
        ret

; -----------------------
; check if Y or N pressed
; -----------------------
;
kbYesNo call    readKb
        ;
        ld      b, 10
pause   ei
        halt
        djnz    pause
        ;
        ret

readKb  xor     $7f
        in      a, ($fe)
        cpl
        and     %00001000
        jr      nz, isNo
        ;
        xor     $df
        in      a, ($fe)
        cpl
        and     %00010000
        jr      nz, isYes
        ;
        jr      readKb
        ;
isNo    ld      hl, msgNo
        call    prStr
        or      a
        ret
        ;
isYes   ld      hl, msgYes
        call    prStr
        scf
        ret

; -----------------------------------------------------------------------------
; process command line args
; -----------------------------------------------------------------------------
;
; HL=Pointer to args or HL=0 if no args
; HL is typically pointing directly to BASIC line, so for END marker
; you should check for $0D, ":" as well as 0.
;
getArg  ld      hl, (ptrArgs)
        ld      de, argStr
getChr  ld      a, (hl)
        inc     hl
        or      a
        jr      z, getEnd
        cp      $0D
        jr      z, getEnd
        cp      ':'
        jr      z, getEnd
        cp      ' '
        jr      z, getChr
        cp      '-'
        jr      nz, getStr
        ld      a, 1            ; A=1 option arg
        jr      savPtr
getEnd  xor     a               ; A=0 no more args
savPtr  ld      (ptrArgs), hl
        ret

getStr  ld      (de), a
        inc     de
        ld      a, (hl)
        or      a
        jr      z, getStr1
        cp      $0D
        jr      z, getStr1
        cp      ':'
        jr      z, getStr1
        cp      '-'
        jr      z, getStr1
        cp      ' '
        jr      z, getStr1
        inc     hl
        jr      getStr
getStr1 xor     a
        ld      (de), a
        ld      a, 2            ; A=2 string arg
        jr      savPtr

; -----------------------------------------------------------------------------
; Print a asciiz string at cursor position
; Updates cursor coordinates
; -----------------------------------------------------------------------------
;
prStr   ld      a, (hl)
        or      a
        ret     z
        rst     $10
        inc     hl
        jr      prStr

; -----------------------------------------------------------------------------
; messages
; -----------------------------------------------------------------------------
;
msg0001         db      13
                db      'rm v'
                VERSION
                db      ' By Dr. Slump 2017',13,0
msg0002         db      13
                db      'Usage: rm [OPTIONS]... [FILE]...',13
                db      13
                db      'Remove the FILE(s)',13
                db      13
                db      '-f ignore nonexistent files and',13
                db      '   arguments, never prompt',13
                db      '-i prompt before every removal',13
                db      '-r remove directories and their',13
                db      '   contents recursively',13
                db      '-d remove empty directories',13
                db      '-v explain what is being done',13
                db      '-? display this help and exit',13
                db      0
msg0003         db      'Invalid command lin','e'+$80
msg0004         db      'Out of memor','y'+$80

msg0006         db      'remove file ',$27,0
msg0007         db      'remove directory ',$27,0
msg0008         db      'removed ',$27,0
msg0009         db      'removed directory ',$27,0
msg0010         db      'descend into directory ',$27,0
msg0011         db      'cannot remove ',$27,0
msg0012         db      $27,': Is a directory',0
msg0013         db      $27,': esxDOS error',13,0
msgAcc          db      $27,' (Y/N)? ',0
msgYes          db      'Y',13,0
msgNo           db      'N',13,0
msgApo          db      $27
msgCr           db      13,0

; -----------------------
; variables
; -----------------------
;
flgForce        db      0
flgPrompt       db      0
flgRecurse      db      0
flgDirectories  db      0
flgVerbose      db      0

savedSP         dw      0

buffer          ds      11,0

; ---------------------
; line arguments parser
; ---------------------
;
ptrArgs         dw      0
argStr          equ     $

;------------------------------------------------------------------------------
IF $ > $2000+7000
        .ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

_end    end     main

; -
;
; -
;
; Esto debe ser una funcion recursiva o su conversion a una no recursiva
; que borre el fichero indicado con los flags actuales.
; Si se especifico -r y se indica un directorio, se hara una llamada recursiva
; para todos los elementos del directorio indicado.
;
delete
        ld      hl, argStr
        call    prStr
        ld      hl, msgSp
        call    prStr
        ;
        ld      a, (flgForce)
        or      a
        jr      z, flag01
        ld      hl, msg_f
        call    prStr
flag01  ld      a, (flgPrompt)
        or      a
        jr      z, flag02
        ld      hl, msg_i
        call    prStr
flag02  ld      a, (flgRecurse)
        or      a
        jr      z, flag03
        ld      hl, msg_r
        call    prStr
flag03  ld      a, (flgDirectories)
        or      a
        jr      z, flag04
        ld      hl, msg_d
        call    prStr
flag04  ld      a, (flgVerbose)
        or      a
        jr      z, flag05
        ld      hl, msg_v
        call    prStr
flag05  ld      hl, msgCr
        call    prStr
        ;
        ret

msg_f   db      'f',0
msg_i   db      'i',0
msg_r   db      'r',0
msg_d   db      'd',0
msg_v   db      'v',0

msgSp   db      ' ',0

