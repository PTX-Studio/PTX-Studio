param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$PayloadRoot = ""
)

$ErrorActionPreference = "Stop"

$manifestPath = Join-Path $Root "ptx-download\manifest.json"
if (!(Test-Path $manifestPath)) {
    throw "Missing manifest: $manifestPath"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

$checks = @(
    @{
        Name = "PTX Studio"
        Version = $manifest.studio.version
        Url = $manifest.studio.download
        Local = "ptx-download\studio\latest\PTX Studio.exe"
    },
    @{
        Name = "PTX Editor Express"
        Version = $manifest.editor_express.version
        Url = $manifest.editor_express.download
        Local = "ptx-download\editor_express\latest\PTX Editor Express.exe"
    },
    @{
        Name = "PTX Editor Pro"
        Version = $manifest.modules.editor_pro.version
        Url = $manifest.modules.editor_pro.download
        Local = "ptx-download\modules\editor_pro\latest\PTX Editor Pro.exe"
    }
)

foreach ($check in $checks) {
    if ([string]::IsNullOrWhiteSpace($check.Version)) {
        throw "$($check.Name) is missing a version."
    }

    if ([string]::IsNullOrWhiteSpace($check.Url)) {
        throw "$($check.Name) is missing a download URL."
    }

    if ($check.Url -notmatch '^https://download\.ptxstudio\.com/') {
        throw "$($check.Name) download URL is not on download.ptxstudio.com: $($check.Url)"
    }

    if (![string]::IsNullOrWhiteSpace($PayloadRoot)) {
        $payloadBase = (Resolve-Path $PayloadRoot).Path
        $localPath = Join-Path $payloadBase $check.Local
        if (!(Test-Path $localPath)) {
            throw "$($check.Name) latest file is missing: $localPath"
        }

        $file = Get-Item $localPath
        if ($file.Length -lt 1MB) {
            throw "$($check.Name) latest file looks too small: $($file.Length) bytes"
        }

        Write-Host "OK: $($check.Name) $($check.Version) -> $($file.Length) bytes"
    } else {
        Write-Host "OK: $($check.Name) $($check.Version) -> $($check.Url)"
    }
}

Write-Host "Release metadata validation passed."

