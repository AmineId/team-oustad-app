# deploy-web.ps1
# Script de déploiement automatique pour Team Fitness Web

# ========================================
# CONFIGURATION - Modifiez ces valeurs
# ========================================
$VPS_IP = "46.62.194.206"  # ← Remplacez par l'IP de votre VPS
$VPS_USER = "root"
$VPS_PATH = "/var/www/team-fitness-app"
$ENVIRONMENT = "pprod"  # pprod ou prod

# ========================================
# SCRIPT DE DÉPLOIEMENT
# ========================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🚀 Déploiement Team Fitness Web                          ║" -ForegroundColor Cyan
Write-Host "║   📍 Destination: app.team-oustad.com                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Vérification de l'IP VPS
if ($VPS_IP -eq "VOTRE-IP-VPS-ICI") {
    Write-Host "❌ ERREUR: Vous devez configurer l'IP du VPS dans le script!" -ForegroundColor Red
    Write-Host "   Ouvrez deploy-web.ps1 et modifiez la ligne:" -ForegroundColor Yellow
    Write-Host '   $VPS_IP = "VOTRE-IP-VPS-ICI"' -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ========================================
# 1. BUILD
# ========================================
Write-Host "📦 Build Flutter Web ($ENVIRONMENT)..." -ForegroundColor Yellow
Write-Host "   └─ Compilation en cours..." -ForegroundColor Gray

flutter build web --release --dart-define=ENVIRONMENT=$ENVIRONMENT --no-source-maps

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du build Flutter" -ForegroundColor Red
    exit 1
}

Write-Host "   ✓ Build réussi" -ForegroundColor Green
Write-Host ""

# ========================================
# 2. UPLOAD
# ========================================
Write-Host "📤 Upload vers VPS ($VPS_IP)..." -ForegroundColor Yellow
Write-Host "   └─ Transfert des fichiers..." -ForegroundColor Gray

scp -r build/web/* ${VPS_USER}@${VPS_IP}:${VPS_PATH}/

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'upload" -ForegroundColor Red
    Write-Host "   Vérifiez:" -ForegroundColor Yellow
    Write-Host "   - Que vous pouvez vous connecter en SSH: ssh ${VPS_USER}@${VPS_IP}" -ForegroundColor Yellow
    Write-Host "   - Que le dossier existe: ${VPS_PATH}" -ForegroundColor Yellow
    exit 1
}

Write-Host "   ✓ Upload réussi" -ForegroundColor Green
Write-Host ""

# ========================================
# 3. RELOAD NGINX
# ========================================
Write-Host "🔄 Reload Nginx..." -ForegroundColor Yellow
Write-Host "   └─ Test et rechargement de la configuration..." -ForegroundColor Gray

ssh ${VPS_USER}@${VPS_IP} "sudo nginx -t && sudo systemctl reload nginx"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du reload Nginx" -ForegroundColor Red
    Write-Host "   Connectez-vous au VPS et vérifiez:" -ForegroundColor Yellow
    Write-Host "   sudo nginx -t" -ForegroundColor Yellow
    Write-Host "   sudo tail -f /var/log/nginx/error.log" -ForegroundColor Yellow
    exit 1
}

Write-Host "   ✓ Nginx rechargé" -ForegroundColor Green
Write-Host ""

# ========================================
# SUCCÈS
# ========================================
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ Déploiement terminé avec succès !                    ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 App Web:     https://app.team-oustad.com" -ForegroundColor Cyan
Write-Host "📱 OTA Android: https://app.team-oustad.com/android" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Testez votre application dans un navigateur!" -ForegroundColor White
Write-Host ""
