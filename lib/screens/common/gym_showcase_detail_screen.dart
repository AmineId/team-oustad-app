import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/responsive/responsive_grid.dart';

/// Fiche détaillée d'une salle sur la page vitrine publique.
class GymShowcaseDetailScreen extends StatefulWidget {
  final String slugOrId;

  const GymShowcaseDetailScreen({super.key, required this.slugOrId});

  @override
  State<GymShowcaseDetailScreen> createState() => _GymShowcaseDetailScreenState();
}

class _GymShowcaseDetailScreenState extends State<GymShowcaseDetailScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  Map<String, dynamic>? _gym;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadGym();
  }

  Future<void> _loadGym() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final gym = await _apiService.getPublicGym(widget.slugOrId);
    if (!mounted) return;
    setState(() {
      _gym = gym;
      _hasError = gym == null;
      _isLoading = false;
    });
  }

  Future<void> _openMaps(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  String _dayName(int dayOfWeek) {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    return days[dayOfWeek % 7];
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'owner':
        return 'Gérant';
      case 'admin':
        return 'Coach';
      default:
        return 'Équipe';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(_gym?['name'] as String? ?? 'Salle')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_hasError || _gym == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Cette salle n\'est pas disponible.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    final gym = _gym!;
    final name = gym['name'] as String? ?? 'Salle';
    final address = gym['address'] as String? ?? '';
    final phone = gym['phone'] as String?;
    final memberCountDisplay = gym['memberCountDisplay'] as String?;
    final photos = ((gym['photos'] as List<dynamic>?) ?? [])
        .map((p) => p as Map<String, dynamic>)
        .toList();
    final openingHours = ((gym['openingHours'] as List<dynamic>?) ?? [])
        .map((h) => h as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => (a['dayOfWeek'] as int).compareTo(b['dayOfWeek'] as int));
    final team = ((gym['team'] as List<dynamic>?) ?? [])
        .map((t) => t as Map<String, dynamic>)
        .toList();

    return SingleChildScrollView(
      child: ResponsiveContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoCarousel(photos: photos),
            const SizedBox(height: 24),
            Text(
              name,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (memberCountDisplay != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$memberCountDisplay membres',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Adresse + téléphone
            if (address.isNotEmpty)
              _ActionRow(
                icon: Icons.location_on,
                label: address,
                buttonLabel: 'Voir sur la carte',
                onTap: () => _openMaps(address),
              ),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ActionRow(
                icon: Icons.phone,
                label: phone,
                buttonLabel: 'Appeler',
                onTap: () => _call(phone),
              ),
            ],
            const SizedBox(height: 32),

            if (openingHours.isNotEmpty) ...[
              Text(
                'Horaires d\'ouverture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: openingHours.map((hour) {
                    final isClosed = hour['isClosed'] == true;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dayName(hour['dayOfWeek'] as int),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Text(
                            isClosed ? 'Fermé' : '${hour['openTime']} - ${hour['closeTime']}',
                            style: TextStyle(
                              color: isClosed
                                  ? AppColors.error
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (team.isNotEmpty) ...[
              Text(
                'La team',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: team.map((member) {
                  final photoUrl = member['photoUrl'] as String?;
                  return SizedBox(
                    width: 110,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person, color: AppColors.primary)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member['fullName'] as String? ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _roleLabel(member['role'] as String?),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> photos;

  const _PhotoCarousel({required this.photos});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.fitness_center, color: AppColors.primary, size: 56),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final url = widget.photos[index]['url'] as String?;
                return Image.network(
                  url ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.broken_image, color: AppColors.primary),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.photos.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == _page ? 10 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == _page ? AppColors.primary : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
