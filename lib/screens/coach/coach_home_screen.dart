import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/user_utils.dart';
import '../auth/login_screen.dart';
import '../incidents/incidents_screen.dart';
import '../programs/programs_screen.dart';
import '../sessions/session_calendar.dart';
import '../sessions/session_detail_screen.dart';
import '../sessions/session_widgets.dart';

/// Accueil coach : entrées en salle du jour, ses séances à venir (pointage
/// des membres) et ses membres affectés (affectation de programmes).
class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final CoachService _coachService = CoachService(_apiService);
  late final SessionService _sessionService = SessionService(_apiService);

  List<Map<String, dynamic>>? _members;
  List<Map<String, dynamic>>? _checkIns;
  bool _onlyMyMembers = false;
  int? _myId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationRouter.pending.addListener(_openFromNotification);
    // L'app a pu être lancée par un tap sur une notification.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openFromNotification(),
    );
  }

  @override
  void dispose() {
    NotificationRouter.pending.removeListener(_openFromNotification);
    super.dispose();
  }

  /// Séance affectée / modifiée → rafraîchir ; incident → la liste.
  void _openFromNotification() {
    if (!mounted || NotificationRouter.pending.value == null) return;
    final type = NotificationRouter.take();
    final home = ModalRoute.of(context);
    Navigator.of(context).popUntil((route) => route == home);
    _load();
    if (type == 'incident') {
      _openIncidents(NotificationRouter.incidentIdOf(NotificationRouter.data));
    }
  }

  void _openIncidents([int? incidentId]) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => IncidentsScreen(openIncidentId: incidentId),
    ),
  );

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    final results = token == null
        ? null
        : await Future.wait([
            _coachService.getMyMembers(token),
            _coachService.getTodayCheckIns(token),
          ]);
    final profile = await _authService.getCachedUserProfile();
    final myId = profile?['id'] ?? (profile?['user'] as Map?)?['id'];
    if (!mounted) return;
    setState(() {
      _members = results?[0];
      _checkIns = results?[1];
      _myId = myId is int ? myId : int.tryParse('$myId');
      _isLoading = false;
    });
  }

  Future<void> _openSession(Map<String, dynamic> session) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
    );
    if (changed == true) _load();
  }

  Future<void> _assignProgram(Map<String, dynamic> member) async {
    final id = member['id'];
    if (id is! int) return;
    final assigned = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramsScreen(assignToMemberIds: [id]),
      ),
    );
    if (assigned == true) _load();
  }

  Future<void> _logout() async {
    await _authService.clearProfileCache();
    await _authService.clearAll();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(fromLogout: true),
        ),
        (route) => false,
      );
    }
  }

  Widget _message(String text) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    ],
  );

  Widget _buildToday(AppLocalizations l10n) {
    final all = _checkIns;
    if (all == null) return _message('Impossible de charger les entrées');
    final checkIns = _onlyMyMembers
        ? all.where((c) => c['isMyMember'] == true).toList()
        : all;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${checkIns.length} entrée(s) aujourd\'hui',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilterChip(
              label: Text(l10n.coachMyMembers),
              selected: _onlyMyMembers,
              onSelected: (v) => setState(() => _onlyMyMembers = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (checkIns.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Aucune entrée', textAlign: TextAlign.center),
          ),
        for (final c in checkIns) _buildCheckIn(c),
      ],
    );
  }

  Widget _buildCheckIn(Map<String, dynamic> c) {
    final checkIn = DateTime.tryParse(
      c['checkInTime'] as String? ?? '',
    )?.toLocal();
    final gym = (c['gym'] as Map<String, dynamic>?)?['name'] as String?;
    final next = c['nextSessionToday'] as Map<String, dynamic>?;
    final nextStart = next == null ? null : SessionService.startOf(next);
    final mine = next != null && next['coachId'] == _myId;
    final lines = [
      [
        if (checkIn != null) 'Entrée ${sessionTime(checkIn)}',
        if (c['checkOutTime'] != null) 'sorti',
        ?gym,
      ].join(' · '),
      if (nextStart != null)
        'Séance à ${sessionTime(nextStart)}'
            '${next!['title'] == null ? '' : ' · ${next['title']}'}'
            '${mine ? ' (avec vous)' : ''}',
    ];
    return Card(
      child: ListTile(
        leading: Icon(
          c['isMyMember'] == true ? Icons.star : Icons.person_outline,
          color: c['isMyMember'] == true
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        title: Text(getUserFullName(c['member'] as Map<String, dynamic>?)),
        subtitle: Text(lines.join('\n')),
        isThreeLine: lines.length > 1,
        trailing: mine ? const Icon(Icons.chevron_right) : null,
        onTap: mine ? () => _openSession(next) : null,
      ),
    );
  }

  Widget _buildSessions() => SessionCalendar(
    loader: (from, to) async {
      final token = await _authService.loadToken();
      if (token == null) return null;
      return _sessionService.getMySessions(token, from: from, to: to);
    },
    onSessionTap: (s) => Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)),
    ),
  );

  Widget _buildMembers(AppLocalizations l10n) {
    final members = _members;
    if (members == null) return _message('Impossible de charger vos membres');
    if (members.isEmpty) return _message(l10n.coachNoMembers);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final member = members[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(getUserFullName(member)),
            subtitle: Text(member['displayId'] as String? ?? ''),
            trailing: const Icon(Icons.playlist_add),
            onTap: () => _assignProgram(member),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.coachRole),
          actions: [
            IconButton(
              icon: const Icon(Icons.report_outlined),
              tooltip: 'Incidents',
              onPressed: _openIncidents,
            ),
            IconButton(
              icon: const Icon(Icons.fitness_center),
              tooltip: 'Programmes',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgramsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.disconnect,
              onPressed: _logout,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.coachToday),
              Tab(text: l10n.coachMySessions),
              Tab(text: l10n.coachMyMembers),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  RefreshIndicator(onRefresh: _load, child: _buildToday(l10n)),
                  _buildSessions(),
                  RefreshIndicator(
                    onRefresh: _load,
                    child: _buildMembers(l10n),
                  ),
                ],
              ),
      ),
    );
  }
}
