@echo off
set "DSIM_LICENSE=%USERPROFILE%\AppData\Local\metrics-ca\dsim-license.json"
cd "%USERPROFILE%\AppData\Local\metrics-ca\dsim\20240923.7.0"
call shell_activate.bat
cd %~dp0
dsim -f options.txt
pause
exit