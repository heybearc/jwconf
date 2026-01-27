# Building Windows Installer on macOS

**Yes, you can build the Windows .exe installer on your Mac!**

There are 3 methods, from easiest to most complex:

---

## Method 1: Use Wine (Recommended)

Wine lets you run Windows programs on Mac, including NSIS.

### Install Wine

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Wine
brew install --cask wine-stable

# Verify installation
wine --version
```

### Install NSIS via Wine

```bash
# Download NSIS installer
cd ~/Downloads
curl -L -O https://downloads.sourceforge.net/project/nsis/NSIS%203/3.09/nsis-3.09-setup.exe

# Install NSIS using Wine
wine nsis-3.09-setup.exe

# Follow the installer (click Next through the wizard)
```

### Build the Installer

```bash
cd /Users/cory/Projects/jwconf/installers/windows

# Make sure you have Node.js portable and asar-tool set up
# (See BUILD-INSTALLER.md for details)

# Compile with NSIS via Wine
wine ~/.wine/drive_c/Program\ Files\ \(x86\)/NSIS/makensis.exe jwconf-patcher.nsi

# Output: JWConf-Patcher-Setup.exe
```

**Time**: 10-15 minutes for setup, 30 seconds to build

---

## Method 2: Use a Windows VM

Run Windows in a virtual machine on your Mac.

### Option A: Use UTM (Free)

1. **Install UTM**:
   ```bash
   brew install --cask utm
   ```

2. **Download Windows 11 ISO**:
   - Go to: https://www.microsoft.com/software-download/windows11
   - Download the ISO file

3. **Create Windows VM**:
   - Open UTM
   - Create new VM
   - Select Windows 11 ISO
   - Allocate 4 GB RAM, 2 CPU cores
   - Install Windows

4. **Inside Windows VM**:
   - Install NSIS
   - Build the installer normally
   - Copy the .exe back to Mac

### Option B: Use Parallels (Paid, $99/year)

Same process but faster performance.

**Time**: 1-2 hours for setup, then normal Windows build process

---

## Method 3: Use Docker (Advanced)

Build in a Windows container.

### Create Dockerfile

```dockerfile
# installers/windows/Dockerfile
FROM ubuntu:22.04

# Install Wine and dependencies
RUN apt-get update && apt-get install -y \
    wine \
    wine32 \
    wine64 \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install NSIS
RUN wget https://downloads.sourceforge.net/project/nsis/NSIS%203/3.09/nsis-3.09-setup.exe \
    && wine nsis-3.09-setup.exe /S

# Set working directory
WORKDIR /build

# Copy installer files
COPY . .

# Build command
CMD ["wine", "/root/.wine/drive_c/Program Files (x86)/NSIS/makensis.exe", "jwconf-patcher.nsi"]
```

### Build with Docker

```bash
cd /Users/cory/Projects/jwconf/installers/windows

# Build Docker image
docker build -t jwconf-installer-builder .

# Run build
docker run -v $(pwd):/build jwconf-installer-builder

# Output: JWConf-Patcher-Setup.exe
```

**Time**: 20 minutes for setup, 2 minutes to build

---

## Method 4: Alternative - Electron-based Installer (No Wine Needed!)

Create a cross-platform installer using Electron Forge that works on both Mac and Windows.

### Install Dependencies

```bash
cd /Users/cory/Projects/jwconf/installers
npm init -y
npm install --save-dev @electron-forge/cli
npm install --save-dev @electron-forge/maker-squirrel  # Windows
npm install --save-dev @electron-forge/maker-dmg       # macOS
```

### Create Electron App

```javascript
// installers/electron-installer/main.js
const { app, BrowserWindow } = require('electron');
const path = require('path');
const fs = require('fs');
const asar = require('asar');

// Your patch logic here
async function applyPatches() {
    // Same logic as the batch file, but in JavaScript
}

app.whenReady().then(() => {
    // Show UI and apply patches
});
```

### Build for Windows (from Mac)

```bash
npm run make -- --platform=win32
```

**Output**: Windows installer that works on Windows

**Benefit**: You can build for both platforms from your Mac!

---

## Recommended Approach

**For you (on Mac)**:

### Quick Start: Use Wine

```bash
# One-time setup (10 minutes)
brew install --cask wine-stable
cd ~/Downloads
curl -L -O https://downloads.sourceforge.net/project/nsis/NSIS%203/3.09/nsis-3.09-setup.exe
wine nsis-3.09-setup.exe

# Build installer (30 seconds)
cd /Users/cory/Projects/jwconf/installers/windows
wine ~/.wine/drive_c/Program\ Files\ \(x86\)/NSIS/makensis.exe jwconf-patcher.nsi
```

**Result**: `JWConf-Patcher-Setup.exe` ready to distribute!

---

## Troubleshooting

### "Wine won't install"

**Try**:
```bash
# Use Homebrew's version
brew install wine-stable

# Or try MacPorts
sudo port install wine-crossover
```

### "NSIS installer won't run in Wine"

**Try**:
```bash
# Use silent install
wine nsis-3.09-setup.exe /S

# Check if installed
ls ~/.wine/drive_c/Program\ Files\ \(x86\)/NSIS/
```

### "Can't find makensis.exe"

**Find it**:
```bash
find ~/.wine -name "makensis.exe"
```

### "Build fails with Wine"

**Alternative**: Use the Electron-based installer (Method 4) - no Wine needed!

---

## What About the Node.js Portable Bundle?

You still need to download the Windows version of Node.js portable:

```bash
cd /Users/cory/Projects/jwconf/installers/windows

# Download Windows Node.js portable
curl -L -O https://nodejs.org/dist/v20.11.0/node-v20.11.0-win-x64.zip

# Extract
unzip node-v20.11.0-win-x64.zip

# Rename
mv node-v20.11.0-win-x64 node-portable
```

---

## Summary

**Can you build Windows installer on Mac?** YES!

**Easiest method**: Wine + NSIS (10 min setup)

**Most reliable**: Windows VM (1-2 hours setup)

**Most flexible**: Electron-based installer (works for both platforms)

**My recommendation**: Start with Wine. If it doesn't work, use Electron method.

---

*Cross-platform build guide created by: Community Contributors*  
*Last updated: January 27, 2026*
