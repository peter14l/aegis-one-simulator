# Intelligent Orchestration Script for Infinity-Cache
# Ensures Core -> Daemon -> UI start in the correct dependency order.

$PROJECT_ROOT = $PSScriptRoot

function Start-DeepTechSystem {
    Write-Host "`n[1/4] COMPILING RUST BACKENDS (Workspace)..." -ForegroundColor Cyan
    cargo build --workspace --quiet
    if ($LASTEXITCODE -ne 0) { 
        Write-Error "Compilation failed. Please fix Rust errors before running."
        exit 1
    }

    Write-Host "`n[2/4] LAUNCHING HARDWARE CORE (IPC SERVER)..." -ForegroundColor Cyan
    # Core MUST start first as it is the IPC Server
    $coreProc = Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $PROJECT_ROOT; title CORE_ENGINE; cargo run --package infinity_cache_core" -PassThru
    
    Write-Host "Waiting for IPC Server to initialize..." -NoNewline
    for ($i=0; $i -lt 5; $i++) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host " Ready." -ForegroundColor Green

    Write-Host "`n[3/4] LAUNCHING INTERCEPTION DAEMON (IPC CLIENT)..." -ForegroundColor Cyan
    # Daemon connects to Core's socket
    $daemonProc = Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $PROJECT_ROOT; title INTERCEPTION_DAEMON; cargo run --package infinity_cache_daemon" -PassThru
    
    Write-Host "Waiting for WebSocket Bridge to stabilize..." -NoNewline
    for ($i=0; $i -lt 3; $i++) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host " Ready." -ForegroundColor Green

    Write-Host "`n[4/4] LAUNCHING FLUTTER DASHBOARD (Windows)..." -ForegroundColor Cyan
    # UI connects to Daemon's WebSocket
    Set-Location -Path "$PROJECT_ROOT\infinity_cache_ui"
    flutter run -d windows
}

Start-DeepTechSystem
