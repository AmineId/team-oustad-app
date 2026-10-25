import 'api_service.dart';

/// Résultat d'une affectation de programme (tout ou rien côté serveur).
class ProgramAssignResult {
  /// Nombre d'affectations actives remplacées (passées en `completed`).
  final int replaced;

  /// Membres refusés (`memberId`, `reason`) : rien n'a été créé.
  final List<Map<String, dynamic>> rejected;

  /// Message d'erreur générique (réseau, droits…), null si succès.
  final String? error;

  const ProgramAssignResult({
    this.replaced = 0,
    this.rejected = const [],
    this.error,
  });

  bool get ok => error == null && rejected.isEmpty;
}

/// Programmes (Rôles V2) : modèles créés par l'owner, puis affectés aux
/// membres par l'owner, le manager (sa salle) ou le coach (ses membres).
/// Remplace les écritures /plannings (désormais 410 côté serveur).
class ProgramService {
  final ApiService _api;

  ProgramService(this._api);

  static const levels = {
    'beginner': 'Débutant',
    'intermediate': 'Intermédiaire',
    'advanced': 'Avancé',
  };

  static const rejectReasons = {
    'member_not_found': 'membre introuvable',
    'not_your_member': "membre qui ne vous est pas affecté",
    'other_gym': 'membre d\'une autre salle',
  };

  /// Jours non vides, triés lundi → dimanche (0 = dimanche côté serveur).
  static List<Map<String, dynamic>> daysOf(Map<String, dynamic> program) {
    final days = ApiService.listFrom(program['days'], 'days')
        .where(
          (d) => ApiService.listFrom(d['exercises'], 'exercises').isNotEmpty,
        )
        .toList();
    int rank(Map<String, dynamic> d) => ((d['dayOfWeek'] as int? ?? 0) + 6) % 7;
    days.sort((a, b) => rank(a).compareTo(rank(b)));
    return days;
  }

  Future<List<Map<String, dynamic>>?> getPrograms(
    String token, {
    String? search,
  }) async {
    final r = await _api.sendJson(
      'GET',
      '/programs',
      token,
      query: (search == null || search.isEmpty) ? null : {'search': search},
    );
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'programs');
  }

  Future<Map<String, dynamic>?> getProgram(String token, int id) async {
    final r = await _api.sendJson('GET', '/programs/$id', token);
    return r.status == 200 && r.body is Map<String, dynamic>
        ? r.body as Map<String, dynamic>
        : null;
  }

  /// Crée ([id] null) ou remplace entièrement un programme (owner).
  /// [data] : `{title, description?, level?, durationWeeks?, days}`.
  Future<Map<String, dynamic>?> saveProgram(
    String token,
    Map<String, dynamic> data, {
    int? id,
  }) async {
    final r = await _api.sendJson(
      id == null ? 'POST' : 'PUT',
      id == null ? '/programs' : '/programs/$id',
      token,
      body: data,
    );
    if (r.status != 200 && r.status != 201) return null;
    final body = r.body;
    if (body is Map<String, dynamic>) {
      return body['program'] is Map<String, dynamic>
          ? body['program'] as Map<String, dynamic>
          : body;
    }
    return const {};
  }

  /// Supprime un programme (owner). Renvoie null si OK, sinon un message.
  Future<String?> deleteProgram(String token, int id) async {
    final r = await _api.sendJson('DELETE', '/programs/$id', token);
    if (r.status == 200 || r.status == 204) return null;
    if (r.status == 409) {
      return 'Programme encore affecté à des membres : annulez d\'abord '
          'leurs affectations.';
    }
    return 'Échec de la suppression';
  }

  Future<ProgramAssignResult> assign(
    String token,
    int programId, {
    required List<int> memberIds,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    String day(DateTime d) => d.toIso8601String().split('T').first;
    final r = await _api.sendJson(
      'POST',
      '/programs/$programId/assignments',
      token,
      body: {
        'memberIds': memberIds,
        'startDate': day(startDate),
        if (endDate != null) 'endDate': day(endDate),
      },
    );
    final body = r.body;
    if (r.status == 200 || r.status == 201) {
      return ProgramAssignResult(
        replaced: body is Map ? (body['replaced'] as int? ?? 0) : 0,
      );
    }
    if (r.status == 422 && body is Map) {
      return ProgramAssignResult(
        rejected: ApiService.listFrom(body['rejected'], 'rejected'),
      );
    }
    return const ProgramAssignResult(error: 'Échec de l\'affectation');
  }

  /// Annule une affectation (historique conservé côté serveur).
  Future<bool> cancelAssignment(String token, int assignmentId) async {
    final r = await _api.sendJson(
      'DELETE',
      '/program-assignments/$assignmentId',
      token,
    );
    return r.status == 200 || r.status == 204;
  }

  /// Affectations d'un membre, la plus récente d'abord.
  Future<List<Map<String, dynamic>>?> getMemberAssignments(
    String token,
    int memberId,
  ) async {
    final r = await _api.sendJson('GET', '/members/$memberId/programs', token);
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'assignments');
  }
}
