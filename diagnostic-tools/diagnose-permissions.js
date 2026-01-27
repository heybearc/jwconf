/**
 * JW Conf Permission Diagnostic Script
 * 
 * Run this in the browser DevTools Console when users experience
 * "moderator has blocked this feature" errors.
 * 
 * Usage:
 * 1. Open DevTools Console (Ctrl+Shift+I or Cmd+Option+I)
 * 2. Copy and paste this entire script
 * 3. Press Enter
 * 4. Copy the output and send to your administrator
 */

(function() {
    console.log('\n========================================');
    console.log('JW CONF PERMISSION DIAGNOSTIC');
    console.log('========================================');
    console.log('Timestamp:', new Date().toISOString());
    console.log('User Agent:', navigator.userAgent);
    console.log('========================================\n');
    
    const results = {
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        tests: {}
    };
    
    // Test 1: Check APP object
    console.log('TEST 1: Checking APP object...');
    if (typeof APP === 'undefined') {
        console.error('❌ APP object not found - not in a JW Conf meeting');
        results.tests.appExists = false;
        return;
    }
    results.tests.appExists = true;
    console.log('✓ APP object found\n');
    
    // Test 2: User role and identity
    console.log('TEST 2: User Identity and Role...');
    try {
        const conference = APP.conference;
        const room = conference._room;
        
        results.tests.identity = {
            userId: conference.getMyUserId(),
            role: room?.getRole(),
            isModerator: room?.isModerator(),
            displayName: conference.getLocalDisplayName?.() || 'Unknown'
        };
        
        console.log('User Identity:', results.tests.identity);
        console.log('Role:', results.tests.identity.role);
        console.log('Is Moderator:', results.tests.identity.isModerator);
        console.log('✓ Identity check complete\n');
    } catch(e) {
        console.error('❌ Error checking identity:', e);
        results.tests.identity = { error: e.message };
    }
    
    // Test 3: Audio permissions
    console.log('TEST 3: Audio Permissions...');
    try {
        const conference = APP.conference;
        const room = conference._room;
        
        results.tests.audioPermissions = {
            localMuted: conference.isLocalAudioMuted(),
            startAudioMuted: room?.isStartAudioMuted(),
            audioMutedByPolicy: room?.isStartAudioMuted() && !room?.isModerator(),
            canUnmute: !room?.isStartAudioMuted() || room?.isModerator(),
            hasAudioTrack: !!conference.getLocalAudioTrack()
        };
        
        console.log('Audio Permissions:', results.tests.audioPermissions);
        
        if (results.tests.audioPermissions.audioMutedByPolicy) {
            console.error('❌ Audio is muted by moderator policy!');
            console.log('   Only moderators can unmute in this room');
        } else {
            console.log('✓ Audio permissions OK\n');
        }
    } catch(e) {
        console.error('❌ Error checking audio permissions:', e);
        results.tests.audioPermissions = { error: e.message };
    }
    
    // Test 4: Video permissions
    console.log('TEST 4: Video Permissions...');
    try {
        const conference = APP.conference;
        const room = conference._room;
        
        results.tests.videoPermissions = {
            localMuted: conference.isLocalVideoMuted(),
            startVideoMuted: room?.isStartVideoMuted(),
            videoMutedByPolicy: room?.isStartVideoMuted() && !room?.isModerator(),
            canUnmute: !room?.isStartVideoMuted() || room?.isModerator(),
            hasVideoTrack: !!conference.getLocalVideoTrack()
        };
        
        console.log('Video Permissions:', results.tests.videoPermissions);
        
        if (results.tests.videoPermissions.videoMutedByPolicy) {
            console.error('❌ Video is muted by moderator policy!');
            console.log('   Only moderators can enable video in this room');
        } else {
            console.log('✓ Video permissions OK\n');
        }
    } catch(e) {
        console.error('❌ Error checking video permissions:', e);
        results.tests.videoPermissions = { error: e.message };
    }
    
    // Test 5: Redux state
    console.log('TEST 5: Redux State...');
    try {
        if (APP.store) {
            const state = APP.store.getState();
            
            results.tests.reduxState = {
                mediaState: state['features/base/media'],
                conferenceState: {
                    joining: state['features/base/conference']?.joining,
                    leaving: state['features/base/conference']?.leaving,
                    locked: state['features/base/conference']?.locked
                },
                localParticipant: state['features/base/participants']?.local
            };
            
            console.log('Redux Media State:', results.tests.reduxState.mediaState);
            console.log('Conference State:', results.tests.reduxState.conferenceState);
            console.log('✓ Redux state check complete\n');
        } else {
            console.warn('⚠️  Redux store not found');
            results.tests.reduxState = { error: 'Store not found' };
        }
    } catch(e) {
        console.error('❌ Error checking Redux state:', e);
        results.tests.reduxState = { error: e.message };
    }
    
    // Test 6: Browser permissions
    console.log('TEST 6: Browser Permissions...');
    const permissionChecks = [];
    
    permissionChecks.push(
        navigator.permissions.query({name: 'microphone'})
            .then(result => ({ microphone: result.state }))
            .catch(e => ({ microphone: 'error: ' + e.message }))
    );
    
    permissionChecks.push(
        navigator.permissions.query({name: 'camera'})
            .then(result => ({ camera: result.state }))
            .catch(e => ({ camera: 'error: ' + e.message }))
    );
    
    Promise.all(permissionChecks).then(perms => {
        results.tests.browserPermissions = Object.assign({}, ...perms);
        console.log('Browser Permissions:', results.tests.browserPermissions);
        
        if (results.tests.browserPermissions.microphone !== 'granted') {
            console.error('❌ Microphone permission not granted at browser level!');
        }
        if (results.tests.browserPermissions.camera !== 'granted') {
            console.error('❌ Camera permission not granted at browser level!');
        }
        console.log('✓ Browser permission check complete\n');
    });
    
    // Test 7: Local storage state
    console.log('TEST 7: Local Storage...');
    try {
        const storageKeys = Object.keys(localStorage);
        const relevantKeys = storageKeys.filter(k => 
            k.includes('jitsi') || k.includes('features') || k.includes('settings')
        );
        
        results.tests.localStorage = {
            totalKeys: storageKeys.length,
            relevantKeys: relevantKeys.length,
            keys: relevantKeys.slice(0, 10) // First 10 only
        };
        
        console.log('Local Storage:', results.tests.localStorage);
        console.log('✓ Storage check complete\n');
    } catch(e) {
        console.error('❌ Error checking local storage:', e);
        results.tests.localStorage = { error: e.message };
    }
    
    // Test 8: Conference lock state
    console.log('TEST 8: Conference Lock State...');
    try {
        const room = APP.conference._room;
        
        results.tests.lockState = {
            isLocked: room?.isLocked?.(),
            password: room?.lock?.password ? '[SET]' : '[NOT SET]'
        };
        
        console.log('Lock State:', results.tests.lockState);
        console.log('✓ Lock state check complete\n');
    } catch(e) {
        console.error('❌ Error checking lock state:', e);
        results.tests.lockState = { error: e.message };
    }
    
    // Summary
    setTimeout(() => {
        console.log('\n========================================');
        console.log('DIAGNOSTIC SUMMARY');
        console.log('========================================');
        
        console.log('\nKey Findings:');
        
        if (!results.tests.appExists) {
            console.log('❌ Not in a JW Conf meeting');
        } else if (!results.tests.identity?.userId) {
            console.log('❌ User not properly joined to conference');
        } else {
            // Check for specific issues
            const issues = [];
            
            if (results.tests.audioPermissions?.audioMutedByPolicy) {
                issues.push('Audio muted by moderator policy');
            }
            if (results.tests.videoPermissions?.videoMutedByPolicy) {
                issues.push('Video muted by moderator policy');
            }
            if (results.tests.browserPermissions?.microphone !== 'granted') {
                issues.push('Browser microphone permission not granted');
            }
            if (results.tests.browserPermissions?.camera !== 'granted') {
                issues.push('Browser camera permission not granted');
            }
            
            if (issues.length > 0) {
                console.log('❌ Issues found:');
                issues.forEach(issue => console.log('   - ' + issue));
            } else {
                console.log('✓ No obvious permission issues detected');
                console.log('  Issue may be transient or server-side');
            }
        }
        
        console.log('\nRecommended Actions:');
        if (results.tests.audioPermissions?.audioMutedByPolicy || 
            results.tests.videoPermissions?.videoMutedByPolicy) {
            console.log('1. Ask moderator to change room settings');
            console.log('2. Or have moderator promote you to moderator');
        }
        if (results.tests.browserPermissions?.microphone !== 'granted' ||
            results.tests.browserPermissions?.camera !== 'granted') {
            console.log('1. Click lock icon in address bar');
            console.log('2. Allow camera and microphone permissions');
            console.log('3. Refresh the page');
        }
        if (!results.tests.audioPermissions?.hasAudioTrack) {
            console.log('1. Check if microphone is plugged in');
            console.log('2. Try Settings > Select different microphone');
        }
        
        console.log('\n========================================');
        console.log('COPY THE RESULTS BELOW:');
        console.log('========================================');
        console.log(JSON.stringify(results, null, 2));
        console.log('========================================\n');
        
        // Store in window for easy copying
        window.jwconfPermissionDiagnostic = results;
        console.log('Results saved to: window.jwconfPermissionDiagnostic');
        console.log('Copy with: copy(window.jwconfPermissionDiagnostic)');
    }, 2000);
    
})();
