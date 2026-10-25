#!/usr/bin/env bash
# Envoie un AAB sur un canal Play (fastlane supply), à lancer depuis android/.
# Tant que l'app n'a jamais été publiée, Play refuse les releases « completed »
# (« Only releases with status draft may be created on draft app ») : l'envoi est
# alors refait en brouillon, à publier une fois à la main dans la Play Console.
#
# Usage : scripts/play-upload.sh <chemin_aab> <canal>   (ex. internal, wear:internal)
# Écrit status=completed|draft dans $GITHUB_OUTPUT si défini.
set -uo pipefail

AAB="${1:?Usage: $0 <chemin_aab> <canal>}"
TRACK="${2:?Usage: $0 <chemin_aab> <canal>}"
[ -f "$AAB" ] || { echo "❌ AAB introuvable : $AAB"; exit 1; }

upload() {
  bundle exec fastlane supply \
    --aab "$AAB" \
    --track "$TRACK" \
    --release_status "$1" \
    --json_key fastlane/service-account-key.json \
    --package_name team.oustad.app \
    --skip_upload_metadata \
    --skip_upload_images \
    --skip_upload_screenshots 2>&1 | tee /tmp/play-upload.log
  return "${PIPESTATUS[0]}"
}

STATUS=completed
if ! upload completed; then
  if grep -q "draft app" /tmp/play-upload.log; then
    echo "ℹ️  App jamais publiée : nouvel envoi en brouillon sur $TRACK"
    STATUS=draft
    upload draft || exit 1
  else
    exit 1
  fi
fi

[ -n "${GITHUB_OUTPUT:-}" ] && echo "status=$STATUS" >> "$GITHUB_OUTPUT"
echo "✅ $AAB → $TRACK ($STATUS)"
