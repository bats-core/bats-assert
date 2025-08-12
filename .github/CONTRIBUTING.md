# Contributing

## Releasing

From a clean working copy, run `npm version major|minor|patch|VERSION`.
This will bump the package version, commit, tag, and push.
The tag-push event triggers the release workflow on GitHub.
The workflow creates a GitHub Release from the tag and publishes to npm.
