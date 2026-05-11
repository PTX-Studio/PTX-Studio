# Repository Policy

This repository is safe to make public only if it remains documentation and release-control focused.

## Allowed

- Public README, support, security, and changelog files
- Issue templates
- Release notes
- Manifest files that contain public download URLs
- No-secret R2 upload helper scripts and examples
- Operational release checklists

## Not Allowed

- PTX Studio application source code
- Built executables committed to Git
- Unpacked Electron directories
- Cloudflare account cache files
- Real R2 credentials, API tokens, signing certificates, or passwords
- License files or customer/user data
- Local logs

## Build Automation Boundary

GitHub-hosted runners can build Electron apps only if they can access source code. Because this repository must not contain source code, builds must use one of these patterns:

1. A separate private source repository checked out with a restricted token.
2. Self-hosted runners with approved local access to source.
3. Manual builds outside GitHub, followed by signed artifact upload from the deployment layer.

