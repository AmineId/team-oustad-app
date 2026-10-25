#!/usr/bin/env bash
# Patch du plugin Gradle Flutter pour les builds multi-module (:app + :wear_app).
# Utilisé par pr-validation.yml et _build-android.yml (nécessite $FLUTTER_ROOT).
set -e

# Flutter 3.35.x enregistre 'generateLockfiles' et l'extension 'flutter'
# sur rootProject sans garde d'idempotence ; quand :app et :wear_app
# appliquent tous deux le plugin, le 2e enregistrement échoue.
#
# subosito/flutter-action met en cache tout $FLUTTER_ROOT, y compris
# packages/flutter_tools/gradle/build/ (classes compilées). On purge ce
# répertoire pour forcer Gradle à recompiler depuis les sources patchées.
GRADLE_SRC="$FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/kotlin"
PLUGIN_FILE="$GRADLE_SRC/FlutterPlugin.kt"
HANDLER_FILE="$GRADLE_SRC/plugins/PluginHandler.kt"
UTILS_FILE="$GRADLE_SRC/FlutterPluginUtils.kt"

# Restaure les .kt originaux si le cache a sauvegardé des versions patchées
git -C "$FLUTTER_ROOT" restore \
  packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt \
  packages/flutter_tools/gradle/src/main/kotlin/plugins/PluginHandler.kt \
  packages/flutter_tools/gradle/src/main/kotlin/FlutterPluginUtils.kt \
  2>/dev/null || echo "ℹ️  restore git flutter ignoré (git non dispo)"

# Purge les classes compilées pour forcer la recompilation depuis les sources patchées
GRADLE_CACHE="$FLUTTER_ROOT/packages/flutter_tools/gradle/build"
if [ -d "$GRADLE_CACHE" ]; then
  rm -rf "$GRADLE_CACHE"
  echo "✅ Cache Gradle plugin Flutter purgé ($GRADLE_CACHE)"
fi

echo "--- lignes clés FlutterPlugin.kt AVANT patch ---"
grep -n "extensions\.create\|tasks\.register.*generateLock\|findByName\|state\.executed\|findProject.*pluginName" "$PLUGIN_FILE" 2>/dev/null | head -10 || echo "(fichier introuvable)"
echo "--- lignes clés PluginHandler.kt AVANT patch ---"
grep -n "extensions\.create\|afterEvaluate\|findProject.*pluginName\|findByName\|state\.executed" "$HANDLER_FILE" 2>/dev/null | head -15 || echo "(fichier introuvable)"
echo "------------------------------------------------"

python3 - "$PLUGIN_FILE" "$HANDLER_FILE" "$UTILS_FILE" <<'PYEOF'
import sys, pathlib

def patch_file(path, patches):
    if not path.exists():
        print(f"⚠️  {path.name} non trouvé, patch ignoré")
        return
    content = path.read_text()
    changes = []
    for old, new in patches:
        if old in content:
            content = content.replace(old, new)
            changes.append(old[:60])
    if changes:
        path.write_text(content)
        for c in changes:
            print(f"✅ {path.name} — Patché : {c}…")
    else:
        print(f"ℹ️  {path.name} — Aucun patch nécessaire (déjà corrigé ou pattern non trouvé)")

# FlutterPlugin.kt
patch_file(pathlib.Path(sys.argv[1]), [
    # generateLockfiles sur rootProject (toutes versions)
    (
        'rootProject.tasks.register("generateLockfiles") {',
        'if (rootProject.tasks.findByName("generateLockfiles") == null) rootProject.tasks.register("generateLockfiles") {',
    ),
    # extension flutter sur rootProject (Flutter ≤ 3.36)
    (
        'rootProject.extensions.create("flutter", FlutterExtension::class.java)',
        '(rootProject.extensions.findByName("flutter") as? FlutterExtension) ?: rootProject.extensions.create("flutter", FlutterExtension::class.java)',
    ),
    # extension flutter sur project (Flutter ≥ 3.37 et 3.35.x inside allprojects)
    (
        'project.extensions.create("flutter", FlutterExtension::class.java)',
        '(project.extensions.findByName("flutter") as? FlutterExtension) ?: project.extensions.create("flutter", FlutterExtension::class.java)',
    ),
])

# PluginHandler.kt
# configurePlugins() est déclenché depuis applicationVariants.configureEach,
# qui s'exécute dans l'afterEvaluate d'AGP (création des variants).
# Gradle 8 interdit d'appeler project.afterEvaluate{} depuis l'intérieur
# d'un afterEvaluate déjà en cours → "Cannot run afterEvaluate when already
# evaluated". Les plugin projects, eux, ne sont PAS encore évalués à ce stade.
#
# Pour :wear_app (2e module app), les plugins sont déjà configurés et évalués
# par :app. On NE doit PAS sauter configurePluginProject : c'est lui qui ajoute
# les plugins en dépendance du module app, et l'embedding Flutter
# (io.flutter:flutter_embedding_*) n'arrive dans un module app avec plugins
# QUE transitivement via ces plugins. Sans ça → "Unresolved reference 'io'".
#
# Fix 1 : extension 'flutter' sur le plugin créée seulement si absente.
# Fix 2 : project.afterEvaluate{} → run{} pour exécuter inline
#         (project = :app est configuré, ses buildTypes sont disponibles).
# Fix 3 : pluginProject.afterEvaluate{} sauté si le plugin est déjà évalué
#         (= déjà configuré par :app : avertissement compileSdk + embedding
#         ajouté au plugin). L'exécuter tout de suite planterait : on est au
#         apply du plugin Flutter dans :wear_app, avant son bloc android{}
#         → compileSdkVersion null (NPE dans getCompileSdkFromProject).
# Fix 4 : early-return dans configurePluginDependencies uniquement — les
#         dépendances plugin→plugin ont déjà été posées lors du passage de :app.
patch_file(pathlib.Path(sys.argv[2]), [
    # Fix 1
    (
        'pluginProject.extensions.create("flutter", FlutterExtension::class.java)',
        'if (pluginProject.extensions.findByName("flutter") == null) pluginProject.extensions.create("flutter", FlutterExtension::class.java)',
    ),
    # Fix 3
    (
        '// Wait until the Android plugin loaded.\n            pluginProject.afterEvaluate {',
        '// Wait until the Android plugin loaded.\n            if (!pluginProject.state.executed) pluginProject.afterEvaluate {',
    ),
    # Fix 4 (contexte suivant spécifique à configurePluginDependencies)
    (
        'val pluginProject: Project = project.rootProject.findProject(":$pluginName") ?: return\n\n            getAndroidExtension(project).buildTypes.forEach { buildType ->\n                val flutterBuildMode',
        'val pluginProject: Project = project.rootProject.findProject(":$pluginName") ?: return\n            if (pluginProject.state.executed) return\n\n            getAndroidExtension(project).buildTypes.forEach { buildType ->\n                val flutterBuildMode',
    ),
    # Fix 2 : project.afterEvaluate{} dans configurePluginProject → run{}
    # Raison : appelé depuis l'intérieur d'un afterEvaluate (AGP crée
    # les variants dans son afterEvaluate). Gradle 8 interdit les appels
    # afterEvaluate imbriqués → on exécute inline (project est déjà
    # configuré, ses buildTypes sont disponibles).
    # Note : pluginProject.afterEvaluate{} est intentionnellement gardé —
    # les plugins ne sont pas encore évalués à ce stade, il faut différer.
    (
        'project.afterEvaluate {',
        'run {',
    ),
])

# FlutterPluginUtils.kt
# detectLowCompileSdkVersionOrNdkVersion() appelle pluginProject.afterEvaluate{}
# pour chaque plugin. Pour :app c'est OK (plugins pas encore évalués), mais
# pour :wear_app (évalué après :app via evaluationDependsOn) les plugins sont
# déjà évalués → "Cannot run afterEvaluate when the project is already evaluated".
# Fix : helper afterEvaluateOrNow — exécute tout de suite si déjà évalué.
patch_file(pathlib.Path(sys.argv[3]), [
    (
        'pluginProject.afterEvaluate {',
        'pluginProject.afterEvaluateOrNow {',
    ),
    (
        'private data class PluginVersionPair(',
        'internal fun Project.afterEvaluateOrNow(action: Project.() -> Unit) {\n'
        '    if (state.executed) action() else afterEvaluate { action() }\n'
        '}\n\n'
        'private data class PluginVersionPair(',
    ),
])
PYEOF

echo "--- PluginHandler.kt APRÈS patch (lignes autour de findProject) ---"
grep -n "findProject.*pluginName\|findByName.*flutter\|state\.executed\|afterEvaluate" "$HANDLER_FILE" 2>/dev/null | head -20
echo "--- FlutterPluginUtils.kt APRÈS patch ---"
grep -n "afterEvaluate" "$UTILS_FILE" 2>/dev/null | head -20
echo "-------------------------------------------------------------------"
