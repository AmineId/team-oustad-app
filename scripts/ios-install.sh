#!/usr/bin/env bash
# Sign and install the unsigned iOS build on a connected iPhone with xtool.
#
# Usage:
#   scripts/ios-install.sh path/to/TeamFitness-pprod.ipa
#   scripts/ios-install.sh --download [pprod|prod|dev]          # dernier artifact réussi (gh requis)
#   scripts/ios-install.sh --build    [pprod|prod|dev] [ref]    # déclenche un build GH puis installe
#
# Set XTOOL_UDID to target a specific device when several are connected.
set -euo pipefail

for cmd in xtool usbmuxd; do
  command -v "$cmd" >/dev/null || { echo "❌ '$cmd' introuvable — voir docs/ios/IOS_XTOOL.md"; exit 1; }
done

_gh_check() { command -v gh >/dev/null || { echo "❌ 'gh' requis pour $1"; exit 1; }; }

# Trouve le nom exact de l'artefact ios-ipa-<env>* dans un run donné.
_find_artifact_name() {
  local run_id="$1" env="$2"
  gh api "repos/{owner}/{repo}/actions/runs/$run_id/artifacts" \
    --jq ".artifacts[] | select(.name | startswith(\"ios-ipa-$env\")) | select(.expired == false) | .name" \
    2>/dev/null | head -1
}

_download_artifact() {
  local run_id="$1" env="$2"
  local artifact_name
  artifact_name=$(_find_artifact_name "$run_id" "$env")
  [[ -n "$artifact_name" ]] || { echo "❌ Artefact ios-ipa-$env* introuvable ou expiré dans run $run_id"; exit 1; }
  local out="build/ipa-download"
  rm -rf "$out" && mkdir -p "$out"
  gh run download "$run_id" --name "$artifact_name" --dir "$out"
  # Le nom du .ipa peut varier (avec ou sans version) — on prend le premier trouvé.
  find "$out" -name "*.ipa" | head -1
}

if [[ "${1:-}" == "--build" ]]; then
  env="${2:-pprod}"
  ref="${3:-$(git rev-parse --abbrev-ref HEAD)}"
  _gh_check "--build"
  echo "🚀 Déclenchement du build iOS ($env) sur '$ref'…"
  gh workflow run ios-build.yml --ref "$ref" --field environment="$env"
  sleep 5
  run_id=$(gh run list --workflow ios-build.yml --limit 1 \
    --json databaseId --jq '.[0].databaseId // empty')
  [[ -n "$run_id" ]] || { echo "❌ Run introuvable après déclenchement"; exit 1; }
  echo "⏳ Build en cours (run $run_id) — en attente…"
  gh run watch "$run_id" --exit-status
  echo "✅ Build terminé — téléchargement de l'artefact…"
  ipa=$(_download_artifact "$run_id" "$env")

elif [[ "${1:-}" == "--download" ]]; then
  env="${2:-pprod}"
  _gh_check "--download"
  run_id=""
  while IFS= read -r candidate; do
    if gh api "repos/{owner}/{repo}/actions/runs/$candidate/artifacts" \
        --jq ".artifacts[] | select((.name | startswith(\"ios-ipa-$env\")) and .expired == false) | .id" \
        2>/dev/null | grep -q .; then
      run_id="$candidate"
      break
    fi
  done < <(gh run list --workflow ios-build.yml --status success --limit 50 \
    --json databaseId,displayTitle \
    --jq ".[] | select(.displayTitle | startswith(\"iOS build\")) | .databaseId | tostring")
  [[ -n "$run_id" ]] || { echo "❌ Aucun artefact ios-ipa-$env non expiré trouvé (50 derniers runs)"; exit 1; }
  echo "✅ Run trouvé : $run_id"
  ipa=$(_download_artifact "$run_id" "$env")

else
  ipa="${1:?Usage: $0 <path.ipa> | --download [env] | --build [env] [ref]}"
fi

[[ -f "$ipa" ]] || { echo "❌ Fichier introuvable : $ipa"; exit 1; }

# Sous WSL2 : tunnel vers le relais iTunes TCP du host Windows (port 27015).
# Prérequis Windows (PowerShell admin, à relancer après chaque reboot) :
#   $ip = (Get-NetIPAddress -InterfaceAlias "vEthernet (WSL*)" -AddressFamily IPv4).IPAddress
#   netsh interface portproxy set v4tov4 listenport=27015 connectaddress=127.0.0.1 connectport=27015 listenaddress=$ip
# Fallback : usbmuxd local (nécessite usbipd attach).
WIN_HOST=$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}')
if [[ -n "$WIN_HOST" ]] && nc -z -w1 "$WIN_HOST" 27015 2>/dev/null; then
  echo "📡 Relais iTunes actif ($WIN_HOST:27015)"
  # sudo pkill -x usbmuxd 2>/dev/null || true
  export USBMUXD_SOCKET_ADDRESS="$WIN_HOST:27015"
else
  echo "⚠️  Relais iTunes non détecté sur $WIN_HOST:27015"
  echo "   → Dans PowerShell admin Windows :"
  echo '   $ip = (Get-NetIPAddress -InterfaceAlias "vEthernet (WSL*)" -AddressFamily IPv4).IPAddress'
  echo '   netsh interface portproxy set v4tov4 listenport=27015 connectaddress=127.0.0.1 connectport=27015 listenaddress=$ip'
  echo '   New-NetFirewallRule -DisplayName "WSL-usbmuxd-27015" -Direction Inbound -Protocol TCP -LocalPort 27015 -Action Allow'
  echo "   Fallback usbmuxd local…"
  pgrep -x usbmuxd >/dev/null || sudo usbmuxd
fi

xtool devices

# ── Patch WKCompanionAppBundleIdentifier ─────────────────────────────────────
# xtool re-signe avec le préfixe XTL-<teamID>. Le WKCompanionAppBundleIdentifier
# dans le plist de la Watch app doit correspondre au bundle ID effectif du
# compagnon iPhone après re-signature, sinon iOS refuse l'installation.
_patch_watch_companion_id() {
  local src_ipa="$1"

  # Récupère le team ID actif depuis xtool (ex. "Mohammed AMINE IDRISSI [active]: D79Q935LUX")
  local team_id
  team_id=$(xtool ds teams 2>/dev/null | awk '/\[active\]/{gsub(/.*: /,""); print; exit}')
  if [[ -z "$team_id" ]]; then
    echo "⚠️  Team ID xtool introuvable — WKCompanionAppBundleIdentifier non patché"
    echo "   Définir XTOOL_TEAM_PREFIX=XTL-<teamID> pour forcer la valeur"
    return 0
  fi
  local prefix="${XTOOL_TEAM_PREFIX:-XTL-${team_id}}"
  local companion_id="${prefix}.team.oustad.app"

  local work
  work=$(mktemp -d)
  trap 'rm -rf "$work"' RETURN

  cp "$src_ipa" "$work/orig.ipa"
  (cd "$work" && unzip -q orig.ipa)

  local plist
  plist=$(find "$work/Payload" -path "*/Watch/*.app/Info.plist" | head -1)
  if [[ -z "$plist" ]]; then
    echo "ℹ️  Pas de Watch app dans l'IPA — aucun patch nécessaire"
    return 0
  fi

  local current
  current=$(python3 -c "
import plistlib, sys
with open('$plist','rb') as f: pl=plistlib.load(f)
print(pl.get('WKCompanionAppBundleIdentifier',''))
" 2>/dev/null || true)

  if [[ "$current" == "$companion_id" ]]; then
    echo "✅ WKCompanionAppBundleIdentifier déjà correct ($companion_id)"
    return 0
  fi

  # Patch du bundle ID de la Watch app + du companion ID
  local watch_bundle_id="${prefix}.team.oustad.app.watchkitapp"
  python3 -c "
import plistlib
with open('$plist','rb') as f: pl=plistlib.load(f)
pl['WKCompanionAppBundleIdentifier'] = '$companion_id'
pl['CFBundleIdentifier'] = '$watch_bundle_id'
pl['UIDeviceFamily'] = [4]
with open('$plist','wb') as f: plistlib.dump(pl, f)
"
  (cd "$work" && zip -qr patched.ipa Payload)
  cp "$work/patched.ipa" "$src_ipa"
  echo "✅ WKCompanionAppBundleIdentifier → $companion_id"
  echo "✅ CFBundleIdentifier Watch       → $watch_bundle_id"
}

IPA_TO_INSTALL="$ipa"
PATCHED=$(mktemp --suffix=.ipa)
cp "$IPA_TO_INSTALL" "$PATCHED"
_patch_watch_companion_id "$PATCHED"

xtool install ${XTOOL_UDID:+-u "$XTOOL_UDID"} "$PATCHED"
rm -f "$PATCHED"
