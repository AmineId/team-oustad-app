# Script de test de la configuration Android
# Vérifie que tout est prêt pour le déploiement Play Store

Write-Host "🔍 Vérification de la configuration Android pour Play Store" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Test 1: Keystore
Write-Host "1️⃣  Vérification du keystore..." -ForegroundColor Yellow
$keystorePath = Join-Path $PSScriptRoot "upload-keystore.jks"
if (Test-Path $keystorePath) {
    Write-Host "   ✅ Keystore trouvé: $keystorePath" -ForegroundColor Green
    
    # Vérifier les détails du keystore
    try {
        $keystoreInfo = & keytool -list -v -keystore $keystorePath -storepass $(
            (Get-Content (Join-Path $PSScriptRoot "key.properties") | 
            Where-Object { $_ -match "^storePassword=" }) -replace "storePassword=", ""
        ) 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Keystore valide" -ForegroundColor Green
            $keystoreInfo | Select-String "Alias name:|Valid from:" | ForEach-Object {
                Write-Host "      $_" -ForegroundColor Gray
            }
        } else {
            Write-Host "   ⚠️  Impossible de lire le keystore" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ⚠️  Erreur lors de la lecture du keystore: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ Keystore non trouvé" -ForegroundColor Red
    Write-Host "      Exécutez: .\create-keystore.ps1" -ForegroundColor Yellow
    $allGood = $false
}
Write-Host ""

# Test 2: key.properties
Write-Host "2️⃣  Vérification de key.properties..." -ForegroundColor Yellow
$keyPropertiesPath = Join-Path $PSScriptRoot "key.properties"
if (Test-Path $keyPropertiesPath) {
    Write-Host "   ✅ key.properties trouvé" -ForegroundColor Green
    
    $props = Get-Content $keyPropertiesPath
    $requiredProps = @("storePassword", "keyPassword", "keyAlias", "storeFile")
    
    foreach ($prop in $requiredProps) {
        if ($props -match "^$prop=") {
            Write-Host "   ✅ $prop configuré" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $prop manquant" -ForegroundColor Red
            $allGood = $false
        }
    }
} else {
    Write-Host "   ❌ key.properties non trouvé" -ForegroundColor Red
    Write-Host "      Exécutez: .\create-keystore.ps1" -ForegroundColor Yellow
    $allGood = $false
}
Write-Host ""

# Test 3: build.gradle.kts
Write-Host "3️⃣  Vérification de build.gradle.kts..." -ForegroundColor Yellow
$buildGradlePath = Join-Path $PSScriptRoot "app\build.gradle.kts"
if (Test-Path $buildGradlePath) {
    $content = Get-Content $buildGradlePath -Raw
    
    if ($content -match "signingConfigs") {
        Write-Host "   ✅ Configuration de signature présente" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Configuration de signature manquante" -ForegroundColor Yellow
        Write-Host "      Voir BACKUP_ANDROID_SIGNING_CONFIG.md" -ForegroundColor Yellow
    }
    
    if ($content -match "keystoreProperties") {
        Write-Host "   ✅ Chargement de key.properties configuré" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Chargement de key.properties manquant" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ build.gradle.kts non trouvé" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# Test 4: Fastlane
Write-Host "4️⃣  Vérification de Fastlane..." -ForegroundColor Yellow
$fastlanePath = Join-Path $PSScriptRoot "fastlane"
if (Test-Path $fastlanePath) {
    Write-Host "   ✅ Dossier fastlane trouvé" -ForegroundColor Green
    
    $fastfile = Join-Path $fastlanePath "Fastfile"
    if (Test-Path $fastfile) {
        Write-Host "   ✅ Fastfile présent" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Fastfile manquant" -ForegroundColor Red
        $allGood = $false
    }
    
    $appfile = Join-Path $fastlanePath "Appfile"
    if (Test-Path $appfile) {
        Write-Host "   ✅ Appfile présent" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Appfile manquant" -ForegroundColor Red
        $allGood = $false
    }
    
    $serviceAccount = Join-Path $fastlanePath "service-account-key.json"
    if (Test-Path $serviceAccount) {
        Write-Host "   ✅ Service account key présent (local)" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️  Service account key non trouvé (normal en local)" -ForegroundColor Cyan
        Write-Host "      Sera configuré via GitHub Secrets en CI/CD" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ Dossier fastlane non trouvé" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# Test 5: Firebase
Write-Host "5️⃣  Vérification de Firebase..." -ForegroundColor Yellow
$googleServicesPprod = Join-Path $PSScriptRoot "app\google-services-pprod.json"
$googleServicesProd = Join-Path $PSScriptRoot "app\google-services-prod.json"

if (Test-Path $googleServicesPprod) {
    Write-Host "   ✅ google-services-pprod.json présent" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  google-services-pprod.json manquant" -ForegroundColor Yellow
}

if (Test-Path $googleServicesProd) {
    Write-Host "   ✅ google-services-prod.json présent" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  google-services-prod.json manquant" -ForegroundColor Yellow
}
Write-Host ""

# Test 6: Java/keytool
Write-Host "6️⃣  Vérification des outils..." -ForegroundColor Yellow
try {
    $javaVersion = & java -version 2>&1 | Select-Object -First 1
    Write-Host "   ✅ Java installé: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Java non trouvé" -ForegroundColor Yellow
}

try {
    $keytoolVersion = & keytool 2>&1 | Select-Object -First 1
    Write-Host "   ✅ keytool disponible" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  keytool non trouvé" -ForegroundColor Yellow
}
Write-Host ""

# Résumé
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

if ($allGood) {
    Write-Host "✅ Configuration complète et prête pour le déploiement !" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Prochaines étapes:" -ForegroundColor Cyan
    Write-Host "   1. Configurez les secrets GitHub (.\setup-github-secrets.ps1)" -ForegroundColor White
    Write-Host "   2. Créez un Service Account Google Cloud" -ForegroundColor White
    Write-Host "   3. Liez le service account dans Play Console" -ForegroundColor White
    Write-Host "   4. Faites le premier upload manuel de l'AAB" -ForegroundColor White
    Write-Host ""
    Write-Host "📖 Guide complet: ..\GOOGLE_PLAY_SETUP.md" -ForegroundColor Cyan
    Write-Host "📖 Guide rapide: ..\GUIDE_RAPIDE_PLAY_STORE.md" -ForegroundColor Cyan
} else {
    Write-Host "❌ Configuration incomplète" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Actions requises:" -ForegroundColor Yellow
    Write-Host "   1. Exécutez: .\create-keystore.ps1" -ForegroundColor White
    Write-Host "   2. Vérifiez build.gradle.kts (voir BACKUP_ANDROID_SIGNING_CONFIG.md)" -ForegroundColor White
    Write-Host "   3. Exécutez: .\setup-github-secrets.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "📖 Documentation: ..\GOOGLE_PLAY_SETUP.md" -ForegroundColor Cyan
}

Write-Host ""
