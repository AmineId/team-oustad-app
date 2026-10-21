import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/responsive/responsive_grid.dart';
import 'gym_showcase_detail_screen.dart';

/// Page vitrine publique — liste des salles publiées. Build web dédié
/// (team-oustad.com), voir WEB_TARGET dans lib/main.dart.
class GymShowcaseListScreen extends StatefulWidget {
  const GymShowcaseListScreen({super.key});

  @override
  State<GymShowcaseListScreen> createState() => _GymShowcaseListScreenState();
}

class _GymShowcaseListScreenState extends State<GymShowcaseListScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  List<Map<String, dynamic>> _gyms = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  Future<void> _loadGyms() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final gyms = await _apiService.getPublicGyms();
    if (!mounted) return;
    setState(() {
      _gyms = (gyms ?? []).map((g) => g as Map<String, dynamic>).toList();
      _hasError = gyms == null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Nos salles'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGyms,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_hasError) {
      return _buildMessage(
        context,
        icon: Icons.wifi_off_rounded,
        message: 'Impossible de charger les salles pour le moment.',
      );
    }
    if (_gyms.isEmpty) {
      return _buildMessage(
        context,
        icon: Icons.fitness_center,
        message: 'Aucune salle à afficher pour le moment.',
      );
    }

    return ResponsiveContainer(
      maxWidth: 1200,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: ResponsiveGrid(
          children: _gyms.map((gym) => _GymShowcaseCard(gym: gym)).toList(),
        ),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GymShowcaseCard extends StatelessWidget {
  final Map<String, dynamic> gym;

  const _GymShowcaseCard({required this.gym});

  @override
  Widget build(BuildContext context) {
    final name = gym['name'] as String? ?? 'Salle';
    final address = gym['address'] as String? ?? '';
    final memberCountDisplay = gym['memberCountDisplay'] as String?;
    final coverPhotoUrl = gym['coverPhotoUrl'] as String?;
    final slugOrId = (gym['slug'] as String?) ?? gym['id'].toString();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GymShowcaseDetailScreen(slugOrId: slugOrId),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: coverPhotoUrl != null
                  ? Image.network(
                      coverPhotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (memberCountDisplay != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$memberCountDisplay membres',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.fitness_center, color: AppColors.primary, size: 40),
      ),
    );
  }
}
