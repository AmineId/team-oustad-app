#!/usr/bin/env bash
# Sign and install the unsigned iOS build on a connected iPhone with xtool.
#
# Usage:
#   scripts/ios-install.sh path/to/TeamFitness-pprod.ipa
#   scripts/ios-install.sh --download [pprod|prod|dev]   # latest "iOS Build" run artifact (needs gh)
#
# Set XTOOL_UDID to target a specific device when several are connected.
set -euo pipefail

for cmd in xtool usbmuxd; do
  command -v "$cmd" >/dev/null || { echo "❌ '$cmd' introuvable — voir docs/ios/IOS_XTOOL.md"; exit 1; }
done

if [[ "${1:-}" == "--download" ]]; then
  env="${2:-pprod}"
  command -v gh >/dev/null || { echo "❌ 'gh' requis pour --download"; exit 1; }
  run_id=$(gh run list --workflow ios-build.yml --status success --limit 20 \
    --json databaseId,displayTitle \
    --jq "[.[] | select(.displayTitle == \"iOS build ($env)\")][0].databaseId // empty")
  [[ -n "$run_id" ]] || { echo "❌ Aucun build iOS réussi trouvé"; exit 1; }
  out="build/ipa-download"
  rm -rf "$out" && mkdir -p "$out"
  gh run download "$run_id" --name "ios-ipa-$env" --dir "$out"
  ipa="$out/TeamFitness-$env.ipa"
else
  ipa="${1:?Usage: $0 <path.ipa> | --download [env]}"
fi

[[ -f "$ipa" ]] || { echo "❌ Fichier introuvable : $ipa"; exit 1; }

# usbmuxd must be running for xtool to see the device (started on demand under WSL).
pgrep -x usbmuxd >/dev/null || sudo usbmuxd

xtool devices
xtool install ${XTOOL_UDID:+-u "$XTOOL_UDID"} "$ipa"
