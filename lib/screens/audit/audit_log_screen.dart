import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import 'audit_entry_screen.dart';

/// Historique d'audit (super-owner) : qui a modifié quoi et quand, toutes
/// salles confondues. Liste groupée par jour, filtres et défilement infini.
/// [userId] / [gymId] (displayId) pré-filtrent depuis une fiche membre ou
/// salle.
class AuditLogScreen extends StatefulWidget {
  final String? userId;
  final String? gymId;
  final String? title;

  const AuditLogScreen({super.key, this.userId, this.gymId, this.title});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final AuditService _auditService = AuditService(_apiService);
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _entries = [];
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  // Incrémenté à chaque changement de filtre : une page en retard est ignorée.
  int _generation = 0;

  List<String> _entities = [];
  List<Map<String, dynamic>> _gyms = [];
  String? _action;
  String? _entity;
  late String? _gymId = widget.gymId;
  int? _days;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFilters();
    _reload();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final token = await _authService.loadToken();
    if (token == null) return;
    final entities = await _auditService.getEntities(token);
    final gyms = widget.gymId == null && widget.userId == null
        ? await _apiService.getGyms(token)
        : null;
    if (!mounted) return;
    setState(() {
      _entities = [...?entities]
        ..sort(
          (a, b) => AuditService.entityLabel(
            a,
          ).compareTo(AuditService.entityLabel(b)),
        );
      _gyms =
          gyms
              ?.whereType<Map<String, dynamic>>()
              .where((g) => g['displayId'] is String)
              .toList() ??
          [];
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) _loadMore();
  }

  Future<void> _reload() async {
    _generation++;
    setState(() {
      _entries.clear();
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    setState(() => _loading = true);
    final token = await _authService.loadToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final result = await _auditService.getEntries(
      token,
      action: _action,
      entity: _entity,
      gymId: _gymId,
      userId: widget.userId,
      q: _searchController.text.trim(),
      from: _days == null
          ? null
          : DateUtils.dateOnly(
              DateTime.now(),
            ).subtract(Duration(days: _days! - 1)),
      before: _entries.isEmpty ? null : _entries.last['id'] as int?,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      final page = result.page;
      if (page == null) {
        _error = result.error;
        _hasMore = false;
      } else {
        _entries.addAll(page.entries);
        _hasMore = page.hasMore;
      }
    });
    // Page trop courte pour défiler : charger la suivante tout de suite.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent == 0) {
        _loadMore();
      }
    });
  }

  static String _dayLabel(DateTime d) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(d);
    if (day == today) return 'Aujourd\'hui';
    if (day == today.subtract(const Duration(days: 1))) return 'Hier';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(day.day)}/${two(day.month)}/${day.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Lignes à plat : en-têtes de jour (String) et entrées (Map).
    final rows = <Object>[];
    String? lastDay;
    for (final e in _entries) {
      final date = DateTime.tryParse(e['createdAt'] as String? ?? '');
      final day = date == null ? '' : _dayLabel(date.toLocal());
      if (day != lastDay) {
        rows.add(day);
        lastDay = day;
      }
      rows.add(e);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Historique')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                itemCount: rows.length + 1,
                itemBuilder: (context, i) {
                  if (i == rows.length) return _buildFooter();
                  final row = rows[i];
                  return row is String
                      ? _buildDayHeader(row)
                      : _AuditTile(entry: row as Map<String, dynamic>);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher (nom, titre, identifiant)…',
            ),
            onSubmitted: (_) => _reload(),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              for (final e in <String?, String>{
                null: 'Tout',
                ...AuditService.actions,
              }.entries) ...[
                ChoiceChip(
                  label: Text(e.value),
                  selected: _action == e.key,
                  onSelected: (_) {
                    _action = e.key;
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
              ],
              _buildMenuChip<int?>(
                icon: Icons.date_range,
                label: switch (_days) {
                  null => 'Toute période',
                  1 => 'Aujourd\'hui',
                  _ => '$_days derniers jours',
                },
                selected: _days != null,
                items: const {
                  null: 'Toute période',
                  1: 'Aujourd\'hui',
                  7: '7 derniers jours',
                  30: '30 derniers jours',
                },
                onSelected: (v) => _days = v,
              ),
              const SizedBox(width: 8),
              if (_entities.isNotEmpty) ...[
                _buildMenuChip<String?>(
                  icon: Icons.category_outlined,
                  label: _entity == null
                      ? 'Tous les objets'
                      : AuditService.entityLabel(_entity),
                  selected: _entity != null,
                  items: {
                    null: 'Tous les objets',
                    for (final e in _entities) e: AuditService.entityLabel(e),
                  },
                  onSelected: (v) => _entity = v,
                ),
                const SizedBox(width: 8),
              ],
              if (_gyms.isNotEmpty)
                _buildMenuChip<String?>(
                  icon: Icons.fitness_center,
                  label: _gymId == null
                      ? 'Toutes les salles'
                      : (_gyms.firstWhere(
                                  (g) => g['displayId'] == _gymId,
                                  orElse: () => const {},
                                )['name']
                                as String? ??
                            _gymId!),
                  selected: _gymId != null,
                  items: {
                    null: 'Toutes les salles',
                    for (final g in _gyms)
                      g['displayId'] as String:
                          g['name'] as String? ?? g['displayId'] as String,
                  },
                  onSelected: (v) => _gymId = v,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuChip<T>({
    required IconData icon,
    required String label,
    required bool selected,
    required Map<T, String> items,
    required ValueChanged<T> onSelected,
  }) {
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: (v) {
        onSelected(v);
        _reload();
      },
      itemBuilder: (_) => [
        for (final e in items.entries)
          PopupMenuItem<T>(value: e.key, child: Text(e.value)),
      ],
      child: Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        backgroundColor: selected
            ? context.palette.primary.withValues(alpha: 0.15)
            : null,
      ),
    );
  }

  Widget _buildDayHeader(String day) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        day,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFooter() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final text =
        _error ??
        (_entries.isEmpty
            ? 'Aucune modification trouvée'
            : (_hasMore ? null : 'Fin de l\'historique'));
    if (text == null) return const SizedBox(height: 48);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Couleur et icône d'une action d'audit.
(IconData, Color) auditActionStyle(BuildContext context, String? action) =>
    switch (action) {
      'create' => (Icons.add_circle_outline, context.palette.success),
      'delete' => (Icons.delete_outline, context.palette.error),
      _ => (Icons.edit_outlined, context.palette.primary),
    };

class _AuditTile extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _AuditTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = auditActionStyle(context, entry['action'] as String?);
    final entity = AuditService.entityLabel(entry['entity'] as String?);
    final label = entry['label'] as String?;
    final gym = (entry['gym'] as Map<String, dynamic>?)?['name'] as String?;
    final date = DateTime.tryParse(entry['createdAt'] as String? ?? '');
    String two(int n) => n.toString().padLeft(2, '0');
    final time = date == null
        ? null
        : '${two(date.toLocal().hour)}:${two(date.toLocal().minute)}';
    final bulk = AuditService.isBulk(entry);
    return Card(
      child: ListTile(
        leading: Icon(bulk ? Icons.layers_outlined : icon, color: color),
        title: Text(
          '${AuditService.sentenceOf(entry)} $entity'
          '${label == null || label.isEmpty ? '' : ' · $label'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text([?gym, ?time].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AuditEntryScreen(entry: entry)),
        ),
      ),
    );
  }
}
