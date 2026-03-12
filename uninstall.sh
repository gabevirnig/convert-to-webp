#!/bin/bash

# =============================================================================
# uninstall.sh — Remove the Convert to WebP Quick Action
# =============================================================================

ACTION_NAME="Convert to WebP"
WORKFLOW_PATH="$HOME/Library/Services/$ACTION_NAME.workflow"

echo ""
echo "▶ Convert to WebP — Uninstaller"
echo "================================"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "✖ This uninstaller is for macOS only."
  exit 1
fi

if [ -d "$WORKFLOW_PATH" ]; then
  rm -rf "$WORKFLOW_PATH"
  /System/Library/CoreServices/pbs -update 2>/dev/null || true
  echo "✅ Quick Action removed successfully."
else
  echo "ℹ️  Quick Action not found — nothing to remove."
fi

# Offer to remove cwebp (optional — other tools may depend on it)
if command -v cwebp &>/dev/null; then
  echo ""
  read -r -p "→ Also uninstall cwebp via Homebrew? (y/N) " REPLY
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    brew uninstall webp 2>/dev/null && echo "✅ cwebp removed." || echo "⚠ Could not remove cwebp."
  else
    echo "  Keeping cwebp installed."
  fi
fi

echo ""
