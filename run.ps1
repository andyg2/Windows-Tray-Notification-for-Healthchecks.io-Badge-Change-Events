Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$badgeUrl = "https://healthcheacks.io/badge/ef5b9d3f-46ea-4598-9715-debe1c/rH2dTWNz.svg"
$pollSeconds = 10         # Check every 10 seconds
$gracePeriodSeconds = 30  # Must be in a bad state for 30 seconds before notifying (should be >2x multiplier of $pollSeconds)

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true
$notify.Text = "Healthchecks Aggregate"

$iconOk = [System.Drawing.SystemIcons]::Information
$iconWarn = [System.Drawing.SystemIcons]::Warning
$iconDown = [System.Drawing.SystemIcons]::Error

$lastNotifiedState = ""
$pendingState = ""
$firstDetectedTime = $null

$notify.BalloonTipTitle = "Healthchecks"
$notify.BalloonTipText = "Monitoring started (1m grace period active)"
$notify.ShowBalloonTip(3000)

function Get-BadgeState {
  try {
    $web = New-Object System.Net.WebClient
    $content = $web.DownloadString($badgeUrl)
    $regMatches = [regex]::Matches($content, '<text[^>]*>\s*(up|down|late)\s*</text>', 'IgnoreCase')

    if ($regMatches.Count -gt 0) {
      return $regMatches[$regMatches.Count - 1].Groups[1].Value.ToLower()
    }
  }
  catch {
    Write-Host "$(Get-Date) error=$($_.Exception.Message)"
  }
  return "unknown"
}

while ($true) {
  $currentState = Get-BadgeState
    
  # Ignore network blips
  if ($currentState -eq "unknown") {
    Start-Sleep $pollSeconds
    continue
  }

  if ($currentState -eq $lastNotifiedState) {
    # The state matches what we last alerted on. Reset pending timers.
    $pendingState = ""
    $firstDetectedTime = $null
  }
  else {
    # The state has changed from our last notification
    if ($currentState -ne $pendingState) {
      # This is the FIRST time we are seeing this specific new state
      $pendingState = $currentState
      $firstDetectedTime = Get-Date
      Write-Host "$(Get-Date) Change detected: $currentState. Waiting for consistency..."
    }
    else {
      # We are currently in the grace period for this state
      $elapsed = (New-TimeSpan -Start $firstDetectedTime -End (Get-Date)).TotalSeconds
      Write-Host "$(Get-Date) State '$currentState' persistent for $(([math]::Round($elapsed)))s"

      if ($elapsed -ge $gracePeriodSeconds) {
        # The state has been solid for over a minute. NOTIFY NOW.
        Write-Host "$(Get-Date) Grace period exceeded. Updating UI."
                
        switch ($currentState) {
          "up" { 
            $notify.Icon = $iconOk
            $notify.BalloonTipText = "All systems UP" 
          }
          "late" { 
            $notify.Icon = $iconWarn
            $notify.BalloonTipText = "Some systems are LATE" 
          }
          "down" { 
            $notify.Icon = $iconDown
            $notify.BalloonTipText = "One or more systems DOWN" 
          }
        }

        $notify.ShowBalloonTip(5000)
        $lastNotifiedState = $currentState
        $pendingState = ""
        $firstDetectedTime = $null
      }
    }
  }

  Start-Sleep $pollSeconds
}

# Scheduled task run powershell in sta mode (Action=Start a program)
# Program/Script: powershell.exe
# Arguments: -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Users\Andy\HCRampTrayApp\run.ps1
