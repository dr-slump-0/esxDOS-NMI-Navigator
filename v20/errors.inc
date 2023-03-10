EOK		equ 1			; O.K. ESXDOS
ENONSENSE	equ 2			; Nonsense in ESXDOS
ESTEND		equ 3			; Statement END error
EWRTYPE		equ 4			; Wrong file TYPE
ENOENT		equ 5			; No such FILE or DIR
EIO		equ 6			; I/O ERROR
EINVAL		equ 7			; Invalid FILENAME
EACCES		equ 8			; Access DENIED
ENOSPC		equ 9			; Drive FULL
ENXIO		equ 10			; Invalid I/O REQUEST   ; Request beyond the limits of the device
ENODRV		equ 11			; No such DRIVE
ENFILE		equ 12			; Too many OPEN FILES
EBADF		equ 13			; Bad file DESCRIPTOR
ENODEV		equ 14			; No such DEVICE
EOVERFLOW	equ 15			; File pointer OVERFLOW
EISDIR		equ 16			; Is a DIRECTORY
ENOTDIR		equ 17			; Not a DIRECTORY
EEXIST		equ 18			; File already EXISTS
EPATH		equ 19			; Invalid PATH
ENOSYS		equ 20			; No SYS
ENAMETOOLONG	equ 21			; Path too LONG
ENOCMD		equ 22			; No such COMMAND
EINUSE		equ 23			; File in USE
ERDONLY		equ 24			; File is READ ONLY
EVERIFY		equ 25			; Verify FAILED
ELOADKO		equ 26			; Loading .KO FAILED
ENOTEMPTY	equ 27			; Directory NOT EMPTY
EMAPRAM		equ 28			; MAPRAM is ACTIVE

EDRVBUSY	equ 29			; Drive is BUSY
EFILESYS	equ 30			; Unknown FILESYSTEM
EDEVBUSY	equ 31			; Device is BUSY

EEOC		equ 128			; End of cluster chain
EEOF		equ 129			; End of file
