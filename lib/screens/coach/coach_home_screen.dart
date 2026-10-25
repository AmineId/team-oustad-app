import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/user_utils.dart';
import '../auth/login_screen.dart';
import '../programs/programs_screen.dart';

/// Accueil coach : ses membres affectés. Les séances et les check-ins du
/// jour arrivent dans les prochaines tranches Rôles V2.
class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final CoachService _coachService = CoachService(_apiService);

  List<Map<String, dynamic>>? _members;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    final members = token == null
        ? null
        : await _coachService.getMyMembers(token);
    if (!mounted) return;
    setState(() {
      _members = members;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members = _members;
    return Scaffold(
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
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (members == null || members.isEmpty)
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      members == null
                          ? 'Impossible de charger vos membres'
                          : l10n.coachNoMembers,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: members.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Text(
                      l10n.coachMyMembers,
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                  }
                  final member = members[i - 1];
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
              ),
      ),
    );
  }
}
