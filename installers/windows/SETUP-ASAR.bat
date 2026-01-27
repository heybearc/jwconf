@echo off
REM Setup asar tool using portable Node.js
REM Run this from the same folder as node-portable

echo ========================================
echo Setting up asar tool
echo ========================================
echo.

REM Check if node-portable exists
if not exist "node-portable\node.exe" (
    echo ERROR: node-portable folder not found
    echo Make sure node-portable folder is in the same directory as this script
    pause
    exit /b 1
)

echo Found Node.js portable
echo.

echo Installing asar tool...
echo This may take a minute...
echo.

REM Install asar using portable Node.js
node-portable\node.exe node-portable\npm install asar --prefix asar-tool

if %errorLevel% neq 0 (
    echo.
    echo ERROR: Failed to install asar
    pause
    exit /b 1
)

echo.
echo ========================================
echo Success! asar tool installed
echo ========================================
echo.
echo You can now build the installer using:
echo "C:\Program Files (x86)\NSIS\makensis.exe" jwconf-patcher.nsi
echo.
pause
