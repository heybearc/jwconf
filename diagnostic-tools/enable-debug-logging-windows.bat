@echo off
REM Enable Debug Logging for JW Conf on Windows
REM This will enable verbose logging to help diagnose issues

echo ========================================
echo JW Conf Debug Logging Setup
echo ========================================
echo.
echo This will enable detailed logging for JW Conf.
echo Logs will be saved to your Desktop.
echo.
echo WARNING: Debug logs can be large. Disable after troubleshooting.
echo.
pause

echo.
echo Setting environment variables...

REM Enable Electron logging
setx ELECTRON_ENABLE_LOGGING 1 >nul 2>&1
echo [1/5] Electron logging enabled

REM Set log file location
setx ELECTRON_LOG_FILE "%USERPROFILE%\Desktop\jwconf-debug.log" >nul 2>&1
echo [2/5] Log file location set

REM Enable stack dumping for crashes
setx ELECTRON_ENABLE_STACK_DUMPING 1 >nul 2>&1
echo [3/5] Stack dumping enabled

REM Enable WebRTC logging
setx WEBRTC_LOGGING 1 >nul 2>&1
echo [4/5] WebRTC logging enabled

REM Enable Chromium verbose logging
setx ELECTRON_LOG_LEVEL "verbose" >nul 2>&1
echo [5/5] Verbose logging enabled

echo.
echo ========================================
echo Debug Logging Enabled!
echo ========================================
echo.
echo Log file location: %USERPROFILE%\Desktop\jwconf-debug.log
echo.
echo IMPORTANT: You must restart JW Conf for changes to take effect.
echo.
echo To disable debug logging later, run: disable-debug-logging-windows.bat
echo.
pause
