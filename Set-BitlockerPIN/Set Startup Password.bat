:: ================================================================================== 
:: NAME        		: Set Startup Password
:: DESCRIPTION 	: Set bitlocker PIN which will be prompted for every time the computer restarts  
:: AUTHOR      		: Daniel Tsekhanskiy
:: VERSION			: 1.0
:: DATE					: 3/22/16
:: ================================================================================== 

@if (1==1) @if(1==0) @ELSE
@echo off&SETLOCAL ENABLEEXTENSIONS
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"||(
    cscript //E:JScript //nologo "%~f0"
    @goto :EOF
)
echo Welcome! FactSet requires all laptop's to be password protected.
echo Please set a password below. This password must be at least 7 characters long.
echo You will be asked to enter this password every time you restart your laptop.
echo.
echo.
color B
set /p PIN=Startup Password:
manage-bde.exe -protectors -add c: -TPMAndPIN %PIN%
@pause
@goto :EOF
@end @ELSE
ShA=new ActiveXObject("Shell.Application")
ShA.ShellExecute("cmd.exe","/c \""+WScript.ScriptFullName+"\"","","runas",5);
@end