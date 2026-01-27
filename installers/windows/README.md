# Windows Patches Installer - Super Easy Instructions

**What this does**: Automatically installs patches to fix JW Conf bugs  
**Time needed**: 5 minutes  
**Difficulty**: Easy - just double-click!

---

## What You Need First

### 1. Install Node.js (One-Time Setup)

**Why**: The installer needs this tool to work

**How to install**:
1. Go to: https://nodejs.org/
2. Click the big green button that says "Download"
3. Run the downloaded file
4. Click "Next" a bunch of times
5. Click "Finish"
6. **Restart your computer**

**That's it!** You only need to do this once.

---

## How to Install the Patches

### Super Easy Steps:

1. **Close JW Conf** (if it's running)
2. **Find the file**: `INSTALL-PATCHES.bat` (in this folder)
3. **Right-click** on `INSTALL-PATCHES.bat`
4. **Click**: "Run as administrator"
5. **Click "Yes"** when Windows asks if you're sure
6. **Wait** while it installs (about 1 minute)
7. **Press any key** when it says "Installation Complete!"

**Done!** The patches are installed.

---

## What Gets Installed

✅ **Screen Share Audio AGC Fix**
- Fixes audio "pumping" when sharing screen with audio
- Makes volume stay consistent during presentations

---

## How to Test It Works

1. **Open JW Conf**
2. **Join a test meeting**
3. **Share your screen** with audio
4. **Play some music or a video**
5. **Listen**: Volume should stay steady (no pumping)

---

## If Something Goes Wrong

### "It says I need to run as administrator"

**Fix**:
1. Right-click the file
2. Choose "Run as administrator" (not just double-click)

### "It says Node.js is not installed"

**Fix**:
1. Install Node.js (see instructions above)
2. Restart your computer
3. Try again

### "It can't find JW Conf"

**Fix**:
1. Make sure JW Conf is installed
2. Check it's in the normal location: `C:\Users\[YourName]\AppData\Local\Programs\jw-conf`

### "I want to undo the patches"

**Easy**:
1. Close JW Conf
2. Go to: `C:\Users\[YourName]\AppData\Local\Programs\jw-conf\resources`
3. Delete the file `app.asar`
4. Rename `app.asar.original` to `app.asar`

**Or**: Reinstall JW Conf from scratch

---

## What the Installer Does (Behind the Scenes)

Don't worry about understanding this - it's just for reference:

1. Checks if you have the right tools
2. Finds your JW Conf installation
3. Makes a backup (just in case)
4. Extracts the app files
5. Applies the patches
6. Puts everything back together
7. Cleans up temporary files

**Your backup is saved** in case you need to restore the original.

---

## Backup Location

Your original JW Conf is backed up here:
```
C:\Users\[YourName]\AppData\Local\Programs\jw-conf\resources\backups\
```

The backup file name includes the date and time, like:
```
app.asar.backup-20260127-143022
```

---

## Questions?

**Q: Is this safe?**  
A: Yes! It makes a backup first, and you can always restore the original.

**Q: Will this break JW Conf?**  
A: No. Worst case, you restore the backup or reinstall.

**Q: Do I need to do this again after JW Conf updates?**  
A: Yes, if JW Conf releases a new version, you'll need to reapply the patches.

**Q: Can I share this with other people?**  
A: Yes! Just send them this whole folder.

---

*Installer created by: Community Contributors*  
*Last updated: January 27, 2026*
