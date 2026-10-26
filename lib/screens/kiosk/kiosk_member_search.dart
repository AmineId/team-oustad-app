import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

/// Membre choisi pour un check-in manuel, avec sa photo si elle existe.
typedef KioskManualPick = ({Map<String, dynamic> member, Uint8List? photo});

/// Check-in sans QR code : recherche d'un membre de la salle, puis fiche
/// (photo, abonnement, coach) à valider. Renvoie le membre confirmé, ou null.
Future<KioskManualPick?> showKioskMemberSearch(
  BuildContext context, {
  required ApiService api,
  required String token,
  required int gymId,
}) {
  return showDialog<KioskManualPick>(
    context: context,
    builder: (_) =>
        _KioskMemberSearchDialog(api: api, token: token, gymId: gymId),
  );
}

class _KioskMemberSearchDialog extends StatefulWidget {
  final ApiService api;
  final String token;
  final int gymId;

  const _KioskMemberSearchDialog({
    required this.api,
    required this.token,
    required this.gymId,
  });

  @override
  State<_KioskMemberSearchDialog> createState() =>
      _KioskMemberSearchDialogState();
}

class _KioskMemberSearchDialogState extends State<_KioskMemberSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>>? _members;
  bool _loading = true;
  String _query = '';

  Map<String, dynamic>? _selected;
  Uint8List? _photo;
  bool _loadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final list = await widget.api.getGymMembers(widget.gymId, widget.token);
    if (!mounted) return;
    setState(() {
      _members = list?.whereType<Map<String, dynamic>>().toList();
      _loading = false;
    });
  }

  Future<void> _select(Map<String, dynamic> member) async {
    setState(() {
      _selected = member;
      _photo = null;
      _loadingPhoto = true;
    });
    final id = member['id'];
    final photo = id is int
        ? await widget.api.getBytes('/users/$id/profile-image', widget.token)
        : null;
    if (!mounted || _selected != member) return;
    setState(() {
      _photo = photo;
      _loadingPhoto = false;
    });
  }

  static String _fullName(Map<String, dynamic> m) =>
      '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();

  static String _initials(Map<String, dynamic> m) {
    final first = (m['firstName'] as String? ?? '').trim();
    final last = (m['lastName'] as String? ?? '').trim();
    final initials =
        '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}';
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    final members = _members ?? [];
    if (q.isEmpty) return members;
    return members.where((m) {
      return _fullName(m).toLowerCase().contains(q) ||
          '${m['lastName'] ?? ''} ${m['firstName'] ?? ''}'
              .toLowerCase()
              .contains(q) ||
          (m['displayId'] as String? ?? '').toLowerCase().contains(q) ||
          (m['email'] as String? ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _selected == null
              ? _buildSearch()
              : _buildMemberCard(_selected!),
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.barlowCondensed(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.darkTextTertiary,
          ),
          tooltip: 'Fermer',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    final members = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitle('CHECK-IN SANS QR CODE'),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: GoogleFonts.barlow(fontSize: 18, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom, prénom, identifiant ou e-mail',
            hintStyle: GoogleFonts.barlow(color: AppColors.darkTextTertiary),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.darkTextTertiary,
            ),
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _members == null
              ? _buildMessage('Impossible de charger les membres')
              : members.isEmpty
              ? _buildMessage('Aucun membre trouvé')
              : ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _buildMemberRow(members[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildMessage(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.barlow(
          fontSize: 16,
          color: AppColors.darkTextTertiary,
        ),
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> m) {
    final active = m['activeSubscription'] != null;
    return Material(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _select(m),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  _initials(m),
                  style: GoogleFonts.barlowCondensed(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName(m),
                      style: GoogleFonts.barlow(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      m['displayId'] as String? ?? '',
                      style: GoogleFonts.barlow(
                        fontSize: 13,
                        color: AppColors.darkTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatus(active),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(bool active) {
    final color = active ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        active ? 'Abonnement actif' : 'Sans abonnement',
        style: GoogleFonts.barlow(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> m) {
    final sub = m['activeSubscription'] as Map<String, dynamic>?;
    final coach = m['coach'] as Map<String, dynamic>?;
    final endDate = DateTime.tryParse(sub?['endDate'] as String? ?? '');
    final subType = sub?['type'];
    final rows = <(IconData, String)>[
      (Icons.badge_outlined, m['displayId'] as String? ?? '—'),
      if (sub != null)
        (
          Icons.card_membership_outlined,
          [
            if (subType is String && subType.isNotEmpty) subType,
            if (endDate != null)
              'jusqu\'au ${DateFormat('dd/MM/yyyy').format(endDate.toLocal())}',
          ].join(' · ').ifEmpty('Abonnement actif'),
        ),
      if (coach != null) (Icons.sports_outlined, 'Coach : ${_fullName(coach)}'),
      if ((m['email'] as String?)?.isNotEmpty == true)
        (Icons.mail_outline, m['email'] as String),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitle('CONFIRMER L\'ENTRÉE'),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sub != null ? AppColors.success : AppColors.error,
                      width: 3,
                    ),
                  ),
                  child: _photo != null
                      ? Image.memory(
                          _photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildCardInitials(m),
                        )
                      : _loadingPhoto
                      ? const Center(child: CircularProgressIndicator())
                      : _buildCardInitials(m),
                ),
                const SizedBox(height: 16),
                Text(
                  _fullName(m),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatus(sub != null),
                const SizedBox(height: 20),
                for (final (icon, text) in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 18, color: AppColors.darkTextTertiary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            text,
                            style: GoogleFonts.barlow(
                              fontSize: 16,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Retour'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                // Le serveur refuse aussi sans abonnement : on bloque avant.
                onPressed: sub == null
                    ? null
                    : () =>
                          Navigator.of(context).pop((member: m, photo: _photo)),
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  sub == null ? 'Aucun abonnement actif' : 'Valider l\'entrée',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardInitials(Map<String, dynamic> m) {
    return Center(
      child: Text(
        _initials(m),
        style: GoogleFonts.barlowCondensed(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
