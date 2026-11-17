$logDir = "$env:USERPROFILE\HealthLogs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$logFile = Join-Path $logDir "health-$(Get-Date -Format 'yyyy-MM-dd').log"

function Write-Status($level, $msg) {
    $colors = @{ OK = "Green"; WARNING = "Yellow"; CRITICAL = "Red" }
    $line = "$(Get-Date -Format 's') [$level] $msg"
    Write-Host $line -ForegroundColor $colors[$level]
    Add-Content -Path $logFile -Value $line
}

function Get-Level($value, $warn, $crit) {
    if ($value -ge $crit) { "CRITICAL" }
    elseif ($value -ge $warn) { "WARNING" }
    else { "OK" }
}

$os = Get-CimInstance Win32_OperatingSystem
Write-Host "=== Health check for $env:COMPUTERNAME ===" -ForegroundColor Cyan
Write-Host "OS: $($os.Caption)"
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host ("Uptime: {0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes)
Write-Host ""

# CPU
$cpu = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average)
Write-Status (Get-Level $cpu 80 95) "CPU load: $cpu%"

# Memory
$ram = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
Write-Status (Get-Level $ram 80 90) "Memory used: $ram%"

# Disks (all drives with a size)
Get-CimInstance Win32_LogicalDisk | Where-Object { $_.Size -gt 0 } | ForEach-Object {
    $used = [math]::Round(100 - ($_.FreeSpace / $_.Size * 100))
    Write-Status (Get-Level $used 80 90) "Drive $($_.DeviceID) used: $used%"
}

# Battery (laptops only)
$bat = Get-CimInstance Win32_Battery
if ($bat) {
    $charge = $bat.EstimatedChargeRemaining
    $level = if ($charge -le 10) { "CRITICAL" } elseif ($charge -le 20) { "WARNING" } else { "OK" }
    Write-Status $level "Battery: $charge%"
}

# Internet
if (Test-Connection 8.8.8.8 -Count 1 -Quiet) {
    Write-Status "OK" "Internet: reachable"
} else {
    Write-Status "CRITICAL" "Internet: unreachable"
}

Write-Host ""
Read-Host "Press Enter to close"