#!/usr/bin/env bash
# Notes de version Google Play (fr-FR, 500 caractères max) + résumé développeur,
# rédigés par Claude à partir des commits depuis le tag précédent.
#
# Usage : scripts/release-notes.sh <fichier_changelog> [<fichier_résumé_md>]
#   ANTHROPIC_API_KEY absent ou appel en échec → notes construites depuis les
#   commits feat/fix (jamais d'échec du job pour des notes de version).
set -euo pipefail
export LC_ALL=C.UTF-8

OUT="${1:?Usage: $0 <fichier_changelog> [<fichier_résumé_md>]}"
SUMMARY="${2:-/dev/null}"
MAX_CHARS=500   # limite Google Play par langue

CUR=$(git describe --tags --abbrev=0 2>/dev/null || true)
PREV=""
[[ -n "$CUR" ]] && PREV=$(git describe --tags --abbrev=0 "$CUR^" 2>/dev/null || true)
RANGE="${PREV:+$PREV..}${CUR:-HEAD}"
COMMITS=$(git log --no-merges --format='- %s' "$RANGE" | grep -v '^- chore(release)' | head -200 || true)

# Repli : feat/fix/perf hors périmètres internes, préfixe retiré.
fallback_notes() {
  local lines
  lines=$(printf '%s\n' "$COMMITS" \
    | grep -E '^- (feat|fix|perf)(\([^)]*\))?!?:' \
    | grep -v -E '^- \w+\((build|ci|deps|release|fastlane|server|docs|test)\)' \
    | sed -E 's/^- [a-z]+(\([^)]*\))?!?: */• /' | head -6 || true)
  if [[ -n "$lines" ]]; then
    printf 'Nouveautés et corrections :\n%s\n' "$lines"
  else
    echo "Corrections et améliorations de stabilité."
  fi
}

SOURCE="commits (repli)"
NOTES=""
DEV_SUMMARY=""

if [[ -n "${ANTHROPIC_API_KEY:-}" && -n "$COMMITS" ]]; then
  SYSTEM='Tu rédiges les notes de version Google Play de « Team Oustad », une app de gestion de salles de sport utilisée par des membres, des coachs et des gérants. On te donne les sujets de commits (Conventional Commits) depuis la version précédente. Réponds selon le schéma JSON :
- user_facing : true seulement si au moins un changement est visible ou utile pour les utilisateurs de l app mobile. Build, CI, docs, tests, scripts, refactor et changements serveur seuls ne comptent pas.
- play_notes : en français, 450 caractères maximum, ton simple et direct, sans jargon technique, sans identifiant de commit, une puce « • » par nouveauté. Si user_facing est false : une seule phrase courte, par exemple « Corrections et améliorations de stabilité. ».
- dev_summary : en français, pour le développeur, 3 à 8 puces markdown « - » qui résument ce qui a changé techniquement, regroupé par thème.
Ne décris que ce que les commits disent, n invente rien. Le nom de l app est toujours « Team Oustad ».'

  BODY=$(jq -n --arg system "$SYSTEM" --arg commits "$COMMITS" --arg range "$RANGE" '{
    model: "claude-opus-5-5",
    max_tokens: 16000,
    fallbacks: "default",
    output_config: {
      effort: "medium",
      format: {
        type: "json_schema",
        schema: {
          type: "object",
          properties: {
            user_facing: { type: "boolean" },
            play_notes: { type: "string" },
            dev_summary: { type: "string" }
          },
          required: ["user_facing", "play_notes", "dev_summary"],
          additionalProperties: false
        }
      }
    },
    system: $system,
    messages: [{ role: "user", content: ("Commits " + $range + " :\n" + $commits) }]
  }')

  RESPONSE=$(curl -sS --max-time 180 -w '\n%{http_code}' https://api.anthropic.com/v1/messages \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2026-10-21" \
    -H "anthropic-beta: server-side-fallback-2026-07-01" \
    -d "$BODY" || true)
  HTTP_CODE=$(printf '%s' "$RESPONSE" | tail -n1)
  JSON=$(printf '%s' "$RESPONSE" | sed '$d')

  STOP=$(printf '%s' "$JSON" | jq -r '.stop_reason // empty' 2>/dev/null || true)
  if [[ "$HTTP_CODE" == "200" && "$STOP" == "end_turn" ]]; then
    RESULT=$(printf '%s' "$JSON" | jq -r '[.content[] | select(.type == "text") | .text] | join("")' 2>/dev/null || true)
    NOTES=$(printf '%s' "$RESULT" | jq -r '.play_notes // empty' 2>/dev/null || true)
    DEV_SUMMARY=$(printf '%s' "$RESULT" | jq -r '.dev_summary // empty' 2>/dev/null || true)
    USER_FACING=$(printf '%s' "$RESULT" | jq -r '.user_facing // empty' 2>/dev/null || true)
    [[ -n "$NOTES" ]] && SOURCE="Claude (user_facing=$USER_FACING)"
  else
    echo "⚠️  Notes Claude indisponibles (HTTP $HTTP_CODE, stop_reason=${STOP:-—}) — repli sur les commits" >&2
    printf '%s' "$JSON" | jq -r '.error.message // empty' 2>/dev/null >&2 || true
  fi
else
  echo "ℹ️  ANTHROPIC_API_KEY absent ou aucun commit — repli sur les commits" >&2
fi

[[ -n "$NOTES" ]] || NOTES=$(fallback_notes)
NOTES="${NOTES:0:$MAX_CHARS}"

mkdir -p "$(dirname "$OUT")"
printf '%s\n' "$NOTES" > "$OUT"

{
  echo "### 📝 Notes de version (${RANGE})"
  echo
  echo "Source : $SOURCE — ${#NOTES}/${MAX_CHARS} caractères"
  echo
  echo '```'
  printf '%s\n' "$NOTES"
  echo '```'
  if [[ -n "$DEV_SUMMARY" ]]; then
    echo
    echo "**Résumé technique**"
    echo
    printf '%s\n' "$DEV_SUMMARY"
  fi
} >> "$SUMMARY"

echo "✅ Notes écrites dans $OUT ($SOURCE)"
