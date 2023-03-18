;==============================================================================
; Project: drives.zdsp
; Main File: drives.asm
; Date: 09/11/2017 17:23:56
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

        include ../esxdos.inc

VERSION macro
        db      '0.3'
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
        jp      z, mI           ; no args

        ld      (ptrArgs), hl   ; save pointer to args

        call    getArg
        or      a
        jp      z, mI           ; no args
        cp      1
        jr      nz, errArgs     ; no option

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
        cp      '1'
        jr      z, mI
        cp      '2'
        jp      z, mII
        cp      '3'
        jp      z, mIII
	cp	'd'
	jp	z, debug
        jr      errArgs
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
; method I: drives M_DRIVEINFO
;
; Note: not documented by esxDOS developers
;       Aditional info supplied  by Miguel Guerreiro (lordcoxis)
;
; 0   1  byte   Drive unit (40h, 41h... @, A... hd1, hd2...)
; 1   1  byte   Device
; 2   1  byte   Flags
; 3   1  dword  Drive size in 512 bytes blocks (little-endian)
; 7   -  asciiz File System Type
; -   -  asciiz Volume Label
;
mI      ld      hl, msg0003
        call    prStr
        ;
        ld      hl, buffer
        rst     $08
        db      M_DRIVEINFO     ; A=number of drives found
        jp      c, Err
        ld      b, a
        ld      hl, buffer
mainL2  push    bc
        push    hl
        ld      a, (hl)         ; Drive unit
        ld      hl, drvName
        call    convDrv
        ld      hl, drvName
        call    prStr
        ;
        ld      hl, msg0006     ; ':'
        call    prStr
	;
        pop     hl
        push    hl
        ld      bc, 7
        add     hl, bc          ; asciiz File System Type
        call    prStr
        ;
        inc     hl              ;
        push    hl              ; asciiz Volume Label
        ;
        ld      hl, msg0007     ; ','
        call    prStr
        ;pop     hl
        ;push    hl
        ;ld      bc, 13
        ;add     hl, bc
        pop     hl
        call    prStr
        ;
        inc     hl              ;
        push    hl              ; next field if exists
        ;
        ld      hl, msg0007     ; ','
        call    prStr
        ;pop     hl
        ;push    hl
        ;inc     hl
        ;inc     hl
        ;inc     hl
        ;
        pop     bc              ;
        pop     hl              ;
        push    bc              ;
        inc     hl              ;
        inc     hl              ;
        inc     hl              ; Drive size in 512 bytes blocks
        ;
        call    prtSize
        ;
        ld      hl, msgCr
        call    prStr
        ;pop     hl
        ;ld      bc, 21
        ;add     hl, bc
        ;pop     bc
        ;
        pop     hl
        pop     bc
        ;
        djnz    mainL2
        jp      Exit

;
; method II: drives M_GETSETDRV
;
mII     ld      hl, msg0003
        call    prStr
        ;
        xor     a               ; default drive
        rst     $08
        db      M_GETSETDRV
        jp      c, Err
        ld      (defdrv), a     ; saves default drive

        xor     a               ; detect all valid drives from 1 to 255
        ld      (actdrv), a
Otro    ld      a, (actdrv)
        inc     a
        ld      (actdrv), a
        or      a
        jr      z, Fin          ; end reached
        cp      SYS_DRIVE
        jr      z, Otro         ; skip system/boot drive
        cp      CUR_DRIVE
        jr      z, Otro         ; skip default drive
        rst     $08
        db      M_GETSETDRV
        jr      c, Otro         ; skip if error
        ;
        ; valid drive found
        ;
        ld      a, (actdrv)
        ld      hl, drvName
        call    convDrv
        ld      hl, drvName
        call    prStr
        ld      hl, msgCr
        call    prStr
        ;
        jr      Otro

Fin     ld      a, (defdrv)     ; restore default drive
        rst     $08
        db      M_GETSETDRV
        jp      Exit

;
; method III: devices DISK_INFO
;
; 0   1  byte   Device Path (40, 48... hda, hdb...)
; 1   1  byte   Device Flags (to be documented, block size, etc)
; 2   1  dword  Device size in blocks (little-endian ???)
; 6
;
mIII    ld      hl, msg0004
        call    prStr
        ;
        ld      hl, buffer
        xor     a
        rst     $08
        db      DISK_INFO
        jp      c, Err
        ld      hl, buffer
mainL1  ld      a, (hl)
        or      a
        jp      z, Exit
        push    hl
        ld      hl, drvName
        call    convDev
        ld      hl, drvName
        call    prStr
	/*
	ld	hl, msg0007
	call	prStr
	pop	hl
	push	hl
	ld	a, (hl)
	ld	l, a
	call	bin2hex8
	*/
        ;
        ld      hl, msg0006
        call    prStr
        pop     hl
        push    hl
        inc     hl
        inc     hl
        call    prtSize
        ;
        ld      hl, msgCr
        call    prStr
        pop     hl
        ld      bc, 6
        add     hl, bc
        jr      mainL1

;
; dump structs
;
debug	//
	// M_DRIVEINFO
	//
	ld      hl, msg0003
        call    prStr
        ;
        ld      hl, buffer
        rst     $08
        db      M_DRIVEINFO     ; A=number of drives found
        jp      c, Err
        ld      b, a
        ld      hl, buffer
debugL1	push	bc

	ld	b, 7
debugL2	push	bc
	push	hl
	ld	l, (hl)
	call	bin2hex8
	ld	a, ' '
	rst     $10
	pop	hl
	pop	bc
	;
	inc	hl
	djnz	debugL2

	xor	a
	ld	bc, 6
	cpir

	xor	a
	ld	bc, 8
	cpir

	push	hl
	ld	hl, msg0008
	call	prStr
	pop     hl

        pop     bc
        ;
        djnz    debugL1

	//
	// DISK_INFO
	//
	ld      hl, msg0004
        call    prStr
        ;
	ld      hl, buffer
        xor     a
        rst     $08
        db      DISK_INFO
        jp      c, Err
        ld      hl, buffer
debugL3	ld      a, (hl)
        or      a
        jp      z, Exit
	push	hl

	ld	b, 6
debugL4	push	bc
	push	hl
	ld	l, (hl)
	call	bin2hex8
	ld	a, ' '
        rst     $10
	pop	hl
	pop	bc
	;
	inc	hl
	djnz	debugL4

	ld	a, 13
	rst     $10
        pop     hl
        ld      bc, 6
        add     hl, bc
        jr      debugL3


; -----------------------------------------------------------------------------
; converts drive number to 'hd0' format
; -----------------------------------------------------------------------------
;
; LOGICAL DRIVES
; =========================
;
; --------------------------------------------------
; BIT   |         7-3           |       2-0        |
; --------------------------------------------------
;       | Drive letter from A-Z | Drive number 0-7 |
; --------------------------------------------------
;
; Programs that need to print all available drives (ie, file selector)
; just need to:
;
; a) Process higher 5 bits to print Drive letter
; b) Print the 'd'
; c) Process the lower 3 bits to print Drive number.
;
convDrv push    af
        and     %11111000
        rrca
        rrca
        rrca
        add     a, 'a'-1        ; BUG in esxDOS, it should not be necessary to subtract 1
        ld      (hl), a
        inc     hl
        inc     hl
        pop     af
        and     %00000111
        add     a, '0'
        ld      (hl), a
	//
	inc	hl
	xor	a
	ld	(hl),a
	//
        ret

; -----------------------------------------------------------------------------
; converts device number to 'hda' format
; -----------------------------------------------------------------------------
;
; [BYTE] DEVICE PATH
;
; ---------------------------------
; |       MAJOR       |  MINOR    |
; +-------------------------------+
; | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
; +---+---+---+---+---+---+---+---+
; | E | D | C | B   B | A   A   A |
;
; ESTA INFO PARECE NO SER CORRECTA:
;
; A: MINOR
; --------
; 000 : RAW (whole device)
; 001 : 0       (first partition/session)
; 010 : 1       (second partition/session)
; 011 : 2       (etc...)
; 100 : 3
; 101 : 4
; 110 : 5
; 111 : 6
;
; B:
; --
; 00 : RESERVED
; 01 : IDE
; 10 : FLOPPY
; 11 : VIRTUAL
;
; C:
; --
; 0 : PRIMARY
; 1 : SECONDARY
;
; D:
; --
; 0 : MASTER
; 1 : SLAVE
;
; E:
; --
; 0 : ATA
; 1 : ATAPI
;
convDev push    af	//
	push	af
	cp	$80
	jr	c, notMMC
	ld	a, 's'
	jr	isMMC
notMMC	cp	$60
	jr	c, isIDE
isVirt	ld	a, 'v'
	ld      (hl), a
	inc	hl
	inc	hl
	pop	af
	pop	af
        and     %00011000
        rrca
        rrca
        rrca
	add	a, '0'
	ld	(hl), a
	inc	hl
	ld	a, ' '
	jr	label_1
isIDE	ld      a, 'h'
isMMC	ld      (hl), a
        inc     hl
        inc     hl
        pop     af
        and     %00111000
        rrca
        rrca
        rrca
        add     a, 'a'
        ld      (hl), a
	//
	inc	hl
	pop	af
	and     %00000111
	jr	nz, notRAW
	sub	a, '0'-' '
notRAW	add	a, '0'
label_1	ld	(hl), a
	inc	hl
	xor	a
	ld	(hl),a
	//
        ret

; -----------------------------------------------------------------------------
; pretty printer for size
; -----------------------------------------------------------------------------
;
; Size is in blocks of 512 bytes
;
prtSize ;
        ; shift size one bit to right to obtain size in blocks of 1 Kb
        ;
        inc     hl
        inc     hl
        inc     hl
        or      a               ; clear CF
        ld      a, (hl)
        rra
        ld      (hl), a
        dec     hl
        ld      a, (hl)
        rra
        ld      (hl), a
        dec     hl
        ld      a, (hl)
        rra
        ld      (hl), a
        dec     hl
        ld      a, (hl)
        rra
        ld      (hl), a

        ;
        ; store size in mem, try to use two 16 bit registers?
        ;
        ld      (sizeL), hl
        inc     hl
        inc     hl
        ld      (sizeH), hl

        ld      a, 'K'
        ld      (utoaBuf+6), a
        ;
        ; normalize size in K, M, G, T
        ;
        ld      b, 3
normL4  ld      hl, (sizeH)
        ld      a, (hl)
        inc     hl
        or      (hl)
        jr      nz, normL5
        ld      hl, (sizeL)
        inc     hl
        ld      a, $26
        cp      (hl)
        jr      nc, normL6
normL5  ld      d, 0
        ld      e, b

div1024 ld      b, 10
divL0   ld      hl, (sizeH)
        inc     hl
        srl     (hl)
        ex      af, af'
        ld      c, b
        ld      b, 3
divL1   dec     hl
        srl     (hl)
        ex      af, af'
        jr      nc, divL2
        ld      a, %10000000    ;
        add     a, (hl)         ; set bit 7 of (hl) if carry set
        ld      (hl), a         ;
divL2   djnz    divL1
        ld      b, c
        djnz    divL0

        ld      hl, prefix-1
        add     hl, de
        ld      a, (hl)
        ld      (utoaBuf+6), a
        ld      b, e
normL6  djnz    normL4

normL0  ld      hl, (sizeL)
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl
        call    utoa

        xor     a
        ld      (utoaBuf+6), a
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
; Converts and print an unsigned int (unsigned char) to an 4 (2) char asciiz
; string
;
; input:    hl = unigned int to convert (l = unsigned char to convert)
; output:   -
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------
bin2hex8
        ld      de, utoaBuf+4
        push    de
        jr      bin2hex_2
bin2hex16
        ld      de, utoaBuf+2
        push    de
        ld      a, h
        call    cvtUpperNibble2
        ld      a, h
        call    cvtLowerNibble2
bin2hex_2
        ld      a, l
        call    cvtUpperNibble2
        ld      a, l
        call    cvtLowerNibble2
        pop     hl
        jp      prStr
cvtUpperNibble2
        rra                     ; move upper nibble into lower nibble
        rra
        rra
        rra
cvtLowerNibble2
        and     $0F             ; isolate lower nibble
        add     a,'0'
        cp      ':'
        jr      c, cvtStoreVal
        add     a,'A'-'0'-10
cvtStoreVal
        ld      (de), a
        inc     de
        ret

; -----------------------------------------------------------------------------
; Converts an unsigned int to an 6 char ASCII string
; Don't deletes '0' on the left
;
; input:    hl = unigned int to convert
;           de = pointer to ASCII string -> NO, ACTUALLY NOT USED
; output:   c:hl = 6 digits BCD number
;           de = pointer to end of string
; destroys: af,bc,de,hl
; -----------------------------------------------------------------------------
;
utoa
        ld      bc, 16*256+0    ; handle 16 bits, one bit per iteration
        ld      de, 0
cvtLoop
        add     hl, hl
        ld      a, e
        adc     a, a
        daa
        ld      e, a
        ld      a, d
        adc     a, a
        daa
        ld      d, a
        ld      a, c
        adc     a, a
        daa
        ld      c, a
        djnz    cvtLoop
        ex      de, hl          ; C:HL = numero BCD de 6 digitos

bcd2hex
        ld      de, utoaBuf
        push    de
        ld      a, c
        call    cvtUpperNibble
        ld      a, c
        call    cvtLowerNibble
        ld      a, h
        call    cvtUpperNibble
        ld      a, h
        call    cvtLowerNibble
        ld      a, l
        call    cvtUpperNibble
        ld      a, l
        call    cvtLowerNibble
        pop     hl
        jr      prtDec
cvtUpperNibble
        rra                     ; move upper nibble into lower nibble
        rra
        rra
        rra
cvtLowerNibble
        and     $0F             ; isolate lower nibble
        or      %00110000       ; convert to ASCII
        ld      (de), a
        inc     de
        ret

; -----------------------------------------------------------------------------
; Print a asciiz string representing a number at cursor position
; Skips '0' on the left
;
; input:    hl = pointer to asciiz string
; output:   hl = pointer to end of string
; destroys: af,bc,de,hl,af'
; -----------------------------------------------------------------------------
;
prtDec  ld a, (hl)
        cp '0'
        jr nz, prStr    ; if not equal to '0', print it
ignCero inc hl
        ld a, (hl)
        cp '0'
        jr z, ignCero   ; if next digit equal to '0', skip '0' on the left
        jr c, impCero   ; if next digit below '0', print almost one '0'

        cp '9'
        jr z, prStr     ; if equal
        jr c, prStr     ; or below than '9', print it

impCero dec hl          ; print almost one '0'

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
        db      'drives v'
        VERSION
        db      ' By Dr. Slump 2022',13,0
msg0002 db      13
        db      'Usage: drives [args]',13, 13
        db      '-1 use M_DRIVEINFO syscall (*)',13
        db      '-2 use M_GETSETDRV syscall',13
        db      '-3 use DISK_INFO syscall',13
        db      '-d debug, dump structs',13
        db      ' * default option',13
        db      13
        db      '-? this help info',13
        db      0
msg0003 db      13
        db      'Detected drives:',13
        db      13,0
msg0004 db      13
        db      'Detected devices:',13
msgCr   db      13,0
msg0005 db      'Invalid command lin', 'e'+$80

drvName db      0,'d',0,0,0

msg0006 db      ': ',0
msg0007 db      ', ',0

msg0008	db	'...',13,0

; ----------------------
; prefixes for filesizes
; ----------------------
;
prefix  db      'TGM'      ; 'GMK'

; -----------------------
; buffer to utoa function
; -----------------------
;
utoaBuf ds      8,0

; -----------------------
; variables
; -----------------------
;
defdrv  db      0       ; default drive
actdrv  db      0       ; actual drive

sizeL   dw      0       ;
sizeH   dw      0       ; size in blocks of 512 bytes

; ---------------------
; line arguments parser
; ---------------------
;
ptrArgs         dw      0
argStr          equ     $

;
; DISK_INFO buffer
;
;	M_DRIVEINFO 4,  1+1+1+4+6+1+8+1 = 4x23 = 92
;	DISK_INFO   10, 1+1+4           = 10x6 = 60
;
;buffer  equ     $
buffer  ds      92,0

;------------------------------------------------------------------------------
        IF $ > $2000+7000
        .ERROR Resulting code too long
        ENDIF
;------------------------------------------------------------------------------

        end     main


