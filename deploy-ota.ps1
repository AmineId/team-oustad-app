# Script de déploiement OTA automatique
# Usage: 
#   .\deploy-ota.ps1                                    # Utilise version-metadata.json
#   .\deploy-ota.ps1 -Environment prod                  # Déploie en production
#   .\deploy-ota.ps1 -Version "1.0.1" -BuildNumber 2    # Override manuel

param(
    [Parameter()]
    [string]$Version,
    
    [Parameter()]
    [int]$BuildNumber = 0,
    
    [Parameter()]
    [string]$Changelog,
    
    [Parameter()]
    [ValidateSet("pprod", "prod")]
    [string]$Environment = "pprod",
    
    [Parameter()]
    [string]$ServerHost = "51.178.41.135",
    
    [Parameter()]
    [string]$ServerUser = "root",
    
    [Parameter()]
    [string]$ServerPath = "/root/team-server/db-server",
    
    [Parameter()]
    [string]$MetadataFile = ".\version-metadata.json"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Déploiement OTA Android - Team Fitness App            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Étape 0: Charger les métadonnées de version
if (-not $Version -or $BuildNumber -eq 0) {
    Write-Host "📋 Chargement de version-metadata.json..." -ForegroundColor Cyan
    
    if (-not (Test-Path $MetadataFile)) {
        Write-Host "   ❌ Fichier $MetadataFile introuvable" -ForegroundColor Red
        Write-Host "   Créez ce fichier ou spécifiez -Version et -BuildNumber manuellement" -ForegroundColor Yellow
        exit 1
    }
    
    try {
        $metadata = Get-Content $MetadataFile -Raw | ConvertFrom-Json
        
        if (-not $Version) { $Version = $metadata.version_name }
        if ($BuildNumber -eq 0) { $BuildNumber = $metadata.version_code }
        if (-not $Changelog) { $Changelog = $metadata.changelog }
        
        Write-Host "   ✅ Métadonnées chargées:" -ForegroundColor Green
        Write-Host "      Version: $Version (Build $BuildNumber)" -ForegroundColor Gray
        Write-Host "      Obligatoire: $($metadata.force_update)" -ForegroundColor Gray
        Write-Host "      Date: $($metadata.release_date)" -ForegroundColor Gray
        
        # Mettre à jour la date de build
        $metadata.build_info.build_date = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        $metadata.build_info.environment = $Environment
        
        # Sauvegarder les métadonnées mises à jour
        $metadata | ConvertTo-Json -Depth 10 | Set-Content $MetadataFile -NoNewline
        
    } catch {
        Write-Host "   ❌ Erreur lors de la lecture de $MetadataFile" -ForegroundColor Red
        Write-Host "   $_" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

Write-Host "📱 Version: $Version (Build $BuildNumber)" -ForegroundColor Yellow
Write-Host "🌍 Environment: $Environment" -ForegroundColor Yellow
Write-Host "📝 Changelog: $($Changelog.Substring(0, [Math]::Min(60, $Changelog.Length)))..." -ForegroundColor Yellow
Write-Host "🖥️  Serveur: $ServerUser@$ServerHost" -ForegroundColor Yellow
Write-Host ""

# Étape 1: Mettre à jour pubspec.yaml
Write-Host "📝 Étape 1/5: Mise à jour de pubspec.yaml..." -ForegroundColor Cyan
$pubspecPath = ".\pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw

# Remplacer la ligne version
$pubspecContent = $pubspecContent -replace 'version:\s+[\d\.]+\+\d+', "version: $Version+$BuildNumber"
Set-Content -Path $pubspecPath -Value $pubspecContent -NoNewline

Write-Host "   ✅ Version mise à jour: $Version+$BuildNumber" -ForegroundColor Green
Write-Host ""

# Étape 2: Builder l'APK
Write-Host "🔨 Étape 2/5: Build de l'APK..." -ForegroundColor Cyan
$buildCommand = if ($Environment -eq "prod") { "build-apk-prod" } else { "build-apk-pprod" }

Write-Host "   Exécution: .\scripts.ps1 $buildCommand" -ForegroundColor Gray
& .\scripts.ps1 $buildCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Erreur lors du build" -ForegroundColor Red
    exit 1
}

$apkPath = ".\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "   ❌ APK introuvable: $apkPath" -ForegroundColor Red
    exit 1
}

$apkSize = (Get-Item $apkPath).Length / 1MB
Write-Host "   ✅ APK généré: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Green
Write-Host ""

# Étape 3: Upload vers le serveur
Write-Host "📤 Étape 3/5: Upload vers le serveur..." -ForegroundColor Cyan
$remoteTempPath = "/tmp/app-release-$BuildNumber.apk"

Write-Host "   Transfert SCP vers ${ServerHost}:${remoteTempPath}" -ForegroundColor Gray

# Vérifier si scp est disponible
$scpExists = Get-Command scp -ErrorAction SilentlyContinue
if (-not $scpExists) {
    Write-Host "   ⚠️  SCP non trouvé. Installation d'OpenSSH Client recommandée." -ForegroundColor Yellow
    Write-Host "   Alternatives:" -ForegroundColor Yellow
    Write-Host "   1. Installer OpenSSH: Settings > Apps > Optional Features > OpenSSH Client" -ForegroundColor Gray
    Write-Host "   2. Utiliser WinSCP ou FileZilla pour uploader manuellement" -ForegroundColor Gray
    Write-Host "   3. Utiliser WSL: wsl scp $apkPath ${ServerUser}@${ServerHost}:${remoteTempPath}" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   📂 APK à uploader: $apkPath" -ForegroundColor Yellow
    Write-Host "   📍 Destination: ${ServerUser}@${ServerHost}:${remoteTempPath}" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "   Appuyez sur Entrée une fois l'upload terminé manuellement"
} else {
    scp $apkPath "${ServerUser}@${ServerHost}:${remoteTempPath}"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Erreur lors de l'upload SCP" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ✅ Upload terminé" -ForegroundColor Green
}
Write-Host ""

# Étape 4: Déploiement sur le serveur
Write-Host "🚀 Étape 4/5: Déploiement OTA sur le serveur..." -ForegroundColor Cyan

$deployScript = "$ServerPath/scripts/deploy-android-apk.sh"
$changelogEscaped = $Changelog -replace '"', '\"'

$sshCommand = @"
cd $ServerPath && \
$deployScript \
  $remoteTempPath \
  $BuildNumber \
  "$Version" \
  "$changelogEscaped" && \
rm -f $remoteTempPath
"@

Write-Host "   Exécution du script de déploiement..." -ForegroundColor Gray

$sshExists = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $sshExists) {
    Write-Host "   ⚠️  SSH non trouvé. Commande à exécuter manuellement:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   ssh ${ServerUser}@${ServerHost}" -ForegroundColor Gray
    Write-Host "   cd $ServerPath" -ForegroundColor Gray
    Write-Host "   $deployScript $remoteTempPath $BuildNumber `"$Version`" `"$changelogEscaped`"" -ForegroundColor Gray
    Write-Host "   rm -f $remoteTempPath" -ForegroundColor Gray
    Write-Host ""
    Read-Host "   Appuyez sur Entrée une fois le déploiement terminé"
} else {
    ssh "${ServerUser}@${ServerHost}" $sshCommand
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Erreur lors du déploiement" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ✅ Déploiement terminé" -ForegroundColor Green
}
Write-Host ""

# Étape 5: Vérification
Write-Host "✅ Étape 5/5: Vérification..." -ForegroundColor Cyan

$testUrl = "https://app.team-oustad.com/android/version.json"
Write-Host "   Test de l'API: $testUrl" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri $testUrl -Method Get
    Write-Host "   ✅ API accessible" -ForegroundColor Green
    Write-Host "   📦 Version déployée: $($response.version_name) (Build $($response.version_code))" -ForegroundColor Green
    
    if ($response.version_code -eq $BuildNumber) {
        Write-Host "   ✅ Version correspondante !" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Version différente (attendu: $BuildNumber, reçu: $($response.version_code))" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  Impossible de vérifier l'API (peut prendre quelques secondes)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    ✅ DÉPLOIEMENT TERMINÉ !                    ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Version: $Version+$BuildNumber" -ForegroundColor White
Write-Host "🌍 Environment: $Environment" -ForegroundColor White
Write-Host "📝 Changelog: $Changelog" -ForegroundColor White
Write-Host ""
Write-Host "🔗 URLs de test:" -ForegroundColor Yellow
Write-Host "   Version JSON: https://app.team-oustad.com/android/version.json" -ForegroundColor Gray
Write-Host "   Check Update: https://app.team-oustad.com/android/check-update?current_version=1" -ForegroundColor Gray
Write-Host "   Download APK: https://app.team-oustad.com/android/download" -ForegroundColor Gray
Write-Host ""
Write-Host "📲 Les utilisateurs peuvent maintenant mettre à jour l'application !" -ForegroundColor Cyan
Write-Host ""
