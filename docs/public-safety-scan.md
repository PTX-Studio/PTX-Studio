# Public Safety Scan

This repository is customer-facing. The public safety scan blocks common mistakes before they reach GitHub.

It checks tracked files for:

- Local machine paths
- Internal deployment folder names
- Server/storage/tooling references
- Manifest/license filenames that belong outside this repo
- Credential-like words
- Binary or certificate file extensions

Run locally before pushing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\public-safety-scan.ps1
```

The same scan runs in GitHub Actions on pushes and pull requests.

