import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/utils/user_utils.dart';
import 'find_slot_screen.dart';
import 'session_detail_screen.dart';
import 'session_editor_screen.dart';
import 'session_widgets.dart';

/// Planning hebdomadaire des coachs (owner : salle au choix ; manager : sa
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
  List<Map<String, dynamic>>? _sessions;
  bool _isLoading = true;

  late DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime d) {
    final day = DateUtils.dateOnly(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

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
    await _load();
  }

  Future<void> _loadCoaches(String token) async {
    if (_gymId == null) return;
    _coaches = await _coachService.getCoaches(token, gymId: _gymId) ?? [];
    if (_coaches.every((c) => c['id'] != _coachId)) _coachId = null;
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    final sessions = (token == null || _gymId == null)
        ? null
        : await _sessionService.getSessions(
            token,
            gymId: _gymId,
            coachId: _coachId,
            type: _type,
            from: _weekStart,
            to: _weekStart.add(const Duration(days: 7)),
          );
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  void _shiftWeek(int weeks) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));
    _load();
  }

  Future<void> _push(Widget screen) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = _sessions ?? [];
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning des coachs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_search),
            tooltip: 'Trouver un créneau',
            onPressed: _gymId == null
                ? null
                : () => _push(FindSlotScreen(gymId: _gymId!)),
          ),
        ],
      ),
      floatingActionButton: _gymId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _push(
                SessionEditorScreen(
                  gymId: _gymId!,
                  coaches: _coaches,
                  initialDay: _weekStart,
                ),
              ),
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
                  _gymId = v;
                  final token = await _authService.loadToken();
                  if (token != null) await _loadCoaches(token);
                  _load();
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
              onChanged: (v) {
                _coachId = v;
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SessionTypeFilter(
              value: _type,
              onChanged: (v) {
                setState(() => _type = v);
                _load();
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shiftWeek(-1),
              ),
              Expanded(
                child: Text(
                  '${sessionDay(_weekStart)} – ${sessionDay(weekEnd)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shiftWeek(1),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions == null
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Impossible de charger le planning',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      children: [
                        for (var i = 0; i < 7; i++)
                          ..._buildDay(
                            _weekStart.add(Duration(days: i)),
                            sessions,
                            theme,
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDay(
    DateTime day,
    List<Map<String, dynamic>> sessions,
    ThemeData theme,
  ) {
    final ofDay = sessions.where((s) {
      final start = SessionService.startOf(s);
      return start != null && DateUtils.isSameDay(start, day);
    }).toList();
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(sessionDay(day), style: theme.textTheme.titleSmall),
      ),
      if (ofDay.isEmpty)
        Text('Aucune séance', style: theme.textTheme.bodySmall),
      for (final s in ofDay)
        SessionCard(
          session: s,
          onTap: () => _push(SessionDetailScreen(session: s)),
        ),
    ];
  }
}
