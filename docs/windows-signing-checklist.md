# Windows Signing Checklist

Use this checklist before publishing PTX Studio Windows `.exe` assets.

## Trust Layers

There are three separate layers:

```text
Self-signed certificate
Internal pipeline test only
Does not create public customer trust
```

```text
Authenticode signing with trusted certificate or managed signing service
Windows publisher identity and SmartScreen reputation path
Required for customer trust
```

```text
GitHub tag/signing/attestation
Release provenance
Does not replace Authenticode
```

## Release Order

For each product:

1. Build the final `.exe`.
2. Sign the `.exe`.
3. Verify the signature.
4. Generate SHA256 checksum from the signed `.exe`.
5. Update the release checksum file.
6. Upload the signed `.exe` to the GitHub Release page.
7. Download the uploaded asset once and verify size/checksum.

## PTX Studio v1.1.0 Files

Current public Windows release files:

```text
PTX Studio.exe
PTX Editor Express.exe
PTX Editor Pro.exe
```

## SignTool Command Shape

Final certificate-backed signing generally looks like:

```powershell
signtool sign /fd SHA256 /tr "http://timestamp.digicert.com" /td SHA256 /a "PTX Studio.exe"
signtool verify /pa /v "PTX Studio.exe"
```

Use the timestamp URL and certificate selection required by the final certificate authority or managed signing provider.

## Self-Signed Test Rule

Self-signing is allowed only as a test.

Do not publish self-signed executables as the final customer trust solution unless there is a deliberate temporary release decision and the release notes/support material account for possible Windows warnings.

## Checksum Rule

Checksums must be regenerated after signing.

Signing changes the executable file, so old checksums no longer match after a signature is applied.

