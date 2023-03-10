;==============================================================================
; Project: NMI.zdsp
; Main File: NMI.asm
; Date: 27/07/2017 19:49:54
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin --public nmi.asm nmi.sys nmi.publics
;
;==============================================================================

/* ----------------------------------------------------------------------------
	----
	TODO
	----
	* Rutinas de impresion, incorporar mas caracteres de control, como
	  retroceso, color, etc.
	* Corregir la rutina de tratamiento de errores.

	----
	TIPS
	----
	To compare stuff, simply do a CP, and if the zero flag is set, A and
	the argument were equal, else if the carry is set the argument was
	greater, and finally, if neither is set, then A must be greater.

	cp val                  cp val
	------------------      --------------
	a==val  z       nc      nc      a>=val
	a>val   nz      nc      c       a<val
	a<val   nz      c       nz      a!=val

	Too much time working with x86 processors...

---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
	-----
	NOTAS
	-----

	Las llamadas a traves de rst $10, rst $18 o rst $30 no funcionan si SP
	apunta dentro de la zona paginada. Si funcionan las llamadas a traves
	de rst $08.
	Esto es valido para dot commands y codigo NMI, ambos en pagina 0.
	Validado para la pagina 5 tambien.

	Ademas, para que la llamada rst $08 M_EXECCMD funcione en una pagina
	distinta de la 0, es preciso que el puntero HL apunte fuera de la zona
	paginada tambien. Modificada funcion fExecCMD. REVISAR SI ES NECESARIO
	EN OTRAS FUNCIONES DE LA API DISTINTAS A M_EXECCMD.

	Las MACROS para cambiar de pagina precisan que SP apunte fuera de la
	zona paginada.

	La llamada a rst $30 db $0a utiliza 4 bytes de la pila.

	CONTROL DE ERRORES EN LAS LLAMADAS AL SISTEMA

	1378 ACTIONS functions.asm:
	Revisar llamadas a la API y systituir por funciones.

	-----------------------------------------------------------------------

	lb	label
	db	byte variable
	dw	word variable

	Ptr	pointer
	Fn	file name
	msg	string message

---------------------------------------------------------------------------- */

;==============================================================================
; DEFINITIONS
;==============================================================================

		INCLUDE "NMI.inc"
		INCLUDE "../esxdos.inc"
		INCLUDE "../errors.inc"

;==============================================================================
; LOADER - PAGE 0
;==============================================================================

		DEFINE DivXXXPg 0
		org NMI_OVERLAY

pg0start	MODULE initNMI

		INCLUDE "loader.asm"

		; -------------------------------------------------------------
		IF $ > NMI_OVERLAY+NMI_SIZE
		LUA
		sj.error("Page ".._c("DivXXXPg")..": Resulting code too long ("
		..(_c("$")-(_c("NMI_OVERLAY")+_c("NMI_SIZE"))).." bytes)")
		ENDLUA
		ENDIF
		; -------------------------------------------------------------

		ENDMODULE

pg0end

;==============================================================================
; MAIN - PAGE 5
;==============================================================================

		UNDEFINE DivXXXPg
		DEFINE DivXXXPg 5
		DISP PAGE_START

offsetPg5	EQU $$$-NMI_OVERLAY	; offset relative to start of file
					; used to load page 5

pg5start	MODULE page5

		INCLUDE "main.asm"

		; -------------------------------------------------------------
		; FUNCTIONS
		; -------------------------------------------------------------

		include "api.asm"
		include "sharedfunctions.asm"
		include "functions.asm"
		include "actions.asm"

		; -------------------------------------------------------------
		; DATA
		; -------------------------------------------------------------

		include "shareddata.asm"
		include "data.asm"

		; -------------------------------------------------------------
		IF $ > PAGE_START+PAGE_LENGTH
		LUA
		sj.error("Page ".._c("DivXXXPg")..": Resulting code too long ("
		..(_c("$")-(_c("PAGE_START")+_c("PAGE_LENGTH"))).." bytes)")
		ENDLUA
		ENDIF
		; -------------------------------------------------------------

		ENDMODULE

pg5end		ENT

;==============================================================================
; AUX - PAGE 6
;==============================================================================

		UNDEFINE DivXXXPg
		DEFINE DivXXXPg 6
		DISP PAGE_START

offsetPg6	EQU $$$-NMI_OVERLAY	; offset relative to start of file
					; used to load page 6

pg6start	MODULE page6

		INCLUDE "page6code.asm"

		; -------------------------------------------------------------
		; FUNCTIONS
		; -------------------------------------------------------------

		include "api.asm"
		include "sharedfunctions.asm"
		include "page6functions.asm"

		; -------------------------------------------------------------
		; DATA
		; -------------------------------------------------------------

		include "shareddata.asm"
		include "page6data.asm"

		; -------------------------------------------------------------
		IF $ > PAGE_START+PAGE_LENGTH
		LUA
		sj.error("Page ".._c("DivXXXPg")..": Resulting code too long ("
		..(_c("$")-(_c("PAGE_START")+_c("PAGE_LENGTH"))).." bytes)")
		ENDLUA
		ENDIF
		; -------------------------------------------------------------

		ENDMODULE

pg6end		ENT

;==============================================================================
; END
;==============================================================================

offsetEnd	EQU $-NMI_OVERLAY	; offset relative to start of file
					; used to see file length

		LUA
		print("----------------------")
		print("NMI_SIZE:    "..string.format("%04x ",_c("NMI_SIZE")).._c("NMI_SIZE"))
		print("PAGE_LENGTH: "..string.format("%04x ",_c("PAGE_LENGTH")).._c("PAGE_LENGTH"))
		print("Size p0:     "..string.format("%04x ",_c("pg0end-pg0start")).._c("pg0end-pg0start"))
		print("Size p5:     "..string.format("%04x ",_c("pg5end-pg5start")).._c("pg5end-pg5start"))
		print("Size p6:     "..string.format("%04x ",_c("pg6end-pg6start")).._c("pg6end-pg6start"))
		print("offsetPg5:   "..string.format("%04x ",_c("offsetPg5")).._c("offsetPg5"))
		print("offsetPg6:   "..string.format("%04x ",_c("offsetPg6")).._c("offsetPg6"))
		print("offsetEnd:   "..string.format("%04x ",_c("offsetEnd")).._c("offsetEnd"))
		print("----------------------")
		ENDLUA

		END

