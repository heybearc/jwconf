# JW Conf Proxmox Deployment Guide

**Quick Start Guide for Self-Hosting on Proxmox**

Target: 150-180 concurrent users  
Timeline: 2-4 weeks  
Difficulty: Intermediate

---

## Prerequisites

### Hardware Requirements

**Minimum Proxmox Host**:
- CPU: 16 cores / 32 threads
- RAM: 64 GB
- Storage: 500 GB NVMe SSD
- Network: 10 Gbps NIC (or dual 1 Gbps bonded)
- Internet: 3 Gbps sustained bandwidth

**Check Your Proxmox**:
```bash
# SSH to Proxmox host
ssh root@proxmox-host

# Check CPU
lscpu | grep -E "^CPU\(s\)|Model name"

# Check RAM
free -h

# Check storage
df -h

# Check network
ip link show
ethtool eth0 | grep Speed
```

### Network Requirements

- **Public IP address** (static)
- **Domain name** (e.g., meet.yourdomain.com)
- **Firewall access** to configure port forwarding
- **DNS control** to create A records

---

## Phase 1: Create VMs (Day 1)

### Step 1: Create VM Templates

**On Proxmox Web UI** (https://proxmox-host:8006):

1. **Download Ubuntu 22.04 ISO**:
   - Datacenter → Storage → local → ISO Images → Download from URL
   - URL: `https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso`

2. **Create VM 100** (Control Plane):
   ```
   General:
   - VM ID: 100
   - Name: jitsi-control
   
   OS:
   - ISO: ubuntu-22.04.3-live-server-amd64.iso
   
   System:
   - Machine: q35
   - BIOS: OVMF (UEFI)
   - Add EFI Disk
   
   Disks:
   - Bus/Device: SCSI
   - Storage: local-lvm
   - Size: 100 GB
   - Cache: Write back
   - Discard: enabled
   
   CPU:
   - Cores: 4
   - Type: host
   
   Memory:
   - Memory: 8192 MB
   
   Network:
   - Bridge: vmbr0
   - Model: VirtIO
   ```

3. **Clone for other VMs**:
   - Right-click VM 100 → Clone
   - VM 101: jitsi-jvb-1 (4 cores, 8 GB RAM)
   - VM 102: jitsi-jvb-2 (4 cores, 8 GB RAM)
   - VM 103: jitsi-turn (2 cores, 4 GB RAM)
   - VM 104: jitsi-monitoring (2 cores, 4 GB RAM)

### Step 2: Install Ubuntu on All VMs

**For each VM**:

1. Start VM and open console
2. Install Ubuntu Server (minimal installation)
3. Configure during install:
   - Hostname: jitsi-control, jitsi-jvb-1, etc.
   - Username: jitsi
   - Enable OpenSSH server
   - No additional packages

4. After install, update:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo reboot
   ```

### Step 3: Configure Static IPs

**On each VM**, edit netplan:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

**VM 100** (jitsi-control):
```yaml
network:
  version: 2
  ethernets:
    ens18:
      addresses:
        - 10.0.0.10/24
      gateway4: 10.0.0.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

**VM 101** (jitsi-jvb-1): Use `10.0.0.11`  
**VM 102** (jitsi-jvb-2): Use `10.0.0.12`  
**VM 103** (jitsi-turn): Use `10.0.0.13`  
**VM 104** (jitsi-monitoring): Use `10.0.0.14`

Apply:
```bash
sudo netplan apply
```

### Step 4: Configure SSH Access

**From your workstation**:
```bash
# Copy SSH key to each VM
ssh-copy-id jitsi@10.0.0.10
ssh-copy-id jitsi@10.0.0.11
ssh-copy-id jitsi@10.0.0.12
ssh-copy-id jitsi@10.0.0.13
ssh-copy-id jitsi@10.0.0.14

# Test
ssh jitsi@10.0.0.10 'hostname'
```

---

## Phase 2: Install Jitsi Meet (Day 2)

### Step 1: Prepare Control VM (VM 100)

```bash
ssh jitsi@10.0.0.10

# Set hostname
sudo hostnamectl set-hostname meet.yourdomain.com

# Update /etc/hosts
sudo nano /etc/hosts
```

Add:
```
10.0.0.10 meet.yourdomain.com meet
```

### Step 2: Install Jitsi Meet

```bash
# Add Jitsi repository
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list

# Update package list
sudo apt update

# Install Jitsi Meet
sudo apt install -y jitsi-meet
```

**During installation**:
- Hostname: `meet.yourdomain.com`
- SSL: "Generate a new self-signed certificate" (temporary)

### Step 3: Configure Let's Encrypt SSL

```bash
# Install Let's Encrypt
sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
```

Enter your email when prompted.

### Step 4: Test Basic Installation

**From your workstation**:
1. Add to `/etc/hosts`: `YOUR_PUBLIC_IP meet.yourdomain.com`
2. Open browser: `https://meet.yourdomain.com`
3. Create a test room
4. Join with 2 devices

If this works, proceed to add JVB instances.

---

## Phase 3: Add JVB Instances (Day 3)

### Step 1: Install JVB on VM 101

```bash
ssh jitsi@10.0.0.11

# Add Jitsi repository (same as before)
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list

# Install only JVB
sudo apt update
sudo apt install -y jitsi-videobridge2
```

### Step 2: Configure JVB to Connect to Control VM

**Get JVB password from control VM**:
```bash
ssh jitsi@10.0.0.10
sudo cat /etc/jitsi/videobridge/config | grep JVB_SECRET
# Copy the password
```

**Configure JVB on VM 101**:
```bash
ssh jitsi@10.0.0.11
sudo nano /etc/jitsi/videobridge/sip-communicator.properties
```

Add/modify:
```properties
org.jitsi.videobridge.SINGLE_PORT_HARVESTER_PORT=10000
org.jitsi.videobridge.DISABLE_TCP_HARVESTER=true

# XMPP connection to control VM
org.jitsi.videobridge.xmpp.user.shard.HOSTNAME=10.0.0.10
org.jitsi.videobridge.xmpp.user.shard.DOMAIN=auth.meet.yourdomain.com
org.jitsi.videobridge.xmpp.user.shard.USERNAME=jvb
org.jitsi.videobridge.xmpp.user.shard.PASSWORD=<JVB_SECRET_FROM_CONTROL_VM>
org.jitsi.videobridge.xmpp.user.shard.MUC_JIDS=JvbBrewery@internal.auth.meet.yourdomain.com
org.jitsi.videobridge.xmpp.user.shard.MUC_NICKNAME=jvb-1

# Public IP (your external IP)
org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=10.0.0.11
org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=YOUR_PUBLIC_IP
```

**Restart JVB**:
```bash
sudo systemctl restart jitsi-videobridge2
sudo systemctl status jitsi-videobridge2
```

### Step 3: Repeat for VM 102 (JVB-2)

Same steps, but:
- Use `10.0.0.12` for local address
- Use `MUC_NICKNAME=jvb-2`

### Step 4: Verify JVBs are Connected

**On control VM**:
```bash
ssh jitsi@10.0.0.10
sudo tail -f /var/log/prosody/prosody.log | grep JvbBrewery
```

You should see both `jvb-1` and `jvb-2` join the brewery.

---

## Phase 4: Configure for Production (Day 4)

### Step 1: Optimize Video Quality

**Edit config on control VM**:
```bash
ssh jitsi@10.0.0.10
sudo nano /etc/jitsi/meet/meet.yourdomain.com-config.js
```

**Key changes**:
```javascript
var config = {
    // Increase resolution from 360p to 720p
    resolution: 720,
    constraints: {
        video: {
            height: {
                ideal: 720,
                max: 720,
                min: 180
            }
        }
    },
    
    // Show more participants (increase from default 25)
    channelLastN: 50,
    
    // Enable simulcast for adaptive quality
    enableLayerSuspension: true,
    
    // Disable P2P, force through JVB for stability
    p2p: {
        enabled: false
    },
    
    // Audio optimization
    enableOpusRed: true,
    enableNoAudioDetection: true,
    enableNoisyMicDetection: true,
    
    // Moderator controls
    disableRemoteMute: false,
    enableModeratorUnmuteConsent: true,
    
    // Performance
    useNewBandwidthAllocationStrategy: true,
    enableIceRestart: true,
    
    // Breakout rooms
    breakoutRooms: {
        hideAddRoomButton: false,
        hideAutoAssignButton: false,
        hideJoinRoomButton: false
    }
};
```

### Step 2: Configure Interface

**Edit interface config**:
```bash
sudo nano /etc/jitsi/meet/meet.yourdomain.com-interface_config.js
```

**Key changes**:
```javascript
var interfaceConfig = {
    APP_NAME: 'Your Organization Video',
    DEFAULT_BACKGROUND: '#474747',
    DEFAULT_REMOTE_DISPLAY_NAME: 'Guest',
    
    // Show participant count
    SHOW_JITSI_WATERMARK: false,
    SHOW_WATERMARK_FOR_GUESTS: false,
    
    // Toolbar buttons
    TOOLBAR_BUTTONS: [
        'microphone', 'camera', 'closedcaptions', 'desktop', 'fullscreen',
        'fodeviceselection', 'hangup', 'profile', 'chat', 'recording',
        'livestreaming', 'etherpad', 'sharedvideo', 'settings', 'raisehand',
        'videoquality', 'filmstrip', 'invite', 'feedback', 'stats', 'shortcuts',
        'tileview', 'videobackgroundblur', 'download', 'help', 'mute-everyone'
    ]
};
```

### Step 3: Fix Screen Share Audio

**Create custom script**:
```bash
sudo nano /usr/share/jitsi-meet/libs/screen-share-audio-fix.js
```

```javascript
// Disable AGC for screen share audio
(function() {
    const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
    
    navigator.mediaDevices.getUserMedia = function(constraints) {
        if (constraints.audio && constraints.audio.chromeMediaSource === 'desktop') {
            constraints.audio = {
                ...constraints.audio,
                autoGainControl: false,
                noiseSuppression: false,
                echoCancellation: false,
                googAutoGainControl: false
            };
            console.log('Screen share audio: AGC disabled');
        }
        return originalGetUserMedia(constraints);
    };
})();
```

**Include in config**:
```javascript
// In meet.yourdomain.com-config.js
config.customScripts = [
    '/libs/screen-share-audio-fix.js'
];
```

### Step 4: Configure Firewall

**On Proxmox host**:
```bash
# Allow JVB UDP ports
iptables -A FORWARD -p udp --dport 10000 -d 10.0.0.11 -j ACCEPT
iptables -A FORWARD -p udp --dport 10000 -d 10.0.0.12 -j ACCEPT

# Allow HTTPS
iptables -A FORWARD -p tcp --dport 443 -d 10.0.0.10 -j ACCEPT
iptables -A FORWARD -p tcp --dport 4443 -d 10.0.0.10 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

**On your router/firewall**, forward:
- TCP 443 → 10.0.0.10:443
- TCP 4443 → 10.0.0.10:4443
- UDP 10000 → 10.0.0.11:10000
- UDP 10000 → 10.0.0.12:10000

---

## Phase 5: Install TURN Server (Day 5)

### Step 1: Install coturn on VM 103

```bash
ssh jitsi@10.0.0.13

sudo apt install -y coturn

# Enable coturn
sudo nano /etc/default/coturn
```

Uncomment:
```
TURNSERVER_ENABLED=1
```

### Step 2: Configure coturn

```bash
sudo nano /etc/turnserver.conf
```

**Configuration**:
```conf
# Listening ports
listening-port=3478
tls-listening-port=5349

# IPs
listening-ip=10.0.0.13
external-ip=YOUR_PUBLIC_IP/10.0.0.13

# Realm
realm=meet.yourdomain.com
server-name=turn.yourdomain.com

# Authentication
lt-cred-mech
user=jitsi:CHANGE_THIS_PASSWORD

# Optimization
no-tcp-relay
no-multicast-peers
no-cli

# Logging
verbose
log-file=/var/log/turnserver.log

# SSL (after getting cert)
# cert=/etc/letsencrypt/live/turn.yourdomain.com/fullchain.pem
# pkey=/etc/letsencrypt/live/turn.yourdomain.com/privkey.pem
```

**Start coturn**:
```bash
sudo systemctl restart coturn
sudo systemctl enable coturn
sudo systemctl status coturn
```

### Step 3: Configure Jitsi to Use TURN

**On control VM**:
```bash
sudo nano /etc/jitsi/meet/meet.yourdomain.com-config.js
```

Add:
```javascript
config.p2p = {
    enabled: false,
    stunServers: [
        { urls: 'stun:10.0.0.13:3478' }
    ]
};

// For users behind restrictive firewalls
config.useStunTurn = true;
```

---

## Phase 6: Setup Monitoring (Day 6)

### Step 1: Install Prometheus on VM 104

```bash
ssh jitsi@10.0.0.14

# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
sudo mv prometheus-2.45.0.linux-amd64 /opt/prometheus

# Create config
sudo nano /opt/prometheus/prometheus.yml
```

**Configuration**:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'jvb'
    static_configs:
      - targets: 
          - '10.0.0.11:8080'
          - '10.0.0.12:8080'
        labels:
          service: 'jvb'
  
  - job_name: 'jicofo'
    static_configs:
      - targets: ['10.0.0.10:8888']
        labels:
          service: 'jicofo'
```

**Create systemd service**:
```bash
sudo nano /etc/systemd/system/prometheus.service
```

```ini
[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
User=jitsi
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**Start Prometheus**:
```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

### Step 2: Install Grafana

```bash
# Add Grafana repository
sudo apt-get install -y software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Install
sudo apt-get update
sudo apt-get install -y grafana

# Start Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

### Step 3: Configure Grafana

1. Open browser: `http://10.0.0.14:3000`
2. Login: admin / admin (change password)
3. Add Prometheus data source:
   - URL: `http://localhost:9090`
4. Import Jitsi dashboard:
   - Dashboard ID: 11969
   - Or create custom dashboard

---

## Phase 7: Testing (Day 7)

### Load Testing

**Install Jitsi Torture** (on your workstation):
```bash
git clone https://github.com/jitsi/jitsi-meet-torture.git
cd jitsi-meet-torture

# Build
mvn install -DskipTests

# Run test with 50 users (start small)
./scripts/malleus.sh \
    --conferences=1 \
    --participants=50 \
    --senders=50 \
    --audio-senders=50 \
    --duration=300 \
    --room-name=loadtest \
    --hub-url=https://meet.yourdomain.com
```

**Monitor during test**:
- Grafana: `http://10.0.0.14:3000`
- Watch CPU, memory, bandwidth
- Check for packet loss
- Verify video quality

**Gradually increase**:
- 50 users → 100 users → 150 users → 180 users
- Monitor for issues at each level

---

## Phase 8: Go Live (Week 2)

### Pre-Launch Checklist

- [ ] All VMs running and healthy
- [ ] SSL certificates valid
- [ ] DNS pointing to your server
- [ ] Firewall rules configured
- [ ] Load testing passed (180 users)
- [ ] Monitoring dashboards working
- [ ] Backup strategy in place
- [ ] Moderators trained
- [ ] Support documentation ready

### Launch Strategy

**Week 1: Pilot**
- Test with small group (10-20 users)
- One breakout room
- Gather feedback

**Week 2: Partial Migration**
- Move breakout rooms to self-hosted
- Keep main meeting on meet.jwconf.com
- Monitor closely

**Week 3: Full Migration**
- Move all meetings to self-hosted
- Keep meet.jwconf.com as backup
- Announce to all users

**Week 4: Optimization**
- Tune based on real usage
- Fix any issues
- Add capacity if needed

---

## Troubleshooting

### Issue: JVB not connecting to control VM

**Check logs**:
```bash
ssh jitsi@10.0.0.11
sudo journalctl -u jitsi-videobridge2 -f
```

**Common fixes**:
- Verify JVB_SECRET matches
- Check firewall between VMs
- Verify MUC_JIDS is correct

### Issue: Poor video quality

**Check bandwidth**:
```bash
# On JVB VMs
sudo iftop -i ens18
```

**Adjust config**:
- Lower resolution to 480p
- Reduce channelLastN to 25
- Enable more aggressive simulcast

### Issue: Users can't connect

**Check TURN**:
```bash
ssh jitsi@10.0.0.13
sudo tail -f /var/log/turnserver.log
```

**Test TURN**:
```bash
# From external network
turnutils_uclient -v -u jitsi -w PASSWORD YOUR_PUBLIC_IP
```

---

## Maintenance

### Daily

- Check Grafana dashboards
- Review error logs
- Monitor disk space

### Weekly

- Update packages: `sudo apt update && sudo apt upgrade`
- Review capacity trends
- Check SSL expiry

### Monthly

- Full backup of VMs
- Review and optimize configuration
- Update documentation

---

## Backup Strategy

### VM Snapshots (Proxmox)

```bash
# Create snapshot before changes
qm snapshot 100 pre-update-$(date +%Y%m%d)

# List snapshots
qm listsnapshot 100

# Restore if needed
qm rollback 100 pre-update-20260127
```

### Configuration Backup

```bash
# On control VM
sudo tar czf /tmp/jitsi-config-$(date +%Y%m%d).tar.gz \
    /etc/jitsi \
    /etc/prosody \
    /etc/nginx/sites-available

# Copy to backup location
scp /tmp/jitsi-config-*.tar.gz backup-server:/backups/
```

---

## Next Steps

After successful deployment:

1. **Optimize** based on real usage patterns
2. **Add features**: Recording, transcription, etc.
3. **Scale** if needed (add more JVB instances)
4. **Document** your specific procedures
5. **Train** additional administrators

---

## Support Resources

- **Jitsi Community**: https://community.jitsi.org
- **Jitsi Handbook**: https://jitsi.github.io/handbook/
- **Proxmox Wiki**: https://pve.proxmox.com/wiki/
- **This Repository**: Issues and discussions

---

*Deployment guide created by: Community Contributors*  
*Last updated: January 27, 2026*
