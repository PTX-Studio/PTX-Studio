# Release Update Workflow

Use this process every time a new PTX Studio version is ready.

## 1. Build Outside This Repo

Build PTX Studio, PTX Editor Express, and PTX Editor Pro from the approved source environment. Do not build directly inside `Deployments`.

## 2. Sign Before Release

Windows `.exe` files should be Authenticode signed with a trusted code-signing certificate. macOS builds should be signed with an Apple Developer ID certificate and notarized. Linux builds generally do not need code signing in the same way, but checksums and provenance attestations should be published.

## 3. Copy Approved Artifacts Into Deployments

Copy only approved release artifacts into the deployment payload folder, which is the parent folder beside this Git repo:

- `..\ptx-download/studio/releases/vX.Y.Z/`
- `..\ptx-download/editor_express/releases/vX.Y.Z/`
- `..\ptx-download/modules/editor_pro/releases/vX.Y.Z/`

Then update the matching `latest` file only after the release is approved.

## 4. Update Metadata

Update:

- `ptx-download/manifest.json`
- `ptx-website-deployment/manifest.json`, if still used by the website
- `CHANGELOG.md`
- `release-notes/X.Y.Z.md`

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-release.ps1 -PayloadRoot ..
```

## 5. Review Git Changes

In GitHub Desktop:

1. Open `D:\Dev Folder\PTX Studio\Deployments`.
2. Review the changed files.
3. Confirm no binaries, secrets, caches, logs, or source files are staged.
4. Commit with a message like `Release metadata for 1.2.0`.
5. Push to GitHub.

## 6. Upload To R2

Follow `Deployment Rules.txt` and run the dry-run first:

```powershell
powershell -ExecutionPolicy Bypass -File ..\R2_UPLOAD_ACCESS\r2-dry-run.ps1
```

Only after reviewing the dry-run and approving the exact upload:

```powershell
powershell -ExecutionPolicy Bypass -File ..\R2_UPLOAD_ACCESS\r2-upload-approved.ps1 -Approved
```

## 7. Verify Public Release

Confirm:

- Public URLs download the intended files.
- File sizes match the approved local files.
- Website buttons point to the intended URLs.
- The manifest is reachable and correct.
- Windows Defender/SmartScreen behavior is tracked after signing.
