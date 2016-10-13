@echo off 
set LOCAL_NAME=common-web  
call Y:\common-web\..\setEnv.cmd 
set OUTPUT_DIR=Y:\common-web\target
cd /d Z:\eclipse 
start eclipse.exe -data "Y:\common-web\workspace"  -vmargs -Xms1024m -Xmx2048m -XX:MaxPermSize=512m -Xbootclasspath/a:lombok.jar -javaagent:lombok.jar -Dfile.encoding=UTF-8 
