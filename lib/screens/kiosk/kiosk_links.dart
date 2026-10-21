// Liens de distribution affichés sur la page kiosk.
// Valeurs injectées à la compilation via --dart-define (voir _build-web.yml).

// URLs de distribution pprod — à mettre à jour à chaque release
const kAndroidTestingUrl = String.fromEnvironment(
  'ANDROID_TESTING_URL',
  defaultValue: 'https://play.google.com/apps/internaltest/4700178556172561963',
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
