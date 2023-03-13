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

;------------------------------------------------------------------------------
; TODO
;------------------------------------------------------------------------------
;
; * Cambiar sistema de overlays por dot commands. O utilizar toda la RAM del
;   spectrum y toda la RAM del DIVMMC.
; * Nombres mas adecuados para pTable y pTable2
; * Optimizacion general del codigo
;
; * Rutinas de impresion, incorporar mas caracteres de control, como
;   retroceso, color, etc.
;
; * Corregir la rutina de tratamiento de errores.
;
;------------------------------------------------------------------------------

;
; To compare stuff, simply do a CP, and if the zero flag is set,
; A and the argument were equal, else if the carry is set the argument was
; greater, and finally, if neither is set, then A must be greater.
;
;       cp val                  cp val
;       ------------------      --------------
;       a==val  z       nc      nc      a>=val
;       a>val   nz      nc      c       a<val
;       a<val   nz      c       nz      a!=val
;                               z       a==val
;
; too much time working with x86 processors...
;

;==============================================================================
; DEFINITIONS
;==============================================================================

		include "NMI.inc"
		include "API.inc"
		include "..\esxdos.inc"
		include "..\errors.inc"

;==============================================================================
; MAIN
;==============================================================================

		include "main.asm"

;==============================================================================
; FUNCTIONS
;==============================================================================

		include "functions.asm"

;==============================================================================
; DATA
;==============================================================================

		include "data.asm"	; It must be the last include

;==============================================================================
; END
;==============================================================================

;------------------------------------------------------------------------------
		IF $ > NMI_OVERLAY+$0e00
		.ERROR Resulting code too long
		ENDIF
;------------------------------------------------------------------------------

		end mainNMI

