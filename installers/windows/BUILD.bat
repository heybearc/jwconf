@echo off
REM Build the JW Conf Patcher installer
REM Run this after SETUP-ASAR.bat has been run

echo ========================================
echo Building JW Conf Patcher Installer
echo ========================================
echo.

REM Check if NSIS is installed
if not exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    echo ERROR: NSIS not found
    echo Please install NSIS from: https://nsis.sourceforge.io/Download
    pause
    exit /b 1
)

REM Check if node-portable exists
if not exist "node-portable" (
    echo ERROR: node-portable folder not found
    echo Please make sure node-portable folder exists
    pause
    exit /b 1
)

REM Check if asar-tool exists
if not exist "asar-tool" (
    echo ERROR: asar-tool folder not found
    echo Please run SETUP-ASAR.bat first
    pause
    exit /b 1
)

REM Check if NSI script exists
if not exist "jwconf-patcher.nsi" (
    echo ERROR: jwconf-patcher.nsi not found
    echo Please download it from GitHub
    pause
    exit /b 1
)

echo All dependencies found
echo.
echo Building installer...
echo.

REM Build the installer
"C:\Program Files (x86)\NSIS\makensis.exe" jwconf-patcher.nsi

if %errorLevel% neq 0 (
    echo.
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo Success!
echo ========================================
echo.
echo Installer created: JWConf-Patcher-Setup.exe
echo.
echo You can now distribute this file to users.
echo.
pause
