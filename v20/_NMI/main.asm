;==============================================================================
; Project: NMI.zdsp
; File: main.asm
; Date: 29/08/2017 13:39:54
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; MAIN - divXXX page 5
;==============================================================================

mainNMI		ld hl, BACKED_UP_RAM	; DB 21,00,5B	; $5b00
		ld de, savedSP		; DB 11,CA,37
		ld bc, 31+9		; DB 01,28,00
		ldir			; DB ED,B0

		//ld sp, (savedSP)
		//jp init.start

mainL1		//jp reload.start
		ld sp, (savedSP)
		//jp startup.start
		call startup.start

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
		ld hl, dbdwTbActions
nextKey		ld a, (hl)		; a <- key to check
		or a
		jr z, mainL5		; end of table
		inc hl
		ld e, (hl)		;
		inc hl			;
		ld d, (hl)		; de <- address of action routine
		inc hl
		cp c			; key pressed = key to check ?
		jr nz, nextKey		; no, try next key to check
		;
		push de
		call readEnt		; read current dir entry (entry at cursor)
		pop hl
		;
		jp (hl)			; yes, jump to action routine

exitNMI		call wait

		//ld sp, (savedSP)	///
		//RETPG0		; return to NMI loader on page 0

		ld sp, NMI_STACK	; necessary to use PAGING MACROS
		JUMPPG 0, initNMI.lbBack; return to NMI loader on page 0

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
		;       RECUPERAR DE pPrvDir EL PUNTERO A LA PAGINA ANTERIOR
		;
		ld hl, (pCurPg)
		dec hl

		IFDEF _POINTER4BYTES
		  ld de, pCurDir+3
		  ld bc, 4
		ELSE
		  ld de, pCurDir+2
		  ld bc, 3
		ENDIF
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
		;
		; If ofY is zero, end of directory not reached yet
		;
		ld a,d
		or e
		scf
		ret z
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
		;       GUARDAR EN pPrvDir EL PUNTERO A LA PAGINA ACTUAL
		;
		ld hl, pCurDir
		ld de, (pCurPg)
		IFDEF _POINTER4BYTES
		  ld bc, 4
		ELSE
		  ld bc, 3
		ENDIF
		ldir
		ld (pCurPg), de
		;
		;       CARGAR EN pCurDir EL PUNTERO A LA PAGINA SIGUIENTE
		;
		IFDEF _POINTER4BYTES
		  ld hl, pCurDir+22*4
		  ld bc, 4
		ELSE
		  ld hl, pCurDir+22*3
		  ld bc, 3
		ENDIF
		ld de, pCurDir
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

		IFDEF _POINTER4BYTES
		  ld hl, (curLn)	;
		  ld de, pCurDir	;
		  add hl, hl		;
		  add hl, hl		;
		  add hl, de		; hl = pCurDir + curLn*4
		  ld c, (hl)		; bcde <- (hl)
		  inc hl		;
		  ld b, (hl)		;
		  inc hl		;
		  ld e, (hl)		;
		  inc hl		;
		  ld d, (hl)		;
		ELSE
		  ld bc, (curLn)	;
		  ld de, pCurDir	;
		  ld h, b		;
		  ld l, c		;
		  add hl, hl		;
		  add hl, bc		;
		  add hl, de		; hl = pCurDir + curLn*3
		  ld b, 0		; bcde <- (hl)
		  ld c, (hl)		;
		  inc hl		;
		  ld e, (hl)		;
		  inc hl		;
		  ld d, (hl)		;
		ENDIF
		;
		call fSeekDir
		;
		call fReadDir
		//jp c, printError	; REVISAR !!!

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
		//ld hl, msgSP
		//call prStr
		//ld hl, (savedSP)
		//ld hl, (NMIbuf_org)
		//call utoa

		ret

//msgSP		db $16,0,64-10,'SP: ', 0

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
		ld a, h
		or l
		jr nz, prBot1
		ld a, '-'
		call prChr
		jr prBot2
prBot1		call utoa
prBot2		ld hl, msgBot4
		call prStr
		ld hl, msgBot5
		call prStr
		ret

; -------------------
; print mid of screen
; -------------------
;

//msgOffset	db $16,1,8+1+3+1+7,0

prMid		ld bc, 22*256+1		; 22 lines from line 1
		ld a, COL_MID		; color
		call clrScr
		call fOpenDir

		IFDEF _POINTER4BYTES
		  ld bc, (pCurDir)
		  ld de, (pCurDir+2)
		ELSE
		  ld b, 0
		  ld a, (pCurDir)
		  ld c, a
		  ld de, (pCurDir+1)
		ENDIF
		call fSeekDir

		ld hl, 0		; counter = 0
prMidL0		push hl
		call fTellDir	; OJO, hay 2 bytes en la pila

		/*
		///
		/// BCDE offset
		///
		pop hl
		push hl
		push bc
		push de
		ld a, l
		inc a
		ld (msgOffset+1), a
		ld hl, msgOffset
		call prStr
		pop de
		pop hl
		push hl
		push de
		call utoa
		ld a, ' '
		call prChr
		pop hl
		push hl
		call utoa
		pop de
		pop bc
		///
		///
		///
		*/

		;
		pop hl
		push hl
		push de
		push bc
		ld de, pCurDir
		IFDEF _POINTER4BYTES
		  add hl, hl		;
		  add hl, hl		;
		  add hl, de		; hl = pCurDir + counter*4
		ELSE
		  ld b, h		;
		  ld c, l		;
		  add hl, hl		;
		  add hl, bc		;
		  add hl, de		; hl = pCurDir + counter*3
		ENDIF
		pop bc
		pop de
		ld (hl), c		; (hl) <- bcde
		inc hl			;
		IFDEF _POINTER4BYTES
		  ld (hl), b		; (hl) <- cde
		  inc hl		;
		ENDIF
		ld (hl), e		;
		inc hl			;
		ld (hl), d		;
		;

		call fReadDir	; en las pruebas: CF=0 A=$01 si hay mas entradas
					;                 CF=1 A=$80 si no hay mas entradas
		jr c, prMidL3
		or a
		jr z, prMidL3		; a==0 if end of dir

		//
		// ignore hidden and system files
		//
		ld a, (bDAttr)

		and A_HIDDEN or A_SYSTEM
		ld hl, flgHidden
		and (hl)
		pop hl
		jr nz, prMidL0		; nz skip system & hidden files
		push hl

		;
		; limit to MAXENTR total dir entries
		;
		pop hl
		push hl
		ld de, (Xof)
		add hl, de		; total number of directory entries
		or a			; clear CF
		ld de, MAXENTR
		sbc hl, de
		jr z, prMidL3		; total number of directory entries = MAXENTR

		;
		; limit to 22 current dir entries
		;
		pop hl
		push hl
		ld a, l
		cp 22
		jr nc, prMidL4		; if hl >= 22 (read 22 entries
					; plus 1 entry for next page)
		;
		; print directory entry
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
		;
		; is directory
		;
isDir		ld hl, msgMid2
		call prStr
		jr prMidL2
		;
		; is file
		;
isFile		call prtSize
		;
		; FALTA IMPRIMIR FECHA
		;
prMidL2		pop hl
		inc hl
		jp prMidL0

prMidL3		;
		; Calculate ofY
		;
		pop hl
		push hl
		ld de, (Xof)
		add hl, de
		ld (ofY), hl

		;
		; calculate Xlim
		;
prMidL4		pop hl
		;ld (Xlim), hl
		dec hl
		ld (Xlim), hl
		;
		; Correct cursor position according to current number of dir entries on screen
		;
		;dec     l
		ld a, (curLn)		; between 0 and 21
		cp l
		jr c, prMidL5		; curLn >= Xlim-1
		ld a, l
		ld (curLn), a

prMidL5		call fClose
		ret

