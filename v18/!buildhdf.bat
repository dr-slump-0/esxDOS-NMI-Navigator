@ECHO OFF

copy /y \\nas\SPECTRUM\!RETRO\zDevStudio\NMI\v18\.prueba\prueba f:\bin\prueba
copy /y \\nas\SPECTRUM\!RETRO\zDevStudio\NMI\v18\.prueba\prueba2 f:\bin\prueba2
copy /y \\nas\SPECTRUM\!RETRO\zDevStudio\NMI\v18\.prueba\prueba.tap f:\prueba.tap

C:
cd "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!ZXSPIN"
echo synchronizing disks...
psexec64 -h sync64.exe
echo synchronized.
echo converting...
raw2hdf SDMINI.img SDMINI.hdf
raw2hdf SDMINI2.img SDMINI2.hdf
echo to hdf ZXSpin, SpecEmu.
rem start "ZXSpin" "C:\Program Files (x86)\zxspin\ZXSpin.exe"
rem start "SpecEmu" "C:\Program Files (x86)\specemu\SpecEmu.exe"

cd "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!FUSE"
raw2hdf divmmcesx088.mmc divmmcesx088.hdf
raw2hdf SD2GB.mmc SD2GB.hdf
echo to hdf Fuse.
rem start "FUSE" "C:\Program Files (x86)\fuse\fuse.exe" "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\087\esxmmc.tap"

cd "C:\Program Files (x86)\ZEsarUX_win-8.1"
rem start "ZESARUX" "C:\Program Files (x86)\ZEsarUX_win-6.1\zesarux.exe"
echo to hdf ZEsarUX.

cd "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!LNXSPECTRUM"
raw2hdf -v1.0 "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!ZESARUX"\mmc088.mmc mmc088_10.hdf
echo to hdf LnxSpectrum.

PAUSE