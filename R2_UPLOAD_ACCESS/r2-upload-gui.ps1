Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$deployRoot = Resolve-Path (Join-Path $scriptDir "..")
$downloadRoot = Resolve-Path (Join-Path $deployRoot "ptx-download")
$logDir = Join-Path $scriptDir "logs"

if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function New-Button {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 150
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, 34)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::System
    return $button
}

function Append-Log {
    param([string]$Message)

    $logBox.AppendText($Message)
}

function Append-UserOutput {
    param([string]$Chunk)

    if ([string]::IsNullOrWhiteSpace($Chunk)) {
        return
    }

    $lines = $Chunk -split "`r?`n"
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $trimmed = $line.Trim()

        if ($trimmed -match '^Transferred:' -or
            $trimmed -match '^Checks:' -or
            $trimmed -match '^Elapsed time:' -or
            $trimmed -match '^Checking:' -or
            $trimmed -match ', ETA ' -or
            $trimmed -match '^\* ') {
            continue
        }

        Update-TimelineFromLine -Line $trimmed
        Append-Log "$trimmed`r`n"
    }
}

function Get-RunStepCount {
    param([string]$Name)

    if ($Name -match 'routine') {
        $manifestStep = if (Test-Path -LiteralPath (Join-Path $downloadRoot "manifest.json")) { 1 } else { 0 }
        $latestCount = @(Get-ChildItem -LiteralPath $downloadRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq "latest" }).Count
        $releaseCount = @(Get-ChildItem -LiteralPath $downloadRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Parent.Name -eq "releases" }).Count
        return [Math]::Max(1, $manifestStep + $latestCount + $releaseCount)
    }

    return 1
}

function Step-Timeline {
    param([string]$Label)

    if ($script:timelineTotalSteps -le 0) {
        return
    }

    $script:timelineCompletedSteps = [Math]::Min($script:timelineCompletedSteps + 1, $script:timelineTotalSteps)
    $value = [Math]::Floor(($script:timelineCompletedSteps / $script:timelineTotalSteps) * 100)
    $timelineBar.Value = [Math]::Max(0, [Math]::Min(100, $value))
    $timelineLabel.Text = "Timeline: $script:timelineCompletedSteps of $script:timelineTotalSteps - $Label"
}

function Update-TimelineFromLine {
    param([string]$Line)

    if ($Line -match '^Source:\s+(.+)$') {
        $leaf = Split-Path -Path $Matches[1] -Leaf
        Step-Timeline -Label "Processing $leaf"
        return
    }

    if ($Line -match '^Release already exists remotely, skipping:\s+(.+)$') {
        Step-Timeline -Label "Skipped existing release"
        return
    }

    if ($Line -match '^Release version appears to exist remotely under alternate naming') {
        Step-Timeline -Label "Skipped alternate release"
        return
    }
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)

    $routineDryRunButton.Enabled = $Enabled
    $routineUploadButton.Enabled = $Enabled
    $fullDryRunButton.Enabled = $Enabled
    $fullUploadButton.Enabled = $Enabled
    $refreshLogButton.Enabled = $Enabled
    $openLogsButton.Enabled = $Enabled
    $openDownloadsButton.Enabled = $Enabled
}

function Show-LatestLog {
    $latestLog = Get-ChildItem -LiteralPath $logDir -Filter "*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latestLog) {
        Append-Log "No log files found yet.`r`n"
        return
    }

    Append-Log "`r`n--- Latest log: $($latestLog.FullName) ---`r`n"
    Get-Content -LiteralPath $latestLog.FullName -Tail 120 | ForEach-Object {
        Append-Log "$_`r`n"
    }
    Append-Log "--- End latest log ---`r`n"
}

function Start-R2Script {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string]$ArgumentText = ""
    )

    Set-ButtonsEnabled $false
    $statusLabel.Text = "$Name running..."
    $detailLabel.Text = "Running. Raw logs are still saved in the logs folder."
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
    $progressBar.MarqueeAnimationSpeed = 35
    $logBox.Clear()
    Append-Log "Started: $Name at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n"
    Append-Log "Working... this may take a moment for larger EXE files.`r`n`r`n"

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $guiOutputFile = Join-Path $logDir "gui-output-$timestamp.txt"
    $script:activeProcess = $null
    $script:activeOutputFile = $guiOutputFile
    $script:activeOutputLength = 0
    $script:activeRunName = $Name
    $script:timelineTotalSteps = Get-RunStepCount -Name $Name
    $script:timelineCompletedSteps = 0
    $timelineBar.Value = 0
    $timelineLabel.Text = "Timeline: 0 of $script:timelineTotalSteps"

    $command = @"
Set-Location -LiteralPath '$($deployRoot.Path -replace "'", "''")'
Write-Output 'GUI command starting: $($Name -replace "'", "''")'
Write-Output 'Script: $($ScriptPath -replace "'", "''")'
Write-Output 'Arguments: $($ArgumentText -replace "'", "''")'
& '$($ScriptPath -replace "'", "''")' $ArgumentText *>&1 | Out-File -LiteralPath '$($guiOutputFile -replace "'", "''")' -Encoding utf8 -Width 240
exit `$LASTEXITCODE
"@

    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.WorkingDirectory = $deployRoot.Path
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError = $false
    $psi.CreateNoWindow = $true
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand"

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $null = $process.Start()
    $script:activeProcess = $process
    $runTimer.Start()
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "PTX Studio R2 Upload Console"
$form.Size = New-Object System.Drawing.Size(1080, 720)
$form.MinimumSize = New-Object System.Drawing.Size(820, 520)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(246, 248, 251)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "PTX Studio R2 Upload Console"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(16, 14)
$titleLabel.Size = New-Object System.Drawing.Size(500, 32)
$form.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Routine mode refreshes live downloads and protects release archives."
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(82, 91, 105)
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 44)
$subtitleLabel.Size = New-Object System.Drawing.Size(760, 22)
$form.Controls.Add($subtitleLabel)

$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Text = "Source: $downloadRoot"
$pathLabel.Location = New-Object System.Drawing.Point(20, 72)
$pathLabel.Size = New-Object System.Drawing.Size(920, 22)
$form.Controls.Add($pathLabel)

$targetLabel = New-Object System.Windows.Forms.Label
$targetLabel.Text = "Target: ptx-r2:ptx-downloads"
$targetLabel.Location = New-Object System.Drawing.Point(20, 94)
$targetLabel.Size = New-Object System.Drawing.Size(920, 22)
$form.Controls.Add($targetLabel)

$routineGroup = New-Object System.Windows.Forms.GroupBox
$routineGroup.Text = "Normal Release Workflow"
$routineGroup.Location = New-Object System.Drawing.Point(18, 122)
$routineGroup.Size = New-Object System.Drawing.Size(400, 86)
$form.Controls.Add($routineGroup)

$routineDryRunButton = New-Button -Text "Routine Dry-Run" -X 18 -Y 34 -Width 170
$routineGroup.Controls.Add($routineDryRunButton)

$routineUploadButton = New-Button -Text "Routine Upload" -X 206 -Y 34 -Width 170
$routineGroup.Controls.Add($routineUploadButton)

$fullGroup = New-Object System.Windows.Forms.GroupBox
$fullGroup.Text = "Advanced Full Mirror"
$fullGroup.Location = New-Object System.Drawing.Point(432, 122)
$fullGroup.Size = New-Object System.Drawing.Size(400, 86)
$form.Controls.Add($fullGroup)

$fullDryRunButton = New-Button -Text "Full Dry-Run" -X 18 -Y 34 -Width 170
$fullGroup.Controls.Add($fullDryRunButton)

$fullUploadButton = New-Button -Text "Full Upload" -X 206 -Y 34 -Width 170
$fullGroup.Controls.Add($fullUploadButton)

$utilityGroup = New-Object System.Windows.Forms.GroupBox
$utilityGroup.Text = "Tools"
$utilityGroup.Location = New-Object System.Drawing.Point(846, 122)
$utilityGroup.Size = New-Object System.Drawing.Size(200, 122)
$form.Controls.Add($utilityGroup)

$refreshLogButton = New-Button -Text "Show Latest Log" -X 18 -Y 28 -Width 160
$utilityGroup.Controls.Add($refreshLogButton)

$openLogsButton = New-Button -Text "Open Logs Folder" -X 18 -Y 66 -Width 160
$utilityGroup.Controls.Add($openLogsButton)

$openDownloadsButton = New-Button -Text "Open Downloads" -X 18 -Y 104 -Width 160
$utilityGroup.Controls.Add($openDownloadsButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$statusLabel.Location = New-Object System.Drawing.Point(20, 220)
$statusLabel.Size = New-Object System.Drawing.Size(220, 24)
$form.Controls.Add($statusLabel)

$detailLabel = New-Object System.Windows.Forms.Label
$detailLabel.Text = "Routine mode uploads manifest, latest, and missing releases only."
$detailLabel.Location = New-Object System.Drawing.Point(250, 222)
$detailLabel.Size = New-Object System.Drawing.Size(580, 22)
$form.Controls.Add($detailLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 250)
$progressBar.Size = New-Object System.Drawing.Size(1026, 18)
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$progressBar.Value = 0
$form.Controls.Add($progressBar)

$timelineLabel = New-Object System.Windows.Forms.Label
$timelineLabel.Text = "Timeline: idle"
$timelineLabel.Location = New-Object System.Drawing.Point(20, 274)
$timelineLabel.Size = New-Object System.Drawing.Size(1026, 18)
$form.Controls.Add($timelineLabel)

$timelineBar = New-Object System.Windows.Forms.ProgressBar
$timelineBar.Location = New-Object System.Drawing.Point(20, 294)
$timelineBar.Size = New-Object System.Drawing.Size(1026, 18)
$timelineBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$timelineBar.Value = 0
$form.Controls.Add($timelineBar)

$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "Activity"
$logLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$logLabel.Location = New-Object System.Drawing.Point(20, 322)
$logLabel.Size = New-Object System.Drawing.Size(220, 22)
$form.Controls.Add($logLabel)

<#
$routineDryRunButton = New-Button -Text "Routine Dry-Run" -X 18 -Y 112
$form.Controls.Add($routineDryRunButton)

$routineUploadButton = New-Button -Text "Routine Upload" -X 180 -Y 112
$form.Controls.Add($routineUploadButton)

$fullDryRunButton = New-Button -Text "Full Dry-Run" -X 342 -Y 112
$form.Controls.Add($fullDryRunButton)

$fullUploadButton = New-Button -Text "Full Upload" -X 504 -Y 112
$form.Controls.Add($fullUploadButton)

$refreshLogButton = New-Button -Text "Show Latest Log" -X 666 -Y 112
$form.Controls.Add($refreshLogButton)

$openLogsButton = New-Button -Text "Open Logs Folder" -X 828 -Y 112
$form.Controls.Add($openLogsButton)

$openDownloadsButton = New-Button -Text "Open Downloads" -X 18 -Y 152
$form.Controls.Add($openDownloadsButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready. Routine mode uploads manifest, latest, and missing releases only."
$statusLabel.Location = New-Object System.Drawing.Point(180, 158)
$statusLabel.Size = New-Object System.Drawing.Size(920, 24)
$form.Controls.Add($statusLabel)
#>

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
$logBox.WordWrap = $false
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logBox.BackColor = [System.Drawing.Color]::White
$logBox.Location = New-Object System.Drawing.Point(20, 348)
$logBox.Anchor = "Top,Bottom,Left,Right"
$logBox.Size = New-Object System.Drawing.Size(1026, 318)
$form.Controls.Add($logBox)

$runTimer = New-Object System.Windows.Forms.Timer
$runTimer.Interval = 500
$runTimer.Add_Tick({
    if ($script:activeOutputFile -and (Test-Path -LiteralPath $script:activeOutputFile)) {
        try {
            $content = Get-Content -LiteralPath $script:activeOutputFile -Raw -ErrorAction Stop
            if ($null -ne $content -and $content.Length -gt $script:activeOutputLength) {
                Append-UserOutput $content.Substring($script:activeOutputLength)
                $script:activeOutputLength = $content.Length
            }
        }
        catch {
            Append-Log "Could not read live output yet: $($_.Exception.Message)`r`n"
        }
    }

    if ($script:activeProcess -and $script:activeProcess.HasExited) {
        $runTimer.Stop()

        if ($script:activeOutputFile -and (Test-Path -LiteralPath $script:activeOutputFile)) {
            $content = Get-Content -LiteralPath $script:activeOutputFile -Raw -ErrorAction SilentlyContinue
            if ($null -ne $content -and $content.Length -gt $script:activeOutputLength) {
                Append-UserOutput $content.Substring($script:activeOutputLength)
                $script:activeOutputLength = $content.Length
            }
        }

        $exitCode = $script:activeProcess.ExitCode
        Append-Log "`r`nFinished: $($script:activeRunName) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n"

        Set-ButtonsEnabled $true
        $progressBar.MarqueeAnimationSpeed = 0
        $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
        if ($exitCode -eq 0) {
            $statusLabel.Text = "$($script:activeRunName) complete"
            $detailLabel.Text = "Completed successfully. Use Show Latest Log for full technical detail."
            $progressBar.Value = 100
            $timelineBar.Value = 100
            $timelineLabel.Text = "Timeline: complete"
        }
        else {
            $statusLabel.Text = "$($script:activeRunName) failed. Review output."
            $detailLabel.Text = "The command failed. Open the logs folder or show the latest log for details."
            $progressBar.Value = 0
        }

        $script:activeProcess.Dispose()
        $script:activeProcess = $null
    }
})

$form.Add_FormClosing({
    if ($script:activeProcess -and -not $script:activeProcess.HasExited) {
        $choice = [System.Windows.Forms.MessageBox]::Show(
            "A command is still running. Close the upload console anyway?",
            "Command Running",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
            $_.Cancel = $true
        }
    }
})

$routineDryRunButton.Add_Click({
    Start-R2Script `
        -Name "R2 routine dry-run" `
        -ScriptPath (Join-Path $scriptDir "r2-routine-dry-run.ps1")
})

$routineUploadButton.Add_Click({
    $message = "This will upload manifest.json, latest folders, and release version folders that are missing remotely.`r`n`r`nIt will not delete remote files and will not overwrite existing release archives during routine mode.`r`n`r`nRun routine upload now?"
    $choice = [System.Windows.Forms.MessageBox]::Show(
        $message,
        "Confirm Routine R2 Upload",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-R2Script `
            -Name "R2 routine upload" `
            -ScriptPath (Join-Path $scriptDir "r2-routine-upload-approved.ps1") `
            -ArgumentText "-Approved"
    }
})

$fullDryRunButton.Add_Click({
    Start-R2Script `
        -Name "R2 full dry-run" `
        -ScriptPath (Join-Path $scriptDir "r2-dry-run.ps1")
})

$fullUploadButton.Add_Click({
    $message = "This will copy the entire local ptx-download mirror to Cloudflare R2.`r`n`r`nIt does not delete remote files, but it can overwrite existing remote objects if local files differ.`r`n`r`nUse this only for an intentional full mirror upload.`r`n`r`nRun full upload now?"
    $choice = [System.Windows.Forms.MessageBox]::Show(
        $message,
        "Confirm Full R2 Upload",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-R2Script `
            -Name "R2 full upload" `
            -ScriptPath (Join-Path $scriptDir "r2-upload-approved.ps1") `
            -ArgumentText "-Approved"
    }
})

$refreshLogButton.Add_Click({
    Show-LatestLog
})

$openLogsButton.Add_Click({
    Start-Process explorer.exe -ArgumentList "`"$logDir`""
})

$openDownloadsButton.Add_Click({
    Start-Process explorer.exe -ArgumentList "`"$downloadRoot`""
})

Append-Log "PTX Studio R2 Upload Console ready.`r`n"
Append-Log "Routine mode uploads manifest, latest folders, and release folders missing remotely.`r`n"
Append-Log "Use full mirror buttons only when you intentionally want to process the whole local mirror.`r`n"
Append-Log "No deletes are performed by these scripts.`r`n"
Append-Log "`r`nRecommended: Routine Dry-Run, review, then Routine Upload.`r`n"

[void]$form.ShowDialog()
