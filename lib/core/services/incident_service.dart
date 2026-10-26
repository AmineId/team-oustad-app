import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Incidents (Rôles V2) : signalés par un manager (app ou kiosk) ou un
/// coach (app), traités par l'owner qui répond et change le statut ; le
/// créateur est notifié. La `source` (app / kiosk) est déduite du token.
class IncidentService {
  final ApiService _api;

  IncidentService(this._api);

  static const categories = {
    'equipment': 'Équipement',
    'safety': 'Sécurité',
    'hygiene': 'Hygiène',
    'member': 'Membre',
    'other': 'Autre',
  };

  static const severities = {
    'low': 'Faible',
    'medium': 'Moyenne',
    'high': 'Élevée',
    'critical': 'Critique',
  };

  static const statuses = {
    'open': 'Ouvert',
    'in_progress': 'En cours',
    'resolved': 'Résolu',
    'closed': 'Clôturé',
  };

  static const _errors = {
    'missing_fields': 'Champs obligatoires manquants',
    'invalid_field': 'Champ invalide',
    'invalid_photo': 'Photo invalide (JPEG, PNG ou WebP, 5 Mo max)',
    'gym_id_required': 'Choisissez une salle',
    'incident_closed': 'Incident clôturé',
    'kiosk_forbidden_role': 'Non autorisé depuis la borne',
    'forbidden': 'Action non autorisée',
  };

  static String _error(({int status, dynamic body}) r) {
    final body = r.body;
    final code = body is Map ? body['error'] as String? : null;
    return _errors[code] ??
        (body is Map ? body['message'] as String? : null) ??
        'Erreur (${r.status == 0 ? 'réseau' : r.status})';
  }

  Future<List<Map<String, dynamic>>?> getIncidents(
    String token, {
    int? gymId,
    String? status,
  }) async {
    final r = await _api.sendJson(
      'GET',
      '/incidents',
      token,
      query: {if (gymId != null) 'gymId': '$gymId', 'status': ?status},
    );
    if (r.status != 200) return null;
    return ApiService.listFrom(r.body, 'incidents');
  }

  /// Incident avec `messages[]` (du plus ancien au plus récent).
  Future<Map<String, dynamic>?> getIncident(String token, int id) async {
    final r = await _api.sendJson('GET', '/incidents/$id', token);
    return r.status == 200 && r.body is Map<String, dynamic>
        ? r.body as Map<String, dynamic>
        : null;
  }

  /// Crée un incident ; renvoie null si OK, sinon le message d'erreur.
  /// [photo] est envoyée en data URI base64 (`photoData`).
  Future<String?> create(
    String token, {
    required String title,
    required String description,
    required String category,
    required String severity,
    int? gymId,
    Uint8List? photo,
    String photoMime = 'image/jpeg',
  }) async {
    final r = await _api.sendJson(
      'POST',
      '/incidents',
      token,
      timeout: const Duration(seconds: 30),
      body: {
        'title': title,
        'description': description,
        'category': category,
        'severity': severity,
        'gymId': ?gymId,
        if (photo != null)
          'photoData': 'data:$photoMime;base64,${base64Encode(photo)}',
      },
    );
    return r.status == 201 || r.status == 200 ? null : _error(r);
  }

  /// Ajoute un message au fil ; null si OK, sinon le message d'erreur.
  Future<String?> addMessage(String token, int id, String body) async {
    final r = await _api.sendJson(
      'POST',
      '/incidents/$id/messages',
      token,
      body: {'body': body},
    );
    return r.status == 201 || r.status == 200 ? null : _error(r);
  }

  /// Change le statut (owner) ; null si OK, sinon le message d'erreur.
  Future<String?> setStatus(String token, int id, String status) async {
    final r = await _api.sendJson(
      'PATCH',
      '/incidents/$id',
      token,
      body: {'status': status},
    );
    return r.status == 200 ? null : _error(r);
  }

  Future<Uint8List?> getPhoto(String token, int id) =>
      _api.getBytes('/incidents/$id/photo', token);
}
