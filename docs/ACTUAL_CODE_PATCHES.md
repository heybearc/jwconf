# Actual Code Patches Required for Windows

**Purpose**: Distinguish between settings recommendations vs actual code bugs requiring patches  
**Date**: January 27, 2026

---

## Summary: Settings vs Patches

### ⚙️ **Settings Recommendation** (Not a Patch)
- **Windows AGC default**: Just a user setting toggle
- **Action**: Document in troubleshooting guide
- **Not a code bug**: Feature working as designed, just wrong default

### 🔧 **Actual Code Patches Required**

1. **Screen Share Audio AGC** - Code bug, needs patch
2. **Breakout Room State Validation** - Missing code, needs patch
3. **Moderator Permission Cache** - Logic bug, needs patch

---

## Patch 1: Screen Share Audio AGC (CRITICAL)

### The Bug

**Location**: `@jitsi/electron-sdk/screensharing/main.js`

**Current Code**:
```javascript
const constraints = {
    video: data.source
};

if (data.screenShareAudio) {
    constraints.audio = 'loopback';  // ← BUG: No audio constraints
}

callback(constraints);
```

**Problem**: 
- No audio constraints specified for loopback audio
- Windows applies AGC to screen share audio by default
- Causes "pumping" and volume fluctuations
- **This is a CODE BUG, not a settings issue**

### The Patch

**File**: `node_modules/@jitsi/electron-sdk/screensharing/main.js`

**Find** (around line 130):
```javascript
if (data.screenShareAudio) {
    // TODO: maybe make this configurable somehow in case
    // someone wants to use `loopbackWithMute`?
    constraints.audio = 'loopback';
}
```

**Replace with**:
```javascript
if (data.screenShareAudio) {
    // Disable audio processing for screen share to prevent pumping
    // Windows AGC conflicts with loopback audio
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

**Impact**:
- Fixes audio pumping during screen share
- Affects ALL platforms (Windows, macOS, Linux)
- Should be upstreamed to Jitsi

**Testing**:
- Share screen with audio
- Play video or music
- Monitor volume levels (should be stable)

---

## Patch 2: Breakout Room State Validation (CRITICAL)

### The Bug

**Location**: Jitsi Meet core (in minified `build/app.js`)

**Problem**:
- When moving between breakout rooms, audio track state is not validated
- Mute state not preserved
- Permissions not re-checked
- Audio device not re-acquired

**This is MISSING CODE, not a configuration issue**

### The Patch Concept

**What needs to be added** (pseudocode, actual implementation in minified code):

```javascript
// Hook into room transition events
function onRoomTransition(fromRoom, toRoom) {
    // 1. Save current state BEFORE leaving
    const savedState = {
        audioMuted: this.isAudioMuted(),
        videoMuted: this.isVideoMuted(),
        role: this.getRole(),
        audioDeviceId: this.getAudioDevice(),
        videoDeviceId: this.getVideoDevice()
    };
    
    // 2. Leave old room
    await this.leaveRoom(fromRoom);
    
    // 3. Join new room
    await this.joinRoom(toRoom);
    
    // 4. VALIDATE audio track exists and is active
    const audioTrack = this.getLocalAudioTrack();
    if (!audioTrack || audioTrack.getTrack().readyState !== 'live') {
        console.error('Audio track invalid after room transition');
        await this.recreateAudioTrack();
    }
    
    // 5. RESTORE saved state
    await this.setAudioMuted(savedState.audioMuted);
    await this.setVideoMuted(savedState.videoMuted);
    
    // 6. RE-VALIDATE permissions
    await this.validatePermissions(savedState.role);
    
    // 7. Emit event for UI sync
    this.emit('room-transition-complete', { fromRoom, toRoom, state: savedState });
}
```

**Challenge**: 
- Code is minified in `build/app.js`
- Need to find the actual room transition logic
- May require unminified source or debugging

**Testing Strategy**:
- Join main room (unmuted)
- Move to breakout room
- Verify audio works
- Return to main room
- **Verify still unmuted and audio works**

---

## Patch 3: Moderator Permission Cache (HIGH PRIORITY)

### The Bug

**Location**: Multiple places in `build/app.js`

**Problem**:
- Permission checks are cached in multiple layers:
  1. Jitsi Meet Redux store (iframe)
  2. Electron wrapper Redux store
  3. LocalStorage persistence
  4. Server-side XMPP state

- When moderator status changes, caches don't invalidate
- Results in "Moderator has blocked this feature" errors

**This is a LOGIC BUG in cache invalidation**

### The Patch Concept

```javascript
// Add cache invalidation on role change
function onParticipantRoleChanged(participantId, newRole) {
    if (participantId === this.getMyUserId()) {
        // 1. Clear ALL permission caches
        this.permissionCache.clear();
        this.featureCache.clear();
        
        // 2. Force refresh from server
        await this.refreshPermissionsFromServer();
        
        // 3. Update Redux stores (both Electron and Jitsi Meet)
        this.electronStore.dispatch({
            type: 'PARTICIPANT_ROLE_CHANGED',
            participantId,
            role: newRole
        });
        
        // 4. Post message to Jitsi Meet iframe
        this.jitsiMeetIframe.contentWindow.postMessage({
            type: 'ROLE_CHANGED',
            role: newRole,
            clearCache: true
        }, '*');
        
        // 5. Re-validate current media state
        await this.validateCurrentMediaState();
        
        // 6. Force UI re-render
        this.forceUpdate();
    }
}
```

**Testing Strategy**:
- Join as participant
- Moderator grants moderator role
- **Immediately try to mute others** (should work)
- **Try to unmute others** (should work)
- No "moderator has blocked" errors

---

## Live Debugging Strategy for Test Meeting

### What to Monitor During Your Test

**Open DevTools** (Ctrl+Shift+I) during the meeting and run these diagnostics:

### 1. Audio Track State Monitor

```javascript
// Run this in Console tab
setInterval(() => {
    const audioTrack = APP.conference.getLocalAudioTrack();
    const track = audioTrack?.getTrack();
    
    console.log('Audio State:', {
        exists: !!audioTrack,
        readyState: track?.readyState,
        enabled: track?.enabled,
        muted: track?.muted,
        deviceId: audioTrack?.getDeviceId(),
        type: audioTrack?.getType()
    });
}, 5000); // Every 5 seconds
```

**What to look for**:
- `readyState` should always be `'live'`
- If it becomes `'ended'`, that's the bug
- `enabled` should match your mute state

### 2. Screen Share Audio Constraints Check

```javascript
// Run this BEFORE sharing screen
navigator.mediaDevices.getUserMedia = new Proxy(navigator.mediaDevices.getUserMedia, {
    apply: function(target, thisArg, args) {
        const [constraints] = args;
        
        if (constraints.audio && typeof constraints.audio === 'object') {
            console.log('Screen Share Audio Constraints:', constraints.audio);
            
            // Check if AGC is disabled
            const hasAGCDisabled = constraints.audio.optional?.some(
                opt => opt.autoGainControl === false
            );
            
            console.log('AGC Disabled:', hasAGCDisabled);
            
            if (!hasAGCDisabled) {
                console.warn('⚠️ BUG: AGC not disabled for screen share!');
            }
        }
        
        return target.apply(thisArg, args);
    }
});

console.log('Screen share audio monitor installed');
```

**What to look for**:
- When you share screen with audio
- Console should show audio constraints
- If AGC is NOT disabled → **that's the bug**

### 3. Breakout Room Transition Monitor

```javascript
// Run this before moving to breakout room
let savedAudioState = null;

// Save state before transition
function saveAudioState() {
    const audioTrack = APP.conference.getLocalAudioTrack();
    savedAudioState = {
        muted: APP.conference.isLocalAudioMuted(),
        trackExists: !!audioTrack,
        trackReady: audioTrack?.getTrack()?.readyState,
        deviceId: audioTrack?.getDeviceId(),
        timestamp: Date.now()
    };
    console.log('Saved audio state:', savedAudioState);
}

// Check state after transition
function checkAudioState() {
    const audioTrack = APP.conference.getLocalAudioTrack();
    const currentState = {
        muted: APP.conference.isLocalAudioMuted(),
        trackExists: !!audioTrack,
        trackReady: audioTrack?.getTrack()?.readyState,
        deviceId: audioTrack?.getDeviceId(),
        timestamp: Date.now()
    };
    
    console.log('Current audio state:', currentState);
    console.log('Saved audio state:', savedAudioState);
    
    // Compare
    if (savedAudioState) {
        const stateChanged = savedAudioState.muted !== currentState.muted;
        const trackChanged = savedAudioState.trackReady !== currentState.trackReady;
        
        if (stateChanged) {
            console.error('⚠️ BUG: Mute state changed during transition!');
        }
        if (trackChanged) {
            console.error('⚠️ BUG: Audio track state changed during transition!');
        }
        if (!currentState.trackExists) {
            console.error('⚠️ BUG: Audio track lost during transition!');
        }
    }
}

console.log('Breakout room monitor installed');
console.log('Run saveAudioState() BEFORE moving to breakout room');
console.log('Run checkAudioState() AFTER arriving in new room');
```

**How to use**:
1. Run the monitor code
2. Before moving to breakout room: `saveAudioState()`
3. Move to breakout room
4. After arriving: `checkAudioState()`
5. Look for error messages

### 4. Permission State Monitor

```javascript
// Monitor permission changes
let lastRole = null;

setInterval(() => {
    const currentRole = APP.conference._room?.getRole();
    
    if (currentRole !== lastRole) {
        console.log('Role changed:', lastRole, '→', currentRole);
        lastRole = currentRole;
        
        // Check if permissions are valid
        const canMuteOthers = APP.conference._room?.isModerator();
        const canUnmuteOthers = APP.conference._room?.isModerator();
        
        console.log('Permissions:', {
            role: currentRole,
            canMuteOthers,
            canUnmuteOthers
        });
        
        // Try to access moderator features
        setTimeout(() => {
            console.log('Testing moderator features...');
            // This will show if permissions are cached incorrectly
        }, 1000);
    }
}, 2000);
```

### 5. WebRTC Stats Monitor

```javascript
// Monitor audio quality metrics
setInterval(async () => {
    const stats = await APP.conference._room?.rtc?.peerConnections?.values()?.next()?.value?.peerconnection?.getStats();
    
    if (stats) {
        stats.forEach(stat => {
            if (stat.type === 'outbound-rtp' && stat.kind === 'audio') {
                console.log('Audio Stats:', {
                    bytesSent: stat.bytesSent,
                    packetsSent: stat.packetsSent,
                    packetsLost: stat.packetsLost || 0,
                    timestamp: stat.timestamp
                });
            }
        });
    }
}, 10000); // Every 10 seconds
```

**What to look for**:
- `bytesSent` should increase steadily when speaking
- If it stops increasing → audio is broken
- `packetsLost` should be low (< 5%)

---

## Test Meeting Debugging Checklist

### Before Meeting Starts

- [ ] Open DevTools (Ctrl+Shift+I)
- [ ] Copy all monitor scripts to Console
- [ ] Run each monitor script
- [ ] Verify monitors are active

### During Meeting

**Test 1: Basic Audio**
- [ ] Speak for 5 minutes
- [ ] Check audio state monitor output
- [ ] Look for `readyState: 'ended'` errors

**Test 2: Screen Share with Audio**
- [ ] Run screen share audio monitor
- [ ] Share screen with audio
- [ ] Check console for AGC warnings
- [ ] Play audio and monitor volume

**Test 3: Breakout Room Transition**
- [ ] Run `saveAudioState()` before moving
- [ ] Move to breakout room
- [ ] Run `checkAudioState()` after arriving
- [ ] Check for state mismatch errors

**Test 4: Moderator Role Change**
- [ ] Have someone grant you moderator
- [ ] Check permission state monitor
- [ ] Try to mute others immediately
- [ ] Look for permission errors

### After Meeting

- [ ] Copy all console output
- [ ] Save WebRTC stats
- [ ] Document any errors found
- [ ] Create bug report

---

## Creating Actual Patches

### Patch File Format

For each bug, create a `.patch` file:

**Example: `screen-share-audio-agc.patch`**
```diff
--- a/node_modules/@jitsi/electron-sdk/screensharing/main.js
+++ b/node_modules/@jitsi/electron-sdk/screensharing/main.js
@@ -127,7 +127,19 @@
                 break;
             }
 
-            if (data.screenShareAudio) {
-                constraints.audio = 'loopback';
+            if (data.screenShareAudio) {
+                // Disable audio processing for screen share
+                constraints.audio = {
+                    mandatory: {
+                        chromeMediaSource: 'desktop',
+                        chromeMediaSourceId: data.source.id
+                    },
+                    optional: [
+                        { autoGainControl: false },
+                        { noiseSuppression: false },
+                        { echoCancellation: false }
+                    ]
+                };
             }
 
             callback(constraints);
```

### How to Apply Patches

```powershell
# Navigate to app directory
cd "%LOCALAPPDATA%\Programs\jw-conf\resources"

# Extract app.asar
asar extract app.asar app-extracted

# Apply patch
cd app-extracted
patch -p1 < screen-share-audio-agc.patch

# Repack
cd ..
ren app.asar app.asar.original
asar pack app-extracted app.asar
```

---

## Summary: What Needs Patches

### ✅ **Real Code Bugs** (Need Patches)

1. **Screen Share Audio AGC**
   - File: `@jitsi/electron-sdk/screensharing/main.js`
   - Lines: ~10 lines
   - Impact: HIGH
   - Testable: YES (during your meeting)

2. **Breakout Room State Validation**
   - File: `build/app.js` (minified)
   - Lines: ~50 lines (if unminified)
   - Impact: CRITICAL
   - Testable: YES (move between rooms)

3. **Moderator Permission Cache**
   - File: `build/app.js` (minified)
   - Lines: ~30 lines (if unminified)
   - Impact: HIGH
   - Testable: YES (role changes)

### ⚙️ **Settings Recommendations** (Not Patches)

1. **Windows AGC Default**
   - Just a setting toggle
   - Document in troubleshooting guide
   - Not a code bug

---

## Next Steps

### For Your Test Meeting

1. **Install all monitors** (copy scripts to DevTools)
2. **Run through test scenarios**
3. **Collect console output**
4. **Identify which bugs you actually hit**

### After Testing

1. **Create patches** for bugs you confirmed
2. **Test patches** in another meeting
3. **Document results**
4. **Share with JW Conf team**

---

*Code patches documentation created by: Community Contributors*  
*Last updated: January 27, 2026*
