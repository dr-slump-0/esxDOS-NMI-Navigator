ERROR_TABLE:

                db      128

EOK             equ     1
                DC	"No SYSTEM"

ENONSENSE       equ     2

ESTEND          equ     3
                
EWRTYPE         equ     4

ENOENT	        equ	5		; No such file or directory.

EIO		equ	6		; I/O error

EINVAL  	equ	7		; Invalid file name

EACCES		equ	8		; Access Denied

ENOSPC  	equ	9		; No space left on device

ENXIO           equ     10               ; Request beyond the limits of the device

ENODRV          equ     11              ; No such drive

ENFILE          equ     12              ; Too many files open in system

EBADF           equ     13              ; Bad file descriptor

ENODEV          equ     14

EOVERFLOW       equ     15
EISDIR          equ     16

ENOTDIR         equ     17

EEXIST          equ     18

EPATH  	        equ	19		; Invalid path

ENOSYS          equ     20
ENAMETOOLONG    equ     21
ENOCMD          equ     22
EINUSE          equ     23
ERDONLY         equ     24
EVERIFY			equ		25
ELOADKO			equ		26
ENOTEMPTY		equ		27
EMAPRAM			equ		28		; MAPRAM is active
EDRVBUSY		equ		29
EFILESYS		equ	30
EDEVBUSY	equ	31

EEOC		equ	128		; End of cluster chain
EEOF		equ	129		; End of file
