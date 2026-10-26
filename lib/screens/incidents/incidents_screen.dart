import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import 'incident_create_screen.dart';
import 'incident_detail_screen.dart';

/// Liste des incidents : owner = tous, manager = sa salle, coach = les
/// siens. Manager et coach peuvent en signaler un nouveau. Avec
/// [openIncidentId] (tap sur une notification), le fil s'ouvre directement.
class IncidentsScreen extends StatefulWidget {
  final int? openIncidentId;

  const IncidentsScreen({super.key, this.openIncidentId});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final IncidentService _incidentService = IncidentService(_apiService);

  List<Map<String, dynamic>>? _incidents;
  String? _status;
  bool _canCreate = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService.getUserType().then((role) {
      if (mounted) {
        setState(() => _canCreate = role == 'manager' || role == 'coach');
      }
    });
    NotificationRouter.received.addListener(_onPush);
    _load();
    final openId = widget.openIncidentId;
    if (openId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _push(IncidentDetailScreen(incident: {'id': openId})),
      );
    }
  }

  @override
  void dispose() {
    NotificationRouter.received.removeListener(_onPush);
    super.dispose();
  }

  /// Nouvel incident, message ou statut : rafraîchir les non-lus.
  void _onPush() {
    if (NotificationRouter.received.value?['type'] == 'incident') {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    final incidents = token == null
        ? null
        : await _incidentService.getIncidents(token, status: _status);
    if (!mounted) return;
    setState(() {
      _incidents = incidents;
      _isLoading = false;
    });
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    // Toujours recharger : la lecture d'un fil change les non-lus.
    if (mounted) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final incidents = _incidents;
    return Scaffold(
      appBar: AppBar(title: const Text('Incidents')),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _push(const IncidentCreateScreen()),
              icon: const Icon(Icons.report_outlined),
              label: const Text('Signaler'),
            )
          : null,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                for (final entry in <String?, String>{
                  null: 'Tous',
                  ...IncidentService.statuses,
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _status == entry.key,
                      onSelected: (_) {
                        _status = entry.key;
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (incidents == null || incidents.isEmpty)
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            incidents == null
                                ? 'Impossible de charger les incidents'
                                : 'Aucun incident',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: incidents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final incident = incidents[i];
                        return IncidentTile(
                          incident: incident,
                          onTap: () =>
                              _push(IncidentDetailScreen(incident: incident)),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Couleur associée à la gravité d'un incident.
Color incidentSeverityColor(BuildContext context, String? severity) =>
    switch (severity) {
      'critical' => context.palette.error,
      'high' => context.palette.warning,
      'medium' => context.palette.primary,
      _ => Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    };

class IncidentTile extends StatelessWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onTap;

  const IncidentTile({super.key, required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final severity = incident['severity'] as String?;
    final gym = (incident['gym'] as Map<String, dynamic>?)?['name'];
    final unread = incident['unreadCount'] as int? ?? 0;
    final last = incident['lastMessage'] as Map<String, dynamic>?;
    final lastAuthor = (last?['author'] as Map<String, dynamic>?)?['firstName'];
    final subtitle = [
      IncidentService.statuses[incident['status']] ?? incident['status'],
      IncidentService.categories[incident['category']] ?? '',
      ?gym,
    ].where((e) => e != '').join(' · ');
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.report_problem_outlined,
          color: incidentSeverityColor(context, severity),
        ),
        title: Text(
          incident['title'] as String? ?? 'Incident',
          style: unread > 0
              ? const TextStyle(fontWeight: FontWeight.bold)
              : null,
        ),
        subtitle: Text(
          last == null
              ? subtitle
              : '$subtitle\n${lastAuthor == null ? '' : '$lastAuthor : '}'
                    '${last['body'] ?? ''}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: unread > 0
            ? Badge.count(
                count: unread,
                child: const Icon(Icons.chat_bubble_outline),
              )
            : incident['hasPhoto'] == true
            ? const Icon(Icons.photo_outlined)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
