# GitHub Releases

GitHub releases are not stored as normal folders in the repo. They are published from Git tags and appear on the repository's Releases page.

For a visual explanation of how local folders differ from GitHub release containers, see [release-folder-model.md](release-folder-model.md).

## Recommended Customer-Facing Flow

1. Update `CHANGELOG.md`.
2. Add a release note file under `releases/`, for example `releases/v1.2.0.md`.
3. Commit the documentation changes.
4. Create a Git tag for the version.
5. Publish a GitHub Release from that tag.

## Version Naming

Use this format:

- Tag: `v1.2.0`
- Release title: `PTX Studio 1.2.0`
- Release note file: `releases/v1.2.0.md`

## What To Put In A GitHub Release

Public-safe:

- Product version
- Release date
- Customer-visible improvements
- Bug fixes
- Known issues
- Link to the official download page

Do not include:

- Server paths
- Bucket names
- Internal manifests
- Upload instructions
- Credentials or signing materials
- Private infrastructure details

## Creating The Release In GitHub Desktop And GitHub

GitHub Desktop handles commits and pushes. Tags and Releases are easiest from GitHub.com:

1. Push the latest `main` branch from GitHub Desktop.
2. Open the repository on GitHub.com.
3. Go to Releases.
4. Click Draft a new release.
5. Click Choose a tag and create a new tag like `v1.2.0`.
6. Set the release title to `PTX Studio 1.2.0`.
7. Paste the customer-facing notes from `releases/v1.2.0.md`.
8. Publish the release.
