@echo off
psexec64 -h "C:\Program Files\OSFMount\OSFMount.com" -d -m d:
psexec64 -h "C:\Program Files\OSFMount\OSFMount.com" -d -m f:
psexec64 -h "C:\Program Files\OSFMount\OSFMount.com" -d -m g:
psexec64 -h "C:\Program Files\OSFMount\OSFMount.com" -d -m h:
psexec64 -h "C:\Program Files\OSFMount\OSFMount.com" -a -t file -f "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!ZESARUX\mmc088.mmc" -o rw -m d:
psexec64 -h "C:\Program Files\OSFMount\OSFMount.com" -a -t file -f "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!ZXSPIN\SDMINI.img" -o rw -m f:
psexec64 -h "C:\Program Files\OSFMount\OSFMount.com" -a -t file -f "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!FUSE\divmmcesx088.mmc" -o rw -m g:
psexec64 -h "C:\Program Files\OSFMount\OSFMount.com" -a -t file -f "C:\Users\David\Desktop\Desarrollos Speccy\5 divide\!ZXSPIN\SDMINI2.img" -o rw -m h:
