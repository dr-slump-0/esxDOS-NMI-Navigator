HOOK_BASE	equ 128
MISC_BASE	equ HOOK_BASE+8
FSYS_BASE	equ MISC_BASE+16

DISK_STATUS	equ HOOK_BASE+0		; 80 (128)      ; hookcodes for block devices
DISK_READ	equ HOOK_BASE+1
DISK_WRITE	equ HOOK_BASE+2
DISK_IOCTL	equ HOOK_BASE+3
DISK_INFO	equ HOOK_BASE+4

M_DOSVERSION	equ MISC_BASE+0		; 88 (136)
M_GETSETDRV	equ MISC_BASE+1
M_DRIVEINFO	equ MISC_BASE+2
M_TAPEIN	equ MISC_BASE+3		; 8B (139)
M_TAPEOUT	equ MISC_BASE+4
M_GETHANDLE	equ MISC_BASE+5
M_GETDATE	equ MISC_BASE+6
M_EXECCMD	equ MISC_BASE+7		; 8F (143)
M_AUTOLOAD	equ MISC_BASE+8		; 90 (144)

F_MOUNT		equ FSYS_BASE+0		; 98 (152)
F_UMOUNT	equ FSYS_BASE+1
F_OPEN		equ FSYS_BASE+2		; 9A
F_CLOSE		equ FSYS_BASE+3		; 9B
F_SYNC		equ FSYS_BASE+4
F_READ		equ FSYS_BASE+5		; 9D
F_WRITE		equ FSYS_BASE+6		; 9E
F_SEEK		equ FSYS_BASE+7
F_FGETPOS	equ FSYS_BASE+8
F_FSTAT		equ FSYS_BASE+9
F_FTRUNCATE	equ FSYS_BASE+10
F_OPENDIR	equ FSYS_BASE+11
F_READDIR	equ FSYS_BASE+12
F_TELLDIR	equ FSYS_BASE+13
F_SEEKDIR	equ FSYS_BASE+14
F_REWINDDIR	equ FSYS_BASE+15
F_GETCWD	equ FSYS_BASE+16
F_CHDIR		equ FSYS_BASE+17	; A9
F_MKDIR		equ FSYS_BASE+18
F_RMDIR		equ FSYS_BASE+19
F_STAT		equ FSYS_BASE+20
F_UNLINK	equ FSYS_BASE+21	; AD
F_TRUNCATE	equ FSYS_BASE+22
F_CHMOD		equ FSYS_BASE+23
F_RENAME	equ FSYS_BASE+24
F_GETFREE	equ FSYS_BASE+25

FA_READ		equ %00000001		; Read access
FA_WRITE	equ %00000010		; Write access

FA_OPEN_EX	equ %00000000		; Open if exists, else error
FA_OPEN_AL	equ %00001000		; Open if exists, if not create

FA_CREATE_NEW	equ %00000100		; Create if not exists, if exists error
FA_CREATE_AL	equ %00001100		; Create if not exists, else open and truncate

FA_USE_HEADER	equ %01000000		; Use +3DOS header (passed in DE)

; NMI stuff
SYS_DRIVE	equ "$"			; expect /tmp, /sys, etc dirs only on sys drive, so use "$"
		;NMI_OVERLAY   equ $3000        ; NMI.SYS is loaded here up to $0d00 bytes
NMI_OVERLAY	equ $2f00		; NMI.SYS is loaded here up to $0e00 bytes

A_WRITE		equ %00000001
A_READ		equ %10000000
A_RDWR		equ %10000001
A_HIDDEN	equ %00000010
A_SYSTEM	equ %00000100
A_ARCH		equ %00100000
A_EXEC		equ %01000000
A_ALL		equ %11100111

