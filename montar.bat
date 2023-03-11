@echo off

pushd %USERPROFILE%\Desktop\Images

psexec64 -h "%ProgramW6432%\OSFMount\OSFMount.com" -d -m f:
psexec64 -h "%ProgramW6432%\OSFMount\OSFMount.com" -a -t file -f "C:\Users\david\Desktop\Images\mmc089.mmc" -o rw -m f:

popd