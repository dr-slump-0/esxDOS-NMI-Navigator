@ECHO OFF
SET RUTA=\\nas\SPECTRUM\!RETRO\zDevStudio\NMI\v19
REM SET PASMO="C:\Program Files (x86)\zDevStudio - Z80 Development Studio\bin\pasmo53.exe"
SET PASMO="C:\Program Files (x86)\zDevStudio - Z80 Development Studio\bin\pasmo54b2.exe"
REM SET PASMO="C:\Program Files (x86)\zDevStudio - Z80 Development Studio\bin\pasmo.exe"
SET SJASMPLUS="C:\Program Files (x86)\zDevStudio - Z80 Development Studio\bin\sjasmplus.exe"

NET USE X: /DELETE /Y > NUL
NET USE X: %RUTA% > NUL
echo mapped X:
X:
if exist D:\sys\nmi goto DIREXISTD
md D:\sys\nmi
:DIREXISTD
if exist F:\sys\nmi goto DIREXISTF
md F:\sys\nmi
:DIREXISTF
if exist G:\sys\nmi goto DIREXISTG
md G:\sys\nmi
:DIREXISTG

cd _nmi
del nmi.sys > NUL
%PASMO% --err --bin --public nmi.asm nmi.sys nmi.publics | FIND /I "ERROR"
if not errorlevel 1 goto ERROR
echo assembled nmi.asm
COPY /Y nmi.sys D:\sys\nmi.sys > NUL
if errorlevel 1 goto ERROR
COPY /Y nmi.sys F:\sys\nmi.sys > NUL
if errorlevel 1 goto ERROR
COPY /Y nmi.sys G:\sys\nmi.sys > NUL
if errorlevel 1 goto ERROR
echo copied nmi.sys
cd ..

COPY /Y .\_nmi\NMI.inc .\custom\NMI.inc > NUL
if errorlevel 1 goto ERROR
echo copied NMI.inc
findstr /c:NMIbuf .\_nmi\nmi.publics > .\custom\nmi.publics	
findstr /c:savedSP .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:divRAM .\_nmi\nmi.publics >> .\custom\nmi.publics
findstr /c:esxDOSv .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:flg128k .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:bDAttr .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:bDName .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:ovrBuf .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:waitKey .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:readKey .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:clrScr .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:utoa .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:prStr .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:prChr .\_nmi\nmi.publics >> .\custom\nmi.publics	
findstr /c:prtDec .\_nmi\nmi.publics >> .\custom\nmi.publics	
echo processed nmi.publics

cd .hexview
del hexview > NUL
%PASMO% --err --bin hexview.asm hexview | FIND /I "ERROR"
if not errorlevel 1 goto ERROR
echo assembled hexview.asm
COPY /Y hexview D:\bin\hexview > NUL
if errorlevel 1 goto ERROR
COPY /Y hexview F:\bin\hexview > NUL
if errorlevel 1 goto ERROR
COPY /Y hexview G:\bin\hexview > NUL
if errorlevel 1 goto ERROR
echo copied hexview
cd ..

cd .ramview
del ramview > NUL
%SJASMPLUS% --nologo --syntax=bFiL --dirbol --raw=ramview ramview.asm 2>&1 | FIND /I "error:"
if not errorlevel 1 goto ERROR
echo assembled ramview .asm
COPY /Y ramview D:\bin\ramview > NUL
if errorlevel 1 goto ERROR
COPY /Y ramview F:\bin\ramview > NUL
if errorlevel 1 goto ERROR
COPY /Y ramview G:\bin\ramview > NUL
if errorlevel 1 goto ERROR
echo copied ramview
cd ..

cd .drives
del drives > NUL
%PASMO% --err --bin drives.asm drives | FIND /I "ERROR"
if not errorlevel 1 goto ERROR
echo assembled drives.asm
COPY /Y drives D:\bin\drives > NUL
if errorlevel 1 goto ERROR
COPY /Y drives F:\bin\drives > NUL
if errorlevel 1 goto ERROR
COPY /Y drives G:\bin\drives > NUL
if errorlevel 1 goto ERROR
echo copied drives
cd ..

cd .rm
del rm > NUL
%PASMO% --err --bin rm.asm rm | FIND /I "ERROR"
if not errorlevel 1 goto ERROR
echo assembled rm.asm
COPY /Y rm D:\bin\rm > NUL
if errorlevel 1 goto ERROR
COPY /Y rm F:\bin\rm > NUL
if errorlevel 1 goto ERROR
COPY /Y rm G:\bin\rm > NUL
if errorlevel 1 goto ERROR
echo copied rm
cd ..

rem for /f %%i in ('dir /ad /b *.') do (
for %%i in (config,custom,debug,delete,enter,fastcfg,fastload,help,init,loadold,lock,poke,reload,rename,reset,savesna,seldrv,tapein,tapeout,trd2drv,view) do (
	cd %%i
	del %%i > NUL
	%PASMO% --err --bin %%i.asm %%i | FIND /I "ERROR"
	if not errorlevel 1 goto ERROR
	echo assembled %%i.asm
	COPY /Y %%i D:\sys\nmi\%%i > NUL
	if errorlevel 1 goto ERROR
	COPY /Y %%i F:\sys\nmi\%%i > NUL
	if errorlevel 1 goto ERROR
	COPY /Y %%i G:\sys\nmi\%%i > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	cd ..
	)

cd _support
for %%i in (nmi.cnf,fastcfg.txt,TRDN.tap,old085.sys,old086.sys,old087.sys,old088.sys,old089.sys,help?.scr) do (
	COPY /Y %%i D:\sys\nmi\%%i > NUL
	if errorlevel 1 goto ERROR
	COPY /D %%i F:\sys\nmi\%%i > NUL
	if errorlevel 1 goto ERROR
	COPY /D %%i G:\sys\nmi\%%i > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)
cd ..

C:
NET USE X: /DELETE /Y > NUL
echo unmapped X:

psexec64 -h sync64.exe

rem
rem SpecEmu
rem ZXSpin
rem
cd "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!ZXSPIN"
raw2hdf SDMINI.img SDMINI.hdf
raw2hdf SDMINI2.img SDMINI2.hdf
echo to hdf ZXSpin, SpecEmu 

rem
rem Fuse
rem
cd "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!FUSE"
raw2hdf divmmcesx088.mmc divmmcesx088.hdf
raw2hdf SD2GB.mmc SD2GB.hdf
echo to hdf Fuse

rem
rem ZEsarUX
rem
rem Ya trabaja con una imagen de disco normal, no hay que convertirla.

rem
rem LnxSpectrum
rem
cd "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!LNXSPECTRUM"
raw2hdf -v1.0 "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!ZESARUX"\mmc088.mmc mmc088_10.hdf

EXIT /B

:ERROR
PAUSE
