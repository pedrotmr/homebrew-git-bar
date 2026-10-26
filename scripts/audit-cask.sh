#!/usr/bin/env bash
set -euo pipefail

tap="pedrotmr/git-bar"
cask="Casks/pedrotmr-git-bar.rb"
if [[ ! -f "$cask" ]]; then
  echo "No installable cask exists until a signed and notarized Sparkle release is available."
  exit 0
fi

if ! brew tap | grep -Fxq "$tap"; then
  brew tap --custom-remote "$tap" "file://$PWD"
fi

tap_dir=$(brew --repository "$tap")
mkdir -p "$tap_dir/Casks"
cp "$cask" "$tap_dir/$cask"
brew audit --cask --strict --online --tap "$tap"
brew style --cask "$tap"
