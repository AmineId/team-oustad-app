import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/user_utils.dart';
import '../auth/login_screen.dart';
import '../programs/programs_screen.dart';
import '../sessions/session_detail_screen.dart';
import '../sessions/session_widgets.dart';

/// Accueil coach : ses séances à venir (pointage des membres) et ses
/// membres affectés (affectation de programmes).
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
  List<Map<String, dynamic>>? _sessions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    final today = DateUtils.dateOnly(DateTime.now());
    final results = token == null
        ? null
        : await Future.wait([
            _coachService.getMyMembers(token),
            _sessionService.getMySessions(
              token,
              from: today,
              to: today.add(const Duration(days: 7)),
            ),
          ]);
    if (!mounted) return;
    setState(() {
      _members = results?[0];
      _sessions = results?[1];
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

  Widget _buildSessions(AppLocalizations l10n) {
    final sessions = _sessions;
    if (sessions == null) return _message('Impossible de charger vos séances');
    if (sessions.isEmpty) return _message(l10n.coachNoSessions);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in sessions)
          SessionCard(session: s, showDay: true, onTap: () => _openSession(s)),
      ],
    );
  }

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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.coachRole),
          actions: [
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
              Tab(text: l10n.coachMySessions),
              Tab(text: l10n.coachMyMembers),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _load,
                    child: _buildSessions(l10n),
                  ),
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
