Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ===== CONFIG =====
$reminderHours = 3
$checkIntervalSeconds = 30
$logFile = "$env:USERPROFILE\creatine-log.jsonl"
# ==================

$intervalSeconds = $reminderHours * 60 * 60

$iconNormal = [System.Drawing.SystemIcons]::Information
$iconAlert = [System.Drawing.SystemIcons]::Warning

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = $iconNormal
$notify.Visible = $true
$notify.Text = "Creatine Reminder"

$notify.BalloonTipTitle = "Creatine Time Reminder"

$lastTaken = Get-Date
$alertActive = $false

# Ensure log directory exists
$logDir = Split-Path $logFile
if (-not (Test-Path $logDir)) {
  New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Log-Event($eventName) {
  $entry = @{
    event     = $eventName
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
  } | ConvertTo-Json -Compress

  Add-Content -Path $logFile -Value $entry
}

# Click = acknowledge (taken)
$notify.add_Click({
    if ($script:alertActive) {
      $script:lastTaken = Get-Date
      $script:alertActive = $false
      $notify.Icon = $iconNormal
      $notify.Text = "Creatine Reminder"

      Log-Event "creatine_taken"
    }
  })

# Startup notice
$notify.BalloonTipText = "Creatine reminder running (every $reminderHours hours)"
$notify.ShowBalloonTip(3000)

while ($true) {
  $elapsed = ((Get-Date) - $lastTaken).TotalSeconds

  if ($elapsed -ge $intervalSeconds -and -not $alertActive) {
    $alertActive = $true
    $notify.Icon = $iconAlert
    $notify.Text = "TAKE CREATINE"
    $notify.BalloonTipText = "Take your creatine now 💪"
    $notify.ShowBalloonTip(8000)
  }

  Start-Sleep -Seconds $checkIntervalSeconds
}

$notify.Dispose()
