$hosts = "google.com", "github.com", "8.8.8.8"

foreach ($h in $hosts) {
    if (Test-Connection -ComputerName $h -Count 1 -Quiet) {
        Write-Host "$h is UP" -ForegroundColor Green
    } else {
        Write-Host "$h is DOWN" -ForegroundColor Red
    }
}

Get-PSDrive -PSProvider FileSystem | Where-Object Used -gt 0 | ForEach-Object {
    $pct = [math]::Round($_.Free / ($_.Used + $_.Free) * 100)
    if ($pct -lt 20) {
        Write-Host "WARNING: Drive $($_.Name) is only $pct% free" -ForegroundColor Yellow
    } else {
        Write-Host "Drive $($_.Name): $pct% free"
    }
}