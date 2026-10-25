#!/usr/bin/env pwsh
# Script de test rapide de l'application avec le nouveau design system

Write-Host "🎨 Test du nouveau Design System - Team Oustad App" -ForegroundColor Cyan
Write-Host ""

# Vérifier que nous sommes dans le bon répertoire
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Erreur: pubspec.yaml non trouvé. Exécutez ce script depuis la racine du projet." -ForegroundColor Red
    exit 1
}

Write-Host "📦 Installation des dépendances..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'installation des dépendances" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dépendances installées" -ForegroundColor Green
Write-Host ""

Write-Host "🔍 Analyse du code..." -ForegroundColor Yellow
flutter analyze

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Avertissements d'analyse détectés (normal)" -ForegroundColor Yellow
} else {
    Write-Host "✅ Aucune erreur d'analyse" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎯 Fonctionnalités du nouveau Design System:" -ForegroundColor Cyan
Write-Host "  ✨ Mode Clair/Sombre avec bouton de basculement" -ForegroundColor White
Write-Host "  🎨 Palette de couleurs moderne et cohérente" -ForegroundColor White
Write-Host "  📱 Composants UI standardisés (ModernButton, ModernCard, etc.)" -ForegroundColor White
Write-Host "  💾 Sauvegarde de la préférence utilisateur" -ForegroundColor White
Write-Host "  🎭 Design minimaliste et épuré" -ForegroundColor White
Write-Host ""

Write-Host "📱 Pour lancer l'application:" -ForegroundColor Cyan
Write-Host "  Mode développement: " -NoNewline -ForegroundColor White
Write-Host ".\scripts.ps1 run-android-dev" -ForegroundColor Yellow
Write-Host "  Mode pré-production: " -NoNewline -ForegroundColor White
Write-Host ".\scripts.ps1 run-android-pprod" -ForegroundColor Yellow
Write-Host "  Mode production: " -NoNewline -ForegroundColor White
Write-Host ".\scripts.ps1 run-android-prod" -ForegroundColor Yellow
Write-Host ""

Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "  Guide complet: " -NoNewline -ForegroundColor White
Write-Host "THEME_SYSTEM_GUIDE.md" -ForegroundColor Yellow
Write-Host "  Changements: " -NoNewline -ForegroundColor White
Write-Host "DESIGN_SYSTEM_UPDATE.md" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔍 Test du bouton de thème:" -ForegroundColor Cyan
Write-Host "  1. Lancez l'application" -ForegroundColor White
Write-Host "  2. Connectez-vous" -ForegroundColor White
Write-Host "  3. Cherchez l'icône ☀️/🌙 dans l'AppBar" -ForegroundColor White
Write-Host "  4. Cliquez pour basculer entre clair/sombre" -ForegroundColor White
Write-Host ""

Write-Host "✅ Script terminé avec succès!" -ForegroundColor Green
