/**
 * JW Conf Audio Diagnostic Script
 * 
 * Run this in the browser DevTools Console (Ctrl+Shift+I or Cmd+Option+I)
 * during a meeting when audio issues occur.
 * 
 * Usage:
 * 1. Open DevTools Console
 * 2. Copy and paste this entire script
 * 3. Press Enter
 * 4. Copy the output and send to your administrator
 */

(function() {
    console.log('\n========================================');
    console.log('JW CONF AUDIO DIAGNOSTIC');
    console.log('========================================');
    console.log('Timestamp:', new Date().toISOString());
    console.log('User Agent:', navigator.userAgent);
    console.log('========================================\n');
    
    const results = {
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        tests: {}
    };
    
    // Test 1: Check if APP object exists
    console.log('TEST 1: Checking APP object...');
    if (typeof APP === 'undefined') {
        console.error('❌ APP object not found - not in a JW Conf meeting');
        results.tests.appExists = false;
        return;
    }
    results.tests.appExists = true;
    console.log('✓ APP object found\n');
    
    // Test 2: Check conference state
    console.log('TEST 2: Conference State...');
    try {
        const conference = APP.conference;
        results.tests.conference = {
            exists: !!conference,
            isJoined: conference?._room?.isJoined(),
            myUserId: conference?.getMyUserId(),
            role: conference?._room?.getRole(),
            participantCount: conference?._room?.getParticipantCount()
        };
        console.log('Conference State:', results.tests.conference);
        console.log('✓ Conference check complete\n');
    } catch(e) {
        console.error('❌ Error checking conference:', e);
        results.tests.conference = { error: e.message };
    }
    
    // Test 3: Check local audio track
    console.log('TEST 3: Local Audio Track...');
    try {
        const localAudio = APP.conference.getLocalAudioTrack();
        if (localAudio) {
            const track = localAudio.getTrack();
            results.tests.audioTrack = {
                exists: true,
                type: localAudio.getType(),
                muted: localAudio.isMuted(),
                deviceId: localAudio.getDeviceId(),
                trackState: track?.readyState,
                trackEnabled: track?.enabled,
                trackMuted: track?.muted,
                trackLabel: track?.label
            };
            console.log('Audio Track:', results.tests.audioTrack);
            
            if (track?.readyState !== 'live') {
                console.warn('⚠️  WARNING: Audio track is not in "live" state!');
            }
            if (track?.muted) {
                console.warn('⚠️  WARNING: Audio track is muted at browser level!');
            }
            console.log('✓ Audio track check complete\n');
        } else {
            console.error('❌ No local audio track found');
            results.tests.audioTrack = { exists: false };
        }
    } catch(e) {
        console.error('❌ Error checking audio track:', e);
        results.tests.audioTrack = { error: e.message };
    }
    
    // Test 4: Enumerate audio devices
    console.log('TEST 4: Audio Devices...');
    navigator.mediaDevices.enumerateDevices().then(devices => {
        const audioInputs = devices.filter(d => d.kind === 'audioinput');
        results.tests.audioDevices = audioInputs.map(d => ({
            label: d.label,
            deviceId: d.deviceId,
            groupId: d.groupId
        }));
        console.log('Available Audio Inputs:', results.tests.audioDevices);
        console.log('✓ Device enumeration complete\n');
    }).catch(e => {
        console.error('❌ Error enumerating devices:', e);
        results.tests.audioDevices = { error: e.message };
    });
    
    // Test 5: Check microphone permissions
    console.log('TEST 5: Microphone Permissions...');
    navigator.permissions.query({name: 'microphone'}).then(result => {
        results.tests.micPermission = result.state;
        console.log('Microphone Permission:', result.state);
        if (result.state !== 'granted') {
            console.error('❌ Microphone permission not granted!');
        } else {
            console.log('✓ Microphone permission granted\n');
        }
    }).catch(e => {
        console.error('⚠️  Could not check permissions:', e);
        results.tests.micPermission = { error: e.message };
    });
    
    // Test 6: Check room audio settings
    console.log('TEST 6: Room Audio Settings...');
    try {
        const room = APP.conference._room;
        results.tests.roomSettings = {
            startAudioMuted: room?.isStartAudioMuted(),
            audioMuted: APP.conference.isLocalAudioMuted(),
            audioOnly: room?.isAudioOnly?.(),
            p2p: room?.isP2PActive?.()
        };
        console.log('Room Settings:', results.tests.roomSettings);
        console.log('✓ Room settings check complete\n');
    } catch(e) {
        console.error('❌ Error checking room settings:', e);
        results.tests.roomSettings = { error: e.message };
    }
    
    // Test 7: Check WebRTC stats
    console.log('TEST 7: WebRTC Audio Statistics...');
    try {
        const room = APP.conference._room;
        if (room?.rtc?.peerConnections) {
            const pcPromises = [];
            room.rtc.peerConnections.forEach((pc, id) => {
                pcPromises.push(
                    pc.peerconnection.getStats().then(stats => {
                        const audioStats = [];
                        stats.forEach(stat => {
                            if (stat.type === 'outbound-rtp' && stat.kind === 'audio') {
                                audioStats.push({
                                    bytesSent: stat.bytesSent,
                                    packetsSent: stat.packetsSent,
                                    packetsLost: stat.packetsLost,
                                    timestamp: stat.timestamp
                                });
                            }
                        });
                        return { peerId: id, stats: audioStats };
                    })
                );
            });
            
            Promise.all(pcPromises).then(allStats => {
                results.tests.webrtcStats = allStats;
                console.log('WebRTC Stats:', allStats);
                
                // Check if audio is being sent
                const hasAudioData = allStats.some(pc => 
                    pc.stats.some(s => s.bytesSent > 0)
                );
                
                if (!hasAudioData) {
                    console.error('❌ WARNING: No audio bytes being sent!');
                } else {
                    console.log('✓ Audio data is being transmitted\n');
                }
            });
        } else {
            console.warn('⚠️  No peer connections found');
            results.tests.webrtcStats = { error: 'No peer connections' };
        }
    } catch(e) {
        console.error('❌ Error checking WebRTC stats:', e);
        results.tests.webrtcStats = { error: e.message };
    }
    
    // Test 8: Check audio context
    console.log('TEST 8: Audio Context...');
    try {
        if (typeof AudioContext !== 'undefined' || typeof webkitAudioContext !== 'undefined') {
            results.tests.audioContext = {
                supported: true,
                // Note: Can't check actual context without access to internal state
            };
            console.log('✓ AudioContext API supported\n');
        } else {
            console.error('❌ AudioContext not supported');
            results.tests.audioContext = { supported: false };
        }
    } catch(e) {
        console.error('❌ Error checking AudioContext:', e);
        results.tests.audioContext = { error: e.message };
    }
    
    // Summary
    setTimeout(() => {
        console.log('\n========================================');
        console.log('DIAGNOSTIC SUMMARY');
        console.log('========================================');
        
        console.log('\nKey Findings:');
        if (!results.tests.appExists) {
            console.log('❌ Not in a JW Conf meeting');
        } else if (!results.tests.conference?.isJoined) {
            console.log('❌ Not joined to conference');
        } else if (!results.tests.audioTrack?.exists) {
            console.log('❌ No audio track - microphone not initialized');
        } else if (results.tests.audioTrack?.trackState !== 'live') {
            console.log('❌ Audio track not in live state - device issue');
        } else if (results.tests.micPermission !== 'granted') {
            console.log('❌ Microphone permission not granted');
        } else {
            console.log('✓ Basic audio setup appears correct');
            console.log('  Check WebRTC stats for transmission issues');
        }
        
        console.log('\n========================================');
        console.log('COPY THE RESULTS BELOW:');
        console.log('========================================');
        console.log(JSON.stringify(results, null, 2));
        console.log('========================================\n');
        
        // Also store in window for easy copying
        window.jwconfDiagnostic = results;
        console.log('Results also saved to: window.jwconfDiagnostic');
        console.log('You can copy it with: copy(window.jwconfDiagnostic)');
    }, 2000);
    
})();
