;==============================================================================
; Project: NMI.zdsp
; File: main.asm
; Date: 29/08/2017 13:39:54
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; MAIN
;==============================================================================

; -----------------------------------------------------------------------------
; ENTRY POINT
; -----------------------------------------------------------------------------

; Info:
; load overlay fails with M_EXECCMD. Do more tests.
; Dot commands uses same addresses space than NMI.sys,
; can not call functions inside NMI.sys code.

; Feature request:
; It is possible to associate a file extension to an external command so when
; the user selects from the NMI browser a file with such extension, the
; corresponding command is executed?

; Aligerar las lecturas del directorio actual que hace el navegador NMI.
; Esto implica no poder mostrar el total de ficheros en el directorio actual, Y. X of Y
; - graba la pantalla (init)
; - carga el fichero de configuracion (init)
; - calcula el numero de entradas en el directorio actual (reload): calcNumDirEntries
; - lee e imprime las entradas en el directorio actual: prMid
; Hay que rehacer la forma de cambiar a la pagina siguiente y a la anterior y
; posiblemente la forma de leer las entradas del directorio actual a mostrar
; en la pantalla actual.
;

		org NMI_OVERLAY

mainNMI		ld (savedSP), sp
		ld (NMIbuf), hl		; saves pointer to NMI buffer
		call saveScreen

		xor a			;
		out ($fe), a		; black border

		jp init

mainL1		jp reload

mainL2		ld bc, 24*256+0		; 24 lines from line 0
		ld a, COL_MID		; color
		call clrScr
		call prTop

mainL3		call prMid

mainL4		call prBot
		call prCur

mainL5		call waitKey

		ld c, a			; c <- key pressed
		;
		call beep
		;
		ld hl, actTbl
nextKey		ld a, (hl)		; a <- key to check
		or a
		jr z, mainL5		; end of table
		inc hl
		ld e, (hl)		;
		inc hl			;
		ld d, (hl)		; de <- address of action routine
		inc hl
		cp c			; key pressed = key to check ?
		;jr      nz, mainL7      ; no, try next key to check
		jr nz, nextKey		; no, try next key to check
		;
		push de
		call readEnt		; read current dir entry (entry at cursor)
		pop hl
		;
		jp (hl)			; yes, jump to action routine

exitNMI		call wait
		call restoreScreen	; exit NMI navigator
		call deleteScreen

		ld sp, (savedSP)
		ret			; ret from NMI handler
					; state is restored and program execution resumed

; -------------------
; save screen to disk
; -------------------
;
saveScreen

		xor a
		ld (savRAM), a

		ld hl, 16384
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		rst $30
		db $0a
		ret nc

		ld a, $ff
		ld (savRAM), a

		ld hl, fileSav		; asciiz string containing path and/or filename
		ld b, FA_CREATE_AL|FA_WRITE
					; create if not exists, else open and truncate
					; write access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, 16384		; source
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		call fWrite

		call fClose

		ret

; ------------------------
; restore screen from disk
; ------------------------
;
restoreScreen

		ld a, (savRAM)
		or a
		jr nz, toFile

		ld de, 16384
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		rst $30
		db $0b
		ret

toFile		ld hl, fileSav		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, 16384		; dest
		ld bc, 7*1024		; 6144+768 ; max size 7*1024
		call fRead

		call fClose

		ret

; -----------------------
; delete screen from disk
; -----------------------
;
deleteScreen
		ld a, (savRAM)
		or a
		ret z

		ld hl, fileSav		; null-terminated string containg path and/or filename
		ld a, SYS_DRIVE		; system/boot drive
		call fUnlink1
		ret

; -----------------------------------------------------------------------------
; NAVIGATION FUNCTIONS
; -----------------------------------------------------------------------------

; ----------------
; go to parent dir
; ----------------
;
upDir		ld a, (flgROOT)
		or a
		jp nz, mainL5		; only if not on root dir

		ld hl, dotDot		; '..'
		call fChDir
		jp mainL1		; reload dir and reprint all

; ------------------
; moves to prev line
; ------------------
;
prevLn		call clCur
		ld a, (curLn)		; between 0 and 21
		or a
		jr z, prevLn1
		dec a
		ld (curLn), a
		jp mainL4		; reprint bottom and cursor
prevLn1		call prevCk
		jp c, mainL4
		ld a, 21
		ld (curLn), a
		jr prevPg1

; ------------------
; moves to next line
; ------------------
;
nextLn		call clCur
		;ld      a, (Xlim)       ; between 1 and 22
		;dec     a
		ld a, (Xlim)		; between 0 and 21
		ld b, a
		ld a, (curLn)		; between 0 and 21
		cp b
		jr nc, nextLn1		; curLn >= Xlim-1
		cp 21
		jr z, nextLn1
		inc a
		ld (curLn), a
		jp mainL4		; reprint bottom and cursor
nextLn1		call nextCk
		jp nc, mainL4
		xor a
		ld (curLn), a
		jr nextPg1

; ------------------
; moves to prev page
; ------------------
;
prevCk		ld hl, (Xof)
		ld de, 22
		or a			; clear carry flag
		sbc hl, de
		ret

prevPg		ld a, (curLn)		; between 0 and 21
		or a
		jr z, prevPg1
		call clCur
		xor a
		ld (curLn), a
		jp mainL4		; reprint bottom and cursor
		;
prevPg1		call prevCk
		jp c, mainL4		; reprint bottom and cursor
		ld (Xof), hl
		call clCur
		;xor     a              ;
		;ld      (curLn), a     ; preserves cursor position
		;
		;       RECUPERAR DE pTable2 EL PUNTERO A LA PAGINA ANTERIOR
		;
		ld hl, (pCurPg)
		dec hl
		;ld      de, pTable+3
		ld de, pTable+2
		;ld      bc, 4
		ld bc, 3
		lddr			; con lddr nos ahorramos restarle 4 a pCurPg
		inc hl
		ld (pCurPg), hl
		;
		jp mainL3		; reprint mid, bottom and cursor

; ------------------
; moves to next page
; ------------------
;
nextCk		ld hl, (Xof)
		ld de, 22
		add hl, de
		ld de, (ofY)
		or a			; clear carry flag
		push hl
		sbc hl, de
		pop hl
		ret

nextPg		;ld      a, (Xlim)       ; between 1 and 22
		;dec     a
		ld a, (Xlim)		; between 0 and 21
		ld b, a
		ld a, (curLn)		; between 0 and 21
		cp b
		jr z, nextPg1
		push bc
		call clCur
		pop af
		ld (curLn), a
		jp mainL4		; reprint bottom and cursor
		;
nextPg1		call nextCk
		jp nc, mainL4		; reprint bottom and cursor
		ld (Xof), hl
		call clCur
		;xor     a              ;
		;ld      (curLn), a     ; preserves cursor position
		;
		;       GUARDAR EN pTable2 EL PUNTERO A LA PAGINA ACTUAL
		;
		ld hl, pTable
		ld de, (pCurPg)
		;ld      bc, 4
		ld bc, 3
		ldir
		ld (pCurPg), de
		;
		;       CARGAR EN pTable EL PUNTERO A LA PAGINA SIGUIENTE
		;
		;ld      hl, pTable+22*4
		ld hl, pTable+22*3
		ld de, pTable
		;ld      bc, 4
		ld bc, 3
		ldir
		;
		jp mainL3		; reprint mid, bottom and cursor

; -----------------------------------------------------------------------------
; GUI functions
; -----------------------------------------------------------------------------

; ----------------------
; read current dir entry
; ----------------------
;
readEnt		call fOpenDir		; read current dir entry (entry at cursor)

		;ld      hl, (curLn)             ;
		;ld      de, pTable              ;
		;add     hl, hl                  ;
		;add     hl, hl                  ;
		;add     hl, de                  ; hl = pTable + curLn*4
		;ld      c, (hl)                 ; bcde <- (hl)
		;inc     hl                      ;
		;ld      b, (hl)                 ;
		;inc     hl                      ;
		;ld      e, (hl)                 ;
		;inc     hl                      ;
		;ld      d, (hl)                 ;
		ld bc, (curLn)		;
		ld de, pTable		;
		ld h, b			;
		ld l, c			;
		add hl, hl		;
		add hl, bc		;
		add hl, de		; hl = pTable + curLn*3
		ld b, 0			; bcde <- (hl)
		ld c, (hl)		;
		inc hl			;
		ld e, (hl)		;
		inc hl			;
		ld d, (hl)		;
		;
		call fSeekDir
		;
		call fReadDir
		jp c, printError	; REVISAR !!!

		call fClose

		ret

; ------------
; clear cursor
; ------------
;
clCur		ld a, COL_MID		; color
		jr prCurL0

; -----------
; draw cursor
; -----------
;
prCur		ld a, COL_CUR		; color
prCurL0		ld c, a
		ld hl, (curLn)		; cursor between 0 and 21
		inc hl			; screen rows between 1 and 22
		ld b, 5			;
multx2		add hl, hl		;
		djnz multx2		; hl = hl x 32
		ld de, 16384+6144
		adc hl, de
		push hl
		pop de
		inc de
		ld a, c
		ld (hl),a
		ld bc,32-1
		ldir
		ret

; -------------------
; print top of screen
; -------------------
;
prTop		ld bc, 1*256+0		; 1 line from line 0
		ld a, COL_TOP		; color
		call clrScr
		;
		ld hl, msgTop1
		call prStr
		;ld      a, (flgCWD)
		;and     a
		;jr      z, prTopL1
		;ld      a, 129          ; two points
		;call    prOk
		;prTopL1 ld      hl, (pCWD)
		;call    prStr
		ret

; ----------------------
; print bottom of screen
; ----------------------
;
prBot		ld bc, 1*256+23		; 1 line from line 23
		ld a, COL_BOT		; color
		call clrScr
		;
		ld hl, msgBot1
		call prStr
		ld hl, (Xof)
		ld de, (curLn)
		add hl, de
		inc hl
		call utoa
		ld hl, msgBot3
		call prStr
		ld hl, (ofY)
		call utoa
		ld hl, msgBot4
		call prStr
		ld hl, msgBot5
		call prStr
		ret

; -------------------
; print mid of screen
; -------------------
;
prMid		ld bc, 22*256+1		; 22 lines from line 1
		ld a, COL_MID		; color
		call clrScr
		call fOpenDir

		;ld      bc, (pTable)
		;ld      de, (pTable+2)
		ld b, 0
		ld a, (pTable)
		ld c, a
		ld de, (pTable+1)
		call fSeekDir

		ld hl, 0		; counter = 0
prMidL0		push hl
		call fTellDir		; OJO, hay 2 bytes en la pila
		;
		pop hl
		push hl
		push de
		push bc
		ld de, pTable		;
		;add     hl, hl          ;
		;add     hl, hl          ;
		;add     hl, de          ; hl = pTable + counter*4
		ld b, h			;
		ld c, l
		add hl, hl		;
		add hl, bc		;
		add hl, de		; hl = pTable + counter*3
		pop bc
		pop de
		ld (hl), c		; (hl) <- bcde
		inc hl			;
		;ld      (hl), b         ; (hl) <- cde
		;inc     hl              ;
		ld (hl), e		;
		inc hl			;
		ld (hl), d		;
		;
		pop hl
		push hl
		ld a, l
		cp 22
		jr nc, prMidL3		; if hl >= 22 (read 22 entries
					; plus 1 entry for next page)
		call fReadDir		; en las pruebas: CF=0 A=$01 si hay mas entradas
					;                 CF=1 A=$80 si no hay mas entradas
		jr c, prMidL3
		or a
		jr z, prMidL3		; a==0 if end of dir
		jr prMidL1
		;
prMidL3		pop hl
		;ld      (Xlim), hl
		dec hl
		ld (Xlim), hl
		; ***
		;
		; Correct cursor position according to current number of dir entries on screen
		;
		;dec     l
		ld a, (curLn)		; between 0 and 21
		cp l
		jr c, prMidL4		; curLn >= Xlim-1
		ld a, l
		ld (curLn), a
		; ***
prMidL4		call fClose
		ret
		;
prMidL1		pop hl
		push hl
		ld a, l
		inc a
		ld (msgMid1+1), a
		ld (msgMid4+1), a
		ld hl, msgMid1
		call prStr
		ld hl, bDName
		call prStr

		ld hl, msgMid4
		call prStr
		ld a, (bDAttr)
		and A_DIR		; check if is dir
		jr z, isFile

isDir		ld hl, msgMid2
		call prStr
		jr prMidL2

isFile		call prtSize

prMidL2		pop hl
		inc hl
		jr prMidL0

; ----------------------------
; pretty printer for file size
; ----------------------------
;
prtSize		xor a			;
		ld hl, bDName		;
		ld bc, 8+1+3+1		;
		cpir			; search end of string
		inc hl
		inc hl
		inc hl
		inc hl			; add 4 to hl, hl points to dword DSize
		ld (pDSizeL), hl
		inc hl
		inc hl
		ld (pDSizeH), hl

		ld b, 3
normL4		ld hl, (pDSizeH)
		ld a, (hl)
		inc hl
		or (hl)
		jr nz, normL5
		ld hl, (pDSizeL)
		inc hl
		ld a, $26
		cp (hl)
		jr nc, normL6
normL5		ld d, 0
		ld e, b

div1024		ld b, 10
divL0		ld hl, (pDSizeH)
		inc hl
		srl (hl)
		ex af, af'
		ld c, b
		ld b, 3
divL1		dec hl
		srl (hl)
		ex af, af'
		jr nc, divL2
		ld a, %10000000		;
		add a, (hl)		; set bit 7 of (hl) if carry set
		ld (hl), a		;
divL2		djnz divL1
		ld b, c
		djnz divL0

		ld hl, prefix-1
		add hl, de
		ld a, (hl)
		ld (utoaBuf+6), a
		ld b, e
normL6		djnz normL4

normL0		ld hl, (pDSizeL)
		ld e, (hl)
		inc hl
		ld d, (hl)
		ex de, hl
		call utoa

		xor a
		ld (utoaBuf+6), a
		ret

; -----------------------------------------------------------------------------
; OVERLAY SYSTEM
; -----------------------------------------------------------------------------

; ------------
; load overlay
; ------------
;
loadOvr		;ld      b, 0
		;ld      c, (hl)
		;inc     hl
		ld de, nameOvr
		ld bc, 8
		ldir			; copy overlay name
		;ld      hl, extOvr
		;ld      bc, 5
		;ldir                    ; copy overlay extension

		ld hl, pathOvr		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, ovrBuf
		ld bc, SIZ_OVR
		call fRead

		call fClose

		ld a, (ovrArg)
		;
		; Alguna forma de indicar argumentos de llamada.
		;
		call ovrBuf
		;
		; Retardo
		;
		call wait
		;
		; Algun tipo de valor de retorno para indicar si saltar a mainL1,
		; mainL2, mainL3, mainL4 o mainL5.
		;
		or a
		ret z			; return (continues normal workflow)
		cp 1
		jp z, mainL1		; reload dir and reprint all
		cp 2
		jp z, mainL2		; reprint all (top, mid, bottom and cursor)
		cp 3
		jp z, mainL3		; reprint mid, bottom and cursor
		cp 4
		jp z, mainL4		; reprint bottom and cursor
		jp mainL5		; reprint nothing

; -----------------------------------------------------------------------------
; ACTIONS
; -----------------------------------------------------------------------------

; -------------
; save snapshot
; -------------
;
saveSNA		ld hl, saveSNAOvr	; asciiz string containg path and/or filename
		jr loadOvr

; ----
; poke
; ----
;
poke		ld hl, pokeOvr		; asciiz string containg path and/or filename
		jr loadOvr

; -----------
; rename file
; -----------
;
renFile		ld hl, renameFileOvr	; asciiz string containg path and/or filename
		jr loadOvr

; -----------
; delete file
; -----------
;
delFile		ld hl, deleteOvr	; asciiz string containg path and/or filename
		jr loadOvr

; -----------
; view screen
; -----------
;
view		ld hl, viewOvr		; asciiz string containg path and/or filename
		jr loadOvr

; ---------------------
; do action over cursor
; ---------------------
;
doAct		ld hl, enterOvr		; asciiz string containg path and/or filename
		jr loadOvr

; ------
; config
; ------
;
config		ld hl, configOvr	; asciiz string containg path and/or filename
		jr loadOvr

; --------------------
; load old NMI handler
; --------------------
;
oldNMI		ld hl, loadoldOvr	; asciiz string containg path and/or filename
		jr loadOvr

; --------------
; fast-ramp load
; --------------
;
fastload
		ld hl, fastloadOvr	; asciiz string containg path and/or filename
		jr loadOvr

; ----------------
; fast-ramp config
; ----------------
;
fastcfg
		ld hl, fastcfgOvr	; asciiz string containg path and/or filename
		jr loadOvr
		; ----
		; help
		; ----
		;
help		ld hl, helpOvr		; asciiz string containg path and/or filename
		jr loadOvr

; ------
; tapein
; ------
;
tapein		ld hl, tapeinOvr
		jr loadOvr

; -------
; tapeout
; -------
;
tapeout		ld hl, tapeoutOvr
		jp loadOvr

; ------------
; TRD to drive
; ------------
;
trd2drv0
		xor a
		jr trd2drv
trd2drv1
		ld a, 1
		jr trd2drv
trd2drv2
		ld a, 2
		jr trd2drv
trd2drv3
		ld a, 3
trd2drv		ld (ovrArg), a
		ld hl, trd2drvOvr
		jp loadOvr

; ------
; seldrv
; ------
;
;seldrv0
;        xor     a
;        jr      seldrv
;seldrv1
;        ld      a, 1
;        jr      seldrv
;seldrv2
;        ld      a, 2
;        jr      seldrv
;seldrv3
;        ld      a, 3
seldrv		;ld      (ovrArg), a
		ld hl, selDrvOvr
		jp loadOvr

; ----
; init
; ----
;
init		ld hl, initOvr
		jp loadOvr

; --------------------
; load external module
; --------------------
;
loadmod		ld hl, loadmodOvr
		jp loadOvr

; --------------------
; lock paging register
; --------------------
;
lock		ld hl, lockOvr
		jp loadOvr

; -----
; reset
; -----
;
reset		ld hl, resetOvr
		jp loadOvr

; ------
; reload
; ------
;
reload		ld hl, reloadOvr
		jp loadOvr

; -----
; debug
; -----
;
debug		ld hl, debugOvr
		jp loadOvr

