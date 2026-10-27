# GitBar Homebrew tap

This tap installs the latest stable version of [GitBar](https://github.com/pedrotmr/git-bar).

## Install

Use the full command:

```sh
brew install --cask pedrotmr/git-bar/pedrotmr-git-bar
```

Or add the tap once, then use its shorter cask name:

```sh
brew tap pedrotmr/git-bar
brew install --cask pedrotmr-git-bar
```

## Update

To update only GitBar, run:

```sh
brew update
brew upgrade --cask --greedy-auto-updates pedrotmr/git-bar/pedrotmr-git-bar
```

The tap follows stable releases. Drafts and prereleases are not installed.

## Direct download

Download the DMG or ZIP from the [latest stable release](https://github.com/pedrotmr/git-bar/releases/latest). Direct installs can update with **Check for Updates…** in GitBar. See the [app install guide](https://github.com/pedrotmr/git-bar#install-and-update).

## Requirements

- macOS 14.6 or later.
- Git must be installed.
- GitHub CLI is optional. Install it with `brew install gh`, then run `gh auth login` to use GitHub pull requests.
