# esxDOS-NMI-Navigator

This is v20 version of my esxDOS NMI Navigator.

Main file is v20/_NMI/NMI.asm

To assemble:  
sjasmplus --nologo --syntax=bFi --dirbol --sym=v20\_nmi\nmi.sym  --raw=v20\_nmi\nmi.sys v20\_nmi\nmi.asm

This GitHub repository is under construction.

Folder      | Contents 
:---------- | :----------------------
**v20**     | v20 version source code
**Images**  | Auxiliary tools and disk images for various emulators  
**Paquete** | Original esxDOS package and destination of built package containing NMI Navigator 

Batch file            | Use
:-------------------- | :---------------------------------------------
**buildhdf.bat**      | Windows batch file for sync/create disk images  
**empaqueta NMI.bat** | Windows batch file for built esxDOS package containing NMI Navigator  
**ensambla NMI.bat**  | Windows batch file for assemble NMI Navigator and update disk images  
**montar.bat**        | Windows batch file for mount disk images  

Mount -> modify sorce code -> assemble -> pack up  
