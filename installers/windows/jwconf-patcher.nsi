; JW Conf Patcher Installer
; NSIS Script for creating a professional Windows installer
; This bundles Node.js portable and automatically applies patches

; Include Modern UI
!include "MUI2.nsh"
!include "LogicLib.nsh"

; General Configuration
Name "JW Conf Patcher"
OutFile "JWConf-Patcher-Setup.exe"
InstallDir "$TEMP\JWConfPatcher"
RequestExecutionLevel admin

; Version Information
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "JW Conf Patcher"
VIAddVersionKey "CompanyName" "Community Contributors"
VIAddVersionKey "FileDescription" "Patches for JW Conf Windows Application"
VIAddVersionKey "FileVersion" "1.0.0.0"
VIAddVersionKey "LegalCopyright" "Apache 2.0 License"

; Modern UI Configuration
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Language
!insertmacro MUI_LANGUAGE "English"

; Sections
Section "JW Conf Patches" SecPatches
  SectionIn RO ; Required section
  
  SetOutPath "$INSTDIR"
  
  ; Display progress
  DetailPrint "Checking JW Conf installation..."
  
  ; Check if JW Conf is installed
  IfFileExists "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar" JWConfFound JWConfNotFound
  
  JWConfFound:
    DetailPrint "JW Conf found at: $LOCALAPPDATA\Programs\jw-conf"
    Goto CheckNode
  
  JWConfNotFound:
    MessageBox MB_ICONSTOP "JW Conf is not installed.$\n$\nPlease install JW Conf first, then run this patcher."
    Abort
  
  CheckNode:
    ; Extract portable Node.js
    DetailPrint "Extracting Node.js tools..."
    File /r "node-portable\*.*"
    
    ; Extract asar tool
    DetailPrint "Extracting asar tool..."
    File /r "asar-tool\*.*"
    
    ; Create backup
    DetailPrint "Creating backup..."
    CreateDirectory "$LOCALAPPDATA\Programs\jw-conf\resources\backups"
    CopyFiles "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar" "$LOCALAPPDATA\Programs\jw-conf\resources\backups\app.asar.backup-$INSTDIR"
    
    ; Extract app.asar
    DetailPrint "Extracting JW Conf application..."
    nsExec::ExecToLog '"$INSTDIR\node-portable\node.exe" "$INSTDIR\asar-tool\cli.js" extract "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar" "$INSTDIR\app-extracted"'
    Pop $0
    ${If} $0 != 0
      MessageBox MB_ICONSTOP "Failed to extract app.asar. Error code: $0"
      Abort
    ${EndIf}
    
    ; Apply Screen Share Audio AGC Patch
    DetailPrint "Applying Screen Share Audio AGC patch..."
    
    ; Read the file
    FileOpen $0 "$INSTDIR\app-extracted\node_modules\@jitsi\electron-sdk\screensharing\main.js" r
    FileOpen $1 "$INSTDIR\app-extracted\node_modules\@jitsi\electron-sdk\screensharing\main.js.new" w
    
    ${Do}
      FileRead $0 $2
      ${If} ${Errors}
        ${Break}
      ${EndIf}
      
      ; Replace the line
      ${StrReplace} $3 $2 "constraints.audio = 'loopback';" "constraints.audio = { mandatory: { chromeMediaSource: 'desktop', chromeMediaSourceId: data.source.id }, optional: [ { autoGainControl: false }, { noiseSuppression: false }, { echoCancellation: false }, { googAutoGainControl: false }, { googNoiseSuppression: false }, { googEchoCancellation: false } ] };"
      FileWrite $1 $3
    ${Loop}
    
    FileClose $0
    FileClose $1
    
    ; Replace original with patched
    Delete "$INSTDIR\app-extracted\node_modules\@jitsi\electron-sdk\screensharing\main.js"
    Rename "$INSTDIR\app-extracted\node_modules\@jitsi\electron-sdk\screensharing\main.js.new" "$INSTDIR\app-extracted\node_modules\@jitsi\electron-sdk\screensharing\main.js"
    
    ; Repack app.asar
    DetailPrint "Repacking application..."
    Rename "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar" "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar.original"
    nsExec::ExecToLog '"$INSTDIR\node-portable\node.exe" "$INSTDIR\asar-tool\cli.js" pack "$INSTDIR\app-extracted" "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar"'
    Pop $0
    ${If} $0 != 0
      MessageBox MB_ICONSTOP "Failed to repack app.asar. Restoring original..."
      Rename "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar.original" "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar"
      Abort
    ${EndIf}
    
    DetailPrint "Patches applied successfully!"
    
    ; Cleanup
    DetailPrint "Cleaning up temporary files..."
    RMDir /r "$INSTDIR\app-extracted"
    
SectionEnd

Section "Uninstaller" SecUninstaller
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

; Section Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecPatches} "Applies bug fixes to JW Conf: Screen Share Audio AGC fix"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Uninstaller Section
Section "Uninstall"
  ; Restore original app.asar
  ${If} ${FileExists} "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar.original"
    Delete "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar"
    Rename "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar.original" "$LOCALAPPDATA\Programs\jw-conf\resources\app.asar"
    MessageBox MB_OK "Original JW Conf restored successfully."
  ${Else}
    MessageBox MB_OK "No backup found. JW Conf was not modified."
  ${EndIf}
  
  ; Remove installation directory
  RMDir /r "$INSTDIR"
SectionEnd

; Helper function for string replace
Function StrReplace
  Exch $R0 ; new string
  Exch
  Exch $R1 ; old string
  Exch 2
  Exch $R2 ; source string
  Push $R3
  Push $R4
  Push $R5
  Push $R6
  
  StrCpy $R3 0
  StrLen $R4 $R1
  StrLen $R5 $R0
  
  loop:
    StrCpy $R6 $R2 $R4 $R3
    StrCmp $R6 "" done
    StrCmp $R6 $R1 replace
    IntOp $R3 $R3 + 1
    Goto loop
    
  replace:
    StrCpy $R6 $R2 $R3
    IntOp $R3 $R3 + $R4
    StrCpy $R2 $R2 "" $R3
    StrCpy $R2 $R6$R0$R2
    IntOp $R3 $R3 + $R5
    IntOp $R3 $R3 - $R4
    Goto loop
    
  done:
    StrCpy $R0 $R2
    
  Pop $R6
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd
