# Convert to WebP — macOS Quick Action

Right-click any image in Finder and convert it to WebP instantly.

- ✅ Resizes so the longest side is max **2300px** (preserves aspect ratio)
- ✅ Converts to **WebP at 90% quality**
- ✅ Works on single files or **bulk selections**
- ✅ Output saved **next to the original** file
- ✅ Supports JPG, JPEG, PNG, TIFF, BMP, **HEIC, HEIF**
- ✅ **macOS notification** when conversion completes
- ✅ Won't overwrite existing `.webp` files

---

## Install

Paste this into Terminal and hit Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/gabevirnig/convert-to-webp/main/install.sh | bash
```

> **That's it.** The script will install Homebrew (if needed), install the `cwebp` encoder, and set up the right-click menu action automatically.

---

## How to Use

1. Select one or more images in Finder
2. Right-click → **Quick Actions → Convert to WebP**
3. The `.webp` file appears next to the original
4. A notification confirms how many files were converted

![demo](demo.gif)

---

## Doesn't show up after install?

Relaunch Finder:

```bash
killall Finder
```

Or: hold **Option** and right-click the Finder icon in your Dock → **Relaunch**.

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/gabevirnig/convert-to-webp/main/uninstall.sh | bash
```

The uninstaller will also offer to remove `cwebp` if you no longer need it.

---

## What it does under the hood

- Uses [cwebp](https://developers.google.com/speed/webp/docs/cwebp) — Google's official WebP encoder
- Detects portrait vs landscape and resizes the longest side to 2300px max
- Images already under 2300px on their longest side are not upscaled
- HEIC/HEIF files are converted through macOS's built-in `sips` before encoding
- Creates an Automator Quick Action workflow at `~/Library/Services/`
- Works on both Apple Silicon (M1/M2/M3/M4) and Intel Macs

---

## Requirements

- macOS 12 Monterey or later (the installer will warn on older versions)
- Terminal access to run the one-line installer
- Internet connection (first-time install only)
