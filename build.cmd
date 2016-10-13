
set build_name=%~1
set target=%~2
set POM_FILE=%~3
set PRIFILE=%~4
title start %build_name%...
echo start %build_name%[PRIFILE:%PRIFILE%]...

set BASE_DIR=%~DP0
rem 设置环境变量
call %BASE_DIR%setEnv.cmd
set MAVEN_ARGS=-DskipTests -Dmaven.test.skip=true -Dmaven.javadoc.skip=true -f %POM_FILE%
if not "" == "%PRIFILE%" (
    set MAVEN_ARGS=%MAVEN_ARGS% -P %PRIFILE%
)

call mvn %target% %MAVEN_ARGS%
set RET=%errorlevel%
if %RET% == 0 (
    echo %build_name% success
    title %build_name% success
) else (
    echo %build_name% failed
    title %build_name% failed
    pause > nul
)

exit /b %RET%
