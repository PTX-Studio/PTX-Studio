# PTX Studio Releases

This repository is the public release-control home for PTX Studio.

It is intentionally customer-facing and does not contain PTX Studio application source code. The repo is used for release notes, support policy, security policy, download metadata, issue routing, and operational release documentation.

## Current Products

- PTX Studio
- PTX Editor Express
- PTX Editor Pro

## Downloads

Current customer downloads are served from:

- https://download.ptxstudio.com/studio/latest/PTX%20Studio.exe
- https://download.ptxstudio.com/editor_express/latest/PTX%20Editor%20Express.exe
- https://download.ptxstudio.com/modules/editor_pro/latest/PTX%20Editor%20Pro.exe

The local download mirror lives outside this repository at `..\ptx-download`. Built executables and unpacked Electron output must stay out of Git and should be distributed through the approved download channel, not committed to this repository.

## Release Model

PTX Studio currently ships as portable standalone applications:

- No installer
- No extraction
- Download and launch

Before any public upload, follow [Deployment Rules.txt](Deployment%20Rules.txt) and [docs/release-update-workflow.md](docs/release-update-workflow.md).

## Source Code Policy

Application source code must remain outside this customer-facing repository. Build automation that needs source code must use a private source repository or a self-hosted runner with approved local source access.
