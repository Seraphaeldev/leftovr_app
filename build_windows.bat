@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo ============================================================
echo  leftovr - Windows portable build
echo ============================================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter was not found on PATH.
  echo Install the Flutter SDK, add its \bin folder to PATH, then run this again.
  exit /b 1
)

echo [1/4] Fetching dependencies...
call flutter pub get
if errorlevel 1 exit /b 1

echo [2/4] Building Windows release...
call flutter build windows --release
if errorlevel 1 exit /b 1

set "SRC=build\windows\x64\runner\Release"
set "STAGE=build\leftovr-windows"
if not exist "%SRC%\leftovr.exe" (
  echo ERROR: Expected build output at "%SRC%\leftovr.exe" but it was not found.
  exit /b 1
)

echo [3/4] Assembling portable package...
if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%" || exit /b 1
xcopy /e /i /y /q "%SRC%\*" "%STAGE%\" >nul
if errorlevel 1 exit /b 1
copy /y "windows\portable\Run leftovr.bat" "%STAGE%\" >nul
if errorlevel 1 exit /b 1
copy /y "windows\portable\README.txt" "%STAGE%\" >nul
if errorlevel 1 exit /b 1

echo [4/4] Creating zip archive...
powershell -NoProfile -Command "Compress-Archive -Path 'build\leftovr-windows' -DestinationPath 'build\leftovr-windows.zip' -Force"
if errorlevel 1 (
  echo ERROR: Could not create the zip archive. Is PowerShell available?
  exit /b 1
)

echo.
echo ============================================================
echo  Done!
echo   Portable app : build\leftovr-windows
echo   Zip archive  : build\leftovr-windows.zip
echo.
echo  Extract the zip anywhere and run "Run leftovr.bat".
echo  Optional: compile windows\installer.iss with Inno Setup for
echo  a Start-menu installer.
echo ============================================================
endlocal
