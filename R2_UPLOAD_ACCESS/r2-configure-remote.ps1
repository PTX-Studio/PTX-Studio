param(
    [string]$RemoteName = "ptx-r2",
    [string]$BucketName = "ptx-downloads",
    [string]$Endpoint = "https://c173b6f9e101745fc4eab43fa68f1721.r2.cloudflarestorage.com"
)

$ErrorActionPreference = "Stop"

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

function Read-SecretPlainText {
    param([string]$Prompt)

    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

$rclone = Get-RcloneCommand

Write-Host "PTX R2 rclone remote setup"
Write-Host "Remote: $RemoteName"
Write-Host "Endpoint: $Endpoint"
Write-Host ""
Write-Host "Paste the Cloudflare R2 Access Key ID and Secret Access Key when prompted."
Write-Host "The credentials are written only to rclone's user config, not to this folder."
Write-Host ""

$accessKeyId = Read-SecretPlainText -Prompt "Access Key ID"
$secretAccessKey = Read-SecretPlainText -Prompt "Secret Access Key"

if ([string]::IsNullOrWhiteSpace($accessKeyId) -or [string]::IsNullOrWhiteSpace($secretAccessKey)) {
    throw "Both Access Key ID and Secret Access Key are required."
}

& $rclone config create $RemoteName s3 `
    provider Cloudflare `
    access_key_id $accessKeyId `
    secret_access_key $secretAccessKey `
    endpoint $Endpoint `
    region auto `
    acl private `
    --obscure `
    --non-interactive

if ($LASTEXITCODE -ne 0) {
    throw "rclone config create failed with exit code $LASTEXITCODE."
}

Write-Host ""
Write-Host "Remote configured. Validating scoped bucket access..."
& $rclone lsf "${RemoteName}:$BucketName" --max-depth 1

if ($LASTEXITCODE -ne 0) {
    throw "rclone bucket validation failed with exit code $LASTEXITCODE."
}

Write-Host ""
Write-Host "Configuration complete. Next run:"
Write-Host "Set-Location `"D:\Dev Folder\PTX Studio\Deployments`""
Write-Host ".\R2_UPLOAD_ACCESS\r2-dry-run.ps1"
