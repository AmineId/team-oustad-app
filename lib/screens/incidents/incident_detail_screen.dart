import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';
import 'incidents_screen.dart';

/// Détail d'un incident et fil de messages. L'owner et le créateur
/// répondent ; seul l'owner change le statut. Renvoie `true` au pop si
/// quelque chose a changé.
class IncidentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> incident;

  const IncidentDetailScreen({super.key, required this.incident});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final IncidentService _incidentService = IncidentService(_apiService);
  final _replyController = TextEditingController();

  late Map<String, dynamic> _incident = widget.incident;
  Uint8List? _photo;
  bool _isOwner = false;
  int? _myId;
  bool _sending = false;
  bool _changed = false;

  int get _id => _incident['id'] as int;
  bool get _closed => _incident['status'] == 'closed';
  bool get _isCreator =>
      _myId != null &&
      (_incident['createdBy'] as Map<String, dynamic>?)?['id'] == _myId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _isOwner = await _authService.isOwner();
    final profile = await _authService.getCachedUserProfile();
    final id = profile?['id'] ?? (profile?['user'] as Map?)?['id'];
    _myId = id is int ? id : int.tryParse('$id');
    await _reload();
    if (_incident['hasPhoto'] == true) {
      final token = await _authService.loadToken();
      final photo = token == null
          ? null
          : await _incidentService.getPhoto(token, _id);
      if (mounted) setState(() => _photo = photo);
    }
  }

  Future<void> _reload() async {
    final token = await _authService.loadToken();
    if (token == null) return;
    final fresh = await _incidentService.getIncident(token, _id);
    if (mounted) setState(() => _incident = fresh ?? _incident);
  }

  Future<void> _send() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    final token = await _authService.loadToken();
    final error = token == null
        ? 'Session expirée'
        : await _incidentService.addMessage(token, _id, body);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _replyController.clear();
      _changed = true;
      _reload();
    } else {
      AppSnackBar.error(context, error);
    }
  }

  Future<void> _setStatus(String status) async {
    final token = await _authService.loadToken();
    if (token == null) return;
    final error = await _incidentService.setStatus(token, _id, status);
    if (!mounted) return;
    if (error == null) {
      AppSnackBar.success(
        context,
        'Statut : ${IncidentService.statuses[status]} (créateur prévenu)',
      );
      _changed = true;
      _reload();
    } else {
      AppSnackBar.error(context, error);
    }
  }

  String _date(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creator = _incident['createdBy'] as Map<String, dynamic>?;
    final gym = (_incident['gym'] as Map<String, dynamic>?)?['name'];
    final messages = ApiService.listFrom(_incident['messages'], 'messages');
    final canReply = !_closed && (_isOwner || _isCreator);
    final severity = _incident['severity'] as String?;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_incident['title'] as String? ?? 'Incident'),
          actions: [
            if (_isOwner)
              PopupMenuButton<String>(
                tooltip: 'Changer le statut',
                icon: const Icon(Icons.flag_outlined),
                onSelected: _setStatus,
                itemBuilder: (_) => [
                  for (final e in IncidentService.statuses.entries)
                    if (e.key != _incident['status'])
                      PopupMenuItem(value: e.key, child: Text(e.value)),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            IncidentService.statuses[_incident['status']] ??
                                '${_incident['status']}',
                          ),
                        ),
                        Chip(
                          avatar: Icon(
                            Icons.circle,
                            size: 12,
                            color: incidentSeverityColor(context, severity),
                          ),
                          label: Text(
                            IncidentService.severities[severity] ?? '$severity',
                          ),
                        ),
                        Chip(
                          label: Text(
                            IncidentService.categories[_incident['category']] ??
                                '${_incident['category']}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (creator != null) 'Par ${getUserFullName(creator)}',
                        ?gym,
                        if (_incident['source'] == 'kiosk') 'depuis la borne',
                        _date(_incident['createdAt'] as String?),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (_photo != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_photo!, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      _incident['description'] as String? ?? '',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Divider(height: 32),
                    if (messages.isEmpty)
                      Text('Aucune réponse', style: theme.textTheme.bodySmall),
                    for (final m in messages) _buildMessage(m),
                  ],
                ),
              ),
            ),
            if (canReply)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Répondre…',
                          ),
                        ),
                      ),
                      _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.send,
                                color: context.palette.primary,
                              ),
                              onPressed: _send,
                            ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> m) {
    final author = m['author'] as Map<String, dynamic>?;
    final mine = _myId != null && author?['id'] == _myId;
    final fromOwner = author?['role'] == 'owner';
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: mine
              ? context.palette.primary.withValues(alpha: 0.15)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${getUserFullName(author)}${fromOwner ? ' (propriétaire)' : ''}'
              ' · ${_date(m['createdAt'] as String?)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(m['body'] as String? ?? ''),
          ],
        ),
      ),
    );
  }
}
