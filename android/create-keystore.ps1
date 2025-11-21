# Script pour créer un keystore de production Android
# Ce keystore sera utilisé pour signer l'application en production

Write-Host "🔐 Création du keystore de production pour Team Fitness App" -ForegroundColor Cyan
Write-Host ""

# Vérifier que keytool est disponible
$keytoolPath = "keytool"
try {
    $null = & $keytoolPath -version 2>&1
} catch {
    Write-Host "❌ keytool n'est pas trouvé. Assurez-vous que Java JDK est installé." -ForegroundColor Red
    Write-Host "Téléchargez Java JDK depuis: https://www.oracle.com/java/technologies/downloads/" -ForegroundColor Yellow
    exit 1
}

Write-Host "📋 Informations requises pour le certificat:" -ForegroundColor Yellow
Write-Host ""

# Demander les informations
$keystorePassword = Read-Host "Mot de passe du keystore (minimum 6 caractères)" -AsSecureString
$keystorePasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keystorePassword)
)

$keyPassword = Read-Host "Mot de passe de la clé (minimum 6 caractères)" -AsSecureString
$keyPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword)
)

$commonName = Read-Host "Nom (CN) [par défaut: Team Fitness]"
if ([string]::IsNullOrWhiteSpace($commonName)) { $commonName = "Team Fitness" }

$orgUnit = Read-Host "Unité organisationnelle (OU) [par défaut: Development]"
if ([string]::IsNullOrWhiteSpace($orgUnit)) { $orgUnit = "Development" }

$org = Read-Host "Organisation (O) [par défaut: Team Fitness]"
if ([string]::IsNullOrWhiteSpace($org)) { $org = "Team Fitness" }

$city = Read-Host "Ville (L) [par défaut: Paris]"
if ([string]::IsNullOrWhiteSpace($city)) { $city = "Paris" }

$state = Read-Host "État/Province (ST) [par défaut: Ile-de-France]"
if ([string]::IsNullOrWhiteSpace($state)) { $state = "Ile-de-France" }

$country = Read-Host "Code pays (C) [par défaut: FR]"
if ([string]::IsNullOrWhiteSpace($country)) { $country = "FR" }

Write-Host ""
Write-Host "🔨 Génération du keystore..." -ForegroundColor Cyan

# Créer le keystore
$keystorePath = Join-Path $PSScriptRoot "upload-keystore.jks"
$dname = "CN=$commonName, OU=$orgUnit, O=$org, L=$city, ST=$state, C=$country"

try {
    & keytool -genkeypair `
        -v `
        -storetype JKS `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -alias upload `
        -keystore $keystorePath `
        -storepass $keystorePasswordText `
        -keypass $keyPasswordText `
        -dname $dname

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Keystore créé avec succès: $keystorePath" -ForegroundColor Green
        Write-Host ""
        
        # Créer le fichier key.properties
        $keyPropertiesPath = Join-Path $PSScriptRoot "key.properties"
        $keyPropertiesContent = @"
storePassword=$keystorePasswordText
keyPassword=$keyPasswordText
keyAlias=upload
storeFile=upload-keystore.jks
"@
        
        $keyPropertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8
        
        Write-Host "✅ Fichier key.properties créé" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  IMPORTANT: Sauvegardez ces fichiers de manière sécurisée:" -ForegroundColor Yellow
        Write-Host "   - $keystorePath" -ForegroundColor White
        Write-Host "   - $keyPropertiesPath" -ForegroundColor White
        Write-Host ""
        Write-Host "⚠️  NE COMMITEZ PAS ces fichiers dans Git!" -ForegroundColor Red
        Write-Host "   (Ils sont déjà dans .gitignore)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "📦 Vous pouvez maintenant builder l'APK/AAB de production avec:" -ForegroundColor Cyan
        Write-Host "   flutter build apk --release" -ForegroundColor White
        Write-Host "   flutter build appbundle --release" -ForegroundColor White
        Write-Host ""
        Write-Host "🚀 Prochaine étape: Configurer les secrets GitHub" -ForegroundColor Cyan
        Write-Host "   Exécutez: .\setup-github-secrets.ps1" -ForegroundColor White
        
    } else {
        throw "Erreur lors de la création du keystore"
    }
} catch {
    Write-Host ""
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
    exit 1
}
