# Code Signing And Trust Plan

Code signing and GitHub artifact signing solve different trust problems.

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

