# Super Simple Debugging Guide for Your Test Meeting

**For**: Someone who's never used DevTools Console before  
**Time needed**: 5 minutes to set up, then just watch during meeting  
**Difficulty**: Easy - just copy and paste!

---

## What We're Doing (In Simple Terms)

Think of DevTools Console like a "secret window" into JW Conf that shows you what's happening behind the scenes. We're going to:

1. Open this secret window
2. Copy some "spy code" into it
3. Let it watch for problems during your meeting
4. Look at what it found

**That's it!** No programming knowledge needed.

---

## Step 1: Open the "Secret Window" (DevTools Console)

### Super Easy Steps:

1. **Open JW Conf** on your Windows laptop
2. **Join your test meeting** (or create one)
3. **Press these 3 keys at the same time**: `Ctrl` + `Shift` + `I`
   - (That's Control, Shift, and the letter I)
4. A new panel will appear on the right side of your screen
5. **Click the "Console" tab** at the top of this panel

**What you'll see**: A white area with a blinking cursor and maybe some text

**Picture this**:
```
┌─────────────────┬──────────────────────┐
│                 │  ← DevTools Panel    │
│  JW Conf        │                      │
│  Meeting        │  Console  Elements   │
│  Window         │  ▼                   │
│                 │  >                   │
│                 │  (blinking cursor)   │
└─────────────────┴──────────────────────┘
```

---

## Step 2: Copy the "Spy Code"

### What to Do:

1. **Open this file on your computer**: `docs/ACTUAL_CODE_PATCHES.md`
2. **Find "Script 1: Audio Track State Monitor"**
3. **Copy everything in the gray box** (the code)
4. **Go back to JW Conf**
5. **Click in the Console** (where the blinking cursor is)
6. **Paste** (Ctrl+V)
7. **Press Enter**

**What you'll see**: Some text appears, then it says "undefined" - that's normal!

### Do This for All 5 Scripts:

Repeat the steps above for:
- Script 1: Audio Track State Monitor
- Script 2: Screen Share Audio Checker
- Script 3: Breakout Room Transition Monitor
- Script 4: Permission State Monitor
- Script 5: WebRTC Stats Monitor

**Don't worry if you don't understand the code** - you're just copying and pasting!

---

## Step 3: Use the Monitors During Your Meeting

### Script 1 & 4 & 5: Automatic Monitors

**These run by themselves!** Just let them work.

Every few seconds, they'll print information to the Console. You don't need to do anything.

**What to look for**: Lines that say "⚠️ BUG" or "ERROR" in red

---

### Script 2: Screen Share Audio Checker

**When to use**: When you're about to share your screen with audio

**What to do**:
1. Before clicking "Share Screen", the monitor is already watching
2. Click "Share Screen" and select "Share audio"
3. Look at the Console
4. **If you see**: "⚠️ BUG: AGC not disabled!" → That's the bug!
5. **If you see**: "AGC Disabled: true" → The patch is working!

---

### Script 3: Breakout Room Monitor

**When to use**: Before and after moving to a breakout room

**What to do**:

**BEFORE moving to breakout room**:
1. Click in the Console
2. Type: `saveAudioState()`
3. Press Enter
4. You'll see: "Saved: {muted: false, trackReady: 'live'}"

**AFTER arriving in breakout room**:
1. Click in the Console again
2. Type: `checkAudioState()`
3. Press Enter
4. **If you see red error messages** → That's the bug!
5. **If you see matching states** → No bug!

---

## Step 4: What to Look For (The Easy Version)

### Good Signs (No Bugs):
- ✅ Lots of text scrolling by (that's normal)
- ✅ "readyState: 'live'" (audio is working)
- ✅ "AGC Disabled: true" (patch working)
- ✅ Numbers increasing (bytes sent, packets sent)

### Bad Signs (Bugs Found!):
- ❌ Red text that says "ERROR" or "⚠️ BUG"
- ❌ "readyState: 'ended'" (audio track died)
- ❌ "AGC not disabled" (patch not working)
- ❌ "Mute state changed" (breakout room bug)

---

## Step 5: Save the Results

### Super Easy Way:

1. **After your meeting**, look at all the text in the Console
2. **Right-click anywhere in the Console**
3. **Click "Save as..."**
4. **Save it** to your Desktop as "jwconf-debug.txt"

**Or even easier**:
1. **Click in the Console**
2. **Press Ctrl+A** (selects all text)
3. **Press Ctrl+C** (copies it)
4. **Open Notepad**
5. **Press Ctrl+V** (pastes it)
6. **Save the file**

---

## Troubleshooting

### "I pressed Ctrl+Shift+I and nothing happened"

**Try this**:
1. Make sure JW Conf window is active (click on it)
2. Try again: Ctrl+Shift+I
3. Still nothing? Try: F12 key instead

### "I see lots of red text already"

**That's okay!** Some errors are normal. We're looking for specific ones that say:
- "⚠️ BUG: AGC not disabled"
- "⚠️ BUG: Mute state changed"
- "⚠️ BUG: Audio track"

### "The Console disappeared"

**Easy fix**:
1. Press Ctrl+Shift+I again to bring it back
2. Or press F12

### "I pasted the code but nothing happened"

**Did you press Enter?** After pasting, you need to press the Enter key.

---

## Quick Reference Card

**Print this out and keep it next to you during the test:**

```
┌─────────────────────────────────────────┐
│  JW CONF DEBUGGING QUICK REFERENCE      │
├─────────────────────────────────────────┤
│  1. Open Console: Ctrl+Shift+I          │
│  2. Click "Console" tab                 │
│  3. Paste all 5 scripts (Ctrl+V, Enter) │
│                                         │
│  DURING MEETING:                        │
│  - Just watch the Console               │
│  - Look for red "ERROR" or "⚠️ BUG"     │
│                                         │
│  BEFORE SCREEN SHARE:                   │
│  - Monitor is already watching          │
│  - Just share screen normally           │
│                                         │
│  BEFORE BREAKOUT ROOM:                  │
│  - Type: saveAudioState()               │
│  - Press Enter                          │
│                                         │
│  AFTER BREAKOUT ROOM:                   │
│  - Type: checkAudioState()              │
│  - Press Enter                          │
│                                         │
│  AFTER MEETING:                         │
│  - Ctrl+A, Ctrl+C to copy all           │
│  - Paste into Notepad and save          │
└─────────────────────────────────────────┘
```

---

## What Each Script Does (In Plain English)

### Script 1: Audio Track State Monitor
**What it does**: Checks every 5 seconds if your microphone is working  
**Why**: Catches when audio mysteriously stops working  
**You do**: Nothing, it runs automatically

### Script 2: Screen Share Audio Checker
**What it does**: Checks if the audio fix is applied when you share screen  
**Why**: Tells us if the patch is working  
**You do**: Nothing, it watches automatically

### Script 3: Breakout Room Monitor
**What it does**: Compares your audio state before and after moving rooms  
**Why**: Catches the breakout room bug  
**You do**: Type two commands (saveAudioState, checkAudioState)

### Script 4: Permission Monitor
**What it does**: Watches for permission changes  
**Why**: Catches moderator permission bugs  
**You do**: Nothing, it runs automatically

### Script 5: Stats Monitor
**What it does**: Shows audio quality numbers  
**Why**: Proves audio is actually being sent  
**You do**: Nothing, it runs automatically

---

## Example: What Success Looks Like

**You'll see text like this scrolling by** (this is GOOD):

```
Audio: {readyState: 'live', enabled: true, muted: false}
Audio: {readyState: 'live', enabled: true, muted: false}
Audio Stats: {bytesSent: 125000, packetsSent: 850}
Audio: {readyState: 'live', enabled: true, muted: false}
```

**If you see this, there's a BUG**:

```
⚠️ BUG: AGC not disabled for screen share!
⚠️ BUG: Mute state changed during transition!
Audio: {readyState: 'ended', enabled: false}  ← Audio died!
```

---

## Still Confused?

### Here's the Absolute Simplest Version:

1. **Open JW Conf**
2. **Press Ctrl+Shift+I**
3. **Click "Console"**
4. **Copy all the code from the document**
5. **Paste it in the Console**
6. **Press Enter**
7. **Have your meeting**
8. **Look for red text that says "BUG"**
9. **Copy everything and save it**

**That's it!** You're done!

---

## Need Help?

If you get stuck:
1. Take a screenshot of what you see
2. Send it to me
3. I'll help you figure it out

**Remember**: You can't break anything by doing this. The worst that happens is the scripts don't work, and you just close the Console and continue your meeting normally.

---

*Super Simple Guide created by: Community Contributors*  
*Last updated: January 27, 2026*  
*Tested with: People who've never used DevTools before*
