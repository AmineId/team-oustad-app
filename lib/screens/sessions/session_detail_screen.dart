import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';
import 'session_editor_screen.dart';
import 'session_widgets.dart';

/// Détail d'une séance : membres inscrits et pointage (coach, manager,
/// owner). Owner / manager : inscrire, désinscrire, modifier, annuler.
/// Renvoie `true` au pop si quelque chose a changé.
class SessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final SessionService _sessionService = SessionService(_apiService);
  late final CoachService _coachService = CoachService(_apiService);

  late Map<String, dynamic> _session = widget.session;
  bool _canManage = false;
  bool _changed = false;
  final Set<int> _busy = {};

  int get _id => _session['id'] as int;
  bool get _open => _session['status'] == 'scheduled';

  @override
  void initState() {
    super.initState();
    _authService.hasManagementAccess().then((v) {
      if (mounted) setState(() => _canManage = v);
    });
    _reload();
  }

  Future<void> _reload() async {
    final token = await _authService.loadToken();
    if (token == null) return;
    final fresh = await _sessionService.getSession(token, _id);
    if (fresh != null && mounted) setState(() => _session = fresh);
  }

  void _apply(SessionResult result) {
    _changed = true;
    final updated = result.sessions.where((s) => s['id'] == _id);
    if (updated.isNotEmpty) {
      setState(() => _session = updated.first);
    } else {
      _reload();
    }
  }

  Future<void> _checkIn(int memberId) async {
    final token = await _authService.loadToken();
    if (token == null) return;
    setState(() => _busy.add(memberId));
    final result = await _sessionService.checkIn(token, _id, memberId);
    if (!mounted) return;
    setState(() => _busy.remove(memberId));
    if (!result.ok) {
      AppSnackBar.error(context, result.errorMessage!);
      return;
    }
    final gymCheckIn = result.data?['gymCheckIn'];
    final remaining = gymCheckIn is Map
        ? gymCheckIn['sessionsRemaining']
        : null;
    AppSnackBar.success(
      context,
      gymCheckIn is Map && gymCheckIn['created'] == true
          ? 'Présence enregistrée'
                '${remaining == null ? '' : ' · $remaining séance(s) restante(s)'}'
          : 'Présence enregistrée (entrée salle déjà comptée aujourd\'hui)',
    );
    _changed = true;
    _reload();
  }

  Future<void> _removeMember(int memberId) async {
    final token = await _authService.loadToken();
    if (token == null) return;
    final result = await _sessionService.removeMember(token, _id, memberId);
    if (!mounted) return;
    if (result.ok) {
      AppSnackBar.success(context, 'Membre désinscrit');
      _apply(result);
    } else {
      AppSnackBar.error(context, result.errorMessage!);
    }
  }

  Future<void> _addMembers() async {
    final token = await _authService.loadToken();
    final gymId = _session['gymId'];
    if (token == null || gymId is! int) return;
    final list = await _apiService.getGymMembers(gymId, token);
    if (!mounted) return;
    final booked = SessionService.membersOf(
      _session,
    ).map((m) => m['memberId']).toSet();
    final candidates =
        list
            ?.whereType<Map<String, dynamic>>()
            .where((m) => !booked.contains(m['id']))
            .toList() ??
        [];
    final picked = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MemberPickerSheet(
        members: candidates,
        max: _session['remaining'] as int? ?? 0,
      ),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    final result = await _sessionService.addMembers(
      token,
      _id,
      picked.toList(),
    );
    if (!mounted) return;
    if (result.ok) {
      AppSnackBar.success(context, 'Membre(s) inscrit(s)');
      _apply(result);
    } else {
      showSessionError(
        context,
        result,
        memberName: (id) => getUserFullName(
          candidates.firstWhere((m) => m['id'] == id, orElse: () => {}),
          defaultValue: 'Membre #$id',
        ),
      );
    }
  }

  Future<void> _edit() async {
    final token = await _authService.loadToken();
    final gymId = _session['gymId'];
    if (token == null || gymId is! int) return;
    final coaches = await _coachService.getCoaches(token, gymId: gymId) ?? [];
    if (!mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionEditorScreen(
          gymId: gymId,
          coaches: coaches,
          session: _session,
        ),
      ),
    );
    if (saved == true) {
      _changed = true;
      _reload();
    }
  }

  Future<void> _cancel() async {
    final scope = await pickSessionScope(context, _session, 'Annuler');
    if (scope == null || !mounted) return;
    if (_session['seriesId'] == null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Annuler la séance ?'),
          content: const Text('Les membres inscrits seront prévenus.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Annuler la séance'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final token = await _authService.loadToken();
    if (token == null) return;
    final result = await _sessionService.cancel(token, _id, scope: scope);
    if (!mounted) return;
    if (result.ok) {
      AppSnackBar.success(context, 'Séance annulée');
      _apply(result);
    } else {
      AppSnackBar.error(context, result.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = SessionService.membersOf(_session);
    final notes = _session['notes'] as String?;
    final gym = (_session['gym'] as Map<String, dynamic>?)?['name'];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_session['title'] as String? ?? 'Séance'),
          actions: [
            if (_canManage && _open) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Modifier',
                onPressed: _edit,
              ),
              IconButton(
                icon: const Icon(Icons.event_busy),
                tooltip: 'Annuler la séance',
                onPressed: _cancel,
              ),
            ],
          ],
        ),
        floatingActionButton:
            _canManage && _open && (_session['remaining'] as int? ?? 0) > 0
            ? FloatingActionButton.extended(
                onPressed: _addMembers,
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Inscrire'),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(sessionSlot(_session), style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                [
                  sessionCoachName(_session),
                  ?gym,
                  '${_session['bookedCount'] ?? members.length}/'
                      '${_session['capacity'] ?? '?'} inscrit(s)',
                  if (!_open) 'Annulée ou terminée',
                ].join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(notes, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aucun inscrit', textAlign: TextAlign.center),
                ),
              for (final m in members) _buildMember(m),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMember(Map<String, dynamic> m) {
    final memberId = m['memberId'] as int? ?? 0;
    final member = m['member'] as Map<String, dynamic>?;
    final status = m['status'] as String? ?? 'booked';
    final present = status == 'checked_in';
    return Card(
      child: ListTile(
        leading: Icon(
          present ? Icons.check_circle : Icons.person_outline,
          color: present ? context.palette.success : null,
        ),
        title: Text(getUserFullName(member, defaultValue: 'Membre #$memberId')),
        subtitle: Text(sessionMemberStatus[status] ?? status),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!present && _open)
              _busy.contains(memberId)
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: () => _checkIn(memberId),
                      child: const Text('Pointer'),
                    ),
            if (_canManage && _open && !present)
              IconButton(
                icon: const Icon(Icons.person_remove_outlined),
                tooltip: 'Désinscrire',
                onPressed: () => _removeMember(memberId),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final int max;

  const _MemberPickerSheet({required this.members, required this.max});

  @override
  State<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<_MemberPickerSheet> {
  final Set<int> _selected = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final members = widget.members
        .where((m) => getUserFullName(m).toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Rechercher (${widget.max} place(s))',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final m in members)
                    if (m['id'] is int)
                      CheckboxListTile(
                        value: _selected.contains(m['id']),
                        title: Text(getUserFullName(m)),
                        subtitle: Text(m['displayId'] as String? ?? ''),
                        onChanged:
                            (_selected.length >= widget.max &&
                                !_selected.contains(m['id']))
                            ? null
                            : (on) => setState(
                                () => on == true
                                    ? _selected.add(m['id'] as int)
                                    : _selected.remove(m['id']),
                              ),
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ModernButton(
                text: 'Inscrire ${_selected.length} membre(s)',
                icon: Icons.check,
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
