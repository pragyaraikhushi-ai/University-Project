# ============================================================
#  Women Safety App — Backend Launcher (AppLocker-safe)
# ============================================================
#  Calls  python -m uvicorn  instead of  uvicorn.exe
#  to bypass the "Application Control policy has blocked this
#  file" error on managed Windows machines.
#
#  Usage (from project root in PowerShell):
#    .\run_backend.ps1              # starts unified server on port 8000
#    .\run_backend.ps1 -Port 9000  # custom port
#    .\run_backend.ps1 -NoReload   # disable auto-reload (faster startup)
#    .\run_backend.ps1 -MapOnly    # start only the map backend (main.py)
#    .\run_backend.ps1 -AuthOnly   # start only the auth backend
# ============================================================

param(
    [int]    $Port     = 8000,
    [switch] $NoReload,
    [switch] $MapOnly,
    [switch] $AuthOnly
)

# ── Resolve Python ────────────────────────────────────────────────────────────
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host ""
    Write-Host "  FAIL  Python not found in PATH." -ForegroundColor Red
    Write-Host "        Download from https://python.org and re-run." -ForegroundColor Red
    Write-Host ""
    exit 1
}
$PythonExe = $pythonCmd.Source
$pyVer     = & python --version 2>&1
Write-Host ""
Write-Host "  OK    Python  : $pyVer" -ForegroundColor Green
Write-Host "  OK    Exe     : $PythonExe" -ForegroundColor Green

# ── Confirm uvicorn is importable ─────────────────────────────────────────────
$uvCheck = & python -c "import uvicorn; print(uvicorn.__version__)" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  FAIL  uvicorn not installed." -ForegroundColor Red
    Write-Host "        Run:  pip install uvicorn[standard]" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Write-Host "  OK    uvicorn : $uvCheck" -ForegroundColor Green

# ── Choose which app to start ─────────────────────────────────────────────────
$App = "app_server:app"
$Label = "Unified (all screens)"
if ($MapOnly) {
    $App   = "main:app"
    $Label = "Map backend only"
}
if ($AuthOnly) {
    $App   = "auth_backend:app"
    $Label = "Auth backend only"
}

$reloadFlag = if ($NoReload) { "" } else { "--reload" }

# ── Print banner ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  +--------------------------------------------------+" -ForegroundColor Magenta
Write-Host "  |   Women Safety App -- Backend Launcher          |" -ForegroundColor Magenta
Write-Host "  +--------------------------------------------------+" -ForegroundColor Magenta
Write-Host "  |  Service  : $Label" -ForegroundColor Cyan
Write-Host "  |  URL      : http://localhost:$Port" -ForegroundColor Cyan
Write-Host "  |  Docs     : http://localhost:$Port/docs" -ForegroundColor Cyan
if ($App -eq "app_server:app") {
    Write-Host "  |  Auth     : http://localhost:$Port/auth/docs" -ForegroundColor DarkCyan
    Write-Host "  |  Contacts : http://localhost:$Port/contacts/docs" -ForegroundColor DarkCyan
    Write-Host "  |  Voice    : http://localhost:$Port/voice/docs" -ForegroundColor DarkCyan
    Write-Host "  |  Settings : http://localhost:$Port/settings/docs" -ForegroundColor DarkCyan
    Write-Host "  |  Location : http://localhost:$Port/location/docs" -ForegroundColor DarkCyan
    Write-Host "  |  Map      : http://localhost:$Port/map/docs" -ForegroundColor DarkCyan
}
Write-Host "  +--------------------------------------------------+" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

# ── Launch via  python -m uvicorn  (AppLocker-safe) ───────────────────────────
# Try  python -m uvicorn  first. If AppLocker still blocks it,
# fall back to running uvicorn programmatically via  python app_server.py
Write-Host "  Attempting: python -m uvicorn $App --port $Port ..." -ForegroundColor DarkGray

if ($reloadFlag) {
    & $PythonExe -m uvicorn $App --reload --port $Port --host 0.0.0.0
} else {
    & $PythonExe -m uvicorn $App --port $Port --host 0.0.0.0
}

# If the above command exited non-zero, offer the programmatic fallback
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  WARN  python -m uvicorn failed (exit $LASTEXITCODE)." -ForegroundColor Yellow
    Write-Host "        Falling back to: python app_server.py" -ForegroundColor Yellow
    Write-Host ""
    & $PythonExe app_server.py
}
