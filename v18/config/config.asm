;==============================================================================
; Project: config.zdsp
; Main File: config.asm
; Date: 15/09/2017 14:54:23
;
; Created with zDevStudio - Z80 Development Studio.
;
; pasmo --err --bin config.asm config
;
;==============================================================================

		include ..\_nmi\nmi.inc
		include ..\_nmi\api.inc
		include ..\esxdos.inc
		include ..\errors.inc
		include ..\_nmi\nmi.publics

		org ovrBuf

; -------------------------
; configure navigation keys
; -------------------------
;
config		ld bc, 3*256+0
		ld a, COL_CUR
		call clrScr

		ld bc, 21*256+3
		ld a, COL_MID
		call clrScr

		; ****

		call readCnf
		xor a
		ld (usedK), a
		ld (usedK+1), a
		ld (usedK+2), a
		ld (usedK+3), a
		ld (usedK+4), a

		; ***

		ld hl, msg0001
		call prStr

		ld hl, msg0003
		call prStr

		ld hl, msg0004
		call prStr
		call chkKey
		ld (cfUp), a
		call prSel

		ld hl, msg0005
		call prStr
		call chkKey
		ld (cfDown), a
		call prSel

		ld hl, msg0006
		call prStr
		call chkKey
		ld (cfLeft), a
		call prSel

		ld hl, msg0007
		call prStr
		call chkKey
		ld (cfRight), a
		call prSel

		ld hl, msg0008
		call prStr
		call chkKey
		ld (cfEnter), a
		call prSel

		ld hl, msgHapp
		call prStr
		call wait
		call waitKey
		cp 'Y'
		jp nz, config

		; ***

		call wrteCnf

		ld a, (cfLeft)
		ld (kLeft), a
		ld a, (cfRight)
		ld (kRight), a
		ld a, (cfUp)
		ld (kUp), a
		ld a, (cfDown)
		ld (kDown), a
		ld a, (cfEnter)
		ld (kEnter), a

		; ***

exit		ld a, 1			; reload dir and reprint all
		ret

abort		pop hl
		jr exit

prSel		ld hl, mDelete
		cp K_DELETE
		jr z, prSelL1
		ld hl, mEnter
		cp K_ENTER
		jr z, prSelL1
		ld hl, mSpace
		cp ' '
		jr z, prSelL1
		ld hl, mBreak
		cp K_BREAK
		jr z, prSelL1
		ld hl, mLeft
		cp K_LEFT
		jr z, prSelL1
		ld hl, mRight
		cp K_RIGHT
		jr z, prSelL1
		ld hl, mUp
		cp K_UP
		jr z, prSelL1
		ld hl, mDown
		cp K_DOWN
		jr z, prSelL1
		ld hl, mEdit
		cp K_EDIT
		jr z, prSelL1
		ld hl, mTo
		cp K_TO
		jr z, prSelL1
		ld hl, mAt
		cp K_AT
		jr z, prSelL1
		ld hl, mSSEnt
		cp K_SS_ENTER
		jr z, prSelL1
		ld hl, mCSEnt
		cp K_CS_ENTER
		jr z, prSelL1
		;
chrNorm		call prChr
		ret

prSelL1		call prStr
		ret

; ---------------------------------
; check not available and used keys
; ---------------------------------
;
chkKey		call waitKey
		cp K_BREAK
		jr z, abort
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

; -----------------------
; read configuration file
; -----------------------
;
readCnf		ld hl, fnConf		; asciiz string containg path and/or filename
		ld b, FA_OPEN_EX|FA_READ
					; open if exists, else error
					; read access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, bufConf		; dest
		ld bc, 7		; size
		call fRead

		call fClose

		ret

; ------------------------
; write configuration file
; ------------------------
;
wrteCnf		ld hl, fnConf		; asciiz string containg path and/or filename
		ld b, FA_OPEN_AL|FA_WRITE
					; open if exists, if not create
					; write access
		ld a, SYS_DRIVE		; system/boot drive
		call fOpen1

		ld hl, bufConf		; dest
		ld bc, 7		; size
		call fWrite

		call fClose

		ret

; ---------
; key names
; ---------
;
mDelete		db 'DELETE',0
mSpace		db 'SPACE',0
mEnter		db 'ENTER',0
mBreak		db 'BREAK',0
mLeft		db 'LEFT',0
mRight		db 'RIGHT',0
mUp		db 'UP',0
mDown		db 'DOWN',0
mEdit		db 'EDIT',0
mTo		db 'SS+F',0
mSSEnt		db 'SS+ENTER',0
mCSEnt		db 'CS+ENTER',0
mAt		db 'SS+I',0

; --------
; messages
; --------
;
msg0001		db $16,1,1,'Dr Slump NMI Navigator'
		db $16,1,56
		M_VERSION
		db 0
msg0003		db $16,4,1,'Define keys: ',0
msg0004		db $16,6,1,'Key for UP? ',0
msg0005		db $16,7,1,'Key for DOWN? ',0
msg0006		db $16,8,1,'Key for LEFT? ',0
msg0007		db $16,9,1,'Key for RIGHT? ',0
msg0008		db $16,10,1,'Key for ENTER? ',0
msgHapp		db $16,12,1,'Happy (Y/N)? ',0

fnConf		db '/SYS/NMI/NMI.CNF',0

unavail		db 'ABCDEFGHIJKLMNOPRSUV',K_DELETE,K_TO,K_EDIT
		db K_AT,';',K_SS_ENTER,K_CS_ENTER
usedK		db 0,0,0,0,0

bufConf
PopUp		db 0
cfLeft		db 0
cfRight		db 0
cfDown		db 0
cfUp		db 0
cfEnter		db 0
flagOut		db 0

;------------------------------------------------------------------------------
IF		$ > ovrBuf+SIZ_OVR
		.ERROR Resulting code too long
ENDIF
;------------------------------------------------------------------------------

