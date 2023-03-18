;==============================================================================
; Project: NMI.zdsp
; File: data.asm
; Date: 29/08/2017 13:29:18
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; DATA
;==============================================================================

; ----------------------------------------
; SP register saved on NMI navigator entry
; ----------------------------------------
;
savedSP		dw 0

; ------------------------------------
; flag to signal load config from file
; ------------------------------------
;
ldConf		db $ff

; -----------------------
; flag to signal load dir
; -----------------------
;
ldDir		db $ff

; ----------------------------------
; flag to signal screen saved to RAM
; ----------------------------------
;
savRAM		db 0

; --------------------------
; argument passed to overlay
; --------------------------
;
ovrArg		db 0

; ---------------
; used on waitKey
; ---------------
;
prevJoy		db 0			; previous joystroke
prevKey		db 0			; previous keystroke

; -------------
; actions table
; -------------
;
actTbl		db 'A'			; attach TRD to drive A
		dw trd2drv0
		db 'B'			; attach TRD to drive B
		dw trd2drv1
		db 'C'			; attach TRD to drive C
		dw trd2drv2
		db 'D'			; attach TRD to drive D
		dw trd2drv3
		db 'E'			; erase file
		dw delFile
		db K_DELETE		; erase file
		dw delFile
		db 'F'			; fast-ramp load
		dw fastload
		db K_TO			; SS+F fast-ramp config
		dw fastcfg
		db 'G'			; load mon dot command
		dw debug
		db 'H'			; show help
		dw help
		db 'I'			; attach TAP to tapein
		dw tapein
		db K_AT			; SS+I detach TAP from tapein
		dw tapein
		db 'J'			; load old NMI handler
		dw oldNMI
		db 'K'			; config navigation keys
		dw config
		db 'L'			; paging register lock, ROM 1 select
		dw lock
		db 'M'			; load module
		dw loadmod
		db 'N'			; rename file
		dw renFile
		db 'O'			; attach TAP to tapeout
		dw tapeout
		db ';'			; SS+O detach TAP from tapeout
		dw tapeout
		db 'P'			; poke memory
		dw poke
		db 'R'			; reset
		dw reset
		db 'S'			; create snapshot
		dw saveSNA
		db 'U'			; change to next valid drive (cycling)
		dw seldrv
		db 'V'			; view screen
		dw view
		db K_EDIT		; up dir
		dw upDir
kLeft		db K_LEFT		; prev page
		dw prevPg
kDown		db K_DOWN		; line down
		dw nextLn
kUp		db K_UP			; line up
		dw prevLn
kRight		db K_RIGHT		; next page
		dw nextPg
kEnter		db K_ENTER		; do action
		dw doAct
		db K_SS_ENTER		; do action
		dw doAct
		db K_CS_ENTER		; do action
		dw doAct
		db K_BREAK		; exit navigator
		dw exitNMI
		db 0

; ---------
; key table
; ---------
;
; (5 x 3 + 1) x 8 + 1 = 129 bytes
; (5 x 4 + 1) x 8 + 1 = 169 bytes
;
keyTbl		db $f7
		db '5', '4', '3', '2', '1'; NORMAL
		db '%', '$', '#', '@', '!'; SS
		db K_LEFT, $00, $00, $00, K_EDIT; CS
		;db      $00, $00, $00, $00, $00         ; E+SS
		db $ef
		db '6', '7', '8', '9', '0'
		db '&', $27, '(', ')', '_'
		db K_DOWN, K_UP, K_RIGHT, $00, K_DELETE
		;db      $00, $00, $00, $00, $00
		db $fb
		db 'T', 'R', 'E', 'W', 'Q'
		db '>', '<', $00, $00, $00
		db $00, $00, $00, $00, $00
		;db      $00, $00, $00, $00, $00
		db $df
		db 'Y', 'U', 'I', 'O', 'P'
		db $00, $00, K_AT, ';', '"'
		;db      $00, $00, $00, $00, $00
		db '[', ']', $00, $00, $7f
		db $fd
		db 'G', 'F', 'D', 'S', 'A'
		db $00, K_TO, $00, $00, $00
		;db      $00, $00, $00, $00, $00
		db '}', '{', '\', '|', '~'
		db $bf
		db 'H', 'J', 'K', 'L', K_ENTER
		db '^', '-', '+', '=', K_SS_ENTER
		db $00, $00, $00, $00, K_CS_ENTER
		;db      $00, $00, $00, $00, $00
		db $fe
		db 'V', 'C', 'X', 'Z', $00; CS IGNORED
		db '/', '?', $60, ':', $00
		db $00, $00, $00, $00, $00
		;db      $00, $00, $00, $00, $00
		db $7f
		db 'B', 'N', 'M', $00, ' '; SS IGNORED
		db '*', ',', '.', $00, $00
		db $00, $00, $00, $00, K_BREAK
		;db      $00, $00, $00, $00, $00
		db 0

flagCS		db 0			; CS pressed
flagSS		db 0			; SS pressed

; -------------------
; half width 4x7 font
; -------------------
;
; 50 x 7 = 350 bytes
;
font		db $02,$02,$02,$02,$00,$02,$00; SPACE !
		db $52,$57,$02,$02,$07,$02,$00; " #
		db $25,$71,$62,$32,$74,$25,$00; $ %
		db $22,$42,$30,$50,$50,$30,$00; & '
		db $14,$22,$41,$41,$41,$22,$14; ( )
		db $20,$70,$22,$57,$02,$00,$00; * +
		db $00,$00,$00,$07,$00,$20,$20; , -
		db $01,$01,$02,$02,$04,$14,$00; . /
		db $22,$56,$52,$52,$52,$27,$00; 0 1
		db $27,$51,$12,$21,$45,$72,$00; 2 3
		db $57,$54,$56,$71,$15,$12,$00; 4 5
		db $17,$21,$61,$52,$52,$22,$00; 6 7
		db $22,$55,$25,$53,$52,$24,$00; 8 9
		db $00,$00,$22,$00,$00,$22,$02; : ;
		db $00,$10,$27,$40,$27,$10,$00; < =
		db $02,$45,$21,$12,$20,$42,$00; > ?
		db $23,$55,$75,$77,$45,$35,$00; @ A
		db $63,$54,$64,$54,$54,$63,$00; B C
		db $67,$54,$56,$54,$54,$67,$00; D E
		db $73,$44,$64,$45,$45,$43,$00; F G
		db $57,$52,$72,$52,$52,$57,$00; H I
		db $35,$15,$16,$55,$55,$25,$00; J K
		db $45,$47,$45,$45,$45,$75,$00; L M
		db $62,$55,$55,$55,$55,$52,$00; N O
		db $62,$55,$55,$65,$45,$43,$00; P Q
		db $63,$54,$52,$61,$55,$52,$00; R S
		db $75,$25,$25,$25,$25,$22,$00; T U
		db $55,$55,$55,$55,$27,$25,$00; V W
		db $55,$55,$25,$22,$52,$52,$00; X Y
		db $73,$12,$22,$22,$42,$72,$03; Z [
		db $46,$42,$22,$22,$12,$12,$06; \ ]
		db $20,$50,$00,$00,$00,$00,$0F; ^ _
		db $20,$10,$03,$05,$05,$03,$00; sterling_pound a
		db $40,$40,$63,$54,$54,$63,$00; b c
		db $10,$10,$32,$55,$56,$33,$00; d e
		db $10,$20,$73,$25,$25,$43,$06; f g
		db $42,$40,$66,$52,$52,$57,$00; h i
		db $14,$04,$35,$16,$15,$55,$20; j k
		db $60,$20,$25,$27,$25,$75,$00; l m
		db $00,$00,$62,$55,$55,$52,$00; n o
		db $00,$00,$63,$55,$55,$63,$41; p q
		db $00,$00,$53,$66,$43,$46,$00; r s
		db $00,$20,$75,$25,$25,$12,$00; t u
		db $00,$00,$55,$55,$27,$25,$00; v w
		db $00,$00,$55,$25,$25,$53,$06; x y
		db $01,$02,$72,$34,$62,$72,$01; z {
		db $24,$22,$22,$21,$22,$22,$04; | }
		db $56,$A9,$06,$04,$06,$09,$06; ~ copyright

		;db      $50,$20,$60,$50,$70,$55,$70     ; [?] [..]      128, 129

; ----------
; NMI_BUFFER
; ----------
;
; Offset   Size   Description
; ------------------------------------------------------------------------
; 0        1      byte   I                              <- 48k SNA, 27 bytes
; 1        8      word   HL',DE',BC',AF'
; 9        10     word   HL,DE,BC,IY,IX
; 19       1      byte   Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
; 20       1      byte   R
; 21       4      words  AF,SP
; 25       1      byte   IntMode (0=IM0/1=IM1/2=IM2)
; 26       1      byte   BorderColor (0..7)
;
; v0.8.0, v0.8.5
;
; 27       2      word   PC (Program Counter)           <- 128k SNA, 4 bytes
; 29       1      byte   RAM bank paged in @ $c000
; 30       1      byte   RAM Size (0=16k,1=48k,2=128k)  <- CONFLICT !!!
; 30       1      byte   TR-DOS (SNA file format)
;
; v0.8.6, v0.8.7, v0.8.8
;
; 27       1      byte   RAM Size (0=16k,1=48k,2=128k)
; 28       2      word   PC (Program Counter)           <- 128k SNA, 4 bytes
; 30       1      byte   RAM bank paged in @ $c000
; 31       1      byte   TR-DOS (SNA file format)
;
NMIbuf		dw 0			; pointer to NMI_BUFFER

; -----------------------------------------
; file name of file containing saved screen
; -----------------------------------------
;
fileSav		db '/tmp/_nmi_bak.scr', 0

; -----------------------
; buffer to utoa function
; -----------------------
;
utoaBuf		db '000000',0,0

; --------
; messages
; --------
;
msgErr		db $16,12,32-8,'ESXDOS error ', 0

;msgTop1 db      $16,0,0,' '
msgTop1		db $16,0,1
msgDrv		db ' d :/'
msgPath		ds 62-5, ' '
		;db      ' ',0          ; <- Sobra un espacio
		db 0

msgBot1		db $16,23,1,'[',0
msgBot3		db '/',0
msgBot4		db ']',0
msgBot5		db $16,23,19
msgLock		db '         '
msgRAM1		db '     '
		db '| '
msgVer		db '              '
msgRAM2		db '     '
		db '| '
		;M_VERSION,' ',0         ; <- Sobra un espacio
		M_VERSION,0

msgMid1		db $16,1,0,0
msgMid2		db '<DIR>',0
msgMid4		;db      $16,1,59,0
		db $16,1,8+1+3+1,0

; -----------------------------------------------------------------------------
; OVERLAY SYSTEM
; -----------------------------------------------------------------------------

pathOvr		db '/sys/nmi/'
nameOvr		db '12345678',0

saveSNAOvr	db 'savesna',0
pokeOvr		db 'poke',0
renameFileOvr	db 'rename',0
configOvr	db 'config',0
deleteOvr	db 'delete',0
viewOvr		db 'view',0
enterOvr	db 'enter',0
loadoldOvr	db 'loadold',0
fastloadOvr	db 'fastload',0
fastcfgOvr	db 'fastcfg',0
helpOvr		db 'help',0
tapeinOvr	db 'tapein',0
tapeoutOvr	db 'tapeout',0
trd2drvOvr	db 'trd2drv',0
selDrvOvr	db 'seldrv',0
initOvr		db 'init',0
loadmodOvr	db 'custom',0
resetOvr	db 'reset',0
lockOvr		db 'lock',0
reloadOvr	db 'reload',0
debugOvr	db 'debug',0

; -----------------------------------------------
; used to open/change to current/upper dir (./..)
; -----------------------------------------------
;
dotDot		db '..', 0

; ----------------------
; prefixes for filesizes
; ----------------------
;
prefix		db 'GMK'

; ------------------------------------------
; file handle of files/dir opened by NMI.sys
; ------------------------------------------
;
fhandle		db 0

; -------------------------------------------
; variables for 64 columns printing functions
; -------------------------------------------
;
flgAT		db 0			; AT flag
row		db 0			; row
col		db 0			; col

; ---------------
; other variables
; ---------------
;
flgLOCK		db $ff			; flag to signal LOCK 48k mode
flgROOT		db 0			; flag to signal root dir reached
flg128k		db 0			; flag to signal 128k speccy

divRAM		dw 0			; number of 8k RAM pages found

esxDOSv		db 0			; version of esxDOS

; ----------------------------------
; variables for NMI navigator paging
; ----------------------------------
;
curLn		dw 0
pCurPg		dw pTable2
Xof		dw 0
Xlim		dw 0
ofY		dw 0

; ----------------
; dir entry buffer
; ----------------
;
; <byte>    attributes (like MSDOS)
; <asciiz>  file/dirname
; <dword>   date
; <dword>   filesize
;
; date and filesize are relatives to the end of file/dirname asciiz string
;
bufDir
bDAttr		db 0
bDName		ds 8+1+3+1+4+4, 0	; set to possible max size

pDSizeL		dw 0			; pointer to filesize on dir entry buffer L
pDSizeH		dw 0			; pointer to filesize on dir entry buffer H

; -----------------------------------
; pointers to dir entry, current page
; -----------------------------------
;
; there are 23 entries because I need an additional pointer to the first dir
; entry of the next page
;
; chaged pointers from 4 bytes to 3 bytes long, on this version of esxDOS works
;
;pTable  ds      4*23,0
pTable		ds 3*23,0

; -------------------------------------
; pointers to dir entry, previous pages
; -------------------------------------
;
;pTable2 ds      (MAXENTR/22)*4,0
pTable2		ds (MAXENTR/22)*3,0

; --------------
; overlay buffer
; --------------
;
ovrBuf		ds SIZ_OVR,0

