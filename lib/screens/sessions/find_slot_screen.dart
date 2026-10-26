import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';
import 'session_widgets.dart';

/// Trouver un créneau pour un membre (owner, manager) : séances à venir avec
/// des places, sans chevauchement avec les siennes, son coach en premier.
/// Un tap inscrit le membre. Renvoie `true` au pop si inscrit.
class FindSlotScreen extends StatefulWidget {
  final int gymId;
  final Map<String, dynamic>? member;

  const FindSlotScreen({super.key, required this.gymId, this.member});

  @override
  State<FindSlotScreen> createState() => _FindSlotScreenState();
}

class _FindSlotScreenState extends State<FindSlotScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final SessionService _sessionService = SessionService(_apiService);

  late Map<String, dynamic>? _member = widget.member;
  List<Map<String, dynamic>>? _members;
  List<Map<String, dynamic>>? _slots;
  String _query = '';
  int _days = 14;
  String? _type;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _member == null ? _loadMembers() : _loadSlots();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    final list = token == null
        ? null
        : await _apiService.getGymMembers(widget.gymId, token);
    if (!mounted) return;
    setState(() {
      _members = list?.whereType<Map<String, dynamic>>().toList();
      _isLoading = false;
    });
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    final now = DateTime.now();
    final slots = token == null
        ? null
        : await _sessionService.getAvailable(
            token,
            gymId: widget.gymId,
            memberId: _member?['id'] as int?,
            type: _type,
            from: now,
            to: now.add(Duration(days: _days)),
          );
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _isLoading = false;
    });
  }

  Future<void> _book(Map<String, dynamic> slot) async {
    final memberId = _member?['id'];
    if (memberId is! int) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inscrire le membre ?'),
        content: Text(
          '${getUserFullName(_member)}\n${sessionSlot(slot)}\n'
          'avec ${sessionCoachName(slot)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Inscrire'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final token = await _authService.loadToken();
    if (token == null) return;
    final result = await _sessionService.addMembers(token, slot['id'] as int, [
      memberId,
    ]);
    if (!mounted) return;
    if (result.ok) {
      AppSnackBar.success(context, 'Membre inscrit à la séance');
      Navigator.pop(context, true);
    } else {
      await showSessionError(
        context,
        result,
        memberName: (_) => getUserFullName(_member),
      );
      _loadSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _member == null
              ? 'Choisir un membre'
              : 'Créneaux pour ${getUserFullName(_member)}',
        ),
      ),
      body: _member == null ? _buildMemberList() : _buildSlots(),
    );
  }

  Widget _buildMemberList() {
    final q = _query.toLowerCase();
    final members = (_members ?? [])
        .where((m) => getUserFullName(m).toLowerCase().contains(q))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher un membre…',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _members == null
              ? const Center(child: Text('Impossible de charger les membres'))
              : ListView(
                  children: [
                    for (final m in members)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(getUserFullName(m)),
                        subtitle: Text(
                          m['coach'] is Map<String, dynamic>
                              ? 'Coach : ${getUserFullName(m['coach'] as Map<String, dynamic>)}'
                              : (m['displayId'] as String? ?? ''),
                        ),
                        onTap: () {
                          setState(() => _member = m);
                          _loadSlots();
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSlots() {
    final slots = _slots;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 jours')),
              ButtonSegment(value: 14, label: Text('14 jours')),
              ButtonSegment(value: 30, label: Text('30 jours')),
            ],
            selected: {_days},
            onSelectionChanged: (v) {
              setState(() => _days = v.first);
              _loadSlots();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SessionTypeFilter(
            value: _type,
            onChanged: (v) {
              setState(() => _type = v);
              _loadSlots();
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSlots,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (slots == null || slots.isEmpty)
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          slots == null
                              ? 'Impossible de charger les créneaux'
                              : 'Aucun créneau disponible sur cette période',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final s in slots)
                        SessionCard(
                          session: s,
                          showDay: true,
                          onTap: () => _book(s),
                          badge: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${s['remaining'] ?? '?'} place(s)',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (s['isMemberCoach'] == true)
                                Text(
                                  'Son coach',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.palette.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
