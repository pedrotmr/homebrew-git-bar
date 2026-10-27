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
tap_modified=false
backup="$trust_config/previous-cask.rb"
cask_token="${tap}/$(basename "${cask}" .rb)"

cleanup() {
  local script_status=$?
  local cleanup_failed=false
  local preserve_backup=false
  trap - EXIT
  if [[ -n "$tap_dir" && "$tap_modified" == true ]]; then
    if [[ "$tap_had_cask" == true ]]; then
      if ! cp "$backup" "$tap_dir/$cask"; then
        echo "error: could not restore the previous cask. Backup retained at $backup" >&2
        cleanup_failed=true
        preserve_backup=true
      fi
    else
      if ! rm -f "$tap_dir/$cask"; then
        echo "error: could not remove the temporary cask from $tap_dir/$cask" >&2
        cleanup_failed=true
      fi
    fi
  fi
  if [[ "$tap_created" == true && "$preserve_backup" == false ]]; then
    if brew list --cask --versions "$cask_token" >/dev/null 2>&1; then
      echo "Leaving $tap tapped because $cask_token is installed; untapping could remove the app."
    elif ! brew untap "$tap" >/dev/null 2>&1; then
      echo "error: could not remove temporary tap $tap" >&2
      cleanup_failed=true
    fi
  fi
  if [[ "$preserve_backup" == true ]]; then
    echo "error: keep $trust_config until the cask is restored." >&2
  elif ! rm -rf "$trust_config"; then
    echo "error: could not remove temporary Homebrew config $trust_config" >&2
    cleanup_failed=true
  fi
  if [[ "$cleanup_failed" == true ]]; then
    exit 1
  fi
  exit "$script_status"
}
trap cleanup EXIT

if ! brew tap | grep -Fxq "$tap"; then
  brew tap --custom-remote "$tap" "file://$PWD"
  tap_created=true
fi

tap_dir=$(brew --repository "$tap")
mkdir -p "$tap_dir/Casks"
if [[ -f "$tap_dir/$cask" ]]; then
  if ! cp "$tap_dir/$cask" "$backup"; then
    echo "error: could not back up the installed cask." >&2
    exit 1
  fi
  tap_had_cask=true
fi
source_path="$(cd "$(dirname "$cask")" && pwd -P)/$(basename "$cask")"
destination_path="$(cd "$(dirname "$tap_dir/$cask")" && pwd -P)/$(basename "$tap_dir/$cask")"
if [[ "$source_path" != "$destination_path" ]]; then
  tap_modified=true
  cp "$cask" "$tap_dir/$cask"
fi
brew trust --cask "$cask_token"
brew audit --cask --strict --online "${cask_token}"
brew style --cask "${cask_token}"
