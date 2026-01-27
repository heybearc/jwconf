# JW Conf Troubleshooting Guide

## Common Issues You're Experiencing

### Issue 1: Audio Dropout (Windows Users)
**Symptoms**:
- User is unmuted but others can't hear them
- Audio works after toggling noise suppression
- Moving user between breakout room and main room fixes it
- Requires toggling settings to restore audio

### Issue 2: Camera/Unmute Blocked
**Symptoms**:
- User can't turn on camera or unmute
- Error: "Moderator has blocked this feature"
- Requires uninstall/reinstall to fix
- Intermittent - sometimes works, sometimes doesn't

---

## Root Causes Analysis

### Audio Dropout Issue

**Likely Causes**:
1. **WebRTC Audio Track State Corruption**
   - Audio track gets into invalid state
   - Not properly released/reacquired
   - State machine bug in Jitsi

2. **Audio Device Switching**
   - Windows audio device changes (Bluetooth, USB headset)
   - App doesn't handle device change gracefully
   - Audio context not properly recreated

3. **Noise Suppression Module Crash**
   - Audio processing pipeline fails
   - Toggling noise suppression forces recreation
   - WebAudio processing node issue

4. **Room State Synchronization**
   - Breakout room transition doesn't properly sync audio state
   - Server-side state vs client-side state mismatch
   - Rejoining forces state resync

### Camera/Unmute Permission Issue

**Likely Causes**:
1. **Permission State Corruption**
   - Local permission cache gets out of sync with server
   - Redux state corruption
   - Moderator permission flags stuck

2. **Race Condition on Join**
   - Permissions checked before fully loaded
   - Conference state not fully initialized
   - Timing issue between server and client

3. **Persistent Storage Corruption**
   - Config.json or local storage corrupted
   - Old permission states cached
   - Reinstall clears corrupted data

---

## Debugging Setup

### 1. Enable Debug Logging

#### For Windows Users (Remote Debugging)

Create a script to enable verbose logging:

**enable-debug-logging.bat**:
```batch
@echo off
echo Enabling JW Conf Debug Logging...

REM Set environment variables for Electron debugging
setx ELECTRON_ENABLE_LOGGING 1
setx ELECTRON_LOG_FILE "%USERPROFILE%\Desktop\jwconf-debug.log"

REM Enable Chromium verbose logging
setx ELECTRON_ENABLE_STACK_DUMPING 1

REM Enable WebRTC logging
setx WEBRTC_LOGGING 1

echo Debug logging enabled!
echo Logs will be saved to: %USERPROFILE%\Desktop\jwconf-debug.log
echo Please restart JW Conf for changes to take effect.
pause
```

#### For macOS (Your Testing)

```bash
# Enable debug mode
export ELECTRON_ENABLE_LOGGING=1
export DEBUG=jitsi*

# Launch with console
open -a "JW Conf" --args --enable-logging --v=1
```

### 2. Access Developer Console

**During a Meeting**:
- Press `Ctrl+Shift+I` (Windows) or `Cmd+Option+I` (macOS)
- Opens Chrome DevTools
- Check Console tab for errors
- Check Network tab for failed requests

### 3. Log File Locations

**Windows**:
```
%APPDATA%\JW Conf\logs\
C:\Users\[Username]\AppData\Roaming\JW Conf\logs\
```

**macOS**:
```
~/Library/Logs/JW Conf/
~/Library/Application Support/JW Conf/
```

---

## Diagnostic Procedures

### Diagnosing Audio Dropout

#### Step 1: Check Audio Device State
When audio drops, have user open DevTools Console and run:

```javascript
// Check audio tracks
const tracks = APP.conference.getLocalAudioTrack();
console.log('Audio Track:', tracks);
console.log('Track State:', tracks?.getTrack()?.readyState);
console.log('Track Enabled:', tracks?.getTrack()?.enabled);
console.log('Track Muted:', tracks?.getTrack()?.muted);

// Check audio devices
navigator.mediaDevices.enumerateDevices().then(devices => {
    console.log('Audio Devices:', devices.filter(d => d.kind === 'audioinput'));
});
```

#### Step 2: Monitor Device Changes
```javascript
// Listen for device changes
navigator.mediaDevices.addEventListener('devicechange', () => {
    console.log('DEVICE CHANGE DETECTED');
    navigator.mediaDevices.enumerateDevices().then(devices => {
        console.log('New device list:', devices);
    });
});
```

#### Step 3: Check WebRTC Stats
```javascript
// Get WebRTC statistics
APP.conference._room.rtc.peerConnections.forEach((pc, id) => {
    pc.peerconnection.getStats().then(stats => {
        stats.forEach(stat => {
            if (stat.type === 'outbound-rtp' && stat.kind === 'audio') {
                console.log('Audio Stats:', {
                    bytesSent: stat.bytesSent,
                    packetsSent: stat.packetsSent,
                    timestamp: stat.timestamp
                });
            }
        });
    });
});
```

### Diagnosing Permission Issues

#### Step 1: Check Permission State
```javascript
// Check current permissions
console.log('Conference State:', APP.conference._room?.getRole());
console.log('Local Participant:', APP.conference.getMyUserId());
console.log('Audio Muted:', APP.conference.isLocalAudioMuted());
console.log('Video Muted:', APP.conference.isLocalVideoMuted());

// Check if moderator has disabled features
console.log('Start Audio Muted:', APP.conference._room?.isStartAudioMuted());
console.log('Start Video Muted:', APP.conference._room?.isStartVideoMuted());
```

#### Step 2: Check Redux State
```javascript
// Inspect Redux state
const state = APP.store.getState();
console.log('Base/Media State:', state['features/base/media']);
console.log('Conference State:', state['features/base/conference']);
console.log('Participants:', state['features/base/participants']);
```

#### Step 3: Clear Corrupted State
```javascript
// Force clear local storage (have user run this)
localStorage.clear();
sessionStorage.clear();
console.log('Storage cleared - please refresh');
```

---

## Quick Fixes for Users

### Audio Dropout Quick Fixes

**Method 1: Toggle Noise Suppression**
1. Click Settings (gear icon)
2. Go to Audio settings
3. Toggle "Noise Suppression" off and on
4. Test microphone

**Method 2: Switch Audio Device**
1. Click Settings
2. Select different microphone
3. Switch back to original microphone
4. Test audio

**Method 3: Rejoin Room**
1. Leave breakout room
2. Return to main room
3. Rejoin breakout room
4. Audio should work

**Method 4: Restart Audio Track**
```javascript
// Have moderator run this in console for affected user
APP.conference.muteAudio(true);
setTimeout(() => APP.conference.muteAudio(false), 1000);
```

### Permission Issue Quick Fixes

**Method 1: Clear App Data** (Windows)
```batch
1. Close JW Conf completely
2. Press Win+R
3. Type: %APPDATA%\JW Conf
4. Delete config.json
5. Restart JW Conf
```

**Method 2: Reset Permissions**
1. Have moderator remove and re-add user
2. User leaves and rejoins meeting
3. Permissions should reset

**Method 3: Browser Permissions** (if using web)
1. Click lock icon in address bar
2. Reset camera/microphone permissions
3. Refresh page

---

## Creating Diagnostic Scripts

### Audio Diagnostic Script

Create this file for users to run during issues:

**diagnose-audio.js** (run in DevTools Console):
```javascript
(function() {
    console.log('=== JW Conf Audio Diagnostic ===');
    console.log('Timestamp:', new Date().toISOString());
    
    // Check conference state
    try {
        const localAudio = APP.conference.getLocalAudioTrack();
        console.log('Local Audio Track:', {
            exists: !!localAudio,
            type: localAudio?.getType(),
            muted: localAudio?.isMuted(),
            deviceId: localAudio?.getDeviceId()
        });
    } catch(e) {
        console.error('Error checking audio track:', e);
    }
    
    // Check devices
    navigator.mediaDevices.enumerateDevices().then(devices => {
        const audioInputs = devices.filter(d => d.kind === 'audioinput');
        console.log('Available Audio Inputs:', audioInputs.map(d => ({
            label: d.label,
            deviceId: d.deviceId,
            groupId: d.groupId
        })));
    });
    
    // Check permissions
    navigator.permissions.query({name: 'microphone'}).then(result => {
        console.log('Microphone Permission:', result.state);
    });
    
    // Check WebRTC connection
    try {
        const room = APP.conference._room;
        console.log('Room State:', {
            joined: room?.isJoined(),
            role: room?.getRole(),
            audioMuted: room?.isStartAudioMuted()
        });
    } catch(e) {
        console.error('Error checking room state:', e);
    }
    
    console.log('=== Diagnostic Complete ===');
})();
```

### Permission Diagnostic Script

**diagnose-permissions.js**:
```javascript
(function() {
    console.log('=== JW Conf Permission Diagnostic ===');
    console.log('Timestamp:', new Date().toISOString());
    
    try {
        const state = APP.store.getState();
        
        console.log('User Role:', APP.conference._room?.getRole());
        console.log('User ID:', APP.conference.getMyUserId());
        
        console.log('Audio Permissions:', {
            localMuted: APP.conference.isLocalAudioMuted(),
            startMuted: APP.conference._room?.isStartAudioMuted(),
            canUnmute: !APP.conference._room?.isStartAudioMuted() || 
                       APP.conference._room?.isModerator()
        });
        
        console.log('Video Permissions:', {
            localMuted: APP.conference.isLocalVideoMuted(),
            startMuted: APP.conference._room?.isStartVideoMuted(),
            canUnmute: !APP.conference._room?.isStartVideoMuted() || 
                       APP.conference._room?.isModerator()
        });
        
        console.log('Redux Media State:', state['features/base/media']);
        
    } catch(e) {
        console.error('Error in diagnostic:', e);
    }
    
    console.log('=== Diagnostic Complete ===');
})();
```

---

## Collecting Logs for Analysis

### Windows Users

**Create log collection script** (collect-logs.bat):
```batch
@echo off
echo Collecting JW Conf Logs...

set OUTPUT=%USERPROFILE%\Desktop\jwconf-logs-%date:~-4,4%%date:~-10,2%%date:~-7,2%
mkdir "%OUTPUT%"

REM Copy log files
xcopy "%APPDATA%\JW Conf\logs" "%OUTPUT%\logs\" /E /I
xcopy "%APPDATA%\JW Conf\*.log" "%OUTPUT%\" /Y

REM Copy config
copy "%APPDATA%\JW Conf\config.json" "%OUTPUT%\"

REM Export system info
systeminfo > "%OUTPUT%\system-info.txt"

REM List audio devices
powershell "Get-PnpDevice -Class 'AudioEndpoint' | Out-File '%OUTPUT%\audio-devices.txt'"

echo Logs collected to: %OUTPUT%
echo Please zip this folder and send for analysis
pause
```

### macOS Users

**collect-logs.sh**:
```bash
#!/bin/bash

OUTPUT=~/Desktop/jwconf-logs-$(date +%Y%m%d-%H%M%S)
mkdir -p "$OUTPUT"

# Copy logs
cp -r ~/Library/Logs/JW\ Conf/* "$OUTPUT/"
cp ~/Library/Application\ Support/JW\ Conf/config.json "$OUTPUT/" 2>/dev/null

# System info
system_profiler SPAudioDataType > "$OUTPUT/audio-devices.txt"
system_profiler SPSoftwareDataType > "$OUTPUT/system-info.txt"

echo "Logs collected to: $OUTPUT"
echo "Please zip this folder for analysis"
```

---

## Advanced Troubleshooting

### Enable Jitsi Debug Mode

Modify the app to enable debug logging permanently:

1. Extract app.asar (like we did for audio fix)
2. Find main.js
3. Add debug flags:

```javascript
// In main.js, add before app initialization
process.env.DEBUG = 'jitsi*';
process.env.NODE_ENV = 'development';
```

### Monitor WebRTC Internals

**Chrome WebRTC Internals** (works in Electron):
1. Open DevTools
2. Navigate to: `chrome://webrtc-internals`
3. Monitor real-time WebRTC stats
4. Export dump for analysis

### Network Debugging

Check for connection issues:

```javascript
// Monitor network quality
APP.conference._room.on('connectionQuality', (stats) => {
    console.log('Connection Quality:', stats);
});

// Check TURN/STUN usage
APP.conference._room.rtc.peerConnections.forEach((pc) => {
    pc.peerconnection.getStats().then(stats => {
        stats.forEach(stat => {
            if (stat.type === 'candidate-pair' && stat.state === 'succeeded') {
                console.log('Active Connection:', {
                    local: stat.localCandidateId,
                    remote: stat.remoteCandidateId,
                    type: stat.currentRoundTripTime
                });
            }
        });
    });
});
```

---

## Preventive Measures

### For Users

1. **Keep Audio Devices Consistent**
   - Don't switch Bluetooth/USB devices during calls
   - Set default device before joining

2. **Clear Cache Regularly**
   - Clear app data weekly
   - Prevents state corruption

3. **Update Audio Drivers**
   - Keep Windows audio drivers current
   - Check manufacturer website

4. **Stable Network**
   - Use wired connection when possible
   - Close bandwidth-heavy apps

### For Administrators

1. **Standardize Settings**
   - Create default config.json
   - Distribute to all users
   - Disable problematic features

2. **Monitor Server Logs**
   - Check Jitsi server logs for errors
   - Look for patterns with specific users

3. **Version Control**
   - Keep all users on same app version
   - Test updates before rollout

---

## Reporting Bugs Upstream

If issues persist, report to:

1. **JW Conf Support**
   - https://jwconf.com/support.php
   - Include logs and diagnostic output

2. **Jitsi Community**
   - https://community.jitsi.org
   - Many similar issues discussed

3. **GitHub Issues**
   - https://github.com/jitsi/jitsi-meet-electron
   - Check for existing issues first

---

## Next Steps

1. **Immediate**: Deploy diagnostic scripts to affected users
2. **Short-term**: Collect logs during next occurrence
3. **Long-term**: Identify patterns and create permanent fix

Would you like me to create automated monitoring tools or dive deeper into any specific issue?
