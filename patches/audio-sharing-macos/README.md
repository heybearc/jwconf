# macOS Audio Sharing Fix

## Problem
JW Conf on macOS doesn't show the audio sharing checkbox during screen sharing, unlike the Windows version. This prevents macOS users from sharing system audio during presentations, demos, or when sharing videos.

## Solution
Automatically enables audio sharing on macOS by modifying the Jitsi Electron SDK to bypass the missing UI checkbox.

## Installation

### Quick Install (Recommended)
```bash
cd ../../installers/macos
bash INSTALL.sh
```

### Manual Install
```bash
# Apply patch to your JW Conf installation
node apply-patch.js
```

### Pre-built Installer
Download the complete installer from [installers/macos/](../../installers/macos/)

## Technical Details

### Root Cause
- Jitsi Meet web interface doesn't display audio sharing checkbox on macOS
- Backend code only enables audio when `data.screenShareAudio` is true
- Without checkbox, this value is never set, so audio is never enabled

### The Fix
**File Modified**: `node_modules/@jitsi/electron-sdk/screensharing/main.js`

**Original Code** (line ~136):
```javascript
if (data.screenShareAudio) {
    constraints.audio = 'loopback';
}
```

**Fixed Code**:
```javascript
// Force enable audio sharing on macOS since the UI doesn't show the checkbox
if (data.screenShareAudio || isMac()) {
    constraints.audio = 'loopback';
}
```

### What Changed
Added `|| isMac()` condition to automatically enable audio sharing on macOS platforms, bypassing the need for the missing UI checkbox.

### Impact
- ✅ macOS users can now share system audio
- ✅ Audio automatically included when screen sharing
- ✅ No user action required
- ⚠️ Audio sharing always enabled on macOS (no way to disable)

## Testing

### Verification Steps
1. Launch JW Conf
2. Join a meeting
3. Play audio (music, video, system sounds)
4. Click "Share Screen" or "Share Application"
5. Select a screen or application window
6. Verify other participants can hear your audio

### Expected Behavior
- Audio from shared content is transmitted to meeting participants
- No checkbox needed - audio sharing is automatic
- Works with all screen sharing modes (full screen, window, application)

## Compatibility

### Tested Platforms
- ✅ macOS 14.2 (Sonoma)
- ✅ macOS 13.x (Ventura)
- ✅ macOS 12.x (Monterey)

### JW Conf Versions
- ✅ 2025.9.1 (tested and verified)
- ⚠️ Other versions should work but not explicitly tested

### Requirements
- macOS 10.15+ (Catalina or later)
- JW Conf installed in `/Applications/JW Conf.app`
- Administrator access (for installation)
- System audio permissions granted

## Rollback

If you need to revert to the original version:

```bash
# Restore from backup
sudo cp ~/Desktop/JW-Conf-app.asar.backup \
  "/Applications/JW Conf.app/Contents/Resources/app.asar"

# Re-sign application
sudo codesign --force --deep --sign - "/Applications/JW Conf.app"
```

The installer automatically creates a backup at `~/Desktop/JW-Conf-app.asar.backup`

## Files in This Directory

- **`main.js.patch`** - Git-style unified diff patch file
- **`apply-patch.js`** - Automated installer script (Node.js)
- **`README.md`** - This file

## Troubleshooting

### App Won't Launch
**Issue**: macOS prevents app from launching after patching

**Solution**: Re-sign the application
```bash
sudo codesign --force --deep --sign - "/Applications/JW Conf.app"
```

### "App is Damaged" Error
**Issue**: macOS Gatekeeper blocking modified app

**Solution**: Remove quarantine attribute
```bash
sudo xattr -cr "/Applications/JW Conf.app"
sudo codesign --force --deep --sign - "/Applications/JW Conf.app"
```

### Audio Still Not Sharing
**Issue**: Fix applied but audio not working

**Solutions**:
1. Verify fix is applied:
   ```bash
   npx @electron/asar extract-file \
     "/Applications/JW Conf.app/Contents/Resources/app.asar" \
     "node_modules/@jitsi/electron-sdk/screensharing/main.js" | \
     grep -A 3 "screenShareAudio"
   ```
   Should show: `if (data.screenShareAudio || isMac())`

2. Check system audio permissions:
   - System Settings → Privacy & Security → Screen Recording
   - Ensure JW Conf has permission

3. Restart JW Conf completely

4. Check logs: `~/Library/Logs/JW Conf/main.log`

## Known Limitations

- **Always On**: Audio sharing cannot be disabled on macOS (always enabled)
- **Code Signing**: Original signature is removed, requires ad-hoc signing
- **Updates**: Fix must be reapplied after JW Conf updates
- **UI Mismatch**: No checkbox shown even though audio is enabled

## Contributing Upstream

This fix should ideally be contributed to:
1. **Jitsi Electron SDK** - https://github.com/jitsi/jitsi-meet-electron-sdk
2. **JW Conf** - Contact their development team

The fix benefits all Electron apps using Jitsi Meet, not just JW Conf.

## License

Apache 2.0 (same as JW Conf and Jitsi Electron SDK)

## Version History

- **v1.0.0** (2026-01-26) - Initial release
  - macOS audio sharing enabled
  - Tested on macOS 14.2
  - JW Conf 2025.9.1 compatibility verified
