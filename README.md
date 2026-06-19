# Roameow

A little cat that roams your desktop.

## Requirements

macOS 12 Monterey or later (untested).

Tested on macOS 14 Sonoma and later.

## Installation

1. Download `Roameow.dmg` from the [latest release](https://github.com/Attacktive/Roameow/releases/latest).
2. Open the DMG and drag **Roameow.app** into your **Applications** folder.

## First launch (unsigned app)

Roameow isn't notarized (no paid Apple Developer account), so macOS Gatekeeper blocks it the first time you open it. You only need to clear it once.

**Option A — System Settings (macOS 15 Sequoia and later)**

1. Double-click **Roameow.app**. macOS refuses to open it — click **Done**.
2. Open **System Settings → Privacy & Security**, scroll down to the **Security** section, and click **Open Anyway** next to the message about Roameow.
3. Authenticate with Touch ID or your password, then click **Open Anyway** once more to confirm.

> On macOS 14 Sonoma and earlier you could instead right-click **Roameow.app** in Finder and choose **Open**. Apple removed that Control-click shortcut for unsigned apps in macOS 15, so it no longer works on current macOS.

**Option B — Terminal (works on every version)**

```bash
xattr -dr com.apple.quarantine /Applications/Roameow.app
```

Then open Roameow normally.

## Usage

Roameow lives in your menu bar. Click the icon to open settings — you can adjust size, speed, volume, and swap in a custom image or sound.

Click the cat on your desktop to hear it meow.
