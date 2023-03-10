@ECHO OFF

for /f %%i in ('dir /b %1\*.asm %1\*.inc') do (
	prettyasm.exe -s1 -p2 -m16 -c40 -t8 -a1 -n0 %1\%%i %1\%%i.tmp
	move /y %1\%%i.tmp %1\%%i
)
