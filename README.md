# 🍺 Homebrew tap for GitBar

Install the latest stable version of [GitBar](https://github.com/pedrotmr/git-bar) with Homebrew.

## 📦 Install

### Full command

```sh
brew install --cask pedrotmr/git-bar/pedrotmr-git-bar
```

### Tap once, then use the short command

```sh
brew tap pedrotmr/git-bar
brew install --cask pedrotmr-git-bar
```

## 🔄 Update

To update only GitBar:

```sh
brew update
brew upgrade --cask --greedy-auto-updates pedrotmr/git-bar/pedrotmr-git-bar
```

This tap follows stable releases. Drafts and prereleases are not installed.

## ⬇️ Direct download

1. Download the latest stable [DMG or ZIP](https://github.com/pedrotmr/git-bar/releases/latest).
2. Open the DMG or extract the ZIP.
3. Move `GitBar.app` to Applications.

To update a direct download, choose **Check for Updates…** in GitBar. Version 0.2.0 was the first Sparkle release. For a predictable upgrade from v0.1.x, install the current release manually once.

## ⚙️ Requirements

- macOS 14.6 or later and Git.
- GitHub CLI is optional. Install it with `brew install gh` and run `gh auth login` to use pull requests.

## Links

- 🐛 [Report a problem](https://github.com/pedrotmr/git-bar/issues)
- 📖 [GitBar README](https://github.com/pedrotmr/git-bar)
