;==============================================================================
; Project: pages.zDSp
; Main File: pages.asm
; Date: 09/06/2020 11:44:03
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================


		INCLUDE "../esxdos.inc"
		INCLUDE "../errors.inc"
		INCLUDE "macros.inc"

		LUA
		print ("START_ADDR:",_c("START_ADDR"))
		print ("END_ADDR:",_c("END_ADDR"))
		ENDLUA

;==============================================================================
; Page 2
;==============================================================================

		DEFINE page_ 2
		ORG START_ADDR

		LUA
		print ("Page 2")
		print ("BEGIN:",_c("$"))
		ENDLUA

main		;
		; Falta cargar las pÃ¡ginas de memoria desde fichero
		;

		ld	a, ($3df9)
		add	a, '0'
		ld	(page1), a
		ld	hl, msg1
		call	prStr

		CHPAGE	5, StartP5.main


Exit    	or 	a		; clear CF (no error)
        	ret

; -----------------------------------------------------------------------------
; Print a asciiz string at cursor position
; Updates cursor coordinates
; -----------------------------------------------------------------------------
;
prStr   	ld      a, (hl)
        	or      a
        	ret     z
        	rst     $10
        	inc     hl
        	jr      prStr

msg1		DB 13, 'dot command, page '
page1		DB '0', 0

		;
		; Posiblemente no haga falta esto
		; Investigar. $- $2000
		LUA
		print ("SIZE:",_c("$")-_c("START_ADDR"))
		print ("$:",_c("$"))
		print ("$$$:",_c("$$$"))
		ENDLUA
		;
		;DS END_ADDR - $, 2	; fill to next page

;==============================================================================
; Page 5
;==============================================================================

		UNDEFINE page_
		DEFINE page_ 5
		DISP START_ADDR

		LUA
		print ("Page 5")
		print ("BEGIN:",_c("$"))
		ENDLUA

		MODULE	StartP5

main		ld	a, ($3df9)
		add	a, '0'
		ld	(page1), a
		ld	hl, msg1
		call	prStr

		CHPAGE	6, StartP6.main


Exit    	or 	a		; clear CF (no error)
        	ret

; -----------------------------------------------------------------------------
; Print a asciiz string at cursor position
; Updates cursor coordinates
; -----------------------------------------------------------------------------
;
prStr   	ld      a, (hl)
        	or      a
        	ret     z
        	rst     $10
        	inc     hl
        	jr      prStr

msg1		DB 13, 'dot command, page '
page1		DB '0', 0

		ENDMODULE

		;DS END_ADDR - $, 5	; fill to next page

		LUA
		print ("SIZE:",_c("$")-_c("START_ADDR"))
		print ("$:",_c("$"))
		print ("$$$:",_c("$$$"))
		ENDLUA

		ENT

;==============================================================================
; Page 6
;==============================================================================

		UNDEFINE page_
		DEFINE page_ 6
		DISP START_ADDR

		LUA
		print ("Page 6")
		print ("BEGIN:",_c("$"))
		ENDLUA

		MODULE	StartP6

main		ld	a, ($3df9)
		add	a, '0'
		ld	(page1), a
		ld	hl, msg1
		call	prStr

		CHPAGE	2, Exit


; -----------------------------------------------------------------------------
; Print a asciiz string at cursor position
; Updates cursor coordinates
; -----------------------------------------------------------------------------
;
prStr   	ld      a, (hl)
        	or      a
        	ret     z
        	rst     $10
        	inc     hl
        	jr      prStr

msg1		DB 13, 'dot command, page '
page1		DB '0', 0

		ENDMODULE

		;DS END_ADDR - $, 6	; fill to next page

		LUA
		print ("SIZE:",_c("$")-_c("START_ADDR"))
		print ("$:",_c("$"))
		print ("$$$:",_c("$$$"))
		ENDLUA

		ENT

;==============================================================================
; End
;==============================================================================

		LUA
		print ("END")
		print ("$:",_c("$"))
		print ("$$$:",_c("$$$"))
		print ("FILE SIZE:",_c("$$$")-_c("START_ADDR"))
		ENDLUA

		END

;------------------------------------------------------------------------------
		IF $ > START_ADDR+7000
		LUA
		sj.error("Resulting code too long")
		ENDLUA
		ENDIF
;------------------------------------------------------------------------------

		END

