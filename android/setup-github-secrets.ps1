# Script pour configurer les secrets GitHub Actions pour la signature Android
# Ce script encode le keystore en base64 et affiche les commandes pour ajouter les secrets

Write-Host "🔐 Configuration des secrets GitHub Actions pour Team Fitness App" -ForegroundColor Cyan
Write-Host ""

# Vérifier que le keystore existe
$keystorePath = Join-Path $PSScriptRoot "upload-keystore.jks"
if (-not (Test-Path $keystorePath)) {
    Write-Host "❌ Keystore non trouvé: $keystorePath" -ForegroundColor Red
    Write-Host "Exécutez d'abord: .\create-keystore.ps1" -ForegroundColor Yellow
    exit 1
}

# Vérifier que key.properties existe
$keyPropertiesPath = Join-Path $PSScriptRoot "key.properties"
if (-not (Test-Path $keyPropertiesPath)) {
    Write-Host "❌ key.properties non trouvé: $keyPropertiesPath" -ForegroundColor Red
    Write-Host "Exécutez d'abord: .\create-keystore.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "📖 Lecture des propriétés..." -ForegroundColor Cyan

# Lire les propriétés
$properties = @{}
Get-Content $keyPropertiesPath | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $properties[$matches[1]] = $matches[2]
    }
}

# Encoder le keystore en base64
Write-Host "🔄 Encodage du keystore en base64..." -ForegroundColor Cyan
$keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
$keystoreBase64 = [System.Convert]::ToBase64String($keystoreBytes)

Write-Host ""
Write-Host "✅ Configuration prête!" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 SECRETS À AJOUTER DANS GITHUB" -ForegroundColor Yellow
Write-Host ""
Write-Host "Allez sur: https://github.com/TeamFitness/mobile-app/settings/secrets/actions" -ForegroundColor Cyan
Write-Host "Cliquez sur 'New repository secret' pour chaque secret ci-dessous:" -ForegroundColor Gray
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

# Secret 1: KEYSTORE_BASE64
Write-Host "1️⃣  Secret Name: " -ForegroundColor White -NoNewline
Write-Host "KEYSTORE_BASE64" -ForegroundColor Green
Write-Host "   Secret Value: " -ForegroundColor Gray -NoNewline
Write-Host "[Copié dans le presse-papier]" -ForegroundColor Yellow
$keystoreBase64 | Set-Clipboard
Read-Host "   Appuyez sur Entrée pour continuer (le secret est dans votre presse-papier)"
Write-Host ""

# Secret 2: KEYSTORE_PASSWORD
Write-Host "2️⃣  Secret Name: " -ForegroundColor White -NoNewline
Write-Host "KEYSTORE_PASSWORD" -ForegroundColor Green
Write-Host "   Secret Value: " -ForegroundColor Gray -NoNewline
Write-Host $properties['storePassword'] -ForegroundColor Yellow
$properties['storePassword'] | Set-Clipboard
Read-Host "   Appuyez sur Entrée pour continuer (le secret est dans votre presse-papier)"
Write-Host ""

# Secret 3: KEY_PASSWORD
Write-Host "3️⃣  Secret Name: " -ForegroundColor White -NoNewline
Write-Host "KEY_PASSWORD" -ForegroundColor Green
Write-Host "   Secret Value: " -ForegroundColor Gray -NoNewline
Write-Host $properties['keyPassword'] -ForegroundColor Yellow
$properties['keyPassword'] | Set-Clipboard
Read-Host "   Appuyez sur Entrée pour continuer (le secret est dans votre presse-papier)"
Write-Host ""

# Secret 4: KEY_ALIAS
Write-Host "4️⃣  Secret Name: " -ForegroundColor White -NoNewline
Write-Host "KEY_ALIAS" -ForegroundColor Green
Write-Host "   Secret Value: " -ForegroundColor Gray -NoNewline
Write-Host $properties['keyAlias'] -ForegroundColor Yellow
$properties['keyAlias'] | Set-Clipboard
Read-Host "   Appuyez sur Entrée pour continuer (le secret est dans votre presse-papier)"
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Tous les secrets de signature Android ont été copiés!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 PROCHAINE ÉTAPE: Configurer Google Play Console" -ForegroundColor Yellow
Write-Host ""
Write-Host "   1. Créez un Service Account sur Google Cloud Console" -ForegroundColor White
Write-Host "   2. Téléchargez le fichier JSON du service account" -ForegroundColor White
Write-Host "   3. Ajoutez le secret PLAY_STORE_SERVICE_ACCOUNT_JSON sur GitHub" -ForegroundColor White
Write-Host ""
Write-Host "   📖 Guide complet: GOOGLE_PLAY_SETUP.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔒 Une fois tous les secrets ajoutés, le workflow CI/CD:" -ForegroundColor Cyan
Write-Host "   ✅ Signera automatiquement les APK/AAB" -ForegroundColor White
Write-Host "   ✅ Déploiera vers Play Store Internal Testing" -ForegroundColor White
Write-Host "   ✅ Déploiera vers le serveur OTA" -ForegroundColor White
Write-Host ""

# Sauvegarder les instructions dans un fichier
$instructionsPath = Join-Path $PSScriptRoot "github-secrets-instructions.txt"
$instructions = @"
SECRETS GITHUB ACTIONS - Team Fitness App
========================================

Repository: https://github.com/TeamFitness/mobile-app/settings/secrets/actions

Secrets de signature Android:
-----------------------------

1. KEYSTORE_BASE64
   Value: $($keystoreBase64.Substring(0, 50))... (voir fichier complet si besoin)

2. KEYSTORE_PASSWORD
   Value: $($properties['storePassword'])

3. KEY_PASSWORD
   Value: $($properties['keyPassword'])

4. KEY_ALIAS
   Value: $($properties['keyAlias'])

Secret Play Store (à ajouter séparément):
-----------------------------------------

5. PLAY_STORE_SERVICE_ACCOUNT_JSON
   Value: [Contenu du fichier JSON du service account]
   Guide: Voir GOOGLE_PLAY_SETUP.md

Secret OTA (si pas encore ajouté):
----------------------------------

6. OTA_BEARER_TOKEN
   Value: [Votre token OTA server]

Notes importantes:
-----------------
- Ne partagez JAMAIS ces valeurs publiquement
- Sauvegardez le keystore et key.properties dans un endroit sécurisé
- Supprimez ce fichier après avoir configuré les secrets

Date de génération: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

$instructions | Out-File -FilePath $instructionsPath -Encoding UTF8
Write-Host "💾 Instructions sauvegardées dans: $instructionsPath" -ForegroundColor Gray
Write-Host "   ⚠️  Supprimez ce fichier après configuration!" -ForegroundColor Red
Write-Host ""
