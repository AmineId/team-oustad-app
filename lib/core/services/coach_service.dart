import 'api_service.dart';

/// Coachs (Rôles V2) : création et salles par l'owner, affectation
/// coach ↔ membre par l'owner ou le manager, liste « mes membres » du coach.
/// Les droits sont appliqués par le serveur ; ce service ne fait que l'appel.
class CoachService {
  final ApiService _api;

  CoachService(this._api);

  /// Salles d'un coach : `gyms` fait foi (le `gymId` d'un coach n'est que
  /// sa salle principale).
  static List<Map<String, dynamic>> gymsOf(Map<String, dynamic> coach) =>
      ApiService.listFrom(coach['gyms'], 'gyms');

  /// Coachs d'une salle, ou tous les coachs (owner) si [gymId] est null.
  Future<List<Map<String, dynamic>>?> getCoaches(
    String token, {
    int? gymId,
  }) async {
    final r = await _api.sendJson(
      'GET',
      '/coaches',
      token,
      query: gymId == null ? null : {'gymId': '$gymId'},
    );
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'coaches');
  }

  /// Crée un coach (owner) ; l'email d'activation est envoyé par le serveur.
  /// Renvoie null en cas de succès, sinon le message d'erreur.
  Future<String?> createCoach(
    String token, {
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    required List<int> gymIds,
  }) async {
    final r = await _api.sendJson(
      'POST',
      '/users/create-coach',
      token,
      body: {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
        'gymIds': gymIds,
      },
    );
    if (r.status == 200 || r.status == 201) return null;
    return _errorOf(r.body) ?? 'Erreur lors de la création du coach';
  }

  /// Remplace les salles d'un coach (owner).
  Future<bool> updateCoachGyms(
    String token,
    int coachId,
    List<int> gymIds,
  ) async {
    final r = await _api.sendJson(
      'PATCH',
      '/users/$coachId/gyms',
      token,
      body: {'gymIds': gymIds},
    );
    return r.status == 200 || r.status == 204;
  }

  /// Affecte un coach à un membre, ou le retire si [coachId] est null.
  Future<bool> setMemberCoach(String token, int memberId, int? coachId) async {
    final r = await _api.sendJson(
      'PATCH',
      '/members/$memberId/coach',
      token,
      body: {'coachId': coachId},
    );
    return r.status == 200 || r.status == 204;
  }

  /// Membres affectés au coach connecté.
  Future<List<Map<String, dynamic>>?> getMyMembers(String token) async {
    final r = await _api.sendJson('GET', '/coaches/me/members', token);
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'members');
  }

  /// Entrées en salle du jour (`GET /check-in/today`) : coach = ses salles
  /// (ou [gymId]) avec `isMyMember` et `nextSessionToday` ; manager = sa
  /// salle ; owner = toutes ou [gymId].
  Future<List<Map<String, dynamic>>?> getTodayCheckIns(
    String token, {
    int? gymId,
  }) async {
    final r = await _api.sendJson(
      'GET',
      '/check-in/today',
      token,
      query: gymId == null ? null : {'gymId': '$gymId'},
    );
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'checkIns');
  }

  static String? _errorOf(dynamic body) {
    if (body is! Map) return null;
    final value = body['message'] ?? body['error'];
    return value is String ? value : null;
  }
}
