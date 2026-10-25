import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/models/showcase_page_model.dart';
import 'package:team_oustad_app/core/services/auth_service.dart';

void main() {
  group('ShowcasePage.fromJson', () {
    test('rien d\'enregistré → contenu par défaut', () {
      final home = ShowcasePage.fromJson(ShowcasePageKind.home, {});
      expect(home.heroTagline, ShowcasePage.defaultHome().heroTagline);
      expect(
        home.sections.map((s) => s.id),
        ShowcasePage.defaultHome().sections.map((s) => s.id),
      );
      final gym = ShowcasePage.fromJson(ShowcasePageKind.gym, null);
      expect(gym.sections.map((s) => s.type), ShowcaseSectionType.gymBuiltins);
    });

    test('aller-retour JSON conserve ordre, visibilité et contenu', () {
      final page = ShowcasePage.defaultHome();
      final hidden = page.copyWith(
        sections: [
          ...page.sections.reversed.map(
            (s) => s.id == 'gyms' ? s.copyWith(visible: false) : s,
          ),
        ],
      );
      final back = ShowcasePage.fromJson(
        ShowcasePageKind.home,
        hidden.toJson(),
      );
      expect(back.sections.map((s) => s.id), hidden.sections.map((s) => s.id));
      expect(back.sections.firstWhere((s) => s.id == 'gyms').visible, false);
      expect(
        back.sections.firstWhere((s) => s.id == 'cta-app').text('buttonLabel'),
        'Télécharger',
      );
    });

    test('types inconnus ignorés, intégrées manquantes rajoutées', () {
      final page = ShowcasePage.fromJson(ShowcasePageKind.gym, {
        'sections': [
          {'id': 'x', 'type': 'video3d', 'visible': true},
          {'id': 'gyms', 'type': 'gyms'}, // intégrée de l'accueil
          {'id': 'gymHours', 'type': 'gymHours'},
          {'id': 'gymHours2', 'type': 'gymHours'}, // doublon
          {
            'id': 'm',
            'type': 'markdown',
            'data': {'title': 'Tarifs', 'body': '**30 €**'},
          },
        ],
      });
      final types = page.sections.map((s) => s.type).toList();
      expect(types.first, ShowcaseSectionType.gymHours);
      expect(types[1], ShowcaseSectionType.markdown);
      expect(types.where((t) => t == ShowcaseSectionType.gymHours).length, 1);
      expect(types, isNot(contains(ShowcaseSectionType.gyms)));
      expect(
        types.toSet().containsAll(ShowcaseSectionType.gymBuiltins),
        isTrue,
      );
    });

    test('ancien format plat converti en sections markdown', () {
      final page = ShowcasePage.fromJson(ShowcasePageKind.gym, {
        'description': 'ignorée (Gym.description)',
        'pricing': '- Mois : 30 €',
      });
      final md = page.sections
          .where((s) => s.type == ShowcaseSectionType.markdown)
          .toList();
      expect(md, hasLength(1));
      expect(md.single.text('title'), 'Tarifs');
    });
  });

  test('AuthService.normalizeRole', () {
    expect(AuthService.normalizeRole(' Owner '), 'owner');
    expect(AuthService.normalizeRole('ADMIN'), 'admin');
    expect(AuthService.normalizeRole('member'), 'member');
    expect(AuthService.normalizeRole('superadmin'), isNull);
    expect(AuthService.normalizeRole(null), isNull);
  });
}
