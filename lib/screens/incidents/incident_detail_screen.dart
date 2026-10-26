import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';
import 'incidents_screen.dart';

/// Détail d'un incident et fil de discussion. L'owner et le créateur
/// écrivent ; seul l'owner change le statut. Les nouveaux messages arrivent
/// par polling (toutes les 10 s, app au premier plan) et sur push FCM ; le
/// fil est marqué lu à l'ouverture et à chaque réception. Renvoie `true` au
/// pop si quelque chose a changé.
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
  final _scrollController = ScrollController();
  late final AppLifecycleListener _lifecycle;
  Timer? _pollTimer;

  late Map<String, dynamic> _incident = widget.incident;
  Uint8List? _photo;
  bool _isOwner = false;
  int? _myId;
  bool _sending = false;
  bool _changed = false;
  List<Map<String, dynamic>> _messages = [];
  bool _hasOlder = false;
  bool _loadingOlder = false;
  bool _polling = false;

  // L'incident peut n'avoir que son id (ouverture depuis une notification).
  int get _id => widget.incident['id'] as int;
  int? get _lastId => _messages.isEmpty ? null : _messages.last['id'] as int?;
  bool get _closed => _incident['status'] == 'closed';
  bool get _isCreator =>
      _myId != null &&
      (_incident['createdBy'] as Map<String, dynamic>?)?['id'] == _myId;

  @override
  void initState() {
    super.initState();
    NotificationRouter.openIncidentId = _id;
    NotificationRouter.received.addListener(_onPush);
    _lifecycle = AppLifecycleListener(onResume: _pollNew);
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _lifecycle.dispose();
    NotificationRouter.received.removeListener(_onPush);
    if (NotificationRouter.openIncidentId == _id) {
      NotificationRouter.openIncidentId = null;
    }
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPush() {
    final data = NotificationRouter.received.value;
    if (data == null ||
        data['type'] != 'incident' ||
        NotificationRouter.incidentIdOf(data) != _id) {
      return;
    }
    _pollNew();
    // Changement de statut : recharger l'en-tête.
    if (data['action'] != 'message') _reload();
  }

  Future<void> _init() async {
    _isOwner = await _authService.isOwner();
    final profile = await _authService.getCachedUserProfile();
    final id = profile?['id'] ?? (profile?['user'] as Map?)?['id'];
    _myId = id is int ? id : int.tryParse('$id');
    await _reload();
    await _loadLatest();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollNew());
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

  /// Derniers messages, puis marque le fil lu.
  Future<void> _loadLatest() async {
    final token = await _authService.loadToken();
    if (token == null) return;
    final page = await _incidentService.getMessages(token, _id);
    if (!mounted) return;
    setState(() {
      _messages =
          page?.messages ??
          ApiService.listFrom(_incident['messages'], 'messages');
      _hasOlder = page?.hasMore ?? false;
    });
    _scrollToBottom();
    _markRead(token);
  }

  /// Messages plus récents que le dernier affiché ([after] exclusif).
  Future<void> _pollNew() async {
    if (_polling || !mounted) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _polling = true;
    try {
      final token = await _authService.loadToken();
      if (token == null) return;
      final fresh = <Map<String, dynamic>>[];
      var hasMore = true;
      while (hasMore) {
        final page = await _incidentService.getMessages(
          token,
          _id,
          after: fresh.isEmpty ? _lastId : fresh.last['id'] as int?,
        );
        if (page == null) break;
        fresh.addAll(page.messages);
        hasMore = page.hasMore && page.messages.isNotEmpty;
      }
      final known = _messages.map((m) => m['id']).toSet();
      fresh.removeWhere((m) => known.contains(m['id']));
      if (fresh.isEmpty || !mounted) return;
      final atBottom =
          !_scrollController.hasClients ||
          _scrollController.position.extentAfter < 120;
      setState(() => _messages = [..._messages, ...fresh]);
      if (atBottom) _scrollToBottom();
      if (fresh.any((m) => (m['author'] as Map?)?['id'] != _myId)) {
        _changed = true;
        _markRead(token);
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _loadOlder() async {
    final first = _messages.isEmpty ? null : _messages.first['id'] as int?;
    if (first == null || _loadingOlder) return;
    setState(() => _loadingOlder = true);
    final token = await _authService.loadToken();
    final page = token == null
        ? null
        : await _incidentService.getMessages(token, _id, before: first);
    if (!mounted) return;
    setState(() {
      _loadingOlder = false;
      if (page != null) {
        _messages = [...page.messages, ..._messages];
        _hasOlder = page.hasMore;
      }
    });
  }

  void _markRead(String token) {
    _incidentService.markRead(token, _id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
      await _pollNew();
      _scrollToBottom();
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
    // Ouvert depuis une notification : seul l'id est connu jusqu'au chargement.
    if (_incident['status'] == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final creator = _incident['createdBy'] as Map<String, dynamic>?;
    final gym = (_incident['gym'] as Map<String, dynamic>?)?['name'];
    final messages = _messages;
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
                onRefresh: () async {
                  await _reload();
                  await _pollNew();
                },
                child: ListView(
                  controller: _scrollController,
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
                    if (_hasOlder)
                      Center(
                        child: _loadingOlder
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(),
                              )
                            : TextButton(
                                onPressed: _loadOlder,
                                child: const Text('Messages précédents'),
                              ),
                      ),
                    if (messages.isEmpty)
                      Text('Aucun message', style: theme.textTheme.bodySmall),
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
                            hintText: 'Écrire un message…',
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
