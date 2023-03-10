;==============================================================================
; Project: NMI.zdsp
; File: page6data.asm
; Date: 03/11/2022 18:35:18
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

; ==============================================================================
; MESSAGES
; ==============================================================================
;

msgErr		DB $16,12,32-8,'ESXDOS error ', 0

msg0001		DB $16,1,1,'DR SLUMP NMI NAVIGATOR'
msg0002		DB $16,1,56
		M_VERSION
		DB 0
msg0003		DB $16,4,1,'DEFINE KEYS: '//,0
msg0004		DB $16,6,1,'KEY FOR UP? ',0
msg0005		DB $16,7,1,'KEY FOR DOWN? ',0
msg0006		DB $16,8,1,'KEY FOR LEFT? ',0
msg0007		DB $16,9,1,'KEY FOR RIGHT? ',0
msg0008		DB $16,10,1,'KEY FOR ENTER? ',0
msg0009		DB $16,11,1,'SHOW START POPUP WINDOW (Y/N)? ',0
msg0010		DB $16,12,1,'SET STANDARD GRAPHICS ON TIMEX (Y/N)? ',0
msg0011		DB $16,13,1,'HIDE SYSTEM & HIDDEN FILES (Y/N)? ',0
msgHapp		DB $16,15,1,'HAPPY (Y/N)? ',0

		//           +---------+---------+---------+---------+---------+---------+---
msgHelp		DB $16,0,0, 'UP DOWN LEFT RIGHT / BREAK - Move cursor / leave navigator.'
		DB $16,1,0, 'EDIT     - Open upper dir.'
		DB $16,2,0, 'ENTER    - Do action over cursor. If dir, open it. If file,'
		DB $16,3,0, '           load it (SNA, TAP, Z80, BAS, ROM, TRD, SCL, SCR).'
		DB $16,4,0, 'A B C D  - Attach TRD or SCL file to virtual disk.'
		DB $16,5,0, 'E DELETE - Delete file or dir.'
		DB $16,6,0, 'SS+F     - Configure Fast-ramp loader.'
		DB $16,7,0, 'F        - Fast-ramp loader.'
		DB $16,8,0, 'G        - Load <mon> debugger.'
		DB $16,9,0, 'H        - This help.'
		DB $16,10,0,'I / SS+I - Attach / detach file to / from tapein.'
		DB $16,11,0,'J        - Load old NMI handler.'
		DB $16,12,0,'K        - Configure navigator.'
		DB $16,13,0,'L        - Lock paging register.'
		DB $16,14,0,'N        - Rename file.'
		DB $16,15,0,'O / SS+O - Attach / detach file to / from tapeout.'
		DB $16,16,0,'P        - Poke.'
		DB $16,17,0,'R        - Reset.'
		DB $16,18,0,'S        - Save snapshot on current dir.'
		DB $16,19,0,'T        - Start TR-DOS Emulator & autoload from virtual disk.'
		DB $16,20,0,'CS+T     - Start TR-DOS Emulator & enter TR-DOS mode.'
		DB $16,21,0,'SS+T     - Start TR-DOS Emulator & loads TR-DOS Navigator.'
		DB $16,22,0,'U        - Change current drive (cycling).'
		DB $16,23,0,'V / SS+V - View screen (SCR, SNA) / view with hexview.'
		DB 0

; =============================================================================
; ACTIONS DATA
; =============================================================================

dbFnConfigFile	DB '/SYS/NMI/NMI.CNF',0

		/*
dbFnHelFile1	DB '/SYS/NMI/HELP1.SCR',0
dbFnHelFile2	DB '/SYS/NMI/HELP2.SCR',0
dbFnHelFile3	DB '/SYS/NMI/HELP3.SCR',0
		*/

unavail		DB 'ABCDEFGHIJKLNOPRSTUV',K_DELETE,K_TO,K_EDIT	; M deleted
		DB K_AT,';',K_SS_ENTER,K_CS_ENTER
usedK		DB 0,0,0,0,0

; ---------
; key names
; ---------
;
mDelete		DB 'DELETE',0
mSpace		DB 'SPACE',0
mEnter		DB 'ENTER',0
mBreak		DB 'BREAK',0
mLeft		DB 'LEFT',0
mRight		DB 'RIGHT',0
mUp		DB 'UP',0
mDown		DB 'DOWN',0
mEdit		DB 'EDIT',0
mTo		DB 'SS+F',0
mSSEnt		DB 'SS+ENTER',0
mCSEnt		DB 'CS+ENTER',0
mAt		DB 'SS+I',0


; ---------------
; other variables
; ---------------
;
bufConf					; config buffer
cfPopUp		DB 0
cfLeft		DB 0
cfRight		DB 0
cfDown		DB 0
cfUp		DB 0
cfEnter		DB 0
cfOut		DB 0
cfHidden	DB 0

//
// PARA JOYSTICK, PERO LAS ACTUALIZADAS CON LA CONFIG ESTAN EN LA PAGINA 5
// LAS TECLAS UTILIZADAS EN LOS MODULOS NO UTILIZAN LA CONFIGURACION?!
//
kLeft		DB K_LEFT		; prev page
kDown		DB K_DOWN		; line down
kUp		DB K_UP			; line up
kRight		DB K_RIGHT		; next page
kEnter		DB K_ENTER		; do action


