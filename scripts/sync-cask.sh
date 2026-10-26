#!/usr/bin/env bash
set -euo pipefail

repo="pedrotmr/git-bar"
cask="Casks/pedrotmr-git-bar.rb"
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  work_dir="$RUNNER_TEMP/git-bar-cask-sync"
else
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/git-bar-cask-sync.XXXXXX")
fi
mkdir -p "$work_dir"
release_json="$work_dir/latest-release.json"
archive="$work_dir/GitBar-release.zip"
extract_dir="$work_dir/extracted"
appcast="$work_dir/appcast.xml"

curl --fail --silent --show-error --location \
  "https://api.github.com/repos/$repo/releases/latest" \
  --header 'Accept: application/vnd.github+json' \
  --header 'X-GitHub-Api-Version: 2022-11-28' \
  --output "$release_json"

tag_name=$(python3 - "$release_json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as release_file:
    release = json.load(release_file)
if release.get("draft") or release.get("prerelease"):
    raise SystemExit("GitHub latest endpoint returned a draft or prerelease")
print(release["tag_name"])
PY
)
if [[ ! "$tag_name" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "::error::Unexpected latest release tag: $tag_name"
  exit 1
fi
version=${tag_name#v}
asset_name="GitBar-$version.zip"
asset_url=$(python3 - "$release_json" "$asset_name" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as release_file:
    release = json.load(release_file)
asset = next((item for item in release["assets"] if item["name"] == sys.argv[2]), None)
print(asset["browser_download_url"] if asset else "")
PY
)
[[ -n "$asset_url" ]] || { echo "::error::Latest stable release is missing $asset_name."; exit 1; }

curl --fail --location --retry 3 --silent --show-error --output "$archive" "$asset_url"
rm -rf "$extract_dir"
mkdir -p "$extract_dir"
ditto -x -k "$archive" "$extract_dir"
app="$extract_dir/GitBar.app"
[[ -d "$app" ]] || { echo "::error::ZIP does not contain GitBar.app at its root."; exit 1; }

bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")
app_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
build_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Contents/Info.plist")
minimum_os=$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$app/Contents/Info.plist")
feed_url=$(/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$app/Contents/Info.plist" 2>/dev/null || true)
public_key=$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$app/Contents/Info.plist" 2>/dev/null || true)
[[ "$bundle_id" == "com.GitBar.app" ]] || { echo "::error::Unexpected bundle identifier: $bundle_id"; exit 1; }
[[ "$app_version" == "$version" ]] || { echo "::error::App version does not match $tag_name."; exit 1; }
[[ "$minimum_os" == "14.6" ]] || { echo "::error::Unexpected minimum macOS version: $minimum_os"; exit 1; }
[[ -s "$app/Contents/Resources/Assets.car" ]] || { echo "::error::The distributed app bundle is missing its compiled icon catalog."; exit 1; }

framework="$app/Contents/Frameworks/Sparkle.framework/Versions/B"
# Keep the tap unavailable until a stable release includes the real Sparkle updater.
if [[ ! -x "$framework/Sparkle" || \
  "$feed_url" != "https://github.com/pedrotmr/git-bar/releases/latest/download/appcast.xml" || \
  -z "$public_key" ]]; then
  echo "::notice::Latest stable release $version predates the stable Sparkle updater; no cask was created or changed."
  exit 0
fi

codesign --verify --deep --strict --verbose=2 "$app"
signature_details=$(codesign --display --verbose=4 "$app" 2>&1)
[[ "$signature_details" == *'Authority=Developer ID Application:'* ]] || { echo "::error::App is not signed with Developer ID Application."; exit 1; }
[[ "$signature_details" == *'TeamIdentifier=YW25U2BJ23'* ]] || { echo "::error::Unexpected Developer ID team."; exit 1; }
[[ "$signature_details" == *'Timestamp='* ]] || { echo "::error::App signature has no secure timestamp."; exit 1; }
[[ "$signature_details" == *'(runtime)'* ]] || { echo "::error::App signature does not enable hardened runtime."; exit 1; }
for binary in "$app/Contents/MacOS/GitBar" \
  "$framework/Sparkle" \
  "$framework/Autoupdate" \
  "$framework/Updater.app/Contents/MacOS/Updater"; do
  lipo -verify_arch arm64 "$binary"
  lipo -verify_arch x86_64 "$binary"
done
framework_root="$app/Contents/Frameworks/Sparkle.framework"
for component in "$framework/Autoupdate" "$framework/Updater.app" "$framework_root"; do
  codesign --verify --strict --verbose=2 "$component"
  component_signature=$(codesign --display --verbose=4 "$component" 2>&1)
  [[ "$component_signature" == *'Authority=Developer ID Application:'* && \
    "$component_signature" == *'TeamIdentifier=YW25U2BJ23'* && \
    "$component_signature" == *'Timestamp='* && "$component_signature" == *'(runtime)'* ]] || {
    echo "::error::Sparkle component has an unexpected or incomplete Developer ID signature: ${component##*/}"; exit 1;
  }
done
xcrun stapler validate "$app"
spctl --assess --type execute --verbose=2 "$app"

curl --fail --silent --show-error --location "$feed_url" --output "$appcast"
feed_version=$(/usr/bin/xmllint --xpath 'string((//*[local-name()="item"])[1]/*[local-name()="version"])' "$appcast")
feed_short_version=$(/usr/bin/xmllint --xpath 'string((//*[local-name()="item"])[1]/*[local-name()="shortVersionString"])' "$appcast")
feed_asset_url=$(/usr/bin/xmllint --xpath 'string((//*[local-name()="item"])[1]/*[local-name()="enclosure"]/@url)' "$appcast")
feed_length=$(/usr/bin/xmllint --xpath 'string((//*[local-name()="item"])[1]/*[local-name()="enclosure"]/@length)' "$appcast")
signature=$(/usr/bin/xmllint --xpath 'string(//*[local-name()="enclosure"]/@*[local-name()="edSignature"])' "$appcast")
[[ "$feed_version" == "$build_version" ]] || { echo "::error::Appcast build version does not match CFBundleVersion."; exit 1; }
[[ "$feed_short_version" == "$version" ]] || { echo "::error::Appcast marketing version does not match the release tag."; exit 1; }
[[ "$feed_asset_url" == "$asset_url" ]] || { echo "::error::Appcast does not point to the versioned release ZIP."; exit 1; }
[[ "$feed_length" == "$(stat -f%z "$archive")" ]] || { echo "::error::Appcast enclosure size does not match the ZIP."; exit 1; }
[[ -n "$signature" ]] || { echo "::error::Appcast enclosure has no EdDSA signature."; exit 1; }

sha256=$(shasum -a 256 "$archive" | awk '{print $1}')
mkdir -p "$(dirname "$cask")"
python3 - "$cask" "$version" "$sha256" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
version, sha256 = sys.argv[2:]
url = "https://github.com/pedrotmr/git-bar/releases/download/v#{version}/GitBar-#{version}.zip"
content = f'''cask "pedrotmr-git-bar" do
  version "{version}"
  sha256 "{sha256}"

  url "{url}"
  name "GitBar"
  desc "A macOS menu bar app for managing Git branches, worktrees, stashes, and GitHub pull requests."
  homepage "https://github.com/pedrotmr/git-bar"

  livecheck do
    url "https://github.com/pedrotmr/git-bar/releases/latest/download/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sonoma

  app "GitBar.app"

  postflight do
    system_command "/usr/bin/defaults", args: ["write", "com.GitBar.app.homebrew", "managedByHomebrew", "-bool", "true"]
  end

  uninstall_postflight do
    system_command "/usr/bin/defaults", args: ["delete", "com.GitBar.app.homebrew", "managedByHomebrew"], must_succeed: false
  end

  caveats <<~EOS
    Update with `brew update && brew upgrade`.
    The in-app updater is disabled for Homebrew installations.
  EOS
end
'''
path.write_text(content)
PY

echo "Verified $asset_name with SHA-256 $sha256."
