# Healthchecks.io Windows Tray Monitor

A lightweight **PowerShell system tray monitor** for Healthchecks.io that displays the **aggregated badge status** (`up`, `late`, `down`) directly in the Windows notification area and raises notifications when the state changes.

Designed for environments with **many checks** where Healthchecks categories and badge aggregation already represent the correct system health.

---

## Features

- Polls a Healthchecks.io **badge SVG**
- No API keys or credentials required
- Parses **semantic status text** (`up`, `late`, `down`)
- System tray icon reflects current health
- Windows notification only on state change
- Runs silently in the background
- Zero dependencies (PowerShell + .NET)

---

## Why use the badge?

- Badges already aggregate **categories, grace periods, and paused checks**
- Single HTTP request instead of hundreds
- No secrets to manage
- Matches exactly what is shown in the Healthchecks dashboard

The badge text is treated as the **source of truth**, making the script resilient to SVG layout or color changes.

---

## How it works

1. Periodically downloads the Healthchecks badge SVG
2. Extracts the visible status text from the SVG
3. Maps state to tray icon:
   - `up` → Information
   - `late` → Warning
   - `down` → Error
4. Displays a Windows notification when the state changes
5. Continues running quietly in the system tray

---

## Requirements

- Windows
- PowerShell 5.1+ or PowerShell 7+
- Internet access to your Healthchecks instance

---

## Configuration

Edit `run.ps1`:

```powershell
$badgeUrl    = "https://your-healthchecks-instance/badge/<uuid>/<token>.svg"
$pollSeconds = 10


## Running
Important: PowerShell must be run in STA mode for system tray notifications to work correctly.

```ps1
powershell.exe -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File run.ps1
```

### Autostart on Login (Recommended)

Create a Task Scheduler task:

Trigger: At logon

Action:

```ps1
powershell.exe -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\path\to\run.ps1
```
