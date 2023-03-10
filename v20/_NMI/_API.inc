;==============================================================================
; Project: NMI.zdsp
; File: NMI.inc
; Date: 29/07/2017 10:58:43
;
; Created with zDevStudio - Z80 Development Studio.
;
;==============================================================================

;==============================================================================
; MACROS
;==============================================================================
;
; TODO: For reasons of ease of code maintenance,
;       define here as macros API calls not necessary for navigator
;       (called into overlays)
;       enter.asm
;               EJECT VDISK
;               DISK_STATUS (MOUNT VDISK)
;               M_TAPEIN
;       fastcfg.asm
;               M_GETSETDRV
;       fastload.asm
;               M_GETSETDRV
;               EJECT VDISK
;               DISK_STATUS (MOUNT VDISK)
;               M_TAPEIN
;       loadold.asm
;               F_OPEN  (without error control)
;               F_READ  (without error control)
;               F_CLOSE (without error control)
;       reload.asm
;               M_GETSETDRV
;       reset.asm
;               M_AUTOLOAD (RESET)
;       savesna.asm
;               F_OPEN  (without error control)
;       seldrv.asm
;               M_GETSETDRV     (without error control)
;       tapein.asm
;               M_TAPEIN        -> FALTA COMPROBAR ERRORES!!!
;       tapeout.asm
;               M_TAPEOUT       -> FALTA COMPROBAR ERRORES!!!
;       trd2drv.asm
;               EJECT VDISK
;               DISK_STATUS (MOUNT VDISK)       -> FALTA COMPROBAR ERRORES!!!
;

;
; TODO: For reasons of ease of code maintenance,
;       define here as macros functions to
;       enter.asm:
;               loadSNA
;               loadTAP
;               viewSCR
;               loadBAS
;               loadTRD
;               attTAP
;               attTRD
;       fastcfg.asm
;               getCDrv
;               getCWD
;               convDrv
;       fastload.asm
;               chgDrv
;               updDrv
;               loadSNA
;               loadTAP
;               loadBAS
;               loadTRD
;               attTAP
;               attTRD
;       init.asm
;               clrAttr
;       seldrv.asm
;               findDrv
;               convDrv
;       reload.asm
;               getCDrv
;               getCWD
;               convDrv
;       tapein.asm
;               attTAP
;       tr2drv.asm
;               attTRD
;       view.asm
;               viewSCR
;               viewSNA
;

