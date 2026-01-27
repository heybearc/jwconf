# JW Conf Production Issues Analysis & Solutions

**Environment**: 150-180 concurrent users per meeting  
**Use Case**: Main meeting + breakout rooms, screen sharing with audio  
**Date**: January 27, 2026

---

## Table of Contents

1. [Current Production Issues](#current-production-issues)
2. [Root Cause Analysis](#root-cause-analysis)
3. [Code-Level Issues](#code-level-issues)
4. [Server Infrastructure Issues](#server-infrastructure-issues)
5. [Immediate Fixes](#immediate-fixes)
6. [Proxmox Self-Hosted Solution](#proxmox-self-hosted-solution)
7. [Migration Plan](#migration-plan)

---

## Current Production Issues

### Issue 1: Pixelated Video ⚠️ HIGH PRIORITY

**Symptoms**:
- Video quality degrades during meetings
- Pixelation increases with more participants
- Especially bad during screen sharing

**User Impact**: Poor visual quality, hard to read shared content

---

### Issue 2: Audio Level Fluctuations ⚠️ HIGH PRIORITY

**Symptoms**:
- Shared audio volume goes up and down
- Inconsistent audio levels during screen sharing
- Users report "pumping" or "breathing" audio

**User Impact**: Difficult to hear shared content, poor user experience

---

### Issue 3: Mute/Unmute Failures ⚠️ CRITICAL

**Symptoms**:
- User can speak, then suddenly cannot
- Happens after moderator status changes
- Occurs when moving from breakout room to main room
- Requires leaving and rejoining to fix

**User Impact**: Meeting disruption, user frustration, lost productivity

---

### Issue 4: Moderator State Corruption ⚠️ CRITICAL

**Symptoms**:
- Permission errors after moderator changes
- "Moderator has blocked this feature" errors
- State doesn't sync properly between rooms

**User Impact**: Users locked out of features, meeting flow disrupted

---

## Root Cause Analysis

### 1. Server Capacity Issues (PRIMARY CAUSE)

**Current Setup** (meet.jwconf.com):
- Likely single JVB instance
- Shared infrastructure (multi-tenant)
- Unknown capacity limits
- No control over resources

**Impact at 150-180 Users**:

**Bandwidth Calculation**:
```
Per user (360p):
- Sending: 500 Kbps
- Receiving: 500 Kbps × (N-1) visible participants

For 180 users in main room:
- Total inbound to JVB: 180 × 500 Kbps = 90 Mbps
- Total outbound from JVB: 180 × (179 × 500 Kbps) = ~16 Gbps

This is IMPOSSIBLE for a single JVB instance!
```

**What's Actually Happening**:
- JVB is hitting bandwidth limits
- Adaptive bitrate kicks in aggressively
- Video quality drops to minimum (180p or lower)
- Audio gets deprioritized
- Packet loss increases

**This explains**:
- ✅ Pixelated video (quality degradation)
- ✅ Audio fluctuations (bandwidth competition)
- ⚠️ Some stability issues

---

### 2. Last-N Configuration

**Jitsi's Last-N Feature**:
- Only forwards N most active speakers
- Default: 25 participants
- Others see "dominant speaker" only

**At 150-180 Users**:
- Most users only receive 25 video streams
- This is BY DESIGN to save bandwidth
- But causes confusion ("I can't see everyone")

**Configuration** (server-side):
```javascript
// In config.js on meet.jwconf.com
channelLastN: 25  // Only 25 videos forwarded
```

---

### 3. Audio Sharing Issues

**Screen Share Audio Pipeline**:
```
Screen → Capture → Audio Loopback → WebRTC → JVB → Users
```

**Problems**:

1. **AGC on Shared Audio** (Windows):
   - Windows applies AGC to loopback audio
   - Causes volume pumping
   - Same issue as microphone AGC

2. **Bandwidth Competition**:
   - Screen share video (1080p attempt) + audio
   - Competes with participant video/audio
   - Audio gets compressed/degraded

3. **Sample Rate Mismatch**:
   - System audio: 48kHz
   - WebRTC: 48kHz (good)
   - But resampling can cause artifacts

**From Code** (`@jitsi/electron-sdk/screensharing/main.js`):
```javascript
const constraints = {
    video: data.source
};

if (data.screenShareAudio) {
    constraints.audio = 'loopback';  // ← No quality controls!
}
```

**Issue**: No audio quality constraints specified, relies on defaults.

---

### 4. Breakout Room Audio Sync Bug 🐛

**State Machine Issue**:

When user moves from breakout → main room:
1. Leave breakout room MUC
2. Close WebRTC connection to JVB
3. Join main room MUC
4. Establish new WebRTC connection
5. **BUG**: Audio track state not properly transferred

**Code Path** (likely in minified `app.js`):
```javascript
// Pseudocode of what's happening
function moveToMainRoom() {
    leaveBreakoutRoom();  // Closes audio track
    joinMainRoom();       // Creates NEW audio track
    // ❌ Old mute state not transferred
    // ❌ Moderator permissions not re-checked
    // ❌ Audio device not re-acquired
}
```

**Why It Fails**:
- Redux state shows "unmuted"
- WebRTC track is actually muted or missing
- UI and reality are out of sync

---

### 5. Moderator Permission State Bug 🐛

**Race Condition**:

```
Timeline:
T0: User joins as participant
T1: Moderator grants moderator role
T2: Server updates role → Client receives XMPP message
T3: Redux updates role state
T4: UI re-renders
T5: User tries to unmute
T6: ❌ Permission check uses OLD cached state
```

**Root Cause**:
- Permission checks cached in multiple places
- Redux state updates don't invalidate all caches
- Jitsi Meet iframe has separate state from Electron wrapper

**Evidence from Analysis**:
- Settings stored in `localStorage` (persist:root)
- Jitsi Meet has its own Redux store inside iframe
- Two separate state trees can diverge

---

## Code-Level Issues

### Issue 1: No Audio Quality Controls for Screen Share

**Location**: `@jitsi/electron-sdk/screensharing/main.js:130-142`

**Current Code**:
```javascript
const constraints = {
    video: data.source
};

if (data.screenShareAudio) {
    constraints.audio = 'loopback';
}

callback(constraints);
```

**Problem**: No audio constraints, uses browser defaults

**Fix Needed**:
```javascript
const constraints = {
    video: data.source
};

if (data.screenShareAudio) {
    constraints.audio = {
        mandatory: {
            chromeMediaSource: 'desktop',
            chromeMediaSourceId: data.source.id
        },
        optional: [
            { autoGainControl: false },      // ← Disable AGC
            { noiseSuppression: false },     // ← Disable NS
            { echoCancellation: false },     // ← Disable EC
            { googAutoGainControl: false }   // ← Legacy flag
        ]
    };
}

callback(constraints);
```

**Impact**: Fixes audio pumping during screen share

---

### Issue 2: Default AGC Enabled (Windows)

**Location**: `build/app.js` (minified)

**Current Default**:
```javascript
const Gp = {
    alwaysOnTopWindowEnabled: true,
    disableAGC: false,  // ← BAD DEFAULT for Windows
    serverURL: undefined,
    serverTimeout: undefined
}
```

**Fix Needed**:
```javascript
const Gp = {
    alwaysOnTopWindowEnabled: true,
    disableAGC: process.platform === 'win32' ? true : false,  // ← Platform-specific
    serverURL: undefined,
    serverTimeout: undefined
}
```

**Impact**: Prevents Windows audio dropouts by default

---

### Issue 3: No State Validation on Room Transitions

**Problem**: When moving between rooms, no validation that:
- Audio track is properly acquired
- Mute state is correctly applied
- Permissions are re-checked

**Fix Needed** (pseudocode):
```javascript
async function moveToRoom(roomJid) {
    // Save current state
    const wasMuted = this.isAudioMuted();
    const role = this.getRole();
    
    // Leave current room
    await this.leaveRoom();
    
    // Join new room
    await this.joinRoom(roomJid);
    
    // ✅ Validate and restore state
    await this.validateAudioTrack();
    await this.setAudioMuted(wasMuted);
    await this.validatePermissions(role);
    
    // ✅ Emit event for UI sync
    this.emit('room-transition-complete');
}
```

---

### Issue 4: Permission Cache Invalidation

**Problem**: Multiple layers of permission caching:
- Jitsi Meet Redux store (iframe)
- Electron wrapper Redux store
- LocalStorage persistence
- Server-side XMPP state

**Fix Needed**:
```javascript
function onRoleChanged(newRole) {
    // ✅ Clear all permission caches
    this.permissionCache.clear();
    
    // ✅ Force re-check from server
    await this.refreshPermissionsFromServer();
    
    // ✅ Update all state layers
    this.electronStore.dispatch(setRole(newRole));
    this.jitsiMeetIframe.postMessage({
        type: 'ROLE_CHANGED',
        role: newRole
    });
    
    // ✅ Re-validate current actions
    await this.validateCurrentMediaState();
}
```

---

## Server Infrastructure Issues

### Current Setup (meet.jwconf.com)

**Estimated Configuration**:
- Single JVB instance (or minimal cluster)
- Shared hosting (multi-tenant)
- 360p max resolution (bandwidth constraint)
- Last-N: 25 (only 25 videos forwarded)
- No control over resources

**Bottlenecks at 150-180 Users**:

1. **JVB Bandwidth**: ~16 Gbps needed, likely has 1-10 Gbps
2. **JVB CPU**: Minimal (SFU doesn't transcode)
3. **Network I/O**: Primary bottleneck
4. **TURN Relay**: May be overloaded for users behind NAT

---

### Why You're Hitting Limits

**Math**:
```
180 users × 500 Kbps sending = 90 Mbps inbound to JVB ✅ (manageable)

180 users × 25 streams × 500 Kbps = 2.25 Gbps outbound ⚠️ (tight)

If Last-N is disabled or higher:
180 users × 179 streams × 500 Kbps = 16 Gbps ❌ (impossible)
```

**What Happens**:
- JVB detects bandwidth saturation
- Triggers aggressive quality reduction
- Video drops to 180p or lower
- Audio bitrate reduced
- Packet loss increases
- Users experience pixelation and audio issues

---

## Immediate Fixes

### Fix 1: Enable disableAGC for All Windows Users ✅

**Action**: Update troubleshooting guide (DONE)

**User Instructions**:
1. Settings → Audio
2. Enable "Disable automatic microphone gain control"
3. Test microphone

**Impact**: Fixes Windows audio dropouts and pumping

---

### Fix 2: Server-Side Configuration Changes

**Contact JW Conf Support** to request:

1. **Increase Last-N**:
   ```javascript
   channelLastN: 50  // From 25 to 50
   ```

2. **Increase Max Resolution** (if bandwidth allows):
   ```javascript
   resolution: 480  // From 360 to 480
   constraints: {
     video: {
       height: { ideal: 480, max: 640, min: 180 }
     }
   }
   ```

3. **Enable Simulcast** (if not already):
   ```javascript
   enableLayerSuspension: true
   ```

4. **Optimize Audio**:
   ```javascript
   enableOpusRed: true  // Already enabled
   enableNoAudioDetection: true
   enableNoisyMicDetection: true
   ```

**Impact**: Improves quality for your user count

---

### Fix 3: User Best Practices

**Distribute to Users**:

1. **Disable Video When Not Speaking**:
   - Reduces bandwidth by 500 Kbps per user
   - 100 users with video off = 50 Mbps saved

2. **Use Wired Connections**:
   - More stable than WiFi
   - Reduces packet loss

3. **Close Unnecessary Apps**:
   - Frees bandwidth and CPU
   - Especially important for screen sharers

4. **Optimal Screen Share Settings**:
   - Share single window, not entire screen
   - Close unnecessary windows
   - Use "optimize for text" mode if available

---

## Proxmox Self-Hosted Solution

### Why Self-Host?

**Benefits**:
- ✅ Full control over resources
- ✅ Dedicated bandwidth (no sharing)
- ✅ Custom configuration for your use case
- ✅ Better quality (720p or 1080p possible)
- ✅ No Last-N limits (can show all participants)
- ✅ Data sovereignty
- ✅ Cost savings at scale

**Challenges**:
- ⚠️ Initial setup complexity
- ⚠️ Ongoing maintenance
- ⚠️ Need to manage infrastructure

---

### Proxmox Infrastructure Design

#### Recommended Setup for 150-180 Users

**Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│                     Proxmox Host                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   VM 1       │  │   VM 2       │  │   VM 3       │ │
│  │  Prosody +   │  │   JVB-1      │  │   JVB-2      │ │
│  │  Jicofo +    │  │              │  │              │ │
│  │  nginx       │  │  4 CPU       │  │  4 CPU       │ │
│  │              │  │  8 GB RAM    │  │  8 GB RAM    │ │
│  │  4 CPU       │  │  1 Gbps NIC  │  │  1 Gbps NIC  │ │
│  │  8 GB RAM    │  │              │  │              │ │
│  │  100 GB SSD  │  │  50 GB SSD   │  │  50 GB SSD   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐                   │
│  │   VM 4       │  │   VM 5       │                   │
│  │   TURN       │  │  Monitoring  │                   │
│  │  (coturn)    │  │  Prometheus  │                   │
│  │              │  │  + Grafana   │                   │
│  │  2 CPU       │  │  2 CPU       │                   │
│  │  4 GB RAM    │  │  4 GB RAM    │                   │
│  │  50 GB SSD   │  │  100 GB SSD  │                   │
│  └──────────────┘  └──────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

---

### Hardware Requirements

**Proxmox Host**:
- **CPU**: 16+ cores (32+ threads recommended)
  - Intel Xeon or AMD EPYC
  - High single-thread performance important
- **RAM**: 64 GB minimum (128 GB recommended)
- **Storage**: 
  - 500 GB NVMe SSD for VMs
  - 1-2 TB HDD for recordings (if enabled)
- **Network**: 
  - 10 Gbps NIC (critical for 150-180 users)
  - Or dual 1 Gbps NICs bonded
- **Bandwidth**: 
  - 2-3 Gbps sustained outbound
  - 100 Mbps sustained inbound

**Cost Estimate**:
- **New Server**: $3,000-5,000
- **Or Existing Proxmox**: $0 (use what you have)

---

### VM Specifications

#### VM 1: Prosody + Jicofo + nginx (Control Plane)

**Purpose**: Signaling, conference orchestration, web server

**Specs**:
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 100 GB SSD
- **Network**: 1 Gbps (low bandwidth usage)

**Software**:
- Prosody 0.12+
- Jicofo (latest)
- nginx (reverse proxy)
- Let's Encrypt SSL

**Load**: Low (signaling is lightweight)

---

#### VM 2 & 3: JVB Instances (Media Plane)

**Purpose**: Media routing (SFU)

**Specs per JVB**:
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 4 cores (8 recommended)
- **RAM**: 8 GB (16 GB recommended)
- **Disk**: 50 GB SSD
- **Network**: 1 Gbps dedicated

**Why 2 JVBs**:
- Load balancing
- Redundancy
- Each handles ~90 users comfortably
- Total capacity: 180+ users

**Bandwidth per JVB** (90 users):
```
Inbound: 90 × 500 Kbps = 45 Mbps ✅
Outbound: 90 × 50 streams × 500 Kbps = 2.25 Gbps ⚠️

With Last-N=50:
Outbound: 90 × 50 × 500 Kbps = 2.25 Gbps ✅ (fits in 10 Gbps)
```

---

#### VM 4: TURN Server (NAT Traversal)

**Purpose**: Relay media for users behind restrictive firewalls

**Specs**:
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 2 cores
- **RAM**: 4 GB
- **Disk**: 50 GB SSD
- **Network**: 1 Gbps

**Software**: coturn

**Usage**: 10-20% of users typically need TURN

---

#### VM 5: Monitoring (Observability)

**Purpose**: Metrics, dashboards, alerts

**Specs**:
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 2 cores
- **RAM**: 4 GB
- **Disk**: 100 GB SSD
- **Network**: 1 Gbps

**Software**:
- Prometheus (metrics)
- Grafana (dashboards)
- Loki (logs)
- Alertmanager (alerts)

---

### Network Configuration

**Proxmox Network Setup**:

1. **Bridge for VMs** (vmbr0):
   ```
   auto vmbr0
   iface vmbr0 inet static
       address 10.0.0.1/24
       bridge-ports bond0
       bridge-stp off
       bridge-fd 0
   ```

2. **Port Forwarding** (on your router/firewall):
   ```
   External → Proxmox Host → VM
   
   TCP 443 → 10.0.0.10:443 (nginx)
   TCP 4443 → 10.0.0.10:4443 (nginx fallback)
   UDP 10000 → 10.0.0.11:10000 (JVB-1)
   UDP 10000 → 10.0.0.12:10000 (JVB-2)
   TCP/UDP 3478 → 10.0.0.13:3478 (TURN)
   TCP/UDP 5349 → 10.0.0.13:5349 (TURN TLS)
   ```

3. **Firewall Rules** (on Proxmox):
   ```bash
   # Allow JVB UDP
   iptables -A FORWARD -p udp --dport 10000 -j ACCEPT
   
   # Allow TURN
   iptables -A FORWARD -p udp --dport 3478 -j ACCEPT
   iptables -A FORWARD -p tcp --dport 3478 -j ACCEPT
   ```

---

### Deployment Steps

#### Phase 1: Prepare Proxmox (Day 1)

1. **Create VMs**:
   ```bash
   # On Proxmox host
   qm create 100 --name prosody-jicofo --memory 8192 --cores 4 --net0 virtio,bridge=vmbr0
   qm create 101 --name jvb-1 --memory 8192 --cores 4 --net0 virtio,bridge=vmbr0
   qm create 102 --name jvb-2 --memory 8192 --cores 4 --net0 virtio,bridge=vmbr0
   qm create 103 --name turn --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
   qm create 104 --name monitoring --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
   ```

2. **Install Ubuntu 22.04** on all VMs

3. **Configure Static IPs**:
   - VM 100: 10.0.0.10
   - VM 101: 10.0.0.11
   - VM 102: 10.0.0.12
   - VM 103: 10.0.0.13
   - VM 104: 10.0.0.14

---

#### Phase 2: Install Jitsi Meet (Day 2-3)

**On VM 100 (Prosody + Jicofo)**:

```bash
# Add Jitsi repository
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list

# Update and install
sudo apt update
sudo apt install -y jitsi-meet

# During install:
# - Enter your domain: meet.yourdomain.com
# - Choose "Generate a new self-signed certificate" (will replace with Let's Encrypt later)
```

**On VM 101 & 102 (JVB instances)**:

```bash
# Install JVB only
sudo apt install -y jitsi-videobridge2

# Configure to connect to VM 100
sudo nano /etc/jitsi/videobridge/sip-communicator.properties
```

Add:
```properties
org.jitsi.videobridge.SINGLE_PORT_HARVESTER_PORT=10000
org.jitsi.videobridge.xmpp.user.shard.HOSTNAME=10.0.0.10
org.jitsi.videobridge.xmpp.user.shard.DOMAIN=auth.meet.yourdomain.com
org.jitsi.videobridge.xmpp.user.shard.USERNAME=jvb
org.jitsi.videobridge.xmpp.user.shard.PASSWORD=<password>
org.jitsi.videobridge.xmpp.user.shard.MUC_JIDS=JvbBrewery@internal.auth.meet.yourdomain.com
```

---

#### Phase 3: Configure for Your Use Case (Day 3-4)

**Edit `/etc/jitsi/meet/meet.yourdomain.com-config.js`**:

```javascript
var config = {
    hosts: {
        domain: 'meet.yourdomain.com',
        muc: 'conference.meet.yourdomain.com'
    },
    
    // ✅ Increase quality for your bandwidth
    resolution: 720,  // Up from 360
    constraints: {
        video: {
            height: {
                ideal: 720,
                max: 720,
                min: 180
            }
        }
    },
    
    // ✅ Increase Last-N for better experience
    channelLastN: 50,  // Show 50 participants
    
    // ✅ Enable simulcast
    enableLayerSuspension: true,
    
    // ✅ Optimize for your use case
    startWithAudioMuted: false,
    startWithVideoMuted: false,
    requireDisplayName: true,
    
    // ✅ Breakout rooms
    breakoutRooms: {
        hideAddRoomButton: false,
        hideAutoAssignButton: false,
        hideJoinRoomButton: false
    },
    
    // ✅ Recording (optional)
    // fileRecordingsEnabled: true,
    // liveStreamingEnabled: false,
    
    // ✅ Moderator controls
    disableRemoteMute: false,
    enableModeratorUnmuteConsent: true,
    
    // ✅ Performance
    useNewBandwidthAllocationStrategy: true,
    enableIceRestart: true,
    
    // ✅ TURN servers
    p2p: {
        enabled: false,  // Force through JVB for stability
        stunServers: [
            { urls: 'stun:10.0.0.13:3478' }
        ]
    },
    
    // ✅ Audio optimization
    enableOpusRed: true,
    disableAudioLevels: false,
    enableNoAudioDetection: true,
    enableNoisyMicDetection: true
};
```

---

#### Phase 4: Install TURN Server (Day 4)

**On VM 103**:

```bash
sudo apt install -y coturn

# Configure
sudo nano /etc/turnserver.conf
```

Add:
```conf
listening-port=3478
tls-listening-port=5349
listening-ip=10.0.0.13
external-ip=YOUR_PUBLIC_IP/10.0.0.13

realm=meet.yourdomain.com
server-name=turn.yourdomain.com

lt-cred-mech
user=jitsi:YOUR_TURN_PASSWORD

no-tcp-relay
no-multicast-peers

cert=/etc/letsencrypt/live/turn.yourdomain.com/fullchain.pem
pkey=/etc/letsencrypt/live/turn.yourdomain.com/privkey.pem
```

---

#### Phase 5: Setup Monitoring (Day 5)

**On VM 104**:

```bash
# Install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*
./prometheus --config.file=prometheus.yml &

# Install Grafana
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install grafana

# Start Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

**Configure Prometheus to scrape JVB**:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'jvb'
    static_configs:
      - targets: ['10.0.0.11:8080', '10.0.0.12:8080']
```

**Import Jitsi Dashboard** in Grafana:
- Dashboard ID: 11969 (Jitsi Meet Dashboard)

---

### Custom Configuration for Your Issues

#### Fix 1: Disable AGC for Screen Share Audio

**Create patch file**: `/usr/share/jitsi-meet/libs/screen-share-audio-fix.js`

```javascript
// Override getUserMedia for screen sharing
const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);

navigator.mediaDevices.getUserMedia = function(constraints) {
    if (constraints.audio && constraints.audio.chromeMediaSource === 'desktop') {
        // ✅ Disable audio processing for screen share
        constraints.audio = {
            ...constraints.audio,
            autoGainControl: false,
            noiseSuppression: false,
            echoCancellation: false
        };
    }
    return originalGetUserMedia(constraints);
};
```

**Include in config**:
```javascript
// In config.js
config.customScripts = [
    '/libs/screen-share-audio-fix.js'
];
```

---

#### Fix 2: Validate State on Room Transitions

**Server-side plugin** (Prosody module):

Create `/usr/share/jitsi-meet/prosody-plugins/mod_validate_room_transition.lua`:

```lua
module:hook("muc-occupant-left", function(event)
    local room, occupant = event.room, event.occupant;
    
    -- Store user state before leaving
    local jid = occupant.bare_jid;
    local was_muted = occupant.muted;
    local role = occupant.role;
    
    module:log("info", "User %s left room %s (muted=%s, role=%s)", 
        jid, room.jid, tostring(was_muted), role);
    
    -- Store in temporary cache
    module:shared("room_transition_cache")[jid] = {
        muted = was_muted,
        role = role,
        timestamp = os.time()
    };
end);

module:hook("muc-occupant-joined", function(event)
    local room, occupant = event.room, event.occupant;
    local jid = occupant.bare_jid;
    
    -- Restore user state
    local cache = module:shared("room_transition_cache")[jid];
    if cache and (os.time() - cache.timestamp) < 30 then
        module:log("info", "Restoring state for %s (muted=%s, role=%s)", 
            jid, tostring(cache.muted), cache.role);
        
        -- Send state restoration message to client
        local stanza = st.message({
            from = room.jid,
            to = occupant.nick,
            type = "groupchat"
        }):tag("restore-state", {
            xmlns = "http://jitsi.org/protocol/room-transition",
            muted = tostring(cache.muted),
            role = cache.role
        }):up();
        
        room:route_stanza(stanza);
        
        -- Clear cache
        module:shared("room_transition_cache")[jid] = nil;
    end
end);
```

**Enable module**:
```lua
-- In /etc/prosody/conf.avail/meet.yourdomain.com.cfg.lua
Component "conference.meet.yourdomain.com" "muc"
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
        "validate_room_transition";  -- ← Add this
    }
```

---

### Testing & Validation

#### Load Testing

**Before going live, test with simulated users**:

```bash
# Install Jitsi Torture (load testing tool)
git clone https://github.com/jitsi/jitsi-meet-torture.git
cd jitsi-meet-torture

# Run test with 180 users
./scripts/malleus.sh \
    --conferences=1 \
    --participants=180 \
    --senders=180 \
    --audio-senders=180 \
    --duration=600 \
    --room-name=loadtest \
    --hub-url=https://meet.yourdomain.com
```

**Monitor during test**:
- Grafana dashboards
- JVB CPU/memory/bandwidth
- Packet loss rates
- Video quality scores

---

### Migration Plan

#### Week 1: Setup & Testing

- Day 1-2: Deploy Proxmox VMs
- Day 3-4: Install and configure Jitsi
- Day 5: Load testing
- Day 6-7: Fix issues, optimize

#### Week 2: Parallel Running

- Run both meet.jwconf.com AND your Proxmox instance
- Test with small group (10-20 users)
- Validate all features work
- Train moderators

#### Week 3: Gradual Migration

- Move breakout rooms to self-hosted first
- Keep main meeting on meet.jwconf.com
- Monitor for issues

#### Week 4: Full Migration

- Move all meetings to self-hosted
- Keep meet.jwconf.com as backup
- Monitor closely

#### Week 5+: Optimization

- Tune based on real usage
- Add capacity if needed
- Implement additional features

---

## Cost Analysis

### Self-Hosted vs Current

**Current** (meet.jwconf.com):
- Unknown cost (possibly free tier)
- Limited quality (360p)
- Shared resources
- No control

**Self-Hosted on Proxmox**:

**One-Time Costs**:
- Server hardware: $3,000-5,000 (if buying new)
- Or $0 if using existing Proxmox

**Ongoing Costs**:
- Electricity: ~$50/month (500W server)
- Internet: $100-200/month (business fiber with static IP)
- Domain/SSL: $20/year
- Maintenance: 4-8 hours/month

**Total Year 1**: $2,000-4,000 (excluding hardware)

**Benefits**:
- 720p video (vs 360p)
- Better audio quality
- More reliable
- Full control
- Data sovereignty

---

## Immediate Action Items

### This Week

1. ✅ **Document Windows AGC fix** (DONE)
2. ✅ **Create architecture docs** (DONE)
3. ✅ **Create this analysis** (IN PROGRESS)
4. ⬜ **Test Proxmox capacity** (can it handle the load?)
5. ⬜ **Request DNS subdomain** (meet.yourdomain.com)

### Next Week

1. ⬜ **Deploy VM 100** (Prosody + Jicofo)
2. ⬜ **Deploy VM 101** (JVB-1)
3. ⬜ **Basic Jitsi install**
4. ⬜ **Test with 2-3 users**

### Week 3

1. ⬜ **Deploy VM 102** (JVB-2)
2. ⬜ **Deploy VM 103** (TURN)
3. ⬜ **Load testing**
4. ⬜ **Apply custom fixes**

### Week 4

1. ⬜ **Deploy VM 104** (Monitoring)
2. ⬜ **Pilot with small group**
3. ⬜ **Train moderators**
4. ⬜ **Document procedures**

---

## Conclusion

Your production issues stem from:
1. **Server capacity limits** (PRIMARY) - 150-180 users exceeds typical single-JVB capacity
2. **AGC conflicts** (Windows) - Causing audio pumping
3. **State synchronization bugs** - Breakout room transitions and moderator changes
4. **Lack of audio quality controls** - Screen share audio not optimized

**Recommended Path**:
1. **Immediate**: Apply Windows AGC fix to all users
2. **Short-term** (2-4 weeks): Deploy self-hosted Jitsi on Proxmox
3. **Long-term**: Optimize and add features

**Expected Improvements**:
- ✅ Eliminate pixelation (720p vs 360p)
- ✅ Fix audio pumping (AGC disabled)
- ✅ Reduce mute/unmute issues (state validation)
- ✅ Better breakout room transitions (custom fixes)
- ✅ More stable overall (dedicated resources)

---

*Analysis created by: Community Contributors*  
*Last updated: January 27, 2026*
