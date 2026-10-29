import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/utils/user_utils.dart';
import 'find_slot_screen.dart';
import 'session_calendar.dart';
import 'session_detail_screen.dart';
import 'session_editor_screen.dart';
import 'session_widgets.dart';

/// Calendrier des séances des coachs (owner : salle au choix ; manager : sa
/// salle). Création de séances, filtre par coach, recherche de créneaux.
class SessionsPlanningScreen extends StatefulWidget {
  const SessionsPlanningScreen({super.key});

  @override
  State<SessionsPlanningScreen> createState() => _SessionsPlanningScreenState();
}

class _SessionsPlanningScreenState extends State<SessionsPlanningScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final SessionService _sessionService = SessionService(_apiService);
  late final CoachService _coachService = CoachService(_apiService);

  bool _isOwner = false;
  List<Map<String, dynamic>> _gyms = [];
  int? _gymId;
  List<Map<String, dynamic>> _coaches = [];
  int? _coachId;
  String? _type;
  bool _ready = false;
  final _calendarKey = GlobalKey<SessionCalendarState>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await _authService.loadToken();
    if (token == null) return;
    _isOwner = await _authService.isOwner();
    if (_isOwner) {
      final gyms = await _apiService.getGyms(token);
      _gyms = gyms?.whereType<Map<String, dynamic>>().toList() ?? [];
      _gymId = _gyms.isEmpty ? null : _gyms.first['id'] as int?;
    } else {
      final profile = await _authService.getCachedUserProfile();
      final gymId = profile?['gymId'];
      _gymId = gymId is int ? gymId : null;
    }
    await _loadCoaches(token);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadCoaches(String token) async {
    if (_gymId == null) return;
    _coaches = await _coachService.getCoaches(token, gymId: _gymId) ?? [];
    if (_coaches.every((c) => c['id'] != _coachId)) _coachId = null;
  }

  Future<List<Map<String, dynamic>>?> _loadRange(
    DateTime from,
    DateTime to,
  ) async {
    final token = await _authService.loadToken();
    if (token == null || _gymId == null) return null;
    return _sessionService.getSessions(
      token,
      gymId: _gymId,
      coachId: _coachId,
      type: _type,
      from: from,
      to: to,
    );
  }

  Future<bool?> _push(Widget screen) =>
      Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => screen));

  /// Écran qui crée ou modifie des séances : recharger le calendrier.
  Future<void> _pushAndReload(Widget screen) async {
    if (await _push(screen) == true) _calendarKey.currentState?.reload();
  }

  void _create([DateTime? slot]) => _pushAndReload(
    SessionEditorScreen(gymId: _gymId!, coaches: _coaches, initialDay: slot),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning des coachs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_search),
            tooltip: 'Trouver un créneau',
            onPressed: _gymId == null
                ? null
                : () => _pushAndReload(FindSlotScreen(gymId: _gymId!)),
          ),
        ],
      ),
      floatingActionButton: _gymId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Séance'),
            ),
      body: Column(
        children: [
          if (_isOwner && _gyms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DropdownButtonFormField<int>(
                initialValue: _gymId,
                decoration: const InputDecoration(labelText: 'Salle'),
                items: [
                  for (final g in _gyms)
                    if (g['id'] is int)
                      DropdownMenuItem(
                        value: g['id'] as int,
                        child: Text(g['name'] as String? ?? 'Salle'),
                      ),
                ],
                onChanged: (v) async {
                  final token = await _authService.loadToken();
                  _gymId = v;
                  if (token != null) await _loadCoaches(token);
                  setState(() {});
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButtonFormField<int?>(
              key: ValueKey('coach-$_gymId-${_coaches.length}'),
              initialValue: _coachId,
              decoration: const InputDecoration(labelText: 'Coach'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous')),
                for (final c in _coaches)
                  if (c['id'] is int)
                    DropdownMenuItem(
                      value: c['id'] as int,
                      child: Text(getUserFullName(c)),
                    ),
              ],
              onChanged: (v) => setState(() => _coachId = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SessionTypeFilter(
              value: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
          ),
          Expanded(
            child: _ready
                ? SessionCalendar(
                    key: _calendarKey,
                    filters: (_gymId, _coachId, _type),
                    loader: _loadRange,
                    onSessionTap: (s) => _push(SessionDetailScreen(session: s)),
                    onSlotTap: _gymId == null ? null : _create,
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
