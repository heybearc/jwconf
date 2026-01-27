@echo off
REM Disable Debug Logging for JW Conf on Windows

echo ========================================
echo JW Conf Debug Logging Removal
echo ========================================
echo.
echo This will disable debug logging and remove environment variables.
echo.
pause

echo.
echo Removing environment variables...

REM Remove Electron logging variables
reg delete "HKCU\Environment" /v ELECTRON_ENABLE_LOGGING /f >nul 2>&1
echo [1/5] Electron logging disabled

reg delete "HKCU\Environment" /v ELECTRON_LOG_FILE /f >nul 2>&1
echo [2/5] Log file location removed

reg delete "HKCU\Environment" /v ELECTRON_ENABLE_STACK_DUMPING /f >nul 2>&1
echo [3/5] Stack dumping disabled

reg delete "HKCU\Environment" /v WEBRTC_LOGGING /f >nul 2>&1
echo [4/5] WebRTC logging disabled

reg delete "HKCU\Environment" /v ELECTRON_LOG_LEVEL /f >nul 2>&1
echo [5/5] Verbose logging disabled

echo.
echo ========================================
echo Debug Logging Disabled!
echo ========================================
echo.
echo IMPORTANT: Restart JW Conf for changes to take effect.
echo.
echo Note: Existing log files on your Desktop have not been deleted.
echo You can manually delete jwconf-debug.log if no longer needed.
echo.
pause
