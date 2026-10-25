# 📦 Suppression des Artifacts GitHub Actions

**Date**: 2025-12-31  
**Référence**: [GitHub Actions Run #20618818925](https://github.com/AmineId/team-oustad-app/actions/runs/20618818925/job/59216687700)

---

## 🎯 Problème Résolu

### Issue Originale
Le workflow GitHub Actions utilisait des artifacts pour transférer les fichiers de build (APK/AAB) entre différents jobs :

```yaml
# Ancien workflow (problématique)
jobs:
  build:
    - Build APK/AAB
    - Upload artifacts ❌
  
  deploy-playstore:
    - Download artifacts ❌
    - Deploy to Play Store
  
  deploy-ota:
    - Download artifacts ❌
    - Deploy OTA
```

### Problèmes avec cette Approche

1. **Stockage et Limites**
   - Les artifacts consomment de l'espace de stockage
   - Limites de rétention (30 jours par défaut)
   - Coûts de stockage pour les organisations

2. **Complexité**
   - Upload/download ajoute des étapes supplémentaires
   - Points de défaillance supplémentaires
   - Code plus complexe pour gérer les chemins de fichiers

3. **Performance**
   - Temps d'upload/download ajouté à chaque run
   - Bande passante réseau utilisée inutilement

4. **Erreurs Fréquentes**
   - Échec de l'upload (comme dans le run #20618818925)
   - Problèmes de chemin lors du download
   - Fichiers introuvables après le download

---

## ✅ Solution Implémentée

### Nouveau Workflow Consolidé

Au lieu d'avoir trois jobs séparés, nous avons consolidé en **un seul job** :

```yaml
# Nouveau workflow (optimisé)
jobs:
  build-and-deploy:
    - Build APK/AAB
    - Deploy to Play Store  ✅ (même runner)
    - Deploy OTA            ✅ (même runner)
```

### Avantages de cette Approche

1. **Simplicité**
   - Un seul job au lieu de trois
   - Pas de gestion d'artifacts
   - Code plus simple et maintenable

2. **Fiabilité**
   - Moins de points de défaillance
   - Fichiers toujours accessibles sur le même runner
   - Pas de problèmes de chemins

3. **Performance**
   - Pas de temps d'upload/download
   - Exécution plus rapide
   - Moins d'utilisation réseau

4. **Coûts**
   - Pas de stockage d'artifacts
   - Moins de minutes GitHub Actions utilisées

---

## 🔄 Changements Détaillés

### Fichiers Modifiés

**`.github/workflows/semantic-release.yml`**

#### Supprimé
```yaml
# Upload artifacts (supprimé)
- name: 📤 Upload artifacts
  uses: actions/upload-artifact@v4
  with:
    name: release-${{ needs.version.outputs.environment }}
    path: |
      build/app/outputs/flutter-apk/app-release.apk
      build/app/outputs/bundle/release/app-release.aab
      version-metadata.json

# Download artifacts (supprimé)
- name: 📥 Download artifacts
  uses: actions/download-artifact@v4
  with:
    name: release-${{ needs.version.outputs.environment }}
```

#### Ajouté/Modifié
```yaml
# Job consolidé
build-and-deploy:
  name: 🏗️ Build & Deploy
  needs: version
  runs-on: ubuntu-latest
  steps:
    # ... build steps ...
    # ... deploy-playstore steps (inline) ...
    # ... deploy-ota steps (inline) ...
```

### Structure des Jobs

**Avant** (3 jobs séparés) :
```
version (job 1)
  ↓
build (job 2)
  ├─ upload artifacts
  ↓
deploy-playstore (job 3)
  ├─ download artifacts
  ↓
deploy-ota (job 4)
  └─ download artifacts
```

**Après** (2 jobs) :
```
version (job 1)
  ↓
build-and-deploy (job 2)
  ├─ build
  ├─ deploy playstore
  └─ deploy ota
```

### Chemins de Fichiers

Les chemins sont maintenant **directs** car tout se passe sur le même runner :

```bash
# Play Store Deploy
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

# OTA Deploy
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# Metadata
jq -r 'to_entries | map("\(.key)=\(.value)") | .[]' version-metadata.json >> $GITHUB_OUTPUT
```

Plus besoin de :
- Chercher les fichiers avec `find`
- Gérer les chemins relatifs après download
- Vérifier l'existence des artifacts

---

## 📊 Impact

### Lignes de Code
- **Supprimées** : ~83 lignes (jobs séparés + artifact operations)
- **Ajoutées** : ~25 lignes (consolidation)
- **Net** : -58 lignes de code

### Temps d'Exécution
- Upload artifacts : ~10-30 secondes (supprimé)
- Download artifacts : ~5-15 secondes × 2 jobs (supprimé)
- **Gain estimé** : 20-60 secondes par workflow run

### Fiabilité
- 3 points de défaillance supprimés (upload + 2 downloads)
- Chemins de fichiers simplifiés
- Pas de gestion d'artifacts

---

## 🧪 Testing

### Comment Tester

1. **Push un commit sur staging** :
   ```bash
   git commit -m "feat: test artifact removal"
   git push origin staging
   ```

2. **Vérifier le workflow** :
   - Aller sur https://github.com/AmineId/team-oustad-app/actions
   - Observer que seuls 2 jobs s'exécutent :
     - ✅ Version & Changelog
     - ✅ Build & Deploy

3. **Vérifier les étapes** dans le job "Build & Deploy" :
   - ✅ Build APK
   - ✅ Build AAB
   - ✅ Deploy to Play Store
   - ✅ Deploy OTA
   - Pas d'étape upload/download artifacts

### Résultats Attendus

✅ Le workflow doit :
- Compiler APK et AAB avec succès
- Déployer vers Play Store Internal Testing
- Déployer vers le serveur OTA
- Se terminer sans erreurs

❌ Il ne doit PLUS :
- Uploader des artifacts
- Downloader des artifacts
- Avoir des erreurs de chemins de fichiers

---

## 📚 Documentation Mise à Jour

Les fichiers suivants ont été mis à jour pour refléter ces changements :

1. **docs/FILES_CHANGED_PLAY_STORE.md**
   - Section workflow mise à jour

2. **docs/DEPLOY_PLAY_STORE_STATUS.md**
   - Pipeline CI/CD mis à jour
   - Section monitoring mise à jour

3. **docs/ARTIFACT_REMOVAL_EXPLANATION.md** (ce fichier)
   - Documentation complète des changements

---

## 🔍 Références

- **Issue Original** : Échec de l'upload d'artifacts dans le run #20618818925
- **Question** : "How to purge artefacts or how not to use artefacts and do it in another way?"
- **Solution** : Consolidation des jobs pour éliminer le besoin d'artifacts

### Ressources
- [GitHub Actions: Storing workflow data as artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [GitHub Actions: Using jobs](https://docs.github.com/en/actions/using-jobs)

---

## 💡 Bonnes Pratiques

### Quand Utiliser des Artifacts

Les artifacts sont utiles pour :
- Partager des fichiers entre workflow runs différents
- Conserver des fichiers pour analyse post-mortem
- Distribuer des builds aux testeurs manuellement

### Quand NE PAS Utiliser des Artifacts

Évitez les artifacts pour :
- ❌ Transférer des fichiers entre jobs du même workflow
- ❌ Données temporaires qui ne servent qu'une fois
- ❌ Fichiers de build qui seront immédiatement déployés

### Alternative Recommandée

Pour partager des données entre jobs dans le même workflow :

1. **Consolidation de jobs** (notre solution) ✅
   - Meilleure performance
   - Code plus simple
   - Moins de points de défaillance

2. **Job outputs** pour petites données
   ```yaml
   outputs:
     version: ${{ steps.version.outputs.version }}
   ```

3. **Cache** pour dépendances
   ```yaml
   - uses: actions/cache@v3
     with:
       path: ~/.pub-cache
       key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.yaml') }}
   ```

---

## ✅ Résumé

**Avant** :
- 3 jobs séparés nécessitant des artifacts
- Upload/download d'artifacts à chaque run
- Complexité et points de défaillance supplémentaires

**Après** :
- 1 job consolidé sans artifacts
- Fichiers partagés sur le même runner
- Code plus simple et plus fiable

**Résultat** :
- ✅ Moins de code
- ✅ Plus rapide
- ✅ Plus fiable
- ✅ Pas de coûts de stockage d'artifacts
- ✅ Pas d'erreurs d'upload/download

---

*Dernière mise à jour : 2025-12-31*
