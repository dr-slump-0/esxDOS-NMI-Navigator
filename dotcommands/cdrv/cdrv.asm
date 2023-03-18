;==============================================================================
; Project: chgdrv.zdsp
; Main File: drives.asm
; Date: 01/04/2020 10:12:56
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

        include ../esxdos.inc

VERSION macro
        db      '0.2'
        endm

; -----------------------------------------------------------------------------
; current drive (missing from esxdos.inc)
; -----------------------------------------------------------------------------
;CUR_DRIVE       equ     '*'

        org     $2000

; -----------------------------------------------------------------------------
; Main
; -----------------------------------------------------------------------------
;
main    push    hl
        ld      hl, msg0001
        call    prStr
        pop     hl

        ld      a, h
        or      l
        jp      z, altdrv	; no args

        ld      (ptrArgs), hl   ; save pointer to args

        call    getArg
        or      a
        jp      z, altdrv	; no args
        cp      1
        jr      nz, chkDrv	; no option

        call    getArg          ; get option value
        cp      2
        jr      nz, errArgs     ; no value

        call    getArg          ; get option value
        or      a
        jr      nz, errArgs     ; more than one arg

        ld      a, (argStr+1)
        or      a
        jr      nz, errArgs     ; value length greater than one character

        ld      a, (argStr)
        cp      '?'
        jr      z, help

	jr	errArgs

chkDrv	ld	hl, argStr
	ld	a, 'h'
	cpi
	jr	nz, errArgs
	ld	a, 'd'
	cpi
	jr	nz, errArgs
	ld	a, (hl)
	cp	'0'
	jr	c, errArgs	; < '0'
	cp	'4'
	jr	nc, errArgs	; >= '4' -> > '3'
	sub	'0'
	or	$40
	ld	b, a

        call    getArg
	or	a
	jr	nz, errArgs

	ld	a, b
	jr	chdrv
        ;
;
; help
;
help    ld      hl, msg0002
        call    prStr
Exit    or      a               ; clear CF (no error)
        ret

;
; error on command line arguments
;
errArgs ld      hl, msg0002
        call    prStr
        ld      hl, msg0005     ; HL=pointer to custom error message
        xor     a               ; A=0 custom error message
Err     scf                     ; set CF (error)
        ret

;
; alternate to next valid drive
;
altdrv  xor     a               ; default drive
        rst     $08
        db      M_GETSETDRV
        inc     a               ; try to change to next drive

;
; change drive A=drive
;
chdrv	rst     $08
        db      M_GETSETDRV
        jp      nc, noErr       ; if no error, print drive name and exit

        call    findDrv
        rst     $08
        db      M_GETSETDRV     ; if error, change to system/boot drive

noErr   ld      hl, drvName
        call    convDrv

        ld      hl, msgOk
        call    prStr

        ld      hl, msgCr
        call    prStr

        xor     a               ; clear CF (no error)
        ret
;
; search first drive unit (system/boot) testing all ones from 1 to 255
;
findDrv ld      a, 1
Otro    or      a
        ret     z               ; end reached, not found drive unit
        cp      SYS_DRIVE
        jr      z, Nuevo        ; skip system/boot drive
        cp      CUR_DRIVE
        jr      z, Nuevo        ; skip default drive
        ld      b, a
        rst     $08
        db      M_GETSETDRV
        ld      a, b
        ret     nc              ; if CF=0 find first drive unit
Nuevo   inc     a
        jr      Otro

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
msg0001 db      13
        db      'cdrv v'
        VERSION
        db      ' By Dr. Slump 2020',13,0
msg0002 db      13
        db      'Usage: cdrv [arg]',13
	db	13
	db	'Change default drive',13
	db	13
	db	'Arg:',13
	db	13
	db	'hd0    1st drive',13
	db	'hd1    2nd drive',13
	db	'hd2    3th drive',13
	db	'hd3    4th drive',13
	db	13
	db	'(none) next drive',13
        db      13
        db      '-?     this help info',13
        db      0
msgCr   db      13,0
msg0005 db      'Invalid command lin', 'e'+$80

msgOk   db      13,'Drive changed to '

drvName db      'hd',0,0

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

        end     main

