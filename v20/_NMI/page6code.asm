;==============================================================================
; Project: NMI.zdsp
; File: page6code.asm
; Date: 03/11/2022 18:32:13
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; AUX - divXXX page 6
;==============================================================================

; =============================================================================
; 'K' configure navigation keys --- revisado
; =============================================================================
;
config		ld bc, 3*256+0
		ld a, COL_CUR
		call clrScr

		ld bc, 21*256+3
		ld a, COL_MID
		call clrScr

		call readCnf

		xor a
		ld (usedK), a
		ld (usedK+1), a
		ld (usedK+2), a
		ld (usedK+3), a
		ld (usedK+4), a

		ld hl, msg0001
		call prStr

		ld hl, msg0003
		call prStr

		//ld hl, msg0004
		//call prStr
		call chkKey
		ld (cfUp), a
		call prKeyName

		ld hl, msg0005
		call prStr
		call chkKey
		ld (cfDown), a
		call prKeyName

		ld hl, msg0006
		call prStr
		call chkKey
		ld (cfLeft), a
		call prKeyName

		ld hl, msg0007
		call prStr
		call chkKey
		ld (cfRight), a
		call prKeyName

		ld hl, msg0008
		call prStr
		call chkKey
		ld (cfEnter), a
		call prKeyName

		ld hl, msg0009
		call prStr
		call waitKey
		push af
		call prChr
		pop af
		cp 'Y'
		ld a, 0
		jp nz, configL1
		dec a
configL1	ld (cfPopUp), a

		ld hl, msg0010
		call prStr
		call waitKey
		push af
		call prChr
		pop af
		cp 'Y'
		ld a, 0
		jp nz, configL2
		dec a
configL2	ld (cfOut), a

		ld hl, msg0011
		call prStr
		call waitKey
		push af
		call prChr
		pop af
		cp 'Y'
		ld a, $0
		jp nz, configL3
		dec a
configL3	ld (cfHidden), a

		ld hl, msgHapp
		call prStr
		call wait
		call waitKey
		push af
		call prChr
		pop af
		cp 'Y'
		jp nz, config

		call writeCnf

exit		//ld sp, NMI_STACK	; necessary to use PAGING MACROS
		//JUMPPG 5, page5.mainL1	; return to NMI navigator on page 5
		jr helpEnd

; ---------------------------------
; check not available and used keys
; ---------------------------------
;
chkKey		call waitKey
		cp K_BREAK
		jr z, exit
		ld b, a
		ld hl, unavail
chkKey1		ld a, (hl)
		or a
		jr z, chkKey2		; end of used keys table
		cp b
		jr z, chkKey		; key already used
		inc hl
		jr chkKey1		; test next used key
chkKey2		ld (hl), b		; save key as used
		ld a, b
		ret

; =============================================================================
; 'H' help --- revisado, view_SCR tiene un ret, viewSCR un jp mainL2. REMODELAR?
; =============================================================================
;
help		ld bc, 24*256+0
		ld a, COL_MID
		call clrScr

		ld hl, msgHelp
		call prStr
		call waitKey

helpEnd		ld sp, NMI_STACK	; necessary to use PAGING MACROS
		JUMPPG 5, page5.mainL1	; return to NMI navigator on page 5

		/*
helpL1		ld hl, dbFnHelFile1
		call view_SCR
		cp K_UP
		jr z, helpL1
		cp K_DOWN
		jr z, helpL2
		cp K_BREAK
		jr z, helpEnd

helpL2		ld hl, dbFnHelFile2
		call view_SCR
		cp K_UP
		jr z, helpL1
		cp K_DOWN
		jr z, helpL3
		cp K_BREAK
		jr z, helpEnd

helpL3		ld hl, dbFnHelFile3
		call view_SCR
		cp K_UP
		jr z, helpL2
		cp K_DOWN
		jr z, helpEnd
		cp K_BREAK
		jr z, helpEnd

helpEnd		ld sp, NMI_STACK	; necessary to use PAGING MACROS
		JUMPPG 5, page5.mainL1	; return to NMI navigator on page 5

; -----------
; view screen
; -----------
;
view_SCR	ld b, FA_OPEN_EX|FA_READ
		ld a, SYS_DRIVE
		call fOpen1
		ld hl, 16384
		ld bc, 6144+768
		call fRead
		call fClose

		call waitKey

		ret
		*/
