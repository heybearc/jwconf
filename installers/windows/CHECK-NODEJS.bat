@echo off
REM Check if Node.js is installed
REM Simple script to verify Node.js installation

echo ========================================
echo Node.js Installation Checker
echo ========================================
echo.

REM Check if node command exists
where node >nul 2>&1
if %errorLevel% equ 0 (
    echo [SUCCESS] Node.js is installed!
    echo.
    echo Version information:
    node --version
    echo.
    echo npm version:
    npm --version
    echo.
    echo ========================================
    echo You're ready to run INSTALL-PATCHES.bat
    echo ========================================
) else (
    echo [ERROR] Node.js is NOT installed
    echo.
    echo You need to install Node.js first.
    echo.
    echo Please follow these steps:
    echo 1. Open INSTALL-NODEJS-FIRST.txt
    echo 2. Follow the instructions
    echo 3. Restart your computer
    echo 4. Run this script again to verify
    echo.
    echo Quick link: https://nodejs.org/
    echo.
    echo ========================================
)

echo.
pause
