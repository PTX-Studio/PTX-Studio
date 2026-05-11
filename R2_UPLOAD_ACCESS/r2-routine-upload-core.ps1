param(
    [switch]$DryRun,
    [switch]$Approved,
    [string]$RemoteName = "ptx-r2",
    [string]$BucketName = "ptx-downloads"
)

$ErrorActionPreference = "Stop"

if (-not $DryRun -and -not $Approved) {
    throw "Routine upload blocked. Use -DryRun first, then use -Approved only after reviewing the dry-run."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$deployRoot = Resolve-Path (Join-Path $scriptDir "..")
$localRoot = Resolve-Path (Join-Path $deployRoot "ptx-download")
$logDir = Join-Path $scriptDir "logs"

if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$mode = if ($DryRun) { "routine-dry-run" } else { "routine-upload" }
$logFile = Join-Path $logDir "r2-$mode-$timestamp.log"

function Get-RcloneCommand {
    $pathCommand = Get-Command rclone -ErrorAction SilentlyContinue
    if ($pathCommand) {
        return $pathCommand.Source
    }

    $wingetRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wingetRoot) {
        $wingetMatch = Get-ChildItem -Path $wingetRoot -Recurse -Filter rclone.exe -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if ($wingetMatch) {
            return $wingetMatch
        }
    }

    throw "rclone is not installed or not discoverable. Install rclone, then run this script again."
}

function Invoke-RcloneCopy {
    param(
        [string]$Source,
        [string]$Target,
        [bool]$UseDryRun,
        [bool]$ForceRefresh = $false
    )

    Write-Host ""
    Write-Host "Source: $Source"
    Write-Host "Target: $Target"
    if ($ForceRefresh) {
        Write-Host "Refresh policy: force upload/update even when remote object already exists."
    }

    $args = @(
        "copy",
        $Source,
        $Target,
        "--progress",
        "--log-file", $logFile,
        "--log-level", "INFO"
    )

    if ($UseDryRun) {
        $args += "--dry-run"
    }

    if ($ForceRefresh) {
        $args += "--ignore-times"
    }

    & $rclone @args

    if ($LASTEXITCODE -ne 0) {
        throw "rclone copy failed with exit code $LASTEXITCODE. Review the log file: $logFile"
    }
}

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$ChildPath
    )

    $baseUri = [Uri]((Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\')
    $childUri = [Uri]((Resolve-Path -LiteralPath $ChildPath).Path)
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($childUri).ToString()).Replace('/', '\')
}

function Test-RemotePathExists {
    param([string]$RemotePath)

    $remoteItems = @(& $rclone lsf $RemotePath --max-depth 1 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    return ($remoteItems.Count -gt 0)
}

$rclone = Get-RcloneCommand
$remoteRoot = "${RemoteName}:$BucketName"
$useDryRun = [bool]$DryRun

Write-Host "PTX R2 routine upload"
Write-Host "Mode: $(if ($useDryRun) { 'dry-run only' } else { 'approved upload' })"
Write-Host "Local root: $localRoot"
Write-Host "Remote root: $remoteRoot"
Write-Host "Log file: $logFile"
Write-Host ""
Write-Host "Routine policy:"
Write-Host "- Force refresh manifest.json."
Write-Host "- Force refresh latest folders."
Write-Host "- Process releases folders only when the version folder is missing remotely."
Write-Host "- Do not delete remote files."

$manifest = Join-Path $localRoot "manifest.json"
if (Test-Path -LiteralPath $manifest) {
    Invoke-RcloneCopy -Source $manifest -Target $remoteRoot -UseDryRun $useDryRun -ForceRefresh $true
}
else {
    Write-Host "WARNING: manifest.json was not found at $manifest"
}

$latestDirs = Get-ChildItem -LiteralPath $localRoot -Recurse -Directory |
    Where-Object { $_.Name -eq "latest" } |
    Sort-Object FullName

foreach ($latestDir in $latestDirs) {
    $relative = Get-RelativePath -BasePath $localRoot -ChildPath $latestDir.FullName
    $remotePath = ($relative -replace '\\', '/')
    Invoke-RcloneCopy -Source $latestDir.FullName -Target "$remoteRoot/$remotePath" -UseDryRun $useDryRun -ForceRefresh $true
}

$releaseVersionDirs = Get-ChildItem -LiteralPath $localRoot -Recurse -Directory |
    Where-Object { $_.Parent.Name -eq "releases" } |
    Sort-Object FullName

foreach ($releaseDir in $releaseVersionDirs) {
    $relative = Get-RelativePath -BasePath $localRoot -ChildPath $releaseDir.FullName
    $remotePath = ($relative -replace '\\', '/')
    $remoteTarget = "$remoteRoot/$remotePath"

    if (Test-RemotePathExists -RemotePath $remoteTarget) {
        Write-Host ""
        Write-Host "Release already exists remotely, skipping: $remotePath"
        continue
    }

    $aliasFound = $false
    $aliasRelatives = @()
    $versionName = $releaseDir.Name
    $aliasVersion = $null

    if ($versionName -match '^v\d') {
        $aliasVersion = $versionName.Substring(1)
    }
    elseif ($versionName -match '^\d') {
        $aliasVersion = "v$versionName"
    }

    if ($aliasVersion) {
        $relativeParent = Split-Path -Path $relative -Parent
        $aliasRelatives += (Join-Path $relativeParent $aliasVersion)
    }

    foreach ($aliasRelative in $aliasRelatives) {
        $aliasRemotePath = ($aliasRelative -replace '\\', '/')
        $aliasRemoteTarget = "$remoteRoot/$aliasRemotePath"
        if (Test-RemotePathExists -RemotePath $aliasRemoteTarget) {
            Write-Host ""
            Write-Host "Release version appears to exist remotely under alternate naming, skipping to avoid duplicate:"
            Write-Host "Local path: $remotePath"
            Write-Host "Remote alternate: $aliasRemotePath"
            $aliasFound = $true
            break
        }
    }

    if ($aliasFound) {
        continue
    }

    Write-Host ""
    Write-Host "Release missing remotely, will process: $remotePath"
    Invoke-RcloneCopy -Source $releaseDir.FullName -Target $remoteTarget -UseDryRun $useDryRun
}

Write-Host ""
Write-Host "Routine upload command complete."
Write-Host "Review log: $logFile"
