:: ================================================================================== 
:: NAME        		: Java-upgradetool.bat
:: DESCRIPTION 	: Keep JAVAPATH pointing to Java 1.7 when Java is upgraded to version 1.8. Also set java to use 1.7 in command line.
:: AUTHOR      		: Daniel Tsekhanskiy
:: VERSION			: 1.0
:: DATE					: 2/29/16
:: ================================================================================== 

:: Rename Java 1.8 javapath folder to javapath_1.8
ren "%ALLUSERSPROFILE%\Oracle\Java\javapath" javapath_1.8

:: Create folder javapath_1.7
mkdir "%ALLUSERSPROFILE%\Oracle\Java\javapath_1.7"

:: Create shortcuts in javapath_1.7 folder to JRE 7 java executibles
mklink "%ALLUSERSPROFILE%\Oracle\Java\javapath_1.7\java.exe" "%ProgramFiles%\Java\jre7\bin\java.exe"
mklink "%ALLUSERSPROFILE%\Oracle\Java\javapath_1.7\javaw.exe" "%ProgramFiles%\Java\jre7\bin\javaw.exe"
mklink "%ALLUSERSPROFILE%\Oracle\Java\javapath_1.7\javaws.exe" "%ProgramFiles%\Java\jre7\bin\javaws.exe"

:: Create folder javapath as a shortcut for all files within javapath_1.7
mklink /D "%ALLUSERSPROFILE%\Oracle\Java\javapath" "%ALLUSERSPROFILE%\Oracle\Java\javapath_1.7"

:: Set the registry key referencing java's currentversion to 1.7. This enables java commands from command prompt.
Reg ADD "HKLM\SOFTWARE\JavaSoft\Java Runtime Environment" /v CurrentVersion /d 1.7 /t REG_SZ /f
