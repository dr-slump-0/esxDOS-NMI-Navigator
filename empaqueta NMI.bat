@ECHO OFF
SET VERSION=20
SET SRC=%USERPROFILE%\Desktop\v%VERSION%
SET DST=%USERPROFILE%\Desktop\Paquete
SET PKG1=nmi_v0.0.%VERSION%
SET PKG2=custom_v0.0.%VERSION%
SET PKG3=esxdos089

::

if exist "%DST%\%PKG1%\" (
rd /q /s %DST%\%PKG1%
)
mkdir %DST%\%PKG1%
mkdir %DST%\%PKG1%\BIN
mkdir %DST%\%PKG1%\SYS
mkdir %DST%\%PKG1%\SYS\NMI

if exist "%DST%\%PKG2%\" (
rd /q /s %DST%\%PKG2%
)
mkdir %DST%\%PKG2%

if exist "%DST%\%PKG3%\" (
rd /q /s %DST%\%PKG3%
)
XCOPY /E /Q /H /Y "%DST%\%PKG3%-org" "%DST%\%PKG3%\" > NUL
mkdir %DST%\%PKG3%\SYS\NMI

::

if exist "%DST%\%PKG1%.zip" (
del /q %DST%\%PKG1%.zip
)
if exist "%DST%\%PKG2%.zip" (
del /q %DST%\%PKG2%.zip
)
if exist "%DST%\%PKG3%.zip" (
del /q %DST%\%PKG3%.zip
)

::

COPY /Y "%SRC%\_nmi\nmi.sys" "%DST%\%PKG1%\sys\nmi.sys" > NUL
if errorlevel 1 goto ERROR
COPY /Y "%SRC%\_nmi\nmi.sys" "%DST%\%PKG3%\sys\nmi.sys" > NUL
if errorlevel 1 goto ERROR
echo copied nmi.sys

::for %%i in (hexview,drives,rm) do (
for %%i in (hexview,drives,rm,ramview,pages) do (
	COPY /Y "%SRC%\.%%i\%%i" "%DST%\%PKG1%\bin\%%i" > NUL
	if errorlevel 1 goto ERROR
	COPY /Y "%SRC%\.%%i\%%i" "%DST%\%PKG3%\bin\%%i" > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

::for %%i in (config,custom,debug,delete,enter,fastcfg,fastload,help,init,loadold,lock,poke,reload,rename,reset,savesna,seldrv,tapein,tapeout,trd2drv,view) do (
for %%i in ()
	COPY /Y "%SRC%\%%i\%%i" "%DST%\%PKG1%\sys\nmi\%%i" > NUL
	if errorlevel 1 goto ERROR
	COPY /Y "%SRC%\%%i\%%i" "%DST%\%PKG3%\sys\nmi\%%i" > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

::for %%i in (nmi.cnf,fastcfg.txt,TRDN.tap,old085.sys,old086.sys,old087.sys,old088.sys,old089.sys,help1.scr,help2.scr,help3.scr) do (
for %%i in (nmi.cnf,fastcfg.txt,old085.sys,old086.sys,old087.sys,old088.sys,old089.sys,help1.scr,help2.scr,help3.scr,TRND.BAS) do (
	COPY /Y "%SRC%\_support\%%i" "%DST%\%PKG1%\sys\nmi\%%i" > NUL
	if errorlevel 1 goto ERROR
	COPY /Y "%SRC%\_support\%%i" "%DST%\%PKG3%\sys\nmi\%%i" > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

for %%i in (128,mon,ownrom) do (
	COPY /Y "%SRC%\_support\%%i" "%DST%\%PKG1%\bin\%%i" > NUL
	if errorlevel 1 goto ERROR
	COPY /Y "%SRC%\_support\%%i" "%DST%\%PKG3%\bin\%%i" > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

for %%i in (rtc.sys) do (
	COPY /Y "%SRC%\_support\%%i" "%DST%\%PKG1%\sys\%%i" > NUL
	if errorlevel 1 goto ERROR
	COPY /Y "%SRC%\_support\%%i" "%DST%\%PKG3%\sys\%%i" > NUL
	if errorlevel 1 goto ERROR
	echo copied %%i
	)

COPY /Y "%SRC%\custom\*.*" "%DST%\%PKG2%\" > NUL
if errorlevel 1 goto ERROR
echo copied custom

COPY /Y "%SRC%\_support\README.txt" "%DST%\" > NUL
if errorlevel 1 goto ERROR
COPY /Y "%SRC%\_support\README.txt" "%DST%\%PKG1%\" > NUL
if errorlevel 1 goto ERROR
COPY /Y "%SRC%\_support\README.txt" "%DST%\%PKG3%\" > NUL
if errorlevel 1 goto ERROR
echo copied README.txt

"%ProgramW6432%\7-Zip\7z.exe" a -r -y "%DST%\%PKG1%.zip" "%DST%\%PKG1%\*" > NUL
echo created %DST%\%PKG1%.zip
"%ProgramW6432%\7-Zip\7z.exe" a -r -y "%DST%\%PKG2%.zip" "%DST%\%PKG2%\*" > NUL
echo created %DST%\%PKG2%.zip
"%ProgramW6432%\7-Zip\7z.exe" a -r -y "%DST%\%PKG3%.zip" "%DST%\%PKG3%\*" > NUL
echo created %DST%\%PKG3%.zip

PAUSE
EXIT /B

:ERROR
PAUSE
