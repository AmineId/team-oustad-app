import 'package:flutter_test/flutter_test.dart';

import 'package:team_oustad_app/screens/kiosk/kiosk_links.dart';

void main() {
  group('Liens de distribution kiosk', () {
    test('la source AltStore est une URL HTTPS vers un fichier JSON', () {
      final uri = Uri.parse(kAltStoreSourceUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
      expect(uri.path, endsWith('.json'));
    });

    test('le lien AltStore ajoute la bonne source', () {
      final uri = Uri.parse(kAltStoreAddSourceUrl);
      expect(uri.scheme, 'altstore');
      expect(uri.host, 'source');
      expect(uri.queryParameters['url'], kAltStoreSourceUrl);
    });

    test('le lien SideStore utilise la même source', () {
      final uri = Uri.parse(kSideStoreAddSourceUrl);
      expect(uri.scheme, 'sidestore');
      expect(uri.host, 'source');
      expect(uri.queryParameters['url'], kAltStoreSourceUrl);
    });

    test("l'IPA est téléchargeable en HTTPS", () {
      final uri = Uri.parse(kIpaDownloadUrl);
      expect(uri.scheme, 'https');
      expect(uri.path, endsWith('.ipa'));
    });
  });
}
