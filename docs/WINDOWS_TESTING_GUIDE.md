# Windows AGC Fix Testing Guide

**Purpose**: Test the Windows audio dropout fix before production deployment  
**Platform**: Windows 10/11  
**Test Environment**: Your Windows laptop + test meeting  
**Date**: January 27, 2026

---

## Overview

You're testing the fix for Windows audio dropouts caused by AGC (Automatic Gain Control) conflicts. This guide walks you through:
1. Applying the fix to your Windows JW Conf installation
2. Running a test meeting
3. Validating the fix works
4. Collecting data for the JW Conf team

---

## Prerequisites

**What You Need**:
- [ ] Windows laptop with JW Conf installed
- [ ] JW Conf version 2025.9.1.1 (or similar)
- [ ] Node.js installed (for extracting/repacking app.asar)
- [ ] 7-Zip installed (for extracting installer if needed)
- [ ] Test meeting environment (2-3 participants minimum)
- [ ] 15-30 minutes for testing

**Download Tools**:
```powershell
# Install Node.js (if not already installed)
# Download from: https://nodejs.org/

# Install 7-Zip (if not already installed)
# Download from: https://www.7-zip.org/

# Install asar tool
npm install -g asar
```

---

## Method 1: Manual Settings Change (EASIEST - START HERE)

**This tests the fix WITHOUT modifying the app.**

### Step 1: Launch JW Conf

1. Open JW Conf on your Windows laptop
2. Join a test meeting (or create one)

### Step 2: Enable disableAGC Setting

1. Click **Settings** (gear icon)
2. Go to **Audio** tab
3. Find **"Disable automatic microphone gain control"**
   - May appear in German: "Automatische Mikrofonlautstärkeregelung deaktivieren"
4. **Check the box** to enable it
5. Click **OK** or **Save**

### Step 3: Test Audio

**Before fix validation**:
1. Speak into microphone for 2-3 minutes
2. Have someone else speak
3. Note if audio drops out or "pumps"

**After enabling disableAGC**:
1. Speak into microphone for 5-10 minutes
2. Vary volume (speak softly, then loudly)
3. Have others speak as well
4. Monitor for dropouts

### Step 4: Validate Fix

**Check these indicators**:
- [ ] Audio remains stable for 10+ minutes
- [ ] No dropouts when speaking
- [ ] No "pumping" or volume fluctuations
- [ ] Others can hear you consistently
- [ ] Audio quality is good

**If successful**: The fix works! Proceed to Method 2 to make it permanent.

**If unsuccessful**: The issue may be something else. Document what happened.

---

## Method 2: Permanent Fix (Modify App Default)

**This makes disableAGC: true the default for all users.**

### Step 1: Backup Current Installation

```powershell
# Create backup folder
mkdir C:\JWConf-Backup

# Copy current installation
xcopy "C:\Users\%USERNAME%\AppData\Local\Programs\jw-conf" "C:\JWConf-Backup\" /E /I /H

# Verify backup
dir "C:\JWConf-Backup\resources"
```

### Step 2: Locate app.asar

**Default location**:
```
C:\Users\[YourUsername]\AppData\Local\Programs\jw-conf\resources\app.asar
```

**Find it**:
```powershell
# Open File Explorer
# Navigate to: %LOCALAPPDATA%\Programs\jw-conf\resources
# You should see: app.asar (8-9 MB file)
```

### Step 3: Extract app.asar

```powershell
# Open PowerShell as Administrator
cd "%LOCALAPPDATA%\Programs\jw-conf\resources"

# Extract app.asar
asar extract app.asar app-extracted

# Verify extraction
dir app-extracted
# Should see: build/, node_modules/, package.json, etc.
```

### Step 4: Apply the Fix

**Open the file**:
```powershell
# Navigate to extracted folder
cd app-extracted\build

# Open app.js in a text editor
notepad app.js
```

**Find this line** (use Ctrl+F to search):
```javascript
disableAGC:!1
```

**Change to**:
```javascript
disableAGC:!0
```

**Explanation**:
- `!1` means `false` (AGC enabled)
- `!0` means `true` (AGC disabled)
- This is minified JavaScript

**Save the file** (Ctrl+S)

### Step 5: Repack app.asar

```powershell
# Go back to resources folder
cd "%LOCALAPPDATA%\Programs\jw-conf\resources"

# Rename original
ren app.asar app.asar.original

# Repack with fix
asar pack app-extracted app.asar

# Verify new file
dir app.asar
# Should be similar size to original (8-9 MB)
```

### Step 6: Test the Modified App

1. **Close JW Conf** completely (check Task Manager)
2. **Launch JW Conf** again
3. **Join a test meeting**
4. **Check Settings → Audio**
   - "Disable automatic microphone gain control" should be **checked by default**
5. **Test audio** for 10-15 minutes

---

## Method 3: Alternative - Edit Settings File Directly

**If you can't modify app.asar, you can edit the settings file.**

### Step 1: Locate Settings File

**Location**:
```
%APPDATA%\JW Conf\Local Storage\leveldb\
```

**Warning**: This is a binary database, harder to edit directly.

### Step 2: Use DevTools to Modify

1. Launch JW Conf
2. Press **Ctrl+Shift+I** to open DevTools
3. Go to **Console** tab
4. Run this command:

```javascript
// Set disableAGC to true
localStorage.setItem('persist:root', JSON.stringify({
    ...JSON.parse(localStorage.getItem('persist:root')),
    settings: JSON.stringify({
        ...JSON.parse(JSON.parse(localStorage.getItem('persist:root')).settings),
        disableAGC: true
    })
}));

// Verify
console.log('disableAGC is now:', 
    JSON.parse(JSON.parse(localStorage.getItem('persist:root')).settings).disableAGC
);

// Reload app
location.reload();
```

5. Close DevTools
6. Restart JW Conf
7. Verify setting is enabled

---

## Testing Checklist

### Pre-Test Setup

- [ ] Backup created
- [ ] Fix applied (Method 1, 2, or 3)
- [ ] JW Conf restarted
- [ ] Setting verified in UI

### Test Scenario 1: Basic Audio Stability

**Duration**: 10 minutes

1. [ ] Join test meeting
2. [ ] Speak continuously for 2 minutes
3. [ ] Pause for 1 minute
4. [ ] Speak again for 2 minutes
5. [ ] Have another participant speak
6. [ ] Switch back and forth

**Monitor for**:
- Audio dropouts
- Volume pumping
- Cutting in/out
- Quality degradation

**Record**:
- Time of any issues: _______________
- Description: _______________

### Test Scenario 2: Extended Use

**Duration**: 30 minutes

1. [ ] Join meeting with 2-3 participants
2. [ ] Normal conversation for 30 minutes
3. [ ] Vary speaking volume
4. [ ] Include pauses and silence

**Monitor for**:
- Sustained stability
- No dropouts over time
- Consistent quality

**Record**:
- Total duration: _______________
- Any issues: _______________

### Test Scenario 3: Device Switching

**Duration**: 5 minutes

1. [ ] Start with default microphone
2. [ ] Switch to different microphone (if available)
3. [ ] Switch back to original
4. [ ] Test audio after each switch

**Monitor for**:
- Audio works after switching
- No dropouts during transition
- Settings persist

**Record**:
- Devices tested: _______________
- Issues: _______________

### Test Scenario 4: Breakout Rooms

**Duration**: 10 minutes

1. [ ] Join main meeting
2. [ ] Move to breakout room
3. [ ] Test audio in breakout room
4. [ ] Return to main meeting
5. [ ] Test audio in main meeting

**Monitor for**:
- Audio works in both rooms
- No dropouts during transitions
- Mute state preserved

**Record**:
- Transitions tested: _______________
- Issues: _______________

---

## Validation Metrics

### Audio Quality Metrics

**Collect these during testing**:

1. **Dropout Frequency**
   - Before fix: ___ dropouts per 10 minutes
   - After fix: ___ dropouts per 10 minutes

2. **Audio Stability**
   - Before fix: Stable / Unstable / Intermittent
   - After fix: Stable / Unstable / Intermittent

3. **Volume Consistency**
   - Before fix: Consistent / Pumping / Fluctuating
   - After fix: Consistent / Pumping / Fluctuating

4. **User Experience**
   - Before fix: Poor / Fair / Good / Excellent
   - After fix: Poor / Fair / Good / Excellent

### Technical Metrics (Optional)

**If you open DevTools (Ctrl+Shift+I)**:

1. Navigate to: `chrome://webrtc-internals`
2. Monitor during test:
   - **bytesSent** (should be consistent)
   - **packetsLost** (should be low)
   - **jitter** (should be stable)

**Record**:
- Average bytesSent: _______________
- Packet loss rate: _______________
- Jitter: _______________

---

## Troubleshooting

### Issue: Can't find app.asar

**Solution**:
```powershell
# Search for it
dir "C:\Users\%USERNAME%\AppData\Local\Programs" /s /b | findstr app.asar

# Or check alternate location
dir "C:\Program Files\JW Conf" /s /b | findstr app.asar
```

### Issue: asar command not found

**Solution**:
```powershell
# Install globally
npm install -g asar

# Verify installation
asar --version

# If still not found, use full path
"%APPDATA%\npm\asar.cmd" extract app.asar app-extracted
```

### Issue: Can't edit app.js (file too large)

**Solution**:
- Use **VS Code** instead of Notepad
- Or use **Notepad++**
- Search for `disableAGC:!1` (Ctrl+F)
- Replace with `disableAGC:!0`

### Issue: App won't start after repacking

**Solution**:
```powershell
# Restore original
cd "%LOCALAPPDATA%\Programs\jw-conf\resources"
del app.asar
ren app.asar.original app.asar

# Try again, or use Method 1 (settings change) instead
```

### Issue: Fix doesn't seem to work

**Verify setting is actually enabled**:
1. Open JW Conf
2. Press Ctrl+Shift+I (DevTools)
3. Console tab
4. Run:
```javascript
JSON.parse(JSON.parse(localStorage.getItem('persist:root')).settings).disableAGC
```
5. Should return: `true`

**If it returns `false`**:
- Setting not applied correctly
- Try Method 1 (manual settings change)

---

## Data Collection for JW Conf Team

### Test Report Template

**Copy this and fill out after testing**:

```
WINDOWS AGC FIX TEST REPORT
===========================

Date: [Date]
Tester: [Your Name]
Environment: [e.g., "Windows 11, JW Conf 2025.9.1.1"]

SETUP:
- Method used: [Method 1 / 2 / 3]
- Participants: [Number of people in test]
- Duration: [Total test time]

RESULTS:
Before Fix:
- Audio dropouts: [Frequency]
- Volume stability: [Stable/Unstable]
- User experience: [Poor/Fair/Good]

After Fix:
- Audio dropouts: [Frequency]
- Volume stability: [Stable/Unstable]
- User experience: [Poor/Fair/Good]

SCENARIOS TESTED:
- [ ] Basic audio stability (10 min)
- [ ] Extended use (30 min)
- [ ] Device switching
- [ ] Breakout rooms

ISSUES ENCOUNTERED:
[Describe any problems]

CONCLUSION:
Fix is: [Effective / Partially Effective / Not Effective]

RECOMMENDATION:
[Should this be deployed? Any concerns?]

ADDITIONAL NOTES:
[Any other observations]
```

---

## Next Steps After Testing

### If Fix Works ✅

1. **Document results** using template above
2. **Update email to JW Conf team**:
   - Change Windows fix status from "needs testing" to "tested and working"
   - Include test results
   - Offer to deploy in production (150-180 users)

3. **Consider production deployment**:
   - Apply to all Windows machines
   - Monitor for issues
   - Collect feedback

### If Fix Doesn't Work ❌

1. **Document what happened**
2. **Try alternative approaches**:
   - Different microphone
   - Different Windows version
   - Check for other audio software

3. **Update JW Conf team**:
   - Share test results
   - Explain what was tried
   - Ask for guidance

### If Fix Partially Works ⚠️

1. **Document specific scenarios**:
   - When it works
   - When it doesn't
   - Patterns observed

2. **Additional testing**:
   - Try different configurations
   - Test with more participants
   - Longer duration tests

---

## Safety & Rollback

### If Something Goes Wrong

**Restore original app**:
```powershell
cd "%LOCALAPPDATA%\Programs\jw-conf\resources"
del app.asar
ren app.asar.original app.asar
```

**Or restore from backup**:
```powershell
xcopy "C:\JWConf-Backup\*" "%LOCALAPPDATA%\Programs\jw-conf\" /E /I /H /Y
```

**Or reinstall**:
1. Uninstall JW Conf
2. Download fresh installer
3. Reinstall

### Settings Persist

**Note**: If you used Method 1 (manual settings change), the setting is stored in localStorage and will persist even if you restore the original app.

**To reset**:
1. Open JW Conf
2. Settings → Audio
3. Uncheck "Disable automatic microphone gain control"

---

## Timeline

**Suggested testing schedule**:

**Day 1** (Today):
- [ ] Apply fix (Method 1 recommended)
- [ ] Basic testing (10-15 minutes)
- [ ] Initial validation

**Day 2-3**:
- [ ] Extended testing (30+ minutes)
- [ ] Multiple test meetings
- [ ] Different scenarios

**Day 4**:
- [ ] Compile results
- [ ] Write test report
- [ ] Update email to JW Conf team

**Day 5**:
- [ ] Send updated email with test results
- [ ] Offer to deploy in production if successful

---

## Questions to Answer

After testing, you should be able to answer:

1. **Does the fix eliminate audio dropouts?**
   - Yes / No / Partially

2. **Is audio quality maintained?**
   - Yes / No / Degraded

3. **Are there any side effects?**
   - None / [Describe]

4. **Would you deploy this in production?**
   - Yes / No / With modifications

5. **What additional testing is needed?**
   - None / [Describe]

---

## Support

**If you need help**:
- Check troubleshooting section above
- Review the documentation in this repository
- Open an issue on GitHub
- Contact me for assistance

---

*Testing guide created by: Community Contributors*  
*Last updated: January 27, 2026*
