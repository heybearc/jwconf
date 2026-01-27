# Building the Professional Windows Installer

**What this creates**: A single `.exe` file that users can double-click to install patches  
**No dependencies needed**: Everything is bundled inside the installer  
**Professional**: Progress bars, proper UI, uninstaller included

---

## What You Need (One-Time Setup)

### 1. Install NSIS (Nullsoft Scriptable Install System)

**Download**:
- Go to: https://nsis.sourceforge.io/Download
- Download: "NSIS 3.x" (latest version)
- File size: ~2 MB

**Install**:
1. Run the downloaded installer
2. Click "Next" through the wizard
3. Accept defaults
4. Click "Install"
5. Click "Finish"

**Time**: 2 minutes

---

### 2. Download Node.js Portable

We need a portable version of Node.js to bundle with the installer.

**Download**:
1. Go to: https://nodejs.org/dist/latest-v20.x/
2. Download: `node-v20.x.x-win-x64.zip` (about 30 MB)
3. Extract the ZIP file
4. Rename the extracted folder to `node-portable`
5. Move it to: `installers/windows/node-portable/`

**Your folder structure should look like**:
```
installers/windows/
├── node-portable/
│   ├── node.exe
│   ├── npm
│   └── node_modules/
├── jwconf-patcher.nsi
└── BUILD-INSTALLER.md
```

---

### 3. Download asar Tool

**Using the portable Node.js**:

```bash
cd installers/windows
node-portable\node.exe node-portable\npm install -g asar --prefix asar-tool
```

This creates:
```
installers/windows/
├── asar-tool/
│   ├── bin/
│   │   └── asar (or asar.cmd)
│   └── lib/
│       └── node_modules/
│           └── asar/
```

---

## Building the Installer

### Method 1: Using NSIS GUI (Easiest)

1. **Open NSIS**
   - Start menu → NSIS → "Compile NSI scripts"

2. **Load the script**
   - Click "File" → "Load Script"
   - Navigate to: `installers/windows/jwconf-patcher.nsi`
   - Click "Open"

3. **Compile**
   - The script will compile automatically
   - Watch the progress in the window
   - When done, you'll see "Total size: X KB"

4. **Find your installer**
   - Location: `installers/windows/JWConf-Patcher-Setup.exe`
   - This is your distributable installer!

**Time**: 30 seconds

---

### Method 2: Command Line

```bash
cd installers/windows
"C:\Program Files (x86)\NSIS\makensis.exe" jwconf-patcher.nsi
```

Output: `JWConf-Patcher-Setup.exe`

---

## What the Installer Does

When a user runs `JWConf-Patcher-Setup.exe`:

1. **Shows professional welcome screen**
2. **Checks if JW Conf is installed**
   - If not found → Shows error and exits
3. **Extracts portable Node.js** (bundled inside)
4. **Extracts asar tool** (bundled inside)
5. **Creates backup** of original app.asar
6. **Extracts app.asar**
7. **Applies patches**:
   - Screen Share Audio AGC fix
8. **Repacks app.asar**
9. **Cleans up temporary files**
10. **Shows success message**

**User experience**: Click → Wait 1 minute → Done!

---

## Testing the Installer

### Before Distributing:

1. **Test on clean Windows machine**
   - Install JW Conf first
   - Run your installer
   - Verify patches applied

2. **Test uninstaller**
   - Run the uninstaller
   - Verify original restored

3. **Test error handling**
   - Run installer without JW Conf installed
   - Should show error message

---

## Distributing the Installer

### What to Share:

**Single file**: `JWConf-Patcher-Setup.exe` (about 35-40 MB)

**Where to share**:
- GitHub Releases
- Direct download link
- Email to users

### User Instructions (Super Simple):

```
JW CONF PATCHER - INSTALLATION INSTRUCTIONS

1. Make sure JW Conf is installed first
2. Close JW Conf if it's running
3. Double-click: JWConf-Patcher-Setup.exe
4. Click "Next" a few times
5. Wait for "Installation Complete"
6. Restart JW Conf

That's it! The patches are installed.

To uninstall:
- Run the installer again
- Choose "Uninstall"
```

---

## Advanced: Customizing the Installer

### Change the Icon

1. Create or find a `.ico` file
2. Save it as `installer-icon.ico`
3. In the NSI script, change:
   ```nsis
   !define MUI_ICON "installer-icon.ico"
   ```

### Add More Patches

In the NSI script, add more patch sections:

```nsis
; Apply another patch
DetailPrint "Applying Another Patch..."
; ... patch code here ...
```

### Change Installer Name

In the NSI script:
```nsis
Name "Your Custom Name"
OutFile "YourCustomName-Setup.exe"
```

---

## Troubleshooting

### "NSIS Error: Can't open script file"

**Fix**: Make sure you're in the right directory and the file exists

### "Error: node-portable not found"

**Fix**: Download and extract Node.js portable (see step 2 above)

### "Error: asar-tool not found"

**Fix**: Install asar using the portable Node.js (see step 3 above)

### "Installer is too large"

**Solution**: This is normal. The installer bundles Node.js (~30 MB) + asar tool (~5 MB)

### "Windows SmartScreen blocks the installer"

**Why**: Unsigned installer (you need a code signing certificate to prevent this)

**User workaround**: Click "More info" → "Run anyway"

**Professional solution**: Get a code signing certificate (~$100-300/year)

---

## Alternative: Simpler Installer (Without Node.js Bundle)

If you want a smaller installer that requires Node.js to be pre-installed:

1. Remove the `node-portable` bundling from the NSI script
2. Add a check for Node.js installation
3. Show error if not found

**Pros**: Smaller installer (~5 MB)  
**Cons**: User must install Node.js first

---

## Code Signing (Optional but Recommended)

To prevent Windows SmartScreen warnings:

1. **Get a code signing certificate**
   - Providers: DigiCert, Sectigo, GlobalSign
   - Cost: $100-300/year
   - Requires business verification

2. **Sign the installer**
   ```bash
   signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com JWConf-Patcher-Setup.exe
   ```

3. **Benefits**:
   - No SmartScreen warnings
   - Shows your organization name
   - Users trust it more

---

## Summary

**For you (developer)**:
1. Install NSIS (one-time)
2. Download Node.js portable (one-time)
3. Install asar tool (one-time)
4. Compile the NSI script (30 seconds)
5. Distribute the .exe file

**For users**:
1. Download the .exe
2. Double-click it
3. Click "Next" a few times
4. Done!

**Much more professional than batch files!**

---

*Build guide created by: Community Contributors*  
*Last updated: January 27, 2026*
