:: arg1 is the build directory
set "projectdir=%~dp0"
call "%projectdir%\..\..\env.bat"
set "operation=%~1"
set "userAppBinary=%projectdir%\..\Binary"
::dummy nsc is generated only in config without secure
set "secure_nsc=%projectdir%\..\Secure_nsclib\secure_nsclib.o"
set "maxbytesize=440"
set "loader_s=%projectdir%\Secure\B-U585I-IOT02A_S\Exe\Project.bin"
set "loader_ns=%projectdir%\NonSecure\B-U585I-IOT02A_NS\Exe\Project.bin"
set "binarydir=%projectdir%\..\Binary"
set "loader=%binarydir%\loader.bin"
set loader_ns_size=
set loader_s_size=

if exist %imgtool% (
echo Postbuild with windows executable
goto postbuild
) else (
  echo ""
  echo "!!! WARNING : imgtool has not been found on your installation."
  echo ""
  echo "  Install CubeProgrammer on your machine in default path : C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer"
  echo "  or "
  echo "  Update your %projectdir%\..\..\env.bat with the proper path."
  echo ""
  exit 0
)

:postbuild
IF "%operation%" == "secure" (
goto secure_operation
)
::Make sure we have a Binary sub-folder in UserApp folder
if not exist "%binarydir%" (
mkdir "%binarydir%" 
)

::get size of secure_nsclib.o to determine MCUBOOT_PRIMARY_ONLY flag
FOR /F "usebackq" %%A IN ('%secure_nsc%') DO set filesize=%%~zA

if %filesize% LSS %maxbytesize% (
echo "loader without secure part (MCUBOOT_PRIMARY_ONLY not defined)" >> %projectdir%\output.txt
set "command=%imgtool% ass  -i %loader_ns_size% %loader_ns% %loader% >> %projectdir%\output.txt 2>&1"
goto execute_command
)
:: loader with secure and non secure
echo "loader with secure part (MCUBOOT_PRIMARY_ONLY defined)" >> %projectdir%\output.txt
set "command=%imgtool% ass -f %loader_s% -o %loader_s_size% -i %loader_ns_size% %loader_ns% %loader% >> %projectdir%\output.txt 2>&1"

:execute_command
%command%
IF %ERRORLEVEL% NEQ 0 goto :error

if not exist "%loader%" (
exit 1
)
exit 0
:secure_operation
set "nsclib_destination=%projectdir%\..\Secure_nsclib\secure_nsclib.o"
set "nsclib_source=%projectdir%\Secure\B-U585I-IOT02A_S\Exe\Project_import_lib.o"
:: recopy non secure callable .o
set "command=copy %nsclib_source% %nsclib_destination%"
%command%
IF %ERRORLEVEL% NEQ 0 goto :error
exit 0
:error
echo "%command% : failed" >> %projectdir%\\output.txt
exit 1


