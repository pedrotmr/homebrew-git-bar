cask "pedrotmr-git-bar" do
  version "0.2.1"
  sha256 "2c6e7f0e5fa32d98e70b192678ab334dc7bcbb22ebe5797d793f0eb72e05b5af"

  url "https://github.com/pedrotmr/git-bar/releases/download/v#{version}/GitBar-#{version}.zip"
  name "GitBar"
  desc "Manage Git branches, worktrees, stashes, and pull requests"
  homepage "https://github.com/pedrotmr/git-bar"

  livecheck do
    url "https://github.com/pedrotmr/git-bar/releases/latest/download/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on macos: :sonoma

  app "GitBar.app"

  preflight_steps do
    run "/usr/bin/osascript",
        args: [
          "-e",
          "set osVersion to system version of (system info)",
          "-e",
          "considering numeric strings",
          "-e",
          "if osVersion < \"14.6\" then error \"Requires macOS 14.6 or later.\" number 1",
          "-e",
          "end considering",
        ]
  end

  postflight_steps do
    run "/usr/bin/defaults",
        args:           [
          "write",
          "com.GitBar.app.homebrew",
          "managedByHomebrew",
          "-bool",
          "true",
        ],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
    run "/usr/bin/defaults",
        args:           [
          "write",
          "com.GitBar.app.homebrew",
          "managedByHomebrewVersion",
          "-string",
          "0.2.1",
        ],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
    run "/usr/bin/defaults",
        args:           [
          "write",
          "com.GitBar.app.homebrew",
          "managedByHomebrewBundlePath",
          "-string",
          "{{appdir}}/GitBar.app",
        ],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
  end

  uninstall_postflight_steps do
    run "/usr/bin/defaults",
        args:           [
          "delete",
          "com.GitBar.app.homebrew",
          "managedByHomebrew",
        ],
        must_succeed:   false,
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
    run "/usr/bin/defaults",
        args:           [
          "delete",
          "com.GitBar.app.homebrew",
          "managedByHomebrewBundlePath",
        ],
        must_succeed:   false,
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
    run "/usr/bin/defaults",
        args:           [
          "delete",
          "com.GitBar.app.homebrew",
          "managedByHomebrewVersion",
        ],
        must_succeed:   false,
        writable_paths: ["Library/Preferences"],
        writable_base:  :home
  end
end
