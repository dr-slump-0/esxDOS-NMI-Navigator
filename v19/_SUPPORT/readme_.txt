/sys
	nmi.sys
/sys/nmi
	config
	custom
	delete
	enter
	fastcfg
	fastload
		fastcfg.txt	fast-ramp loader configuration file
	help
		help1.scr		help screen 1/3
		help2.scr		help screen 2/3
		help3.scr		help screen 3/3
	init
	loadold
	lock
	poke
	reload
	rename
	reset
	savesna
	seldrv
	tapein
	tapeout
	trd2drv
		TRDN.tap		TR-DOS Navigator V0.75bC by CityAceE & Grand, 29.4.2017
		boot.bas		autoboot TRD BASIC program
		load.bas		TRDN loader BASIC program
		old085.sys		old NMI Navigator esxDOS v0.8.5 by ub880d 
		old086.sys		old NMI Navigator esxDOS v0.8.6-BETA4 by ub880d 
	view

assemble.cmd
	del nmi.sys > NUL
	pasmo --err --bin --public nmi.asm nmi.sys nmi.publics | FIND /I "ERROR"
	if not errorlevel 1 goto ERROR
	echo assembled nmi.asm
	COPY /Y nmi.sys D:\sys\nmi.sys > NUL
	if errorlevel 1 goto ERROR
	echo copied nmi.sys
	for /f %%i in ('dir /ad /b *.') do (
		del .\%%i\%%i > NUL
		pasmo --err --bin .\%%i\%%i.asm .\%%i\%%i | FIND /I "ERROR"
		if not errorlevel 1 goto ERROR
		echo assembled %%i.asm
		COPY /Y .\%%i\%%i D:\sys\nmi\%%i > NUL
		if errorlevel 1 goto ERROR
		echo copied %%i
		)
	for %%i in (fastmenu.txt,boot.bas,load.bas,TRDN.tap,old08?.sys,help?.scr) do (
		COPY /Y %%i D:\sys\nmi\%%i > NUL
		if errorlevel 1 goto ERROR
		echo copied %%i
		)
	EXIT
	:ERROR
	PAUSE
