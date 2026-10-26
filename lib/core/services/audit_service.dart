import 'dart:convert';

import 'api_service.dart';

/// Page d'historique : entrées de la plus récente à la plus ancienne.
typedef AuditPage = ({List<Map<String, dynamic>> entries, bool hasMore});

/// Historique d'audit (qui a modifié quoi et quand), réservé au
/// super-owner (`permissions.isSuperOwner`). Les noms d'entité et de champ
/// arrivent bruts (modèles Prisma) : libellés FR ici, repli sur le nom brut.
class AuditService {
  final ApiService _api;

  AuditService(this._api);

  static const actions = {
    'create': 'Création',
    'update': 'Modification',
    'delete': 'Suppression',
  };

  static const _verbs = {
    'create': 'a créé',
    'update': 'a modifié',
    'delete': 'a supprimé',
  };

  static const _entities = {
    'User': 'Utilisateur',
    'Member': 'Membre',
    'Manager': 'Manager',
    'Owner': 'Owner',
    'Gym': 'Salle',
    'GymPhoto': 'Photo de salle',
    'OpeningHour': 'Horaire',
    'Subscription': 'Abonnement',
    'SubscriptionType': 'Type d\'abonnement',
    'Payment': 'Paiement',
    'GymCheckIn': 'Entrée en salle',
    'CoachGym': 'Salle du coach',
    'Program': 'Programme',
    'ProgramDay': 'Jour de programme',
    'ProgramExercise': 'Exercice de programme',
    'ProgramAssignment': 'Affectation de programme',
    'Exercise': 'Exercice',
    'TrainingSession': 'Séance',
    'SessionMember': 'Inscription à une séance',
    'Incident': 'Incident',
    'IncidentMessage': 'Message d\'incident',
    'Product': 'Produit',
    'Banner': 'Événement',
    'ShowcaseSection': 'Section vitrine',
    'Planning': 'Planning',
  };

  static const _fields = {
    'firstName': 'Prénom',
    'password': 'Mot de passe',
    'photo': 'Photo',
    'joinedAt': 'Inscrit le',
    'muscleGroup': 'Groupes musculaires',
    'content': 'Contenu',
    'lastName': 'Nom',
    'email': 'E-mail',
    'phone': 'Téléphone',
    'phoneNumber': 'Téléphone',
    'address': 'Adresse',
    'role': 'Rôle',
    'name': 'Nom',
    'title': 'Titre',
    'description': 'Description',
    'status': 'Statut',
    'type': 'Type',
    'gymId': 'Salle',
    'userId': 'Utilisateur',
    'memberId': 'Membre',
    'coachId': 'Coach',
    'authorId': 'Auteur',
    'createdBy': 'Créé par',
    'assignedBy': 'Affecté par',
    'closedBy': 'Clôturé par',
    'subscriptionTypeId': 'Type d\'abonnement',
    'subscriptionId': 'Abonnement',
    'programId': 'Programme',
    'exerciseId': 'Exercice',
    'sessionId': 'Séance',
    'productId': 'Produit',
    'incidentId': 'Incident',
    'bannerId': 'Événement',
    'startDate': 'Début',
    'endDate': 'Fin',
    'startAt': 'Début',
    'endAt': 'Fin',
    'amount': 'Montant',
    'price': 'Prix',
    'stock': 'Stock',
    'capacity': 'Places',
    'sessionQuota': 'Quota de séances',
    'sessionsUsed': 'Séances utilisées',
    'isPublished': 'Publié',
    'isActive': 'Actif',
    'severity': 'Gravité',
    'category': 'Catégorie',
    'body': 'Message',
    'notes': 'Notes',
    'level': 'Niveau',
    'durationWeeks': 'Durée (semaines)',
    'dayOfWeek': 'Jour',
    'openTime': 'Ouverture',
    'closeTime': 'Fermeture',
    'checkInTime': 'Entrée',
    'checkOutTime': 'Sortie',
    'birthDate': 'Date de naissance',
    'profession': 'Profession',
    'fitnessLevel': 'Niveau sportif',
    'onboarding': 'Onboarding',
    'displayId': 'Identifiant',
    'createdAt': 'Créé le',
    'updatedAt': 'Modifié le',
    '_count': 'Nombre de lignes',
  };

  static String entityLabel(String? entity) =>
      _entities[entity] ?? entity ?? 'Objet';

  static String fieldLabel(String field) => _fields[field] ?? field;

  /// « Amine I. a modifié »
  static String sentenceOf(Map<String, dynamic> e) =>
      '${e['actorLabel'] ?? 'Anonyme'} ${_verbs[e['action']] ?? e['action']}';

  /// Opération de masse résumée en une ligne (`changes._count`).
  static bool isBulk(Map<String, dynamic> e) =>
      e['entityId'] == null && (e['changes'] as Map?)?['_count'] != null;

  /// Valeur affichable d'un côté d'un changement (libellé de clé étrangère
  /// figé à l'écriture si présent).
  static String valueText(Object? value, Object? label) {
    if (label is String && label.isNotEmpty) return label;
    if (value == null) return '—';
    if (value is bool) return value ? 'Oui' : 'Non';
    if (value is String) {
      final date = RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value)
          ? DateTime.tryParse(value)?.toLocal()
          : null;
      if (date != null) {
        String two(int n) => n.toString().padLeft(2, '0');
        return '${two(date.day)}/${two(date.month)}/${date.year} '
            '${two(date.hour)}:${two(date.minute)}';
      }
      return value.isEmpty ? '(vide)' : _truncate(value);
    }
    // Tableaux et objets JSON (muscleGroup, contenu vitrine…) : rendu
    // générique tronqué.
    if (value is List) {
      if (value.isEmpty) return '(aucun)';
      if (value.every((v) => v is String || v is num)) {
        return _truncate(value.join(', '));
      }
      return '${value.length} élément(s)';
    }
    if (value is Map) return _truncate(jsonEncode(value));
    return '$value';
  }

  static String _truncate(String text, [int max = 160]) =>
      text.length <= max ? text : '${text.substring(0, max)}…';

  static const _errors = {
    'super_owner_required': 'Réservé au super-owner',
    'invalid_entity': 'Type d\'objet inconnu',
    'invalid_action': 'Action inconnue',
    'invalid_date': 'Date invalide',
    'invalid_cursor': 'Pagination invalide',
    'invalid_limit': 'Limite invalide',
  };

  static String errorOf(({int status, dynamic body}) r) {
    final body = r.body;
    final code = body is Map ? body['error'] as String? : null;
    return _errors[code] ?? 'Erreur (${r.status == 0 ? 'réseau' : r.status})';
  }

  /// Une page d'historique ; [before] = id de la dernière entrée reçue.
  /// Renvoie le message d'erreur à la place de la page en cas d'échec.
  Future<({AuditPage? page, String? error})> getEntries(
    String token, {
    String? entity,
    String? action,
    String? actorId,
    String? gymId,
    String? userId,
    String? entityId,
    String? q,
    DateTime? from,
    DateTime? to,
    int? before,
    int limit = 50,
  }) async {
    final r = await _api.sendJson(
      'GET',
      '/audit-logs',
      token,
      query: {
        'entity': ?entity,
        'action': ?action,
        'actorId': ?actorId,
        'gymId': ?gymId,
        'userId': ?userId,
        'entityId': ?entityId,
        if (q != null && q.isNotEmpty) 'q': q,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (before != null) 'before': '$before',
        'limit': '$limit',
      },
    );
    final body = r.body;
    if (r.status != 200 || body is! Map) return (page: null, error: errorOf(r));
    return (
      page: (
        entries: ApiService.listFrom(body, 'entries'),
        hasMore: body['hasMore'] == true,
      ),
      error: null,
    );
  }

  /// Types d'objet et actions disponibles pour les filtres.
  Future<List<String>?> getEntities(String token) async {
    final r = await _api.sendJson('GET', '/audit-logs/meta', token);
    final body = r.body;
    if (r.status != 200 || body is! Map) return null;
    final entities = body['entities'];
    return entities is List ? entities.whereType<String>().toList() : null;
  }

  Future<Map<String, dynamic>?> getEntry(String token, int id) async {
    final r = await _api.sendJson('GET', '/audit-logs/$id', token);
    return r.status == 200 && r.body is Map<String, dynamic>
        ? r.body as Map<String, dynamic>
        : null;
  }
}
