# JW Conf Community Fixes

Community-maintained bug fixes and improvements for JW Conf.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

## ⚠️ Disclaimer

This is an **unofficial community project**. We are not affiliated with JW Conf or Jitsi. These fixes are provided as-is under the Apache 2.0 license.

## 🐛 Available Fixes

### ✅ macOS Audio Sharing Fix
**Status**: Stable  
**Issue**: macOS version doesn't show audio sharing checkbox during screen sharing  
**Solution**: Automatically enables audio sharing on macOS  
**Platforms**: macOS 10.15+  
**Version**: v1.0.0

📖 [Documentation](patches/audio-sharing-macos/README.md) | ⬇️ [Download Installer](installers/macos/INSTALL.sh)

### ✅ Windows Audio Dropout Fix
**Status**: Fix Available  
**Issue**: Audio drops out during meetings, requires toggling noise suppression to fix  
**Solution**: Disable Automatic Gain Control (AGC) in audio settings  
**Platforms**: Windows 10/11  
**Version**: Identified in v2025.9.1

� [Quick Fix Guide](docs/TROUBLESHOOTING_GUIDE.md#audio-dropout-quick-fixes) | 🔍 [Technical Details](docs/TROUBLESHOOTING_GUIDE.md#automatic-gain-control-agc-conflict)

### 🔧 Permission State Bug (Under Investigation)
**Status**: Investigating  
**Issue**: Users get "Moderator has blocked this feature" error incorrectly  
**Platforms**: Windows, macOS  

🔍 [Help us debug](https://github.com/heybearc/jwconf/issues) - Run diagnostic tools and share results

## 🚀 Quick Start

### For End Users

#### macOS Audio Fix
```bash
# Download and run installer
curl -L https://raw.githubusercontent.com/heybearc/jwconf/main/installers/macos/INSTALL.sh -o install.sh
bash install.sh
```

Or download manually from [installers/macos/](installers/macos/)

#### Windows Audio Dropout Fix
**Quick Fix** (No installation needed):
1. Open JW Conf and join a meeting
2. Click Settings (gear icon) → Audio
3. Enable "Disable automatic microphone gain control"
4. Test your microphone

This setting persists across sessions. See [Troubleshooting Guide](docs/TROUBLESHOOTING_GUIDE.md#audio-dropout-quick-fixes) for details.

### For Developers

```bash
# Clone repository
git clone https://github.com/heybearc/jwconf.git
cd jwconf

# Apply a patch manually
cd patches/audio-sharing-macos
node apply-patch.js
```

## 🔍 Diagnostic Tools

Having issues? Use our diagnostic scripts to gather data:

- **[diagnose-audio.js](diagnostic-tools/diagnose-audio.js)** - Debug audio problems
  - Run in DevTools Console during a meeting
  - Identifies audio track state, device issues, WebRTC problems
  
- **[diagnose-permissions.js](diagnostic-tools/diagnose-permissions.js)** - Debug permission errors
  - Run when you see "moderator has blocked" errors
  - Checks permission state, role, browser permissions

- **[collect-logs-windows.bat](diagnostic-tools/collect-logs-windows.bat)** - Collect system logs (Windows)
  - Gathers all relevant logs and system info
  - Creates zip file for sharing

- **[enable-debug-logging-windows.bat](diagnostic-tools/enable-debug-logging-windows.bat)** - Enable verbose logging (Windows)
  - Turns on detailed logging for troubleshooting

## 📚 Documentation

- **[Troubleshooting Guide](docs/TROUBLESHOOTING_GUIDE.md)** - Complete guide to debugging issues
- **[Quick Start](docs/QUICK_START.md)** - Fast troubleshooting reference
- **[Technical Details](docs/TECHNICAL_DETAILS.md)** - Deep dive into fixes and architecture
- **[License Analysis](docs/LICENSE_ANALYSIS.md)** - Legal compliance information
- **[GitHub Strategy](docs/GITHUB_STRATEGY.md)** - Repository organization and contribution guide

## 🤝 Contributing

We welcome contributions! Here's how you can help:

- 🐛 **Report bugs** - Use diagnostic tools and open an issue
- 🔧 **Submit fixes** - Create a pull request with your solution
- 📖 **Improve docs** - Help make documentation clearer
- 🧪 **Test patches** - Verify fixes work on your system
- 💬 **Help others** - Answer questions in issues

See [CONTRIBUTING.md](docs/GITHUB_STRATEGY.md#contributing) for detailed guidelines.

## 📬 Contact JW Conf Developers

**To the JW Conf Team:**

We'd love to contribute these fixes upstream! All patches are:
- Apache 2.0 licensed (same as your project)
- Fully tested and documented
- Ready for integration
- Maintained by the community

Contact: Open an issue or reach out via GitHub

## 🛠️ What's Fixed

### macOS Audio Sharing (v1.0.0)
- **Problem**: No audio sharing checkbox on macOS during screen sharing
- **Root Cause**: Jitsi Electron SDK only enables audio when checkbox is checked, but macOS UI doesn't show the checkbox
- **Solution**: Modified `@jitsi/electron-sdk/screensharing/main.js` to automatically enable audio on macOS
- **Impact**: macOS users can now share system audio during screen sharing
- **Testing**: Verified on macOS 14+ with JW Conf 2025.9.1

## 📊 Compatibility

| Platform | JW Conf Version | Status |
|----------|----------------|--------|
| macOS 10.15+ | 2025.9.1 | ✅ Tested |
| macOS 14+ | 2025.9.1 | ✅ Tested |
| Windows 10/11 | 2025.9.1 | 🔍 Investigating |

## 📄 License

Apache 2.0 - See [LICENSE](LICENSE) for details.

This project maintains the same license as JW Conf and Jitsi Meet Electron, allowing:
- ✅ Modification and distribution
- ✅ Commercial use
- ✅ Private use
- ✅ Patent grant

## 🙏 Acknowledgments

- **JW Conf Team** - For creating the application
- **Jitsi Community** - For the underlying platform
- **Contributors** - Everyone who helps identify and fix bugs

## 📈 Project Status

- **Active Development**: Yes
- **Maintained**: Yes
- **Accepting Contributions**: Yes
- **Response Time**: Usually within 48 hours

## 🔗 Links

- **Issues**: [Report bugs or request features](https://github.com/heybearc/jwconf/issues)
- **Discussions**: [Ask questions or share ideas](https://github.com/heybearc/jwconf/discussions)
- **JW Conf**: [https://jwconf.com](https://jwconf.com)
- **Jitsi**: [https://jitsi.org](https://jitsi.org)

---

**Not affiliated with JW Conf or Jitsi. Community project only.**

*Last updated: January 26, 2026*
