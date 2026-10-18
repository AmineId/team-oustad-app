# Script pour incrémenter automatiquement la version
# Usage: .\scripts\bump-version.ps1 [-Type major|minor|patch] [-Changelog "Description"]

param(
    [Parameter()]
    [ValidateSet("major", "minor", "patch")]
    [string]$Type = "patch",
    
    [Parameter()]
    [string]$Changelog,
    
    [Parameter()]
    [string]$MetadataFile = ".\version-metadata.json"
)

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              Incrémentation de version - Team Fitness           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Charger les métadonnées actuelles
if (-not (Test-Path $MetadataFile)) {
    Write-Host "❌ Fichier $MetadataFile introuvable" -ForegroundColor Red
    exit 1
}

$metadata = Get-Content $MetadataFile -Raw | ConvertFrom-Json

# Version actuelle
$currentVersion = $metadata.version_name
$currentBuild = $metadata.version_code

Write-Host "📦 Version actuelle: $currentVersion (Build $currentBuild)" -ForegroundColor White
Write-Host "🔼 Type d'incrémentation: $Type" -ForegroundColor Yellow
Write-Host ""

# Parser la version (format: major.minor.patch)
$versionParts = $currentVersion -split '\.'
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]

# Incrémenter selon le type
switch ($Type) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
    }
    "minor" {
        $minor++
        $patch = 0
    }
    "patch" {
        $patch++
    }
}

$newVersion = "$major.$minor.$patch"
$newBuild = $currentBuild + 1

Write-Host "📦 Nouvelle version: $newVersion (Build $newBuild)" -ForegroundColor Green
Write-Host ""

# Demander le changelog si non fourni
if (-not $Changelog) {
    Write-Host "📝 Veuillez entrer le changelog (Ctrl+C pour annuler):" -ForegroundColor Yellow
    Write-Host "   (Utilisez \n pour les retours à la ligne)" -ForegroundColor Gray
    Write-Host ""
    $Changelog = Read-Host "   Changelog"
    
    if (-not $Changelog) {
        Write-Host "❌ Changelog requis" -ForegroundColor Red
        exit 1
    }
}

# Mettre à jour les métadonnées
$metadata.version_name = $newVersion
$metadata.version_code = $newBuild
$metadata.changelog = $Changelog -replace '\\n', "`n"
$metadata.release_date = Get-Date -Format "yyyy-MM-dd"
$metadata.build_info.build_date = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

# Sauvegarder
$metadata | ConvertTo-Json -Depth 10 | Set-Content $MetadataFile

Write-Host "✅ Métadonnées mises à jour dans $MetadataFile" -ForegroundColor Green
Write-Host ""

# Mettre à jour pubspec.yaml
$pubspecPath = ".\pubspec.yaml"
if (Test-Path $pubspecPath) {
    $pubspecContent = Get-Content $pubspecPath -Raw
    $pubspecContent = $pubspecContent -replace 'version:\s+[\d\.]+\+\d+', "version: $newVersion+$newBuild"
    Set-Content -Path $pubspecPath -Value $pubspecContent -NoNewline
    Write-Host "✅ pubspec.yaml mis à jour: $newVersion+$newBuild" -ForegroundColor Green
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    Version incrémentée !                        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Résumé:" -ForegroundColor Yellow
Write-Host "   Ancienne: $currentVersion (Build $currentBuild)" -ForegroundColor Gray
Write-Host "   Nouvelle: $newVersion (Build $newBuild)" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "   1. Vérifiez les changements dans $MetadataFile" -ForegroundColor White
Write-Host "   2. Commitez les changements: git add . && git commit -m 'Bump version to $newVersion'" -ForegroundColor White
Write-Host "   3. Déployez: .\scripts\deploy-ota.ps1" -ForegroundColor White
Write-Host ""
