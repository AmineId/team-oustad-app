# Script pour configurer les secrets GitHub pour Play Store
# Assurez-vous d'avoir GitHub CLI installé : winget install GitHub.cli

Write-Host "🔐 Configuration des secrets GitHub pour Play Store" -ForegroundColor Cyan
Write-Host ""

# Vérifier si gh est installé
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI (gh) n'est pas installé." -ForegroundColor Red
    Write-Host "Installation : winget install GitHub.cli" -ForegroundColor Yellow
    Write-Host "Puis redémarrez PowerShell et relancez ce script." -ForegroundColor Yellow
    exit 1
}

# Vérifier l'authentification
Write-Host "🔍 Vérification de l'authentification GitHub..." -ForegroundColor Yellow
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Non authentifié avec GitHub CLI" -ForegroundColor Red
    Write-Host "Exécutez : gh auth login" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Authentifié avec GitHub CLI" -ForegroundColor Green
Write-Host ""

# Demander le chemin vers le fichier JSON du service account
Write-Host "📁 Entrez le chemin complet vers le fichier JSON du service account :" -ForegroundColor Cyan
Write-Host "   (ex: C:\Downloads\github-actions-play-deploy-xxxxx.json)" -ForegroundColor Gray
$jsonPath = Read-Host "Chemin"

if (-not (Test-Path $jsonPath)) {
    Write-Host "❌ Fichier non trouvé : $jsonPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Fichier trouvé" -ForegroundColor Green
Write-Host ""

# Lire le contenu du fichier JSON
Write-Host "📖 Lecture du fichier JSON..." -ForegroundColor Yellow
$jsonContent = Get-Content $jsonPath -Raw

# Vérifier que c'est un JSON valide
try {
    $jsonContent | ConvertFrom-Json | Out-Null
    Write-Host "✅ JSON valide" -ForegroundColor Green
} catch {
    Write-Host "❌ Le fichier n'est pas un JSON valide" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🚀 Configuration du secret sur GitHub..." -ForegroundColor Yellow
Write-Host ""

# Créer le secret GitHub
$jsonContent | gh secret set PLAY_STORE_SERVICE_ACCOUNT_JSON

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Secret PLAY_STORE_SERVICE_ACCOUNT_JSON configuré avec succès !" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Prochaines étapes :" -ForegroundColor Cyan
    Write-Host "  1. Vérifiez les secrets Android (keystore) : .\android\setup-github-secrets.ps1" -ForegroundColor White
    Write-Host "  2. Uploadez la première version manuellement sur Play Console" -ForegroundColor White
    Write-Host "  3. Faites un push sur staging pour tester le déploiement automatique" -ForegroundColor White
    Write-Host ""
    Write-Host "🔍 Voir tous les secrets : gh secret list" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "❌ Erreur lors de la configuration du secret" -ForegroundColor Red
    Write-Host "Vérifiez que vous avez les permissions nécessaires sur le repo" -ForegroundColor Yellow
    exit 1
}
