# Roameow

A little cat that roams your desktop.

## Requirements

macOS 12 Monterey or later (untested).

Tested on macOS 14 Sonoma and later.

## Installation

1. Download `Roameow.dmg` from the [latest release](https://github.com/Attacktive/Roameow/releases/latest).
2. Open the DMG and drag **Roameow.app** into your **Applications** folder.

## First launch (unsigned app)

macOS will block the app on first open because it isn't notarized. To get past it:

**Option A — right-click method**

Right-click `Roameow.app` in Finder and choose **Open**, then click **Open** in the dialog. You only need to do this once.

**Option B — terminal**

```bash
xattr -d com.apple.quarantine /Applications/Roameow.app
```

Then open it normally.

## Usage

Roameow lives in your menu bar. Click the icon to open settings — you can adjust size, speed, volume, and swap in a custom image or sound.

Click the cat on your desktop to hear it meow.
