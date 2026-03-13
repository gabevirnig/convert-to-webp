#!/bin/bash

# =============================================================================
# install.sh — Convert to WebP · macOS Finder Quick Action Installer
#
# What this does:
#   1. Checks macOS compatibility
#   2. Installs Homebrew (if needed)
#   3. Installs cwebp — Google's WebP encoder (if needed)
#   4. Builds and installs an Automator Quick Action
#   5. Right-click any image(s) in Finder → Quick Actions → Convert to WebP
#
# Settings:
#   - Max dimension: 2300px (longest side, preserves aspect ratio)
#   - Quality: 90%
#   - Output: .webp file placed next to the original
#   - Supports: JPG, JPEG, PNG, TIFF, BMP, HEIC, HEIF (single or bulk)
# =============================================================================

set -e

ACTION_NAME="Convert to WebP"
SERVICE_DIR="$HOME/Library/Services"
WORKFLOW_PATH="$SERVICE_DIR/$ACTION_NAME.workflow"
CONTENTS_DIR="$WORKFLOW_PATH/Contents"

echo ""
echo "▶  Convert to WebP — Quick Action Installer"
echo "============================================="

# ── Step 0: macOS check ───────────────────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
  echo "✖ This installer is for macOS only."
  exit 1
fi

MAC_VERSION="$(sw_vers -productVersion)"
MAC_MAJOR="$(echo "$MAC_VERSION" | cut -d. -f1)"

if [[ "$MAC_MAJOR" -lt 12 ]]; then
  echo "⚠ macOS 12 Monterey or later is recommended (you have $MAC_VERSION)."
  echo "  The installer will continue, but the Quick Action may not work."
fi

echo "✓ macOS $MAC_VERSION"

# ── Step 1: Homebrew ──────────────────────────────────────────────────────────

if ! command -v brew &>/dev/null; then
  echo "→ Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add to PATH for this session (handles Apple Silicon + Intel)
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # Verify it actually worked
  if ! command -v brew &>/dev/null; then
    echo "✖ Homebrew installation failed. Please install manually:"
    echo "  https://brew.sh"
    exit 1
  fi

  echo "✓ Homebrew installed"
else
  echo "✓ Homebrew already installed"
fi

# ── Step 2: cwebp ─────────────────────────────────────────────────────────────

if ! command -v cwebp &>/dev/null; then
  echo "→ Installing webp tools via Homebrew..."
  brew install webp
  echo "✓ cwebp installed"
else
  echo "✓ cwebp already installed"
fi

# Resolve full path (critical — Automator does not inherit $PATH)
CWEBP_PATH="$(command -v cwebp)"

if [[ ! -x "$CWEBP_PATH" ]]; then
  echo "✖ Could not locate cwebp binary. Install may have failed."
  exit 1
fi

echo "✓ cwebp path: $CWEBP_PATH"

# ── Step 3: Build the Automator Quick Action ──────────────────────────────────

echo "→ Building Automator Quick Action..."

# Remove old version if present, start clean
rm -rf "$WORKFLOW_PATH"
mkdir -p "$CONTENTS_DIR"

# ── Info.plist ────────────────────────────────────────────────────────────────
# Registers this action in Finder's right-click menu for image files only

cat > "$CONTENTS_DIR/Info.plist" << 'INFOPLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSBackgroundColorName</key>
			<string>background</string>
			<key>NSIconName</key>
			<string>NSActionTemplate</string>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>Convert to WebP</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSRequiredContext</key>
			<dict>
				<key>NSApplicationIdentifier</key>
				<string>com.apple.finder</string>
			</dict>
			<key>NSSendFileTypes</key>
			<array>
				<string>public.image</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
INFOPLIST

# ── document.wflow ────────────────────────────────────────────────────────────
# The Automator workflow XML.
# - CWEBP_PATH is injected here at install time (avoids PATH issues in Automator)
# - Shell variables inside the script are escaped (\$) so the outer heredoc
#   doesn't expand them — they expand at runtime inside Automator instead
# - &amp; is required XML escaping for & (used in &>/dev/null)

cat > "$CONTENTS_DIR/document.wflow" << WFLOW
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>526</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMApplication</key>
				<array>
					<string>Automator</string>
				</array>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>#!/bin/bash

CWEBP="$CWEBP_PATH"
MAX_SIZE=2300
QUALITY=90
CONVERTED=0
SKIPPED=0

# Create a timestamped output folder (one folder per batch)
# Format: webp_2026-03-12_21-34-47
TIMESTAMP=\$(date +"%Y-%m-%d_%H-%M-%S")
FIRST_DIR=\$(dirname "\$1")
WEBP_DIR="\$FIRST_DIR/webp_\$TIMESTAMP"
mkdir -p "\$WEBP_DIR"

for FILE in "\$@"; do

  # Normalize extension to lowercase for matching
  EXT=\$(echo "\${FILE##*.}" | tr '[:upper:]' '[:lower:]')

  # Skip non-image extensions
  case "\$EXT" in
    jpg|jpeg|png|tiff|tif|bmp|heic|heif) ;;
    *) SKIPPED=\$((SKIPPED + 1)); continue ;;
  esac

  # Skip files already prefixed with Unoptimized_
  BASENAME=\$(basename "\$FILE")
  if [[ "\$BASENAME" == Unoptimized_* ]]; then
    SKIPPED=\$((SKIPPED + 1))
    continue
  fi

  # HEIC/HEIF: convert to temporary PNG first (sips handles Apple's format natively)
  if [[ "\$EXT" == "heic" || "\$EXT" == "heif" ]]; then
    TMP_FILE="\${FILE%.*}_tmp_\$\$.png"
    sips -s format png "\$FILE" --out "\$TMP_FILE" &amp;>/dev/null || { SKIPPED=\$((SKIPPED + 1)); continue; }
    INPUT="\$TMP_FILE"
  else
    INPUT="\$FILE"
    TMP_FILE=""
  fi

  # Read pixel dimensions via sips (built into macOS, no extra dependency)
  WIDTH=\$(sips -g pixelWidth "\$INPUT" 2>/dev/null | awk '/pixelWidth/{print \$2}')
  HEIGHT=\$(sips -g pixelHeight "\$INPUT" 2>/dev/null | awk '/pixelHeight/{print \$2}')

  # Guard: skip if dimensions couldn't be read (corrupt file, permissions, etc.)
  if [[ -z "\$WIDTH" || -z "\$HEIGHT" || "\$WIDTH" -eq 0 || "\$HEIGHT" -eq 0 ]]; then
    [[ -n "\$TMP_FILE" ]] &amp;&amp; rm -f "\$TMP_FILE"
    SKIPPED=\$((SKIPPED + 1))
    continue
  fi

  # Determine resize flag: cap the longest side, let cwebp auto-calc the other
  if [ "\$WIDTH" -ge "\$HEIGHT" ]; then
    if [ "\$WIDTH" -gt "\$MAX_SIZE" ]; then
      RESIZE="-resize \$MAX_SIZE 0"
    else
      RESIZE=""
    fi
  else
    if [ "\$HEIGHT" -gt "\$MAX_SIZE" ]; then
      RESIZE="-resize 0 \$MAX_SIZE"
    else
      RESIZE=""
    fi
  fi

  # Output: same base name with .webp extension, inside the timestamped folder
  NAMEONLY=\$(basename "\${FILE%.*}")
  OUTPUT="\$WEBP_DIR/\$NAMEONLY.webp"

  # Convert (suppress cwebp stdout/stderr)
  if "\$CWEBP" -q "\$QUALITY" \$RESIZE "\$INPUT" -o "\$OUTPUT" &amp;>/dev/null; then
    CONVERTED=\$((CONVERTED + 1))

    # Rename original file with Unoptimized_ prefix
    DIR=\$(dirname "\$FILE")
    mv "\$FILE" "\$DIR/Unoptimized_\$BASENAME"
  else
    SKIPPED=\$((SKIPPED + 1))
  fi

  # Clean up temp file from HEIC conversion
  [[ -n "\$TMP_FILE" ]] &amp;&amp; rm -f "\$TMP_FILE"

done

# Remove the folder if nothing was converted (clean up empty dirs)
if [[ "\$CONVERTED" -eq 0 ]]; then
  rmdir "\$WEBP_DIR" 2>/dev/null || true
fi

# macOS notification with summary
if [[ "\$CONVERTED" -gt 0 ]]; then
  osascript -e "display notification \"Converted \$CONVERTED file(s) to WebP\" with title \"Convert to WebP\" sound name \"Glass\"" 2>/dev/null || true
fi
</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>1</integer>
					<key>shell</key>
					<string>/bin/bash</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>CanShowSelectedItemsWhenRun</key>
				<false/>
				<key>CanShowWhenRun</key>
				<true/>
				<key>Category</key>
				<array>
					<string>AMCategoryUtilities</string>
				</array>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>CB33A553-16C6-44C0-9CA1-D9A8F7A0CDD0</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>8A2E27F2-CE9D-4B7E-81B6-F84298673E8A</string>
				<key>UUID</key>
				<string>9C1827BA-904D-4D87-8B73-FE0633D133AD</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<false/>
						<key>name</key>
						<string>CheckedForUserDefaultShell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>source</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
					<key>3</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>3</string>
					</dict>
					<key>4</key>
					<dict>
						<key>default value</key>
						<string>/bin/sh</string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>4</string>
					</dict>
				</dict>
				<key>conversionLabel</key>
				<integer>0</integer>
				<key>isViewVisible</key>
				<integer>1</integer>
				<key>location</key>
				<string>301.500000:828.000000</string>
				<key>nibPath</key>
				<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
			</dict>
			<key>isViewVisible</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>applicationBundleID</key>
		<string>com.apple.finder</string>
		<key>applicationBundleIDsByPath</key>
		<dict>
			<key>/System/Library/CoreServices/Finder.app</key>
			<string>com.apple.finder</string>
		</dict>
		<key>applicationPath</key>
		<string>/System/Library/CoreServices/Finder.app</string>
		<key>applicationPaths</key>
		<array>
			<string>/System/Library/CoreServices/Finder.app</string>
		</array>
		<key>inputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject.image</string>
		<key>outputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>presentationMode</key>
		<integer>15</integer>
		<key>processesInput</key>
		<false/>
		<key>serviceApplicationBundleID</key>
		<string>com.apple.finder</string>
		<key>serviceApplicationPath</key>
		<string>/System/Library/CoreServices/Finder.app</string>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.fileSystemObject.image</string>
		<key>serviceOutputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>serviceProcessesInput</key>
		<false/>
		<key>systemImageName</key>
		<string>NSActionTemplate</string>
		<key>useAutomaticInputType</key>
		<false/>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
WFLOW

# ── Step 4: Register with macOS ───────────────────────────────────────────────

echo "→ Registering with macOS Services..."

# pbs handles the Services menu
/System/Library/CoreServices/pbs -update 2>/dev/null || true

# lsregister helps macOS recognize the workflow bundle
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$WORKFLOW_PATH" 2>/dev/null || true

echo ""
echo "============================================="
echo "✅ Done! 'Convert to WebP' is installed."
echo ""
echo "HOW TO USE:"
echo "  1. Select one or more images in Finder"
echo "  2. Right-click → Quick Actions → 'Convert to WebP'"
echo "  3. The .webp file appears next to each original"
echo ""
echo "If the option doesn't appear right away, relaunch Finder:"
echo "  killall Finder"
echo "============================================="
echo ""
