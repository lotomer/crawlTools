@echo off
set build_name=clean
set target=clean

set NUTCH_CURRENT_DIR=%~dp0
set BASE_DIR=%NUTCH_CURRENT_DIR%..

call %BASE_DIR%\build.cmd "%build_name%" "%target%" "%NUTCH_CURRENT_DIR%\parent\pom.xml"

