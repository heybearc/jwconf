# JW Conf Troubleshooting - Quick Start Guide

## For the Issues You're Experiencing

### Issue 1: Audio Dropout on Windows
**Symptoms**: User unmuted but no sound, fixed by toggling noise suppression or moving between rooms

### Issue 2: Camera/Unmute Blocked
**Symptoms**: "Moderator has blocked this feature" error, requires reinstall

---

## Immediate Actions

### Step 1: Deploy Diagnostic Scripts to Affected Users

**For Windows users experiencing audio issues**:
1. Send them: `diagnostic-scripts/diagnose-audio.js`
2. Have them run it during the next audio dropout
3. Collect the output

**For users getting permission errors**:
1. Send them: `diagnostic-scripts/diagnose-permissions.js`
2. Have them run it when they see the error
3. Collect the output

### Step 2: Enable Debug Logging (Windows)

Send affected users:
- `diagnostic-scripts/enable-debug-logging-windows.bat`
- Have them run it before their next meeting
- Collect logs after issue occurs using `collect-logs-windows.bat`

### Step 3: Quick Workarounds for Users

**Audio Dropout Workaround**:
```
Method 1: Toggle noise suppression
  Settings → Audio → Toggle "Noise Suppression"

Method 2: Switch audio device
  Settings → Audio → Select different mic → Switch back

Method 3: Rejoin room
  Leave breakout room → Return to main → Rejoin breakout
```

**Permission Error Workaround**:
```
Method 1: Clear app data
  1. Close JW Conf
  2. Win+R → %APPDATA%\JW Conf
  3. Delete config.json
  4. Restart app

Method 2: Have moderator reset
  1. Moderator removes user from meeting
  2. User rejoins
  3. Permissions should reset
```

---

## How to Use the Diagnostic Scripts

### Running JavaScript Diagnostics

1. **During a meeting with the issue**:
   - Press `Ctrl+Shift+I` (Windows) or `Cmd+Option+I` (macOS)
   - Click "Console" tab
   - Copy entire contents of `diagnose-audio.js` or `diagnose-permissions.js`
   - Paste into console
   - Press Enter
   - Copy the output that appears

2. **Send the output to you** for analysis

### Collecting System Logs

**Windows**:
1. Double-click `collect-logs-windows.bat`
2. Wait for collection to complete
3. Zip the folder that opens
4. Send to you

---

## What to Look For in Diagnostics

### Audio Issues - Key Indicators

**In `diagnose-audio.js` output, check**:
- `audioTrack.trackState` - Should be "live"
- `audioTrack.trackMuted` - Should be false
- `webrtcStats.bytesSent` - Should be > 0 when talking
- `micPermission` - Should be "granted"

**Red flags**:
- Track state is "ended" → Device disconnected
- Track is muted at browser level → Permission issue
- No bytes sent → Audio not transmitting
- No audio track → Microphone not initialized

### Permission Issues - Key Indicators

**In `diagnose-permissions.js` output, check**:
- `audioPermissions.audioMutedByPolicy` - If true, moderator has disabled audio
- `videoPermissions.videoMutedByPolicy` - If true, moderator has disabled video
- `browserPermissions` - Should all be "granted"
- `identity.role` - Check if user is "participant" or "moderator"

**Red flags**:
- `audioMutedByPolicy: true` → Room settings issue
- Browser permissions not granted → User needs to allow
- Redux state shows `locked: true` → Room is locked

---

## Common Patterns to Watch For

### Audio Dropout Pattern Analysis

**If audio drops when**:
- **Switching devices** → Device change handling bug
- **Entering breakout rooms** → Room transition state issue
- **After X minutes** → Possible timeout or memory leak
- **When network fluctuates** → WebRTC reconnection issue

**Collect**:
- Time of occurrence
- What user was doing
- Network conditions
- Device being used

### Permission Error Pattern Analysis

**If error occurs**:
- **On first join** → Race condition during initialization
- **After being in waiting room** → State not cleared properly
- **After network disconnect** → Reconnection doesn't restore state
- **Randomly** → Possible server-side state corruption

**Collect**:
- User's role (participant/moderator)
- Room settings (locked, password, etc.)
- How long they've been in meeting
- If they were moved between rooms

---

## Next Steps Based on Findings

### If Audio Issue is Device-Related
1. Update audio drivers
2. Test with different microphone
3. Check Windows audio settings
4. Disable audio enhancements in Windows

### If Audio Issue is App-Related
1. Check for app updates
2. Clear app cache
3. Reinstall app
4. Test with web version

### If Permission Issue is Server-Related
1. Check Jitsi server logs
2. Verify room configuration
3. Check moderator settings
4. Test with different room

### If Permission Issue is Client-Related
1. Clear local storage
2. Reset app settings
3. Check browser permissions
4. Reinstall app

---

## Creating a Bug Report

Once you've collected diagnostics, create a report with:

1. **Issue Description**
   - What happens
   - How often
   - Which users affected

2. **Diagnostic Output**
   - JavaScript diagnostic results
   - System logs
   - Screenshots of errors

3. **Pattern Analysis**
   - When it happens
   - What triggers it
   - What fixes it temporarily

4. **Environment Info**
   - Windows version
   - App version
   - Network setup
   - Hardware used

5. **Reproduction Steps**
   - Exact steps to reproduce
   - Success rate
   - Workarounds that help

---

## Contact Information

**For JW Conf Support**:
- Website: https://jwconf.com/support.php
- Include all diagnostic output
- Reference this troubleshooting guide

**For Jitsi Community**:
- Forum: https://community.jitsi.org
- Search for similar issues first
- Provide technical details

---

## Files in This Package

- `TROUBLESHOOTING_GUIDE.md` - Complete technical guide
- `QUICK_START.md` - This file
- `diagnostic-scripts/diagnose-audio.js` - Audio diagnostic tool
- `diagnostic-scripts/diagnose-permissions.js` - Permission diagnostic tool
- `diagnostic-scripts/collect-logs-windows.bat` - Log collection script
- `diagnostic-scripts/enable-debug-logging-windows.bat` - Enable verbose logging
- `diagnostic-scripts/disable-debug-logging-windows.bat` - Disable verbose logging

---

## Tips for Success

1. **Act quickly** - Run diagnostics while issue is happening
2. **Document everything** - Screenshots, timestamps, user reports
3. **Look for patterns** - Track when/where issues occur
4. **Test workarounds** - Verify which fixes work
5. **Keep logs** - Save all diagnostic output for analysis

Good luck troubleshooting! The diagnostic scripts will help you gather the data needed to identify and fix these issues.
