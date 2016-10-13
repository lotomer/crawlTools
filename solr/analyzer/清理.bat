@echo off
set build_name=clean
set target=clean
REM product or empty
set PROFILE=product

set CURRENT_DIR=%~dp0
set CURRENT_DIR=%CURRENT_DIR:~0,-1%
set BASE_DIR=%CURRENT_DIR%\..\..
set OUTPUT_DIR=%CURRENT_DIR%\target

call :getLocalName  "%CURRENT_DIR%"

echo ======================================
echo LOCAL_NAME=%LOCAL_NAME%
echo ======================================
echo.
goto :end

:getLocalName
set LOCAL_NAME=%~n1
goto :eof

:end
if exist "%OUTPUT_DIR%" rmdir /s/q "%OUTPUT_DIR%"

call "%BASE_DIR%\build.cmd" "%build_name%" "%target%" "%CURRENT_DIR%\pom.xml" "%PROFILE%"