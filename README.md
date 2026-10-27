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

Homebrew manages updates for this copy. Run:

```sh
brew update
brew upgrade
```

The tap follows stable releases. Drafts and prereleases are not installed.

## Requirements

- macOS 14.6 or later.
- Git must be installed.
- GitHub CLI is optional. Install it with `brew install gh`, then run `gh auth login` to use GitHub pull requests.
