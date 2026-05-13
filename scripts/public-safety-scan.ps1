param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$blockedPatterns = @(
    '[A-Z]:\\',
    'C:\\Users',
    'Dev Folder',
    'Deployments',
    'ptx-download',
    'R2_UPLOAD_ACCESS',
    'ptx-website',
    'Cloudflare',
    'rclone',
    'manifest\.json',
    'license\.json'
)

$blockedFilePatterns = @(
    '\.exe$',
    '\.dmg$',
    '\.AppImage$',
    '\.deb$',
    '\.rpm$',
    '\.zip$',
    '\.7z$',
    '\.pfx$',
    '\.p12$',
    '\.pem$',
    '\.key$'
)

$allowlistedFiles = @(
    '.gitignore',
    'SECURITY.md',
    'SUPPORT.md',
    'CONTRIBUTING.md',
    '.github/pull_request_template.md',
    'docs/github-releases.md',
    'docs/repository-policy.md',
    'docs/public-safety-scan.md',
    'releases/README.md'
)

$trackedFiles = git -C $Root ls-files
if ($LASTEXITCODE -ne 0) {
    throw "Unable to list tracked files. Is this a Git repository?"
}

$failures = New-Object System.Collections.Generic.List[string]

foreach ($file in $trackedFiles) {
    foreach ($pattern in $blockedFilePatterns) {
        if ($file -match $pattern) {
            $failures.Add("Blocked tracked file: $file")
        }
    }

    $path = Join-Path $Root $file
    if (!(Test-Path -LiteralPath $path)) {
        continue
    }

    if ($allowlistedFiles -contains $file) {
        continue
    }

    $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        continue
    }

    foreach ($pattern in $blockedPatterns) {
        if ($content -match $pattern) {
            $failures.Add("Blocked text pattern '$pattern' found in $file")
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Public safety scan failed:"
    $failures | Sort-Object -Unique | ForEach-Object { Write-Host "- $_" }
    exit 1
}

Write-Host "Public safety scan passed."
