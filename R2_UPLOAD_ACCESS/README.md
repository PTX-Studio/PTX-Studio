# PTX Studio R2 Upload Access

Last updated: 2026-05-09

This folder contains the safe local workflow for uploading PTX Studio release downloads to Cloudflare R2.

It does not contain real credentials.

Current local status:

- `rclone` is installed and validated locally at version `1.74.1`.
- The helper scripts can find `rclone` from PATH or the Windows winget package location.
- The Cloudflare R2 token still needs to be created or pasted into the one-time config helper before bucket validation can complete.

---

## Purpose

Cloudflare dashboard uploads are limited for large files. PTX Studio release files can exceed that limit, so large release uploads should use Cloudflare R2's S3-compatible API through `rclone`.

The upload source is always:

`D:\Dev Folder\PTX Studio\Deployments\ptx-download`

The upload target is:

`Cloudflare R2 bucket: ptx-downloads`

---

## Known Cloudflare R2 Values

Use these values when configuring `rclone`:

```text
Remote name: ptx-r2
Provider: Cloudflare
Bucket: ptx-downloads
Account ID: c173b6f9e101745fc4eab43fa68f1721
Endpoint: https://c173b6f9e101745fc4eab43fa68f1721.r2.cloudflarestorage.com
Region/location: auto
ACL: private
```

The public download URLs remain under:

```text
https://download.ptxstudio.com/
```

---

## Required Cloudflare Token

Create the token in Cloudflare:

1. Open Cloudflare Dashboard.
2. Go to R2 Object Storage.
3. Open Account Details.
4. Click Manage API Tokens.
5. Create an Account API token.
6. Name it `PTX R2 Upload Token`.
7. Permission: `Object Read & Write`.
8. Scope: specific bucket only.
9. Bucket: `ptx-downloads`.
10. TTL: `Forever` or a founder-approved expiration.
11. Client IP filtering: optional.

Copy the Access Key ID and Secret Access Key immediately. The secret cannot be viewed again later.

Do not paste the credentials into this folder.

---

## Install rclone

Check whether `rclone` exists:

```powershell
rclone version
```

If it is not installed, install it from:

```text
https://rclone.org/downloads/
```

or with a package manager if Mario approves that approach.

---

## Configure rclone

Preferred setup helper:

```powershell
Set-Location "D:\Dev Folder\PTX Studio\Deployments"
.\R2_UPLOAD_ACCESS\r2-configure-remote.ps1
```

Paste the Cloudflare R2 Access Key ID and Secret Access Key when prompted.

The helper writes credentials only to rclone's normal user config location:

```text
C:\Users\mario\AppData\Roaming\rclone\rclone.conf
```

The helper validates the scoped bucket directly with:

```powershell
rclone lsf ptx-r2:ptx-downloads --max-depth 1
```

This matters because a bucket-scoped token may not be allowed to list every bucket in the Cloudflare account.

Manual setup option:

```powershell
rclone config
```

Create a new remote:

```text
n) New remote
name> ptx-r2
Storage> s3
provider> Cloudflare
access_key_id> paste Access Key ID
secret_access_key> paste Secret Access Key
endpoint> https://c173b6f9e101745fc4eab43fa68f1721.r2.cloudflarestorage.com
region> auto
acl> private
```

If your `rclone` version asks different questions, use the values in `rclone.conf.example` as the reference.

After setup, verify:

```powershell
rclone lsf ptx-r2:ptx-downloads
```

---

## Dry Run First

### GUI Option

For the simplest workflow, open:

```text
D:\Dev Folder\PTX Studio\Deployments\R2_UPLOAD_ACCESS\Open R2 Upload GUI.cmd
```

Use the GUI buttons in this order for normal releases:

1. `Routine Dry-Run`
2. Review the output and latest log in the GUI.
3. `Routine Upload` only after the dry-run looks correct.
4. Verify the live download URLs.

Routine mode uploads:

- `manifest.json`
- all `latest/` folders
- any local `releases/` version folder that is missing remotely

Routine mode force-refreshes `manifest.json` and `latest/` with `rclone --ignore-times`, so those live files are uploaded/updated even when matching remote objects already exist.

Routine mode skips release/version folders that already exist in R2. This preserves archive history and avoids unnecessary archive overwrites.

Routine mode also treats version folder names with and without a leading `v` as the same release version for duplicate prevention. For example, if local has `v1.2.0` but R2 already has `1.2.0`, routine mode skips the upload and reports the alternate remote path instead of creating another archive folder.

Routine mode checks for actual objects under a release prefix, not just an empty R2 folder marker. This prevents empty or partially deleted remote prefixes from being mistaken for complete release archives.

The GUI also has full mirror buttons for rare intentional full uploads. Full mirror mode copies the entire local `ptx-download` mirror but still does not delete remote files.

### PowerShell Option

Normal release workflow:

```powershell
Set-Location "D:\Dev Folder\PTX Studio\Deployments"
.\R2_UPLOAD_ACCESS\r2-routine-dry-run.ps1
```

Review the output carefully.

If approved:

```powershell
.\R2_UPLOAD_ACCESS\r2-routine-upload-approved.ps1 -Approved
```

Full mirror workflow, only when intentionally needed:

```powershell
Set-Location "D:\Dev Folder\PTX Studio\Deployments"
.\R2_UPLOAD_ACCESS\r2-dry-run.ps1
```

The dry-run should show what would upload or update, without changing R2.

If the dry-run reports that the `ptx-r2` remote is missing, run `r2-configure-remote.ps1` first.

---

## Approved Upload

Only after Mario approves a full mirror dry-run:

```powershell
Set-Location "D:\Dev Folder\PTX Studio\Deployments"
.\R2_UPLOAD_ACCESS\r2-upload-approved.ps1 -Approved
```

This uses `rclone copy`, not `rclone sync`.

That means it uploads new or changed files but does not delete remote files.

---

## Verification After Upload

After upload, verify:

```powershell
rclone lsf ptx-r2:ptx-downloads
```

Then test the public URLs in a browser:

```text
https://download.ptxstudio.com/manifest.json
https://download.ptxstudio.com/studio/latest/PTX%20Studio.exe
https://download.ptxstudio.com/editor_express/latest/PTX%20Editor%20Express.exe
https://download.ptxstudio.com/modules/editor_pro/latest/PTX%20Editor%20Pro.exe
```

Verify:

- URL resolves.
- File downloads.
- File size looks correct.
- Website links point to the intended objects.
- The downloaded `.exe` launches locally.

---

## Safety Rules

- Never upload from a dev environment.
- Never upload from `RAW`.
- Never use `rclone sync` until the workflow has been proven and Mario approves delete behavior.
- Never store real credentials in this folder.
- Always dry-run first.
- Always review changed files before upload.
- Always verify live URLs after upload.
