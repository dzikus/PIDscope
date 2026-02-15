@echo off
setlocal
cd /d "%~dp0"

rem First launch: run Octave post-install to rebuild font cache and register packages
if not exist ".pidscope-initialized" (
    echo Initializing PIDscope - please wait...
    call octave\post-install.bat >nul 2>&1
    echo. > .pidscope-initialized
    echo Done. Launching PIDscope...
)

rem Launch PIDscope in Octave GUI
start "" "octave\mingw64\bin\octave-gui.exe" --gui --eval "cd('%~dp0app'); PIDscope"
