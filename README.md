<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/DeskPad/Assets.xcassets/AppIcon.appiconset/Icon-256.png">
  <img src="https://github.com/Stengo/DeskPad/blob/main/DeskPad/Assets.xcassets/AppIcon.appiconset/Icon-256.png?raw=true" alt="DeskPad Icon" width="128">
  </a>
</h3>

# DeskPad
A virtual monitor for screen sharing

<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/screenshot.jpg">
  <img src="https://github.com/Stengo/DeskPad/blob/main/screenshot.jpg?raw=true" alt="DeskPad Screenshot">
  </a>
</h3>

Certain workflows require sharing the entire screen (usually due to switching through multiple applications), but if the presenter has a much larger display than the audience it can be hard to see what is happening.

DeskPad creates a virtual display that is mirrored within its application window so that you can create a dedicated, easily shareable workspace.

# Installation
You can either download the [latest release binary](https://github.com/Stengo/DeskPad/releases) or install via [Homebrew](https://brew.sh) by calling `brew install --cask deskpad`.

## Build and install from source

Requires Xcode and [`just`](https://github.com/casey/just) (`brew install just`).

```sh
just build   # Build the complete Release app
just deploy  # Build and install /Applications/DeskPad.app
```

Quit DeskPad before deploying. Deployment replaces the app bundle's contents, including removing obsolete files, but does not launch the app or change its preferences.

Build output is `.build/Build/Products/Release/DeskPad.app`. The app is ad-hoc signed for local use, so no Apple Developer account is needed. Xcode defaults to `/Applications/Xcode.app`; set `DEVELOPER_DIR` if it is installed elsewhere. macOS may ask you to approve Screen Recording again for the locally signed build.

# Usage
DeskPad behaves like any other display. Launching the app is equivalent to plugging in a monitor, so macOS will take care of properly arranging your windows to their previous configuration.

You can change the display resolution through the system preferences and the application window will adjust accordingly.

Whenever you move your mouse cursor to the virtual display, DeskPad will highlight its title bar in blue and move the application window to the front to let you know where you are.

## Portrait orientation

The orientation and resolution controls are in **DeskPad's menu bar**, not the Rotation control in macOS Displays settings.

- **Display → Portrait Resolution** offers portrait desktops from 1080 × 1920 up to 3200 × 5120. Entries show their aspect ratio; **5:8 — DELL** identifies modes matching a portrait 1200 × 1920 DELL monitor.
- **Display → Landscape Resolution** offers the corresponding landscape sizes.
- **Display → Rotate 90°** (⌘R) swaps the current desktop's width and height.

These controls reconfigure the virtual monitor with a native 1× mode. The selected dimensions represent usable desktop space, rather than a Retina backing image at half the logical resolution. Text remains upright, the preview follows the aspect ratio, and the confirmed resolution is restored when DeskPad restarts.

### Mirror a high-resolution portrait desktop onto a physical monitor

1. In **System Settings → Displays**, set **DeskPad Display → Use as → Extended display** first.
2. Activate the DeskPad application and choose **Display → Portrait Resolution → 2400 × 3840**, or another desired size.
3. Return to Displays settings, select the physical portrait monitor (for example, DELL U2415), and set it to **Mirror for DeskPad Display**.
4. Set **Optimize for → DeskPad Display** so that the virtual desktop, rather than the physical monitor, determines the workspace resolution.

The direction matters: DeskPad must be the source and the physical monitor must be its mirror. If DeskPad is already mirroring another monitor, the app explains how to make it an extended source before changing its resolution. macOS can restrict modes in a mirror set; keep the set optimized for DeskPad, or disconnect mirroring before selecting another resolution.

### Full-screen mirroring on a 1200 × 1920 DELL

The DELL's portrait aspect ratio is **5:8**, not 9:16. Choose a mode labeled **5:8 — DELL** in **Display → Portrait Resolution** to match its full panel without aspect-ratio side bars.

| Portrait desktop | Scale relative to 1200 × 1920 |
| --- | --- |
| 1200 × 1920 | 1× |
| 1500 × 2400 | 1.25× |
| 1600 × 2560 | ≈1.33× |
| 1800 × 2880 | 1.5× |
| 2100 × 3360 | 1.75× |
| 2400 × 3840 | 2× |
| 2700 × 4320 | 2.25× |
| 3000 × 4800 | 2.5× |
| 3200 × 5120 | ≈2.67× |

Start with 1800 × 2880 for more workspace with less downscaling, or 2400 × 3840 for twice the workspace dimensions. All these modes have exactly the same aspect ratio. The largest, 3200 × 5120, reaches DeskPad's current 5120-pixel height limit.

The 9:16 modes remain available for other monitors. For example, 1080 × 1920, 2160 × 3840, and 2880 × 5120 are narrower than this DELL and can produce black bars on its sides when mirrored.

The physical monitor's pixel count does not increase. A 2400 × 3840 desktop mirrored onto a 1200 × 1920 panel is scaled down, providing more workspace with smaller text and controls. Screen Recording permission is needed for the live DeskPad preview; see Troubleshooting below.

These controls require a build containing this change. Quit other running copies of DeskPad before launching the local build; an older installed release does not gain the new menus automatically.

<h3 align="center">
  <a href="https://github.com/Stengo/DeskPad/blob/main/demonstration.gif">
  <img src="https://github.com/Stengo/DeskPad/blob/main/demonstration.gif?raw=true" alt="DeskPad Demonstration">
  </a>
</h3>

# Troubleshooting
DeskPad may need screen recording permissions to display properly. Follow these steps:

1. **Open System Settings** → **Privacy & Security** → **Screen Recording**
2. **Enable DeskPad** by checking the box next to it
3. **If DeskPad appears but isn't working:**
   - Uncheck the DeskPad option
   - Check it again to re-enable
4. **Restart DeskPad** for changes to take effect
