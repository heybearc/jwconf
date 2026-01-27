@echo off
REM JW Conf Windows Patches Installer
REM This script automatically applies all patches to your JW Conf installation
REM Created: January 27, 2026

echo ========================================
echo JW Conf Windows Patches Installer
echo ========================================
echo.
echo This will install the following patches:
echo - Screen Share Audio AGC Fix
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: This script must be run as Administrator
    echo.
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Check if Node.js is installed
where node >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ========================================
    echo ERROR: Node.js is not installed
    echo ========================================
    echo.
    echo You need to install Node.js first (one-time setup).
    echo.
    echo QUICK STEPS:
    echo 1. Go to: https://nodejs.org/
    echo 2. Click the green "Download" button
    echo 3. Install the downloaded file
    echo 4. RESTART YOUR COMPUTER (important!)
    echo 5. Run this script again
    echo.
    echo For detailed instructions, open:
    echo INSTALL-NODEJS-FIRST.txt
    echo.
    echo ========================================
    pause
    exit /b 1
)

REM Check if asar is installed
where asar >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo Installing asar tool...
    npm install -g asar
    if %errorLevel% neq 0 (
        echo ERROR: Failed to install asar
        pause
        exit /b 1
    )
)

REM Find JW Conf installation
set JWCONF_PATH=%LOCALAPPDATA%\Programs\jw-conf\resources

if not exist "%JWCONF_PATH%\app.asar" (
    echo.
    echo ERROR: JW Conf installation not found
    echo Expected location: %JWCONF_PATH%
    echo.
    echo Please make sure JW Conf is installed.
    echo.
    pause
    exit /b 1
)

echo.
echo Found JW Conf at: %JWCONF_PATH%
echo.

REM Create backup
echo Creating backup...
if not exist "%JWCONF_PATH%\backups" mkdir "%JWCONF_PATH%\backups"
set BACKUP_NAME=app.asar.backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set BACKUP_NAME=%BACKUP_NAME: =0%
copy "%JWCONF_PATH%\app.asar" "%JWCONF_PATH%\backups\%BACKUP_NAME%" >nul
echo Backup created: %BACKUP_NAME%
echo.

REM Extract app.asar
echo Extracting app.asar...
cd /d "%JWCONF_PATH%"
if exist "app-extracted" rmdir /s /q "app-extracted"
asar extract app.asar app-extracted
if %errorLevel% neq 0 (
    echo ERROR: Failed to extract app.asar
    pause
    exit /b 1
)
echo Extraction complete.
echo.

REM Apply Screen Share Audio AGC Patch
echo Applying Screen Share Audio AGC patch...

set PATCH_FILE=app-extracted\node_modules\@jitsi\electron-sdk\screensharing\main.js

if not exist "%PATCH_FILE%" (
    echo ERROR: Patch target file not found
    echo File: %PATCH_FILE%
    pause
    exit /b 1
)

REM Create patched version
powershell -Command "(Get-Content '%PATCH_FILE%') -replace 'constraints\.audio = ''loopback'';', 'constraints.audio = { mandatory: { chromeMediaSource: ''desktop'', chromeMediaSourceId: data.source.id }, optional: [ { autoGainControl: false }, { noiseSuppression: false }, { echoCancellation: false }, { googAutoGainControl: false }, { googNoiseSuppression: false }, { googEchoCancellation: false } ] };' | Set-Content '%PATCH_FILE%.patched'"

if %errorLevel% neq 0 (
    echo ERROR: Failed to apply patch
    pause
    exit /b 1
)

move /y "%PATCH_FILE%.patched" "%PATCH_FILE%" >nul
echo Screen Share Audio AGC patch applied.
echo.

REM Repack app.asar
echo Repacking app.asar...
if exist "app.asar.original" del "app.asar.original"
ren "app.asar" "app.asar.original"
asar pack app-extracted app.asar
if %errorLevel% neq 0 (
    echo ERROR: Failed to repack app.asar
    echo Restoring original...
    ren "app.asar.original" "app.asar"
    pause
    exit /b 1
)
echo Repacking complete.
echo.

REM Cleanup
echo Cleaning up...
rmdir /s /q "app-extracted"
echo.

echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo Patches installed:
echo - Screen Share Audio AGC Fix
echo.
echo Backup saved to:
echo %JWCONF_PATH%\backups\%BACKUP_NAME%
echo.
echo To restore original:
echo 1. Close JW Conf
echo 2. Delete app.asar
echo 3. Rename app.asar.original to app.asar
echo.
echo Please restart JW Conf to use the patched version.
echo.
pause
