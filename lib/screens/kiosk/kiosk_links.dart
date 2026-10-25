// Liens de distribution affichés sur la page kiosk.
// Valeurs injectées à la compilation via --dart-define (voir _build-web.yml).

// Lien Play tests internes = variable GitHub ANDROID_TESTING_URL ; fiche Play sinon
const kAndroidTestingUrl = String.fromEnvironment(
  'ANDROID_TESTING_URL',
  defaultValue: 'https://play.google.com/store/apps/details?id=team.oustad.app',
);
const kIpaDownloadUrl = String.fromEnvironment(
  'KIOSK_IPA_URL',
  defaultValue: 'https://kiosk.team-oustad.com/TeamOustad.ipa',
);
// Source AltStore / SideStore générée par la CI (deploy-kiosk) à côté de l'IPA
const kAltStoreSourceUrl = String.fromEnvironment(
  'KIOSK_ALTSTORE_SOURCE_URL',
  defaultValue: 'https://staging.team-fitness-kiosk.pages.dev/altstore.json',
);
const kAltStoreAddSourceUrl = 'altstore://source?url=$kAltStoreSourceUrl';
const kSideStoreAddSourceUrl = 'sidestore://source?url=$kAltStoreSourceUrl';
