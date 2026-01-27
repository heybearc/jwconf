JW Conf Audio Sharing Fix for macOS
====================================

WHAT THIS FIXES
---------------
This installer enables audio sharing during screen sharing in JW Conf on macOS.

The Windows version of JW Conf has a checkbox to share system audio when 
screen sharing, but the macOS version doesn't show this option. This fix 
automatically enables audio sharing on macOS.


WHAT YOU NEED
-------------
- macOS computer (10.15 or later)
- JW Conf already installed in /Applications/
- Administrator password


INSTALLATION INSTRUCTIONS
-------------------------

1. Download and extract this folder to your Mac

2. Open Terminal (Applications > Utilities > Terminal)

3. Navigate to this folder:
   cd ~/Downloads/jwconf-installer-for-mac
   (adjust path if you extracted it elsewhere)

4. Run the installer:
   bash INSTALL.sh

5. Enter your password when prompted

6. Launch JW Conf and test audio sharing


ALTERNATIVE: Double-Click Installation
---------------------------------------
You can also double-click "INSTALL.command" if you prefer not to use Terminal.


WHAT HAPPENS
------------
✓ Creates a backup of your original JW Conf app
✓ Installs the patched version with audio sharing enabled
✓ Re-signs the app so macOS will run it
✓ Backup saved to your Desktop


TESTING THE FIX
---------------
1. Launch JW Conf
2. Join a meeting
3. Play some audio (music, video, etc.)
4. Click "Share Screen"
5. Select a screen or application window
6. Other participants should now hear your audio!


UNINSTALLING
------------
If you want to remove the fix and restore the original:

1. Open Terminal
2. Navigate to this folder
3. Run: bash UNINSTALL.sh


TROUBLESHOOTING
---------------

Problem: "App cannot be opened"
Solution: Go to System Settings > Privacy & Security
         Click "Open Anyway" next to the JW Conf warning

Problem: "Permission denied"
Solution: Make sure you're entering your administrator password
         Try: sudo bash INSTALL.sh

Problem: No audio is shared
Solution: Check System Settings > Privacy & Security > Screen Recording
         Make sure JW Conf has permission


WHAT'S CHANGED
--------------
Technical details: One line of code was modified in the Jitsi Electron SDK
to automatically enable audio sharing on macOS platforms.

File modified: /Applications/JW Conf.app/Contents/Resources/app.asar
Change: Added automatic audio sharing for macOS in the screen sharing module


SAFETY
------
✓ A backup is automatically created before installation
✓ You can uninstall at any time
✓ The original app is preserved on your Desktop
✓ No system files are modified
✓ Only the JW Conf app is changed


SUPPORT
-------
If you have issues, contact the person who provided this installer.

For technical details, see the full documentation package.


VERSION INFO
------------
Fix Version: 1.0
JW Conf Version: 2025.9.1
Date: January 25, 2026
Platform: macOS
