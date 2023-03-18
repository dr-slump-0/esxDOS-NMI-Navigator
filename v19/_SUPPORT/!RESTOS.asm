
; *****************************************************************************
;  R E S T O S
; *****************************************************************************

		;ld      hl, bFStat
		;call    fFStat

		;ld      hl, msg001
		;call    prStr
		;ld      hl, (bFSsizeL)
		;call    utoa

		;ld      hl, msg002
		;call    prStr
		;ld      hl, (bFSsizeH)
		;call    utoa

		;call    waitKey

		;ret

;msg001  db      $16,0,0,0
;msg002  db      $16,0,32,0

; --------------
; F_FSTAT buffer
; --------------
;
;bFStat
;bFSdrive        db      0
;bFSdevice       db      0
;bFSattrib       db      0
;bFSdateL        dw      0
;bFSdateH        dw      0
;bFSsizeL        dw      0
;bFSsizeH        dw      0

;bHeader ds      26,0

; ***

;        ;
;        ; call BASIC from machine code
;        ;
;prueba  ld      hl, (E_LINE)
;        push    hl
;        ld      hl, B_LIST
;        ld      (E_LINE), hl
;        call    LINE_RUN
;        ld      hl, B_RUN
;        ld      (E_LINE), hl
;        call    LINE_RUN
;        ld      hl, B_TRDOS
;        ld      (E_LINE), hl
;        rst     $18             ;
;        dw      LINE_RUN        ; call routine in BASIC ROM
;        pop     hl
;        ld      (E_LINE), hl

;E_LINE   equ 23641
;LINE_RUN equ $1b8a

;B_LIST  db      $f9,$c0,$b0,'"15619"',':',$ea,':',$f0,13
;B_RUN   db      $f9,$c0,$b0,'"15619"',':',$ea,':',$f7,'"boot"',13
;B_TRDOS db      $fd,$b0,'"31732"',':',$ef,'""',$af,$b0,'"31733"',':',$f9,$c0,$b0,'"31733"',13

; ***


; *****************************************************************************
		;
		; from BETA 128 DISK INTERFACE -- USER MANUAL
		;
		;ld      hl, (CHADD)
		;ld      (tCHADD), hl

		;ld      hl, TRDList
		;ld      (CHADD), hl
		;call    15363

		;ld      hl, TRDRun
		;ld      (CHADD), hl
		;call    15363

		;ld      hl, (tCHADD)
		;ld      (CHADD), hl
		;
		; load LOAD.BAS
		;
		;ld      a, (wrkDrv)
		;ld      hl, nameBAS
		;call    fAutoLoad

		;
		; load TRDNC.SNA
		;
		;ld      hl, TRDNsna
		;call    fExecCMD

		;
		; load TRDN.bin
		;
		;ld      hl, navLoad      ; asciiz string containg path and/or filename
		;ld      b, FA_OPEN_EX|FA_READ
		; open if exists, else error
		; read access
		;call    fOpen

		;ld      hl, 31733       ; dest
		;ld      bc, 15360       ; size  ; 7*1024
		;call    fRead

		;call    fClose

		;ld      (tmpSP), sp
		;ld      sp, 31732
		;call    31733
		;call    31733
		;ld      sp, (tmpSP)

		;
		; load TRDN.tap
		;
		;ld      b, 0
		;ld      hl, TRDNtap
		;call    fTapeIn
		;ld      a, 0
		;call    fAutoLoad


;-------------------
; load TRD variables
;-------------------
;
;CHADD   equ     23645

;tCHADD  dw      0

;TRDList db      $ea     ; REM
;        db      ':'
;        db      $f0     ; LIST
;        db      $0d     ; ENTER

;TRDRun  db      $ea     ; REM
;        db      ':'
;        db      $f7     ; RUN
;        db      '"boot"'
;        db      $0d     ; ENTER

;nameBAS db      '/sys/nmi/LOAD.BAS',0
;nameBAS db      '/sys/nmi/PASO1.BAS',0
;navLoad db      '/sys/nmi/TRDN.BIN',0
;tmpSP   dw      0
;TRDNsna db      'SNAPLOAD /sys/nmi/TRDNC.SNA',0

; ***


; *****************************************************************************
;  R E S T O S  P R O C E S A R   A R G U M E N T O S   L I N E A
; *****************************************************************************

		call getArg
		or a
		jr z, _5
		jr _1

_0		call getArg
		or a
		jr z, _6
_1		cp 1
		jr nz, _2
		ld hl, msgT2
		call prStr
		call getArg
		cp 2
		jr nz, _4
		ld hl, argStr
		call prStr
		ld hl, msgCR
		call prStr
		jr _0

_2		cp 2
		jr nz, _3
		ld hl, msgT3
		call prStr
		ld hl, argStr
		call prStr
		ld hl, msgCR
		call prStr
		jr _0

_3		ld hl, msgT4
		call prStr
		jr _6

_4		ld hl, msgT5
		call prStr
		jr _6

_5		ld hl, msgT1
		call prStr

_6

msgT1		db 'No args'
msgCR		db 13,0
msgT2		db 'opcion: ',0
msgT3		db 'valor: ',0
msgT4		db 'Estado no definido',13,0
msgT5		db 'error en opcion',13,0

