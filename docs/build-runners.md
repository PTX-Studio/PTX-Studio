# Linux, macOS, and Windows Build Runners

PTX Studio is Electron-based, so GitHub Actions can build Windows, macOS, and Linux artifacts. The important boundary is that this customer-facing repository must not contain source code.

## Recommended Structure

- Public repo: this repository, release metadata and customer-facing support only.
- Private source repo: application source for PTX Studio, PTX Editor Express, and PTX Editor Pro.
- GitHub Actions: build from the private source repo, upload artifacts, and generate provenance attestations.

## Runner Matrix

Use:

- `windows-latest` for Windows `.exe`
- `macos-latest` or `macos-14` for macOS `.dmg`/`.zip`
- `ubuntu-latest` for Linux `.AppImage`, `.deb`, or `.rpm`

The template workflow is stored at:

`.github/workflows/build-electron-suite.template.yml`

It is intentionally named `.template.yml` so it does not run until the private source repository, secrets, and build scripts are confirmed.

## Required GitHub Secrets

Set these in GitHub repository settings:

- `PTX_SOURCE_REPOSITORY`: private source repo, for example `OWNER/PRIVATE_REPO`
- `PTX_SOURCE_REPOSITORY_TOKEN`: fine-grained token with read-only source access

For signing, add only after the signing process is finalized:

- Windows certificate secret or external signing service credentials
- Apple Developer ID certificate and app-specific password or API key
- Notarization credentials for macOS

## Electron Build Expectations

The private source repo should expose stable scripts such as:

```json
{
  "scripts": {
    "build:studio": "electron-builder --config electron-builder.studio.yml",
    "build:editor_express": "electron-builder --config electron-builder.editor-express.yml",
    "build:editor_pro": "electron-builder --config electron-builder.editor-pro.yml"
  }
}
```

Use a single artifact directory such as `dist/` so Actions can upload release files consistently.

