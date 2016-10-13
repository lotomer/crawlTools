@echo off
set CURRENT_DIR=%~dp0
set CURRENT_DIR=%CURRENT_DIR:~0,-1%
set BASE_DIR=%CURRENT_DIR%\..
set JAVA_OPTS=-Xms1024m -Xmx2048m -XX:MaxPermSize=512m -Xbootclasspath/a:lombok.jar -javaagent:lombok.jar -Dfile.encoding=UTF-8
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
set START_FILE=%BASE_DIR%\startEclipse-%LOCAL_NAME%.bat
call %BASE_DIR%\setEnv.cmd
echo @echo off > %START_FILE%
echo set LOCAL_NAME=%LOCAL_NAME%  >> %START_FILE%
echo call %BASE_DIR%\setEnv.cmd >> %START_FILE%
echo set OUTPUT_DIR=%CURRENT_DIR%\target>> %START_FILE%
echo cd /d %DEV_TOOL_PATH%\eclipse >> %START_FILE%
rem echo set JAVA_OPTS=%JAVA_OPTS% >> %START_FILE%

echo start eclipse.exe -data "%CURRENT_DIR%\workspace"  -vmargs %JAVA_OPTS% >> %START_FILE%

%START_FILE%