import 'api_service.dart';

/// Résultat d'une écriture sur les séances : séances renvoyées, ou erreur
/// (code serveur + message lisible), avec les détails éventuels (conflits
/// de chevauchement, membres refusés).
class SessionResult {
  final List<Map<String, dynamic>> sessions;
  final Map<String, dynamic>? data;
  final String? errorCode;
  final String? errorMessage;
  final List<Map<String, dynamic>> conflicts;
  final List<Map<String, dynamic>> rejected;

  const SessionResult({
    this.sessions = const [],
    this.data,
    this.errorCode,
    this.errorMessage,
    this.conflicts = const [],
    this.rejected = const [],
  });

  bool get ok => errorCode == null && errorMessage == null;
}

/// Séances (Rôles V2) : plage horaire d'un coach avec un ou plusieurs
/// membres. Planifiées par l'owner / le manager, pointées par le coach.
/// Dates échangées en ISO UTC ; l'affichage se fait en heure locale.
class SessionService {
  final ApiService _api;

  SessionService(this._api);

  static const errorMessages = {
    'session_overlap': 'Le coach a déjà une séance sur ce créneau',
    'coach_not_in_gym': 'Ce coach n\'est pas rattaché à cette salle',
    'outside_opening_hours': 'En dehors des horaires d\'ouverture',
    'gym_closed': 'La salle est fermée ce jour-là',
    'invalid_time_range': 'L\'heure de fin doit suivre l\'heure de début',
    'invalid_capacity': 'Capacité invalide',
    'capacity_below_booked': 'Capacité inférieure au nombre d\'inscrits',
    'session_full': 'Séance complète',
    'session_not_open': 'Séance annulée, terminée ou passée',
    'member_not_in_session': 'Ce membre n\'est pas inscrit à la séance',
    'no_active_subscription': 'Aucun abonnement actif',
    'quota_exhausted': 'Quota de séances épuisé',
    'subscription_expired': 'Abonnement expiré',
  };

  static const rejectReasons = {
    'member_not_found': 'membre introuvable',
    'member_other_gym': 'membre d\'une autre salle',
    'no_active_subscription': 'aucun abonnement actif',
    'member_overlap': 'déjà pris sur ce créneau',
    'already_booked': 'déjà inscrit',
  };

  static DateTime? startOf(Map<String, dynamic> s) =>
      DateTime.tryParse(s['startAt'] as String? ?? '')?.toLocal();

  static DateTime? endOf(Map<String, dynamic> s) =>
      DateTime.tryParse(s['endAt'] as String? ?? '')?.toLocal();

  /// Membres non annulés de la séance.
  static List<Map<String, dynamic>> membersOf(Map<String, dynamic> s) =>
      ApiService.listFrom(
        s['members'],
        'members',
      ).where((m) => m['status'] != 'cancelled').toList();

  static String _iso(DateTime d) => d.toUtc().toIso8601String();

  static Map<String, String> _range(DateTime? from, DateTime? to) => {
    if (from != null) 'from': _iso(from),
    if (to != null) 'to': _iso(to),
  };

  SessionResult _result(({int status, dynamic body}) r) {
    final body = r.body;
    if (r.status >= 200 && r.status < 300) {
      final sessions = body is Map && body['sessions'] != null
          ? ApiService.listFrom(body['sessions'], 'sessions')
          : (body is Map<String, dynamic> && body['id'] != null
                ? [body]
                : <Map<String, dynamic>>[]);
      return SessionResult(
        sessions: sessions,
        data: body is Map<String, dynamic> ? body : null,
      );
    }
    final code = body is Map ? body['error'] as String? : null;
    return SessionResult(
      errorCode: code ?? 'http_${r.status}',
      errorMessage:
          errorMessages[code] ??
          (body is Map ? body['message'] as String? : null) ??
          'Erreur (${r.status == 0 ? 'réseau' : r.status})',
      conflicts: body is Map
          ? ApiService.listFrom(body['conflicts'], 'conflicts')
          : const [],
      rejected: body is Map
          ? ApiService.listFrom(body['rejected'], 'rejected')
          : const [],
    );
  }

  /// Séances (owner : toutes ou [gymId] ; manager : sa salle).
  Future<List<Map<String, dynamic>>?> getSessions(
    String token, {
    int? gymId,
    int? coachId,
    DateTime? from,
    DateTime? to,
  }) async {
    final r = await _api.sendJson(
      'GET',
      '/sessions',
      token,
      query: {
        if (gymId != null) 'gymId': '$gymId',
        if (coachId != null) 'coachId': '$coachId',
        ..._range(from, to),
      },
    );
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'sessions');
  }

  Future<Map<String, dynamic>?> getSession(String token, int id) async {
    final r = await _api.sendJson('GET', '/sessions/$id', token);
    return r.status == 200 && r.body is Map<String, dynamic>
        ? r.body as Map<String, dynamic>
        : null;
  }

  /// Séances du coach connecté, toutes salles.
  Future<List<Map<String, dynamic>>?> getMySessions(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    final r = await _api.sendJson(
      'GET',
      '/coaches/me/sessions',
      token,
      query: _range(from, to),
    );
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'sessions');
  }

  /// Créneaux à venir avec des places (pour un membre : sans chevauchement,
  /// son coach en premier, `isMemberCoach`).
  Future<List<Map<String, dynamic>>?> getAvailable(
    String token, {
    required int gymId,
    int? memberId,
    int? coachId,
    DateTime? from,
    DateTime? to,
  }) async {
    final r = await _api.sendJson(
      'GET',
      '/sessions/available',
      token,
      query: {
        'gymId': '$gymId',
        if (memberId != null) 'memberId': '$memberId',
        if (coachId != null) 'coachId': '$coachId',
        ..._range(from, to),
      },
    );
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'sessions');
  }

  /// Crée une séance, ou une série hebdomadaire jusqu'à [repeatUntil].
  Future<SessionResult> create(
    String token, {
    required int gymId,
    required int coachId,
    required DateTime startAt,
    required DateTime endAt,
    required int capacity,
    String? title,
    String? notes,
    DateTime? repeatUntil,
  }) async {
    final r = await _api.sendJson(
      'POST',
      '/sessions',
      token,
      body: {
        'gymId': gymId,
        'coachId': coachId,
        'startAt': _iso(startAt),
        'endAt': _iso(endAt),
        'capacity': capacity,
        'title': ?title,
        'notes': ?notes,
        if (repeatUntil != null)
          'repeat': {'weekly': true, 'until': _iso(repeatUntil)},
      },
    );
    return _result(r);
  }

  /// Modifie une séance ; [scope] : this | following | series.
  Future<SessionResult> update(
    String token,
    int id, {
    String scope = 'this',
    DateTime? startAt,
    DateTime? endAt,
    int? coachId,
    int? capacity,
    String? title,
    String? notes,
  }) async {
    final r = await _api.sendJson(
      'PATCH',
      '/sessions/$id',
      token,
      query: {'scope': scope},
      body: {
        if (startAt != null) 'startAt': _iso(startAt),
        if (endAt != null) 'endAt': _iso(endAt),
        'coachId': ?coachId,
        'capacity': ?capacity,
        'title': ?title,
        'notes': ?notes,
      },
    );
    return _result(r);
  }

  /// Annule une séance (historique conservé, membres notifiés).
  Future<SessionResult> cancel(
    String token,
    int id, {
    String scope = 'this',
  }) async {
    final r = await _api.sendJson(
      'DELETE',
      '/sessions/$id',
      token,
      query: {'scope': scope},
    );
    return _result(r);
  }

  /// Inscrit des membres (tout ou rien).
  Future<SessionResult> addMembers(
    String token,
    int id,
    List<int> memberIds,
  ) async {
    final r = await _api.sendJson(
      'POST',
      '/sessions/$id/members',
      token,
      body: {'memberIds': memberIds},
    );
    return _result(r);
  }

  Future<SessionResult> removeMember(String token, int id, int memberId) async {
    final r = await _api.sendJson(
      'DELETE',
      '/sessions/$id/members/$memberId',
      token,
    );
    return _result(r);
  }

  /// Pointe un membre inscrit. `data['gymCheckIn']['created']` indique si
  /// une entrée salle a été décomptée (une seule par jour).
  Future<SessionResult> checkIn(String token, int id, int memberId) async {
    final r = await _api.sendJson(
      'POST',
      '/sessions/$id/check-in',
      token,
      body: {'memberId': memberId},
    );
    return _result(r);
  }
}
