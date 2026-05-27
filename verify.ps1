# Integration Verification Script for Infinity-Cache Proxy (Windows)
# Launches both Core Engine and Interception Daemon in parallel.

Write-Host "[INIT] Compiling workspace..."
cargo build

Write-Host "[INIT] Starting Core Engine..."
$coreProcess = Start-Process -FilePath "cargo" -ArgumentList "run -p infinity_cache_core" -PassThru -NoNewWindow

# Wait for core to initialize and bind socket
Start-Sleep -Seconds 3

Write-Host "[INIT] Starting Interception Daemon..."
$daemonProcess = Start-Process -FilePath "cargo" -ArgumentList "run -p infinity_cache_daemon" -PassThru -NoNewWindow

Start-Sleep -Seconds 2

Write-Host "[TEST] Simulating a high-write event in 'scratch_disk'..."
if (-not (Test-Path "scratch_disk")) {
    New-Item -ItemType Directory -Path "scratch_disk" | Out-Null
}
"Simulated build artifact" | Out-File -FilePath "scratch_disk\build.log" -Encoding utf8
"Simulated cargo target data" | Out-File -FilePath "scratch_disk\build.log" -Append -Encoding utf8

Start-Sleep -Seconds 5

Write-Host "[TEST] Verification complete. Check logs above for CORE/DAEMON trace."
Write-Host "[TEST] Stopping processes..."

Stop-Process -Id $daemonProcess.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $coreProcess.Id -Force -ErrorAction SilentlyContinue

Write-Host "[TEST] Done."
