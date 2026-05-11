param(
    [switch]$Approved,
    [string]$RemoteName = "ptx-r2",
    [string]$BucketName = "ptx-downloads"
)

if (-not $Approved) {
    throw "Routine upload blocked. Re-run with -Approved only after reviewing the routine dry-run."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir "r2-routine-upload-core.ps1") -Approved -RemoteName $RemoteName -BucketName $BucketName

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
