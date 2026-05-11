param(
    [switch]$Approved,
    [string]$RemoteName = "ptx-r2",
    [string]$BucketName = "ptx-downloads"
)

$ErrorActionPreference = "Stop"

if (-not $Approved) {
    throw "Upload blocked. Re-run with -Approved only after Mario approves the dry-run results."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$deployRoot = Resolve-Path (Join-Path $scriptDir "..")
$localRoot = Resolve-Path (Join-Path $deployRoot "ptx-download")
$logDir = Join-Path $scriptDir "logs"

if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logDir "r2-upload-$timestamp.log"

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

Write-Host "PTX R2 approved upload"
Write-Host "Local source: $localRoot"
Write-Host "Remote target: ${RemoteName}:$BucketName"
Write-Host "Log file: $logFile"
Write-Host ""
Write-Host "This uses rclone copy. It does not delete remote files."
Write-Host ""

$rclone = Get-RcloneCommand

& $rclone copy `
    "$localRoot" `
    "${RemoteName}:$BucketName" `
    --progress `
    --log-file "$logFile" `
    --log-level INFO

if ($LASTEXITCODE -ne 0) {
    throw "rclone upload failed with exit code $LASTEXITCODE. Review the log file: $logFile"
}

Write-Host ""
Write-Host "Upload command complete. Verify R2 objects and public download URLs."
