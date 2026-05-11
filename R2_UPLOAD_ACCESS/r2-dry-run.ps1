param(
    [string]$RemoteName = "ptx-r2",
    [string]$BucketName = "ptx-downloads"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$deployRoot = Resolve-Path (Join-Path $scriptDir "..")
$localRoot = Resolve-Path (Join-Path $deployRoot "ptx-download")
$logDir = Join-Path $scriptDir "logs"

if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logDir "r2-dry-run-$timestamp.log"

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

Write-Host "PTX R2 dry-run"
Write-Host "Local source: $localRoot"
Write-Host "Remote target: ${RemoteName}:$BucketName"
Write-Host "Log file: $logFile"
Write-Host ""

$rclone = Get-RcloneCommand

& $rclone copy `
    "$localRoot" `
    "${RemoteName}:$BucketName" `
    --dry-run `
    --progress `
    --log-file "$logFile" `
    --log-level INFO

if ($LASTEXITCODE -ne 0) {
    throw "rclone dry-run failed with exit code $LASTEXITCODE. Review the log file: $logFile"
}

Write-Host ""
Write-Host "Dry-run complete. Review the log before approving any real upload."
