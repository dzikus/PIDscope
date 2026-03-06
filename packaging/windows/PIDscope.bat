@echo off
cd /d "%~dp0"

set "OCT_HOME=%~dp0octave\mingw64\"
for %%I in ("%OCT_HOME%") do set "OCT_HOME=%%~sI"

set "PATH=%OCT_HOME%bin;%OCT_HOME%qt6\bin;%PATH%"
set "QT_PLUGIN_PATH=%OCT_HOME%qt6\plugins"
if not exist "%OCT_HOME%qt6\bin\" (
    set "QT_PLUGIN_PATH=%OCT_HOME%qt5\plugins"
    set "PATH=%OCT_HOME%qt5\bin;%PATH%"
)

set "HOME=%USERPROFILE%"
for %%I in ("%HOME%") do set "HOME=%%~sI"

set "OCTAVE_EXE=%OCT_HOME%bin\octave-gui.exe"
if not exist "%OCTAVE_EXE%" (
    echo ERROR: Octave not found at: %OCTAVE_EXE%
    pause
    exit /b 1
)

set "APP_PATH=%~dp0app"
for %%I in ("%APP_PATH%") do set "APP_PATH=%%~sI"

start "" "%OCTAVE_EXE%" --gui --persist --path "%APP_PATH%" --eval "PIDscope"
