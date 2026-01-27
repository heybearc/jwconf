# Screen Share Audio AGC Patch

**Issue**: Audio "pumping" or volume fluctuations during screen sharing  
**Platform**: All (Windows, macOS, Linux)  
**Severity**: HIGH  
**Status**: Ready to test

---

## Problem

When sharing screen with audio, the audio volume fluctuates ("pumps") up and down. This is especially noticeable on Windows.

**Root Cause**: No audio constraints are specified for screen share loopback audio. Windows applies AGC (Automatic Gain Control) by default, which conflicts with the loopback audio stream.

---

## The Fix

**File**: `node_modules/@jitsi/electron-sdk/screensharing/main.js`

**Change**: Add audio constraints to disable AGC, noise suppression, and echo cancellation for screen share audio.

**Lines Changed**: ~15 lines

---

## How to Apply

### Method 1: Manual Patch

1. **Extract app.asar**:
```powershell
cd "%LOCALAPPDATA%\Programs\jw-conf\resources"
asar extract app.asar app-extracted
```

2. **Apply patch**:
```powershell
cd app-extracted
patch -p1 < path\to\screen-share-audio-agc.patch
```

3. **Repack**:
```powershell
cd ..
ren app.asar app.asar.original
asar pack app-extracted app.asar
```

### Method 2: Manual Edit

1. **Extract app.asar** (same as above)

2. **Edit file**:
   - Open: `app-extracted/node_modules/@jitsi/electron-sdk/screensharing/main.js`
   - Find (around line 135):
   ```javascript
   if (data.screenShareAudio) {
       constraints.audio = 'loopback';
   }
   ```

3. **Replace with**:
   ```javascript
   if (data.screenShareAudio) {
       constraints.audio = {
           mandatory: {
               chromeMediaSource: 'desktop',
               chromeMediaSourceId: data.source.id
           },
           optional: [
               { autoGainControl: false },
               { noiseSuppression: false },
               { echoCancellation: false },
               { googAutoGainControl: false },
               { googNoiseSuppression: false },
               { googEchoCancellation: false }
           ]
       };
   }
   ```

4. **Repack** (same as above)

---

## Testing

### Before Patch
1. Share screen with audio
2. Play video or music
3. Observe volume pumping/fluctuations

### After Patch
1. Share screen with audio
2. Play video or music
3. Volume should remain stable

### Validation
- [ ] Audio levels consistent
- [ ] No pumping or breathing effect
- [ ] Clear audio quality
- [ ] Works with different audio sources

---

## Impact

**Positive**:
- Fixes audio pumping during screen share
- Improves presentation quality
- Benefits all platforms

**Negative**:
- None identified

**Risk**: Low - only affects screen share audio

---

## Upstream Contribution

This patch should be contributed to:
- **Jitsi Electron SDK**: https://github.com/jitsi/jitsi-meet-electron-sdk
- **Benefits**: All Jitsi Electron users

---

*Patch created by: Community Contributors*  
*Last updated: January 27, 2026*
