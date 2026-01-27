#!/usr/bin/env node

/**
 * Automated patch script for JW Conf macOS audio sharing fix
 * 
 * This script automatically applies the audio sharing fix to the
 * @jitsi/electron-sdk package in a JW Conf Electron project.
 * 
 * Usage:
 *   node patch-script.js
 * 
 * Or add to package.json:
 *   "scripts": {
 *     "postinstall": "node patch-script.js"
 *   }
 */

const fs = require('fs');
const path = require('path');

const COLORS = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m'
};

function log(message, color = 'reset') {
  console.log(`${COLORS[color]}${message}${COLORS.reset}`);
}

function applyPatch() {
  log('\n🔧 JW Conf macOS Audio Sharing Fix', 'blue');
  log('=====================================\n', 'blue');

  // Locate the file to patch
  const filePath = path.join(
    __dirname,
    '../node_modules/@jitsi/electron-sdk/screensharing/main.js'
  );

  // Check if file exists
  if (!fs.existsSync(filePath)) {
    log('❌ Error: Could not find main.js file', 'red');
    log(`   Expected location: ${filePath}`, 'yellow');
    log('   Make sure @jitsi/electron-sdk is installed\n', 'yellow');
    process.exit(1);
  }

  // Read the file
  let content = fs.readFileSync(filePath, 'utf8');

  // Check if already patched
  if (content.includes('if (data.screenShareAudio || isMac())')) {
    log('✓ Patch already applied - skipping', 'green');
    log('  Audio sharing fix is active\n', 'green');
    return;
  }

  // Apply the fix
  const originalCode = 'if (data.screenShareAudio) {';
  const patchedCode = `// Force enable audio sharing on macOS since the UI doesn't show the checkbox
                if (data.screenShareAudio || isMac()) {`;

  if (!content.includes(originalCode)) {
    log('⚠️  Warning: Original code pattern not found', 'yellow');
    log('   The file may have been modified or is a different version', 'yellow');
    log('   Manual patching may be required\n', 'yellow');
    process.exit(1);
  }

  content = content.replace(originalCode, patchedCode);

  // Write the patched file
  fs.writeFileSync(filePath, content, 'utf8');

  log('✓ Successfully applied macOS audio sharing fix', 'green');
  log('  File: node_modules/@jitsi/electron-sdk/screensharing/main.js', 'green');
  log('  Change: Added || isMac() condition for automatic audio sharing\n', 'green');
  log('ℹ️  Audio will now be automatically shared on macOS during screen sharing', 'blue');
  log('   No checkbox is needed - audio sharing is always enabled\n', 'blue');
}

// Run the patch
try {
  applyPatch();
} catch (error) {
  log(`❌ Error applying patch: ${error.message}`, 'red');
  log(`   ${error.stack}\n`, 'red');
  process.exit(1);
}
