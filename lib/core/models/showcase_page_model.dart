import 'package:flutter/material.dart';

/// Page du site vitrine éditable depuis l'app (CMS) : la page d'accueil
/// (owner) ou la fiche d'une salle (owner, admin de la salle).
///
/// Une page est une liste ordonnée de sections typées. Les sections
/// "intégrées" ([ShowcaseSectionType.isBuiltin]) affichent des données de
/// l'app (liste des salles, horaires, équipe…) : on peut les déplacer ou les
/// masquer, pas les supprimer ni éditer leur contenu ici.
enum ShowcasePageKind { home, gym }

enum ShowcaseSectionType {
  // Contenu libre
  markdown('markdown', 'Texte', Icons.notes_rounded),
  feature('feature', 'Bloc mis en avant', Icons.view_agenda_rounded),
  testimonials('testimonials', 'Témoignages', Icons.format_quote_rounded),
  marquee('marquee', 'Bandeau défilant', Icons.view_stream_rounded),
  categories('categories', 'Tuiles catégories', Icons.grid_view_rounded),
  cta('cta', 'Appel à l\'action', Icons.ads_click_rounded),

  // Intégrées — accueil
  gyms('gyms', 'Liste des salles', Icons.fitness_center_rounded),
  promos('promos', 'Promotions du réseau', Icons.local_offer_rounded),

  // Intégrées — fiche salle
  gymAbout('gymAbout', 'Description de la salle', Icons.description_rounded),
  gymPromos('gymPromos', 'Offres de la salle', Icons.local_offer_rounded),
  gymInfo('gymInfo', 'Adresse, contact, carte', Icons.place_rounded),
  gymHours('gymHours', 'Horaires d\'ouverture', Icons.schedule_rounded),
  gymTeam('gymTeam', 'La team (photos)', Icons.groups_rounded),
  gymSubscriptions(
    'gymSubscriptions',
    'Formules d\'abonnement',
    Icons.card_membership_rounded,
  );

  final String key;
  final String label;
  final IconData icon;

  const ShowcaseSectionType(this.key, this.label, this.icon);

  static ShowcaseSectionType? fromKey(String? key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return null;
  }

  bool get isBuiltin => !contentTypes.contains(this);

  static const contentTypes = [
    markdown,
    feature,
    testimonials,
    marquee,
    categories,
    cta,
  ];

  static const homeBuiltins = [gyms, promos];
  static const gymBuiltins = [
    gymAbout,
    gymPromos,
    gymInfo,
    gymHours,
    gymTeam,
    gymSubscriptions,
  ];

  static List<ShowcaseSectionType> builtinsFor(ShowcasePageKind kind) =>
      kind == ShowcasePageKind.home ? homeBuiltins : gymBuiltins;
}

/// Icônes proposées dans l'éditeur. Stockées par clé (jamais par codePoint)
/// pour garder le tree-shaking des icônes et un contrat serveur stable.
const Map<String, IconData> showcaseIcons = {
  'fitness': Icons.fitness_center_rounded,
  'fire': Icons.whatshot_rounded,
  'groups': Icons.groups_rounded,
  'run': Icons.directions_run_rounded,
  'food': Icons.restaurant_rounded,
  'target': Icons.track_changes_rounded,
  'heart': Icons.favorite_rounded,
  'bolt': Icons.bolt_rounded,
  'timer': Icons.timer_rounded,
  'star': Icons.star_rounded,
  'zen': Icons.self_improvement_rounded,
  'trophy': Icons.emoji_events_rounded,
  'pool': Icons.pool_rounded,
  'bike': Icons.pedal_bike_rounded,
};

IconData showcaseIcon(String? key) =>
    showcaseIcons[key] ?? Icons.fitness_center_rounded;

class ShowcaseSection {
  final String id;
  final ShowcaseSectionType type;
  final bool visible;

  /// Champs propres au type (voir docs/features/GYM_SHOWCASE_PUBLIC_API.md §8).
  final Map<String, dynamic> data;

  const ShowcaseSection({
    required this.id,
    required this.type,
    this.visible = true,
    this.data = const {},
  });

  factory ShowcaseSection.create(ShowcaseSectionType type) =>
      ShowcaseSection(id: newId(), type: type, data: _emptyData(type));

  static String newId() =>
      's${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  /// Retourne null pour un type inconnu (section ajoutée par une version plus
  /// récente de l'app) : elle est ignorée plutôt que de casser la page.
  static ShowcaseSection? fromJson(Map<String, dynamic> json) {
    final type = ShowcaseSectionType.fromKey(json['type'] as String?);
    if (type == null) return null;
    return ShowcaseSection(
      id: (json['id'] as String?) ?? newId(),
      type: type,
      visible: json['visible'] as bool? ?? true,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.key,
    'visible': visible,
    if (!type.isBuiltin) 'data': data,
  };

  ShowcaseSection copyWith({bool? visible, Map<String, dynamic>? data}) =>
      ShowcaseSection(
        id: id,
        type: type,
        visible: visible ?? this.visible,
        data: data ?? this.data,
      );

  String text(String key) => (data[key] as String?)?.trim() ?? '';

  List<String> strings(String key) => ((data[key] as List?) ?? const [])
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<Map<String, dynamic>> items(String key) =>
      ((data[key] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  /// Titre affiché dans la liste de l'éditeur.
  String get summary {
    final candidates = [text('title'), text('eyebrow'), text('text')];
    for (final c in candidates) {
      if (c.isNotEmpty) return c;
    }
    if (type == ShowcaseSectionType.marquee) {
      return strings('words').join(' · ');
    }
    if (type == ShowcaseSectionType.categories) {
      return items('items').map((e) => e['label']).join(' · ');
    }
    if (type == ShowcaseSectionType.markdown) {
      final body = text('body');
      return body.length > 60 ? '${body.substring(0, 60)}…' : body;
    }
    return '';
  }

  static Map<String, dynamic> _emptyData(ShowcaseSectionType type) {
    switch (type) {
      case ShowcaseSectionType.markdown:
        return {'title': '', 'body': ''};
      case ShowcaseSectionType.feature:
        return {
          'eyebrow': '',
          'title': '',
          'body': '',
          'points': <String>[],
          'icon': 'fitness',
          'tag': '',
        };
      case ShowcaseSectionType.testimonials:
        return {'eyebrow': 'LA TEAM PARLE', 'title': '', 'items': []};
      case ShowcaseSectionType.marquee:
        return {'words': <String>[]};
      case ShowcaseSectionType.categories:
        return {'items': []};
      case ShowcaseSectionType.cta:
        return {'eyebrow': '', 'text': '', 'buttonLabel': '', 'url': ''};
      default:
        return const {};
    }
  }
}

class ShowcasePage {
  final ShowcasePageKind kind;

  /// Accueil uniquement : textes du bandeau d'en-tête.
  final String heroEyebrow;
  final String heroTagline;

  final List<ShowcaseSection> sections;

  const ShowcasePage({
    required this.kind,
    this.heroEyebrow = '',
    this.heroTagline = '',
    required this.sections,
  });

  /// [json] null ou sans `sections` (rien encore enregistré) → page par
  /// défaut, identique au contenu historique codé en dur.
  factory ShowcasePage.fromJson(
    ShowcasePageKind kind,
    Map<String, dynamic>? json,
  ) {
    final defaults = kind == ShowcasePageKind.home
        ? ShowcasePage.defaultHome()
        : ShowcasePage.defaultGym();
    final rawSections = json?['sections'];
    if (rawSections is! List) {
      final legacy = json == null ? null : _fromLegacyGym(json);
      return legacy ?? defaults;
    }
    final hero = json!['hero'] as Map<String, dynamic>?;
    final seenBuiltins = <ShowcaseSectionType>{};
    final sections = rawSections
        .whereType<Map>()
        .map((s) => ShowcaseSection.fromJson(Map<String, dynamic>.from(s)))
        .whereType<ShowcaseSection>()
        // Intégrées : uniquement celles de ce type de page, une seule fois.
        .where(
          (s) =>
              !s.type.isBuiltin ||
              (defaults._hasType(s.type) && seenBuiltins.add(s.type)),
        )
        .toList();
    // Une section intégrée absente (ajoutée dans une version ultérieure de
    // l'app) est rajoutée à la fin plutôt que de disparaître silencieusement.
    for (final t in ShowcaseSectionType.builtinsFor(kind)) {
      if (!sections.any((s) => s.type == t)) {
        sections.add(ShowcaseSection(id: t.key, type: t));
      }
    }
    return ShowcasePage(
      kind: kind,
      heroEyebrow: (hero?['eyebrow'] as String?) ?? defaults.heroEyebrow,
      heroTagline: (hero?['tagline'] as String?) ?? defaults.heroTagline,
      sections: sections,
    );
  }

  Map<String, dynamic> toJson() => {
    if (kind == ShowcasePageKind.home)
      'hero': {'eyebrow': heroEyebrow, 'tagline': heroTagline},
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  ShowcasePage copyWith({
    String? heroEyebrow,
    String? heroTagline,
    List<ShowcaseSection>? sections,
  }) => ShowcasePage(
    kind: kind,
    heroEyebrow: heroEyebrow ?? this.heroEyebrow,
    heroTagline: heroTagline ?? this.heroTagline,
    sections: sections ?? this.sections,
  );

  List<ShowcaseSection> get visibleSections =>
      sections.where((s) => s.visible).toList();

  bool _hasType(ShowcaseSectionType t) => sections.any((s) => s.type == t);

  /// Ancien format plat de `GET /gyms/{id}/showcase` (amenities, schedule,
  /// pricing, team en markdown) → sections markdown.
  static ShowcasePage? _fromLegacyGym(Map<String, dynamic> json) {
    const legacy = {
      'amenities': 'Équipements',
      'schedule': 'Horaires',
      'pricing': 'Tarifs',
      'team': 'Équipe',
    };
    final extra = <ShowcaseSection>[
      for (final e in legacy.entries)
        if ((json[e.key] as String?)?.trim().isNotEmpty == true)
          ShowcaseSection(
            id: 'legacy-${e.key}',
            type: ShowcaseSectionType.markdown,
            data: {'title': e.value, 'body': json[e.key]},
          ),
    ];
    if (extra.isEmpty) return null;
    final base = ShowcasePage.defaultGym().sections;
    final infoIndex = base.indexWhere(
      (s) => s.type == ShowcaseSectionType.gymInfo,
    );
    return ShowcasePage(
      kind: ShowcasePageKind.gym,
      sections: [...base]..insertAll(infoIndex + 1, extra),
    );
  }

  static ShowcasePage defaultGym() => ShowcasePage(
    kind: ShowcasePageKind.gym,
    sections: [
      for (final t in ShowcaseSectionType.gymBuiltins)
        ShowcaseSection(id: t.key, type: t),
    ],
  );

  static ShowcasePage defaultHome() => const ShowcasePage(
    kind: ShowcasePageKind.home,
    heroEyebrow: 'VITRINE TEAM OUSTAD',
    heroTagline: 'Choisis ta salle. Dépasse tes limites.',
    sections: [
      ShowcaseSection(
        id: 'marquee',
        type: ShowcaseSectionType.marquee,
        data: {
          'words': [
            'MUSCULATION',
            'CROSSFIT',
            'COACHING',
            'CARDIO',
            'NUTRITION',
            'COMMUNAUTÉ',
          ],
        },
      ),
      ShowcaseSection(
        id: 'categories',
        type: ShowcaseSectionType.categories,
        data: {
          'items': [
            {'label': 'Musculation', 'icon': 'fitness'},
            {'label': 'CrossFit', 'icon': 'fire'},
            {'label': 'Coaching', 'icon': 'groups'},
            {'label': 'Cardio', 'icon': 'run'},
            {'label': 'Nutrition', 'icon': 'food'},
          ],
        },
      ),
      ShowcaseSection(id: 'promos', type: ShowcaseSectionType.promos),
      ShowcaseSection(id: 'gyms', type: ShowcaseSectionType.gyms),
      ShowcaseSection(
        id: 'feature-experience',
        type: ShowcaseSectionType.feature,
        data: {
          'eyebrow': 'EXPÉRIENCE',
          'title': 'Du matériel qui tient ses promesses',
          'body':
              'Chaque salle est découpée en zones claires — musculation, '
              'cardio, fonctionnel, récupération — avec du matériel '
              'entretenu et contrôlé chaque semaine, jamais entassé.',
          'points': [
            'Zones dédiées, jamais de queue aux machines clés',
            'Contrôle et entretien hebdomadaire du matériel',
            'Espace étirements et récupération à part',
          ],
          'icon': 'fitness',
          'tag': 'STUDIO MUSCULATION',
        },
      ),
      ShowcaseSection(
        id: 'feature-community',
        type: ShowcaseSectionType.feature,
        data: {
          'eyebrow': 'COMMUNAUTÉ',
          'title': 'Une team, pas juste une salle',
          'body':
              'On connaît les prénoms, on suit les progrès, on célèbre '
              'les paliers. Les coachs sont présents sur le plateau aux '
              'heures de pointe, pas planqués dans un bureau.',
          'points': [
            'Coachs présents sur le plateau, pas qu\'au bureau',
            'Suivi de progression personnalisé',
            'Communauté active, événements réguliers',
          ],
          'icon': 'groups',
          'tag': 'ESPRIT TEAM',
        },
      ),
      ShowcaseSection(
        id: 'feature-coaching',
        type: ShowcaseSectionType.feature,
        data: {
          'eyebrow': 'ACCOMPAGNEMENT',
          'title': 'Des objectifs, un plan',
          'body':
              'Perte de poids, prise de masse, remise en forme : un '
              'programme ajusté à ton rythme, revu avec ton coach au '
              'fil des séances.',
          'points': [
            'Bilan initial et objectifs définis ensemble',
            'Programme ajusté toutes les 4 semaines',
            'Suivi dans l\'app, entre les séances',
          ],
          'icon': 'target',
          'tag': 'COACHING',
        },
      ),
      ShowcaseSection(
        id: 'testimonials',
        type: ShowcaseSectionType.testimonials,
        data: {
          'eyebrow': 'LA TEAM PARLE',
          'title': 'Ce qu\'en disent les membres',
          'items': [
            {
              'name': 'Sarah M.',
              'meta': 'Membre depuis 8 mois',
              'quote':
                  'Les coachs corrigent la posture sans qu\'on demande. '
                  'Ambiance sérieuse, jamais intimidante.',
            },
            {
              'name': 'Yanis B.',
              'meta': 'Membre depuis 1 an',
              'quote':
                  'Salle ouverte tard, c\'est ce qui me permet de tenir le '
                  'rythme avec le travail. Jamais bondé après 20h.',
            },
            {
              'name': 'Léa D.',
              'meta': 'Membre depuis 5 mois',
              'quote':
                  'Mon programme a été revu trois fois en six mois, '
                  'toujours selon mes vraies progressions. Ça change tout.',
            },
          ],
        },
      ),
      ShowcaseSection(
        id: 'cta-app',
        type: ShowcaseSectionType.cta,
        data: {
          'eyebrow': 'L\'APP TEAM OUSTAD',
          'text': 'Gérez vos séances, vos abonnements et vos objectifs.',
          'buttonLabel': 'Télécharger',
          // Variable GitHub ANDROID_TESTING_URL (tests internes) ; fiche Play sinon
          'url': String.fromEnvironment(
            'ANDROID_TESTING_URL',
            defaultValue:
                'https://play.google.com/store/apps/details?id=team.oustad.app',
          ),
        },
      ),
    ],
  );
}
