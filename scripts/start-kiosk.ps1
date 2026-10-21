# start-kiosk.ps1 — Borne d'accueil Team Fitness
# Usage :
#   Première fois  →  .\scripts\start-kiosk.ps1 -Setup
#   Quotidien      →  .\scripts\start-kiosk.ps1
#   Avec rebuild   →  .\scripts\start-kiosk.ps1 -Build

param(
    [switch]$Setup,                          # Crée le tunnel + entrée DNS (une seule fois)
    [switch]$Build,                          # Rebuild avant de lancer
    [string]$Environment  = "prod",          # prod | pprod
    [int]   $Port         = 8088,            # Port HTTP local
    [string]$TunnelName   = "kiosk-salle",   # Nom du tunnel cloudflared
    [string]$Hostname     = "kiosk.teamfitness.com"
)

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step  ([string]$msg) { Write-Host "  → $msg" -ForegroundColor Cyan }
function Write-Ok    ([string]$msg) { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Fail  ([string]$msg) { Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }
function Write-Info  ([string]$msg) { Write-Host "    $msg" -ForegroundColor Gray }

function Assert-Command ([string]$cmd) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Fail "$cmd introuvable — vérifiez votre PATH"
    }
}

# ── Banner ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🏋  Team Fitness — Borne d'accueil                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Prérequis ─────────────────────────────────────────────────────────────────

Assert-Command "cloudflared"
Assert-Command "flutter"

# Python ou Node pour servir les fichiers statiques
$server = $null
if (Get-Command "python" -ErrorAction SilentlyContinue) { $server = "python" }
elseif (Get-Command "python3" -ErrorAction SilentlyContinue) { $server = "python3" }
elseif (Get-Command "npx" -ErrorAction SilentlyContinue) { $server = "npx" }
else { Write-Fail "python ou npx requis pour servir les fichiers statiques" }

# ── Mode Setup (une fois) ─────────────────────────────────────────────────────

if ($Setup) {
    Write-Host "[ SETUP — exécutez une seule fois ]" -ForegroundColor Yellow
    Write-Host ""

    # 1. Créer le tunnel
    Write-Step "Création du tunnel '$TunnelName'..."
    cloudflared tunnel create $TunnelName
    if ($LASTEXITCODE -ne 0) { Write-Fail "Impossible de créer le tunnel" }
    Write-Ok "Tunnel créé"

    # 2. Entrée DNS : CNAME kiosk.teamfitness.com → <uuid>.cfargotunnel.com
    Write-Step "Route DNS : $Hostname → $TunnelName..."
    cloudflared tunnel route dns $TunnelName $Hostname
    if ($LASTEXITCODE -ne 0) { Write-Fail "Impossible de créer l'entrée DNS" }
    Write-Ok "DNS configuré"

    # 3. Écrire le fichier de config cloudflared pour ce tunnel
    $cfDir = "$env:USERPROFILE\.cloudflared"
    $cfgPath = "$cfDir\kiosk.yml"

    $cfgContent = @"
# Config tunnel borne d'accueil — kiosk.teamfitness.com
tunnel: $TunnelName
credentials-file: $cfDir\$(cloudflared tunnel list --output json 2>$null | ConvertFrom-Json | Where-Object { $_.name -eq $TunnelName } | Select-Object -ExpandProperty id).json

ingress:
  - hostname: $Hostname
    service: http://localhost:$Port
  - service: http_status:404
"@

    $cfgContent | Out-File -FilePath $cfgPath -Encoding utf8
    Write-Ok "Config écrite : $cfgPath"

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅  Setup terminé !                                     ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Lancez la borne avec :" -ForegroundColor White
    Write-Host "  .\scripts\start-kiosk.ps1 -Build" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# ── Mode Run ──────────────────────────────────────────────────────────────────

$webDir = "build\web"

# 1. Build (optionnel)
if ($Build -or -not (Test-Path $webDir)) {
    Write-Step "Build Flutter Web ($Environment)..."
    flutter build web --release --dart-define=ENVIRONMENT=$Environment --no-source-maps
    if ($LASTEXITCODE -ne 0) { Write-Fail "Build Flutter échoué" }
    Write-Ok "Build terminé ($webDir)"
} else {
    Write-Info "Build existant utilisé (passez -Build pour reconstruire)"
}

Write-Host ""

# 2. Lancer le serveur HTTP local en arrière-plan
Write-Step "Serveur HTTP local sur le port $Port..."

if ($server -eq "python" -or $server -eq "python3") {
    $httpJob = Start-Job -ScriptBlock {
        param($dir, $port, $py)
        Set-Location $dir
        & $py -m http.server $port --bind 127.0.0.1
    } -ArgumentList (Resolve-Path $webDir), $Port, $server
} else {
    # npx serve
    $httpJob = Start-Job -ScriptBlock {
        param($dir, $port)
        npx serve $dir -l $port --no-clipboard
    } -ArgumentList (Resolve-Path $webDir), $Port
}

Start-Sleep -Seconds 2

# Test rapide
try {
    $r = Invoke-WebRequest "http://localhost:$Port" -UseBasicParsing -TimeoutSec 3
    Write-Ok "Serveur HTTP actif (HTTP $($r.StatusCode))"
} catch {
    Write-Fail "Serveur HTTP ne répond pas sur le port $Port"
}

# 3. Lancer le tunnel cloudflare
$cfgPath = "$env:USERPROFILE\.cloudflared\kiosk.yml"
Write-Host ""
Write-Step "Démarrage du tunnel Cloudflare → $Hostname..."

if (Test-Path $cfgPath) {
    Write-Info "Config : $cfgPath"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  🌐  Borne disponible sur :                              ║" -ForegroundColor Green
    Write-Host "║      https://$Hostname   ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Ctrl+C pour arrêter" -ForegroundColor Gray
    Write-Host ""

    try {
        cloudflared tunnel --config $cfgPath run $TunnelName
    } finally {
        # Nettoyage au Ctrl+C
        Write-Host ""
        Write-Step "Arrêt du serveur HTTP..."
        Stop-Job $httpJob -ErrorAction SilentlyContinue
        Remove-Job $httpJob -ErrorAction SilentlyContinue
        Write-Ok "Borne arrêtée proprement"
    }

} else {
    # Pas encore de config → tunnel rapide sans domaine fixe
    Write-Host ""
    Write-Host "  ⚠  Aucune config trouvée ($cfgPath)" -ForegroundColor Yellow
    Write-Host "  Tunnel temporaire (URL aléatoire) — lancez -Setup pour fixer $Hostname" -ForegroundColor Yellow
    Write-Host ""

    try {
        cloudflared tunnel --url "http://localhost:$Port"
    } finally {
        Stop-Job $httpJob -ErrorAction SilentlyContinue
        Remove-Job $httpJob -ErrorAction SilentlyContinue
    }
}
