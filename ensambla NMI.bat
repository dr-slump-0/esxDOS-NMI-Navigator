@ECHO OFF

SET VERSION=20
SET RUTA=%USERPROFILE%\Desktop\v%VERSION%
SET DISKS=%USERPROFILE%\Desktop\Images
SET DRIVE=F:

SET OSFMOUNT="%ProgramW6432%\OSFMount\OSFMount.com"
SET RAW2HDF="%USERPROFILE%\Desktop\Images\raw2hdf"
SET PSEXEC="%USERPROFILE%\Desktop\Images\psexec64"
SET SYNC64="%USERPROFILE%\Desktop\Images\sync64"
SET PASMO="%USERPROFILE%\Desktop\Images\pasmo54b2.exe"
SET SJASMPLUS="%USERPROFILE%\Desktop\Images\sjasmplus.exe"

openfiles > NUL 2> NUL
if %ERRORLEVEL% equ 1 (
	%PSEXEC% -d -h "%~f0"
	goto FIN
)

::
:: Ensamblamos nmi.sys
::

del %RUTA%\_nmi\nmi.sys > NUL
::%PASMO% --err --bin %RUTA%\_nmi\nmi.asm %RUTA%\_nmi\nmi.sys %RUTA%\_nmi\nmi.sym | FIND /I "ERROR"
%SJASMPLUS% --nologo --syntax=bFi --dirbol --sym=%RUTA%\_nmi\nmi.sym  --raw=%RUTA%\_nmi\nmi.sys %RUTA%\_nmi\nmi.asm 2>&1 | FIND /I "error:"
if not errorlevel 1 goto ERROR
echo assembled nmi.asm

::
:: Creamos los ficheros _nmi\nmi.publics y custom\nmi.publics
::

::COPY /Y %RUTA%\_nmi\NMI.inc %RUTA%\custom\NMI.inc > NUL
::if errorlevel 1 goto ERROR
::echo updated \custom\NMI.inc

del /q %RUTA%\_nmi\nmi.publics
for %%i in (ovrBuf,clrScr,kUp,kDown,kLeft,kRight,kEnter,prStr,waitKey,prChr,bDAttr,bDName,fUnlink,fChDir,fOpen,fRead,fClose,ckMods,flagSS,flagCS,printError1,fOpen1,fWrite,esxDOSv,msgVer,divRAM,NMIbuf,flg128k,msgRAM1,msgRAM2,restoreScreen,deleteScreen,savedSP,col,pr_64,utoa,saveScreen,fhandle,flgLOCK,curLn,Xof,msgLock,msgDrv,flgROOT,msgPath,fOpenDir,fReadDir,ofY,printError,fTellDir,pCurDir,readKey,prtDec,wait,ldConf,ldDir,exitNMI,pTable) do (
:: pTable obsolete (v18 and below)
	findstr /i /r /c:"^%%i\>" %RUTA%\_nmi\nmi.sym >> %RUTA%\_nmi\nmi.publics
	)
echo created \nmi\nmi.publics

::del /q %RUTA%\custom\nmi.publics
::for %%i in (NMIbuf,savedSP,divRAM,esxDOSv,flg128k,bDAttr,bDName,ovrBuf,waitKey,readKey,clrScr,utoa,prStr,prChr,prtDec) do (
::	findstr /i /r /c:"^%%i\>" %RUTA%\_nmi\nmi.sym >> %RUTA%\custom\nmi.publics
::	)
::echo created \custom\nmi.publics

::
:: Ensamblamos los ovelays auxiliares y dot commands
::

::for %%i in (hexview,drives,rm,cdrv) do (
for %%i in (hexview,drives,rm,cdrv,ramview,pages) do (
	del %RUTA%\.%%i\%%i > NUL
	::%PASMO% --err --bin %RUTA%\.%%i\%%i.asm %RUTA%\.%%i\%%i | FIND /I "ERROR"
	%SJASMPLUS% --nologo --syntax=bFiw --dirbol --raw=%RUTA%\.%%i\%%i %RUTA%\.%%i\%%i.asm 2>&1 | FIND /I "error:"
	if not errorlevel 1 goto ERROR
	echo assembled %%i.asm
	)

::for %%i in (config,custom,debug,delete,enter,fastcfg,fastload,help,init,loadold,lock,poke,reload,rename,reset,savesna,seldrv,tapein,tapeout,trd2drv,view) do (
for %%i in () do (
	del %RUTA%\%%i\%%i > NUL
	::%PASMO% --err --bin%RUTA%\%%i\%%i.asm %RUTA%\%%i\%%i | FIND /I "ERROR"
	%SJASMPLUS% --nologo --syntax=bFiw --dirbol --raw=%RUTA%\%%i\%%i %RUTA%\%%i\%%i.asm 2>&1 | FIND /I "error:"
	if not errorlevel 1 goto ERROR
	echo assembled %%i.asm
	)

::
:: Copiamos los nuevos ficheros ensamblados a disco
::

if not exist %DRIVE%\sys\nmi (md %DRIVE%\sys\nmi)

COPY /Y %RUTA%\_nmi\nmi.sys %DRIVE%\sys\nmi.sys > NUL
if errorlevel 1 goto ERROR
echo copied nmi.sys

::for %%i in (hexview,drives,rm,cdrv) do (
for %%i in (hexview,drives,rm,cdrv,ramview,pages) do (
	COPY /Y %RUTA%\.%%i\%%i %DRIVE%\bin\%%i > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

::for %%i in (config,custom,debug,delete,enter,fastcfg,fastload,help,init,loadold,lock,poke,reload,rename,reset,savesna,seldrv,tapein,tapeout,trd2drv,view) do (
for %%i in () do (
	COPY /Y %RUTA%\%%i\%%i %DRIVE%\sys\nmi\%%i > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

::for %%i in (nmi.cnf,fastcfg.txt,TRDN.tap,old085.sys,old086.sys,old087.sys,old088.sys,old089.sys,help1.scr,help2.scr,help3.scr) do (
for %%i in (nmi.cnf,fastcfg.txt,old085.sys,old086.sys,old087.sys,old088.sys,old089.sys,help1.scr,help2.scr,help3.scr,TRDN.BAS) do (
	COPY /Y %RUTA%\_support\%%i %DRIVE%\sys\nmi\%%i > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

for %%i in (128,mon,ownrom) do (
	COPY /Y "%RUTA%\_support\%%i" "%DRIVE%\bin\%%i" > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

for %%i in (rtc.sys) do (
	COPY /Y "%RUTA%\_support\%%i" "%DRIVE%\sys\%%i" > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

::
:: Sincronizamos disco y actualizamos imagen
::

echo synchronizing disks...
::%OSFMOUNT% -d -m f:
%SYNC64% -r
echo synchronized.

COPY /Y %DISKS%\32MB.ide %DISKS%\32MB.mmc

echo converting to hdf...
rem Convertimos imagen raw a formato hdf
::%RAW2HDF% -v1.0 %DISKS%\mmc089.mmc %DISKS%\mmc089.hdf
%RAW2HDF% -v1.0 %DISKS%\32MB.ide %DISKS%\mmc089.hdf
echo converted to hdf

::echo mounting disks...
::%OSFMOUNT% -a -t file -f %DISKS%\mmc089.mmc -o rw -m f:
::echo remounted.

::PAUSE

:ERROR
PAUSE

:FIN
