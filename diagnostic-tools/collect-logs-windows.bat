@echo off
REM JW Conf Log Collection Script for Windows
REM Run this when experiencing issues to collect diagnostic information

echo ========================================
echo JW Conf Log Collection Tool
echo ========================================
echo.
echo This will collect logs and system information for troubleshooting.
echo.

REM Create output directory with timestamp
set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set OUTPUT=%USERPROFILE%\Desktop\jwconf-logs-%TIMESTAMP%

echo Creating output directory: %OUTPUT%
mkdir "%OUTPUT%" 2>nul

echo.
echo [1/7] Collecting application logs...
if exist "%APPDATA%\JW Conf\logs" (
    xcopy "%APPDATA%\JW Conf\logs" "%OUTPUT%\logs\" /E /I /Y >nul 2>&1
    echo     - Application logs copied
) else (
    echo     - No application logs found
)

echo [2/7] Collecting configuration files...
if exist "%APPDATA%\JW Conf\config.json" (
    copy "%APPDATA%\JW Conf\config.json" "%OUTPUT%\" >nul 2>&1
    echo     - Config file copied
) else (
    echo     - No config file found
)

if exist "%APPDATA%\JW Conf\Preferences" (
    copy "%APPDATA%\JW Conf\Preferences" "%OUTPUT%\" >nul 2>&1
    echo     - Preferences copied
)

echo [3/7] Collecting system information...
systeminfo > "%OUTPUT%\system-info.txt" 2>&1
echo     - System info collected

echo [4/7] Collecting audio device information...
powershell -Command "Get-PnpDevice -Class 'AudioEndpoint' | Select-Object Status, Class, FriendlyName, InstanceId | Format-Table -AutoSize | Out-File '%OUTPUT%\audio-devices.txt'" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo     - Audio devices listed
) else (
    echo     - Could not list audio devices
)

echo [5/7] Collecting network information...
ipconfig /all > "%OUTPUT%\network-info.txt" 2>&1
echo     - Network info collected

echo [6/7] Collecting installed software...
wmic product get name,version > "%OUTPUT%\installed-software.txt" 2>&1
echo     - Software list collected

echo [7/7] Creating diagnostic summary...
(
    echo JW Conf Diagnostic Report
    echo ========================
    echo.
    echo Collection Date: %date% %time%
    echo Computer Name: %COMPUTERNAME%
    echo Username: %USERNAME%
    echo.
    echo Files Collected:
    dir /B "%OUTPUT%"
    echo.
    echo Instructions:
    echo 1. Review the collected files
    echo 2. Zip the entire folder
    echo 3. Send to your IT administrator or support
    echo.
    echo Note: These files may contain system information.
    echo Review before sharing if privacy is a concern.
) > "%OUTPUT%\README.txt"

echo     - Summary created
echo.
echo ========================================
echo Collection Complete!
echo ========================================
echo.
echo Logs saved to: %OUTPUT%
echo.
echo Next steps:
echo 1. Open the folder: %OUTPUT%
echo 2. Review the files
echo 3. Zip the entire folder
echo 4. Send to your administrator
echo.
echo Opening folder...
explorer "%OUTPUT%"
echo.
pause
