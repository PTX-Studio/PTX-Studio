param(
    [string]$RemoteName = "ptx-r2",
    [string]$BucketName = "ptx-downloads"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptDir "r2-routine-upload-core.ps1") -DryRun -RemoteName $RemoteName -BucketName $BucketName

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
