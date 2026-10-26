#!/usr/bin/env bash
set -euo pipefail

tap="pedrotmr/git-bar"
cask="Casks/pedrotmr-git-bar.rb"
if [[ ! -f "$cask" ]]; then
  echo "No installable cask exists until a signed and notarized Sparkle release is available."
  exit 0
fi

trust_config=$(mktemp -d)
export XDG_CONFIG_HOME="$trust_config"
export HOMEBREW_NO_AUTO_UPDATE=1
tap_dir=""
tap_created=false
tap_had_cask=false
backup="$trust_config/previous-cask.rb"

cleanup() {
  set +e
  if [[ -n "$tap_dir" ]]; then
    if [[ "$tap_had_cask" == true ]]; then
      cp "$backup" "$tap_dir/$cask"
    else
      rm -f "$tap_dir/$cask"
    fi
  fi
  if [[ "$tap_created" == true ]]; then
    brew untap --force "$tap" >/dev/null 2>&1
  fi
  rm -rf "$trust_config"
}
trap cleanup EXIT

if ! brew tap | grep -Fxq "$tap"; then
  brew tap --custom-remote "$tap" "file://$PWD"
  tap_created=true
fi

tap_dir=$(brew --repository "$tap")
mkdir -p "$tap_dir/Casks"
if [[ -f "$tap_dir/$cask" ]]; then
  cp "$tap_dir/$cask" "$backup"
  tap_had_cask=true
fi
cp "$cask" "$tap_dir/$cask"
cask_token="${tap}/$(basename "${cask}" .rb)"
brew trust --cask "$cask_token"
brew audit --cask --strict --online "${cask_token}"
brew style --cask "${cask_token}"
