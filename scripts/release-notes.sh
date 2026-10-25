#!/usr/bin/env bash
# Notes de version Google Play (fr-FR, 500 caractères max).
#   - Play : la variable GitHub PLAY_RELEASE_NOTES si elle est définie
#     (Settings → Secrets and variables → Actions → Variables), sinon
#     « Corrections et améliorations de stabilité. ». Rien n'est tiré des commits.
#   - Résumé du run : la liste des commits de la version, pour le développeur.
#
# Usage : PLAY_RELEASE_NOTES="…" scripts/release-notes.sh <fichier_changelog> [<fichier_résumé_md>]
set -euo pipefail
export LC_ALL=C.UTF-8

OUT="${1:?Usage: $0 <fichier_changelog> [<fichier_résumé_md>]}"
SUMMARY="${2:-/dev/null}"
MAX_CHARS=500   # limite Google Play par langue

NOTES="${PLAY_RELEASE_NOTES:-}"
NOTES=$(printf '%s' "$NOTES" | sed -E 's/[[:space:]]+$//')
[[ -n "$NOTES" ]] || NOTES="Corrections et améliorations de stabilité."
if (( ${#NOTES} > MAX_CHARS )); then
  echo "⚠️  PLAY_RELEASE_NOTES dépasse $MAX_CHARS caractères (${#NOTES}) — texte coupé" >&2
  NOTES="${NOTES:0:$((MAX_CHARS - 1))}…"
fi

mkdir -p "$(dirname "$OUT")"
printf '%s\n' "$NOTES" > "$OUT"

CUR=$(git describe --tags --abbrev=0 2>/dev/null || true)
PREV=""
[[ -n "$CUR" ]] && PREV=$(git describe --tags --abbrev=0 "$CUR^" 2>/dev/null || true)
RANGE="${PREV:+$PREV..}${CUR:-HEAD}"

{
  echo "### 📝 Notes de version"
  echo
  echo "Envoyées au Play Store (${#NOTES}/${MAX_CHARS} caractères, source : $([[ -n "${PLAY_RELEASE_NOTES:-}" ]] && echo 'variable PLAY_RELEASE_NOTES' || echo 'texte par défaut')) :"
  echo
  echo '```'
  printf '%s\n' "$NOTES"
  echo '```'
  echo
  echo "<details><summary>Commits de la version (${RANGE}) — non publiés</summary>"
  echo
  git log --no-merges --format='- %s' "$RANGE" | grep -v '^- chore(release)' || true
  echo
  echo "</details>"
} >> "$SUMMARY"

echo "✅ Notes écrites dans $OUT"
