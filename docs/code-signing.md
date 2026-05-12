# Code Signing And Trust Plan

Code signing and GitHub artifact signing solve different trust problems.

## Important Distinction

Self-signing is useful for internal testing, but it does not create public Windows trust.

For customer downloads, Windows trust requires Authenticode signing with a certificate that chains to a trusted certificate authority or a trusted managed signing service. GitHub signing and attestations can help prove repository/build provenance, but they do not replace Windows Authenticode signing.

The recommended order is:

1. Build the executable.
2. Sign the executable.
3. Verify the executable signature.
4. Generate checksums from the signed executable.
5. Upload the signed executable as a GitHub Release asset.

## Windows

Windows Defender and SmartScreen trust primarily improves through:

- Authenticode signing with a trusted code-signing certificate
- Consistent publisher identity
- Reputation over time
- Clean malware scan history
- Avoiding unsigned or frequently changing installer behavior

An Extended Validation code-signing certificate can improve initial SmartScreen reputation faster, but it is more expensive and requires stricter identity validation. A standard organization validation certificate is still useful and is usually the starting point.

Recommended Windows command shape:

```powershell
signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /a "PTX Studio.exe"
signtool verify /pa /v "PTX Studio.exe"
```

Use the timestamp URL required by the certificate authority if different.

## Self-Signed Windows Certificates

Self-signed certificates are appropriate only for private/internal validation.

They can confirm that the signing pipeline works, but normal customer machines will not automatically trust them. A self-signed executable can still show Windows Defender or SmartScreen warnings.

Use self-signing only for:

- Testing the signing command shape.
- Verifying Electron executables survive signing.
- Practicing the sign, verify, checksum, upload order.

Do not treat self-signing as the final customer trust solution.

## Microsoft Trusted Signing / Azure Artifact Signing

Microsoft's managed signing service can sign Windows artifacts without storing a private code-signing key locally. This is the cleaner long-term route if you want cloud-based signing in a GitHub Actions workflow or a controlled release process.

That flow is separate from GitHub Release uploads:

```text
Build artifact
→ Microsoft managed signing
→ verify Authenticode signature
→ checksum signed file
→ upload signed file to GitHub Release
```

## macOS

macOS requires Apple Developer ID signing and notarization for smooth distribution outside the Mac App Store.

Recommended flow:

1. Sign the app with Developer ID Application.
2. Create the `.dmg` or `.zip`.
3. Submit to Apple notarization.
4. Staple the notarization ticket.
5. Verify Gatekeeper acceptance.

## Linux

Linux desktop distributions do not have one universal signing trust flow. Publish checksums, provenance attestations, and package signatures where relevant.

## GitHub Signing And Attestations

GitHub can sign commits/tags and generate artifact attestations. That helps prove that an artifact came from a GitHub Actions workflow, but it does not replace Windows Authenticode signing or Apple notarization.

Use:

- Signed commits or signed tags for release metadata
- GitHub artifact attestations for CI-built files
- Authenticode for Windows executables
- Apple Developer ID plus notarization for macOS

## PTX Studio Current Release Rule

For PTX Studio Windows releases, generate checksums only after final signing. If an executable is signed after a checksum is created, the checksum must be regenerated because signing changes the file.
