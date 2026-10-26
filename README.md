# GitBar Homebrew tap

This repository provides a Homebrew cask for [GitBar](https://github.com/pedrotmr/git-bar).

There is no cask yet. The GitBar app repository will create it after it publishes a signed, notarized stable release. That workflow checks the release ZIP, computes its SHA-256, runs Homebrew's strict audit, and pushes the cask here. Drafts and prereleases do not change this tap.

The app repository stores the fine-grained token for this tap. This repository does not need a cross-repository secret. Its CI audits the cask after each push.
