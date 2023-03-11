@ECHO OFF

SET OSFMOUNT="%ProgramW6432%\OSFMount\OSFMount.com"
SET RAW2HDF="%USERPROFILE%\Desktop\Images\raw2hdf"
SET PSEXEC="%USERPROFILE%\Desktop\Images\psexec64"
SET SYNC64="%USERPROFILE%\Desktop\Images\sync64"

SET DISKS="%USERPROFILE%\Desktop\Images"

openfiles > NUL 2> NUL
if %ERRORLEVEL% equ 1 (
	%PSEXEC% -d -h "%~f0"
	goto FIN
)

::
:: Sincronizamos disco y actualizamos imagen
::

echo synchronizing disks...
::%OSFMOUNT% -d -m f:
%SYNC64% -r
echo synchronized.

echo converting to hdf...
rem Convertimos imagen raw a formato hdf
%RAW2HDF% -v1.0 %DISKS%\mmc089.mmc %DISKS%\mmc089.hdf
echo converted to hdf

::echo mounting disks...
::%OSFMOUNT% -a -t file -f %DISKS%\mmc089.mmc -o rw -m f:
::echo remounted.

PAUSE