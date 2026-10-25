#!/usr/bin/env bash
# Flutter Team Oustad App - Bash Scripts (WSL)
# Usage: ./scripts.sh <command> [--url <url>]

set -euo pipefail

# ── Android SDK (Windows → WSL) ───────────────────────────────────────────────
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
ANDROID_SDK="/mnt/c/Users/${WIN_USER}/AppData/Local/Android/Sdk"
ADB="${ANDROID_SDK}/platform-tools/adb.exe"
EMULATOR="${ANDROID_SDK}/emulator/emulator.exe"

export ANDROID_SDK_ROOT="${ANDROID_SDK}"
export ANDROID_HOME="${ANDROID_SDK}"

# ── Colors ────────────────────────────────────────────────────────────────────
CY='\033[0;36m'; GR='\033[0;32m'; YE='\033[0;33m'
RE='\033[0;31m'; GY='\033[0;90m'; NC='\033[0m'

# ── Args ──────────────────────────────────────────────────────────────────────
COMMAND="${1:-}"
URL=""
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url|-u) URL="$2"; shift 2 ;;
    *) shift ;;
  esac
done

url_flag() { [[ -n "$URL" ]] && echo " --dart-define=API_BASE_URL=$URL" || echo ""; }

run_cmd() {
  echo -e "${GY}> $*${NC}"
  eval "$@"
}

show_help() {
  echo -e ""
  echo -e "${CY}╔════════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CY}║         Flutter Team Oustad App - Bash Scripts (WSL)                ║${NC}"
  echo -e "${CY}╚════════════════════════════════════════════════════════════════════════╝${NC}"
  echo -e ""
  echo -e "${YE}Environments:${NC}"
  echo -e "   dev (default)  → http://localhost:3000 or http://10.0.2.2:3000"
  echo -e "   pprod          → https://api-pprod.team-oustad.com"
  echo -e "   prod           → https://api.team-oustad.com"
  echo -e ""
  echo -e "${CY}Run Commands (Development):${NC}"
  echo -e "  ${GR}install${NC}            - flutter pub get"
  echo -e "  ${GR}run${NC}                - Run app (auto-detect)"
  echo -e "  ${GR}run-android${NC}        - Run on Android emulator (dev)"
  echo -e "  ${GR}run-web${NC}            - Run on Web/Chrome (dev)"
  echo -e ""
  echo -e "${CY}Run Commands (Pre-Production):${NC}"
  echo -e "  ${YE}run-pprod${NC}          - Run on pprod"
  echo -e "  ${YE}run-android-pprod${NC}  - Run Android on pprod"
  echo -e "  ${YE}run-web-pprod${NC}      - Run Web on pprod"
  echo -e ""
  echo -e "${CY}Run Commands (Production):${NC}"
  echo -e "  ${RE}run-prod${NC}           - Run on prod"
  echo -e "  ${RE}run-android-prod${NC}   - Run Android on prod"
  echo -e "  ${RE}run-web-prod${NC}       - Run Web on prod"
  echo -e ""
  echo -e "${CY}Options:${NC}"
  echo -e "  ${YE}--url <url>${NC}        - Override API URL"
  echo -e "                       Ex: ./scripts.sh run-android --url http://192.168.1.50:3000"
  echo -e ""
  echo -e "${CY}Device Management:${NC}"
  echo -e "  ${GR}emulators${NC}          - List available emulators"
  echo -e "  ${GR}launch${NC}             - Launch Pixel 9 Pro emulator"
  echo -e "  ${GR}devices${NC}            - Show connected devices"
  echo -e ""
  echo -e "${CY}Build Commands:${NC}"
  echo -e "  ${GR}build-apk${NC}              - Build APK debug"
  echo -e "  ${YE}build-apk-pprod${NC}        - Build APK pprod"
  echo -e "  ${RE}build-apk-prod${NC}         - Build APK prod"
  echo -e "  ${YE}build-appbundle-pprod${NC}  - Build AAB pprod"
  echo -e "  ${RE}build-appbundle-prod${NC}   - Build AAB prod"
  echo -e "  ${YE}build-web-pprod${NC}        - Build Web pprod"
  echo -e "  ${RE}build-web-prod${NC}         - Build Web prod"
  echo -e ""
  echo -e "${CY}Maintenance:${NC}"
  echo -e "  ${GR}clean analyze format test upgrade doctor${NC}"
  echo -e ""
}

case "$COMMAND" in
  install)
    echo -e "${CY}Installing dependencies...${NC}"
    flutter pub get
    ;;

  run)
    echo -e "${CY}Running app...${NC}"
    run_cmd "flutter run$(url_flag)"
    ;;

  run-android)
    echo -e "${CY}Running app on Android emulator...${NC}"
    [[ -n "$URL" ]] && echo -e "${YE}Using API URL: $URL${NC}"
    run_cmd "flutter run -d emulator-5554$(url_flag)"
    ;;

  run-web)
    echo -e "${CY}Running app on Web...${NC}"
    [[ -n "$URL" ]] && echo -e "${YE}Using API URL: $URL${NC}"
    run_cmd "flutter run -d chrome$(url_flag)"
    ;;

  run-pprod)
    echo -e "${YE}Running app on PPROD — https://api-pprod.team-oustad.com${NC}"
    run_cmd "flutter run --dart-define=ENVIRONMENT=pprod"
    ;;

  run-android-pprod)
    echo -e "${YE}Running Android on PPROD — https://api-pprod.team-oustad.com${NC}"
    run_cmd "flutter run -d emulator-5554 --dart-define=ENVIRONMENT=pprod"
    ;;

  run-web-pprod)
    echo -e "${YE}Running Web on PPROD — https://api-pprod.team-oustad.com${NC}"
    run_cmd "flutter run -d chrome --dart-define=ENVIRONMENT=pprod"
    ;;

  run-prod)
    echo -e "${RE}⚠️  PRODUCTION — https://api.team-oustad.com${NC}"
    run_cmd "flutter run --dart-define=ENVIRONMENT=prod"
    ;;

  run-android-prod)
    echo -e "${RE}⚠️  Android PRODUCTION — https://api.team-oustad.com${NC}"
    run_cmd "flutter run -d emulator-5554 --dart-define=ENVIRONMENT=prod"
    ;;

  run-web-prod)
    echo -e "${RE}⚠️  Web PRODUCTION — https://api.team-oustad.com${NC}"
    run_cmd "flutter run -d chrome --dart-define=ENVIRONMENT=prod"
    ;;

  emulators)
    echo -e "${CY}Available emulators:${NC}"
    flutter emulators
    ;;

  launch)
    echo -e "${CY}Launching Pixel 9 Pro emulator...${NC}"
    if [[ -x "$EMULATOR" ]]; then
      "$EMULATOR" -avd Pixel_9_Pro &
      echo -e "${GR}Emulateur lancé en arrière-plan. Attends qu'il démarre puis lance run-android.${NC}"
    else
      echo -e "${RE}emulator.exe introuvable: ${EMULATOR}${NC}"
      echo -e "${YE}Essai via flutter emulators...${NC}"
      flutter emulators --launch Pixel_9_Pro
    fi
    ;;

  devices)
    echo -e "${CY}Connected devices:${NC}"
    flutter devices
    ;;

  clean)
    echo -e "${CY}Cleaning build files...${NC}"
    flutter clean
    echo -e "${GR}Done! Lance 'install' pour réinstaller les dépendances.${NC}"
    ;;

  build-apk)
    echo -e "${CY}Building debug APK...${NC}"
    run_cmd "flutter build apk --debug$(url_flag)"
    echo -e "${GR}APK: build/app/outputs/flutter-apk/app-debug.apk${NC}"
    ;;

  build-apk-pprod)
    echo -e "${YE}Building APK PPROD...${NC}"
    run_cmd "flutter build apk --release --dart-define=ENVIRONMENT=pprod"
    echo -e "${GR}APK: build/app/outputs/flutter-apk/app-release.apk${NC}"
    ;;

  build-apk-prod)
    echo -e "${RE}⚠️  Building APK PRODUCTION...${NC}"
    run_cmd "flutter build apk --release --dart-define=ENVIRONMENT=prod"
    echo -e "${GR}APK: build/app/outputs/flutter-apk/app-release.apk${NC}"
    ;;

  build-appbundle-pprod)
    echo -e "${YE}Building App Bundle PPROD...${NC}"
    run_cmd "flutter build appbundle --release --dart-define=ENVIRONMENT=pprod"
    echo -e "${GR}AAB: build/app/outputs/bundle/release/app-release.aab${NC}"
    ;;

  build-appbundle-prod)
    echo -e "${RE}⚠️  Building App Bundle PRODUCTION...${NC}"
    run_cmd "flutter build appbundle --release --dart-define=ENVIRONMENT=prod"
    echo -e "${GR}AAB: build/app/outputs/bundle/release/app-release.aab${NC}"
    ;;

  build-web-pprod)
    echo -e "${YE}Building Web PPROD...${NC}"
    run_cmd "flutter build web --release --dart-define=ENVIRONMENT=pprod"
    echo -e "${GR}Web: build/web/${NC}"
    ;;

  build-web-prod)
    echo -e "${RE}⚠️  Building Web PRODUCTION...${NC}"
    run_cmd "flutter build web --release --dart-define=ENVIRONMENT=prod"
    echo -e "${GR}Web: build/web/${NC}"
    ;;

  analyze)
    echo -e "${CY}Analyzing code...${NC}"
    flutter analyze
    ;;

  format)
    echo -e "${CY}Formatting Dart files...${NC}"
    dart format .
    ;;

  test)
    echo -e "${CY}Running tests...${NC}"
    flutter test
    ;;

  upgrade)
    echo -e "${CY}Upgrading dependencies...${NC}"
    flutter pub upgrade
    ;;

  doctor)
    echo -e "${CY}Checking Flutter installation...${NC}"
    flutter doctor -v
    ;;

  "")
    show_help
    ;;

  *)
    echo -e "${RE}Commande inconnue: $COMMAND${NC}\n"
    show_help
    exit 1
    ;;
esac
