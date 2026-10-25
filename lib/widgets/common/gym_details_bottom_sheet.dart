import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';

class GymDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> gym;

  const GymDetailsBottomSheet({super.key, required this.gym});

  @override
  State<GymDetailsBottomSheet> createState() => _GymDetailsBottomSheetState();
}

class _GymDetailsBottomSheetState extends State<GymDetailsBottomSheet> {
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final ApiService _apiService = ApiService.fromEnv();
  List<dynamic>? _openingHours;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOpeningHours();
  }

  Future<void> _loadOpeningHours() async {
    try {
      final token = await _authService.loadToken();
      if (token == null) return;

      final gymId = widget.gym['id'] as int;
      final hours = await _apiService.getOpeningHours(gymId, token);

      setState(() {
        _openingHours = hours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openNavigation(String address, {bool useWaze = false}) async {
    final encodedAddress = Uri.encodeComponent(address);

    if (useWaze) {
      // Try to open Waze
      final wazeUrl = 'waze://?q=$encodedAddress';
      try {
        final uri = Uri.parse(wazeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        // Waze not installed, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Waze n\'est pas installé. Ouverture de Google Maps...',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }

    // Try Google Maps
    final urls = [
      'geo:0,0?q=$encodedAddress', // Google Maps on Android
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress', // Web fallback
    ];

    bool launched = false;

    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir la navigation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    return days[dayOfWeek % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: context.palette.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.gym['name'] ?? 'Ma Salle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.gym['address'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Opening hours
          Text(
            'Horaires d\'ouverture',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: context.palette.primary),
                )
              : _openingHours == null || _openingHours!.isEmpty
              ? Text(
                  'Horaires non disponibles',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                )
              : Column(
                  children: _openingHours!.map((hour) {
                    final dayOfWeek = hour['dayOfWeek'] as int;
                    final isClosed = hour['isClosed'] as bool;
                    final openTime = hour['openTime'] as String?;
                    final closeTime = hour['closeTime'] as String?;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getDayName(dayOfWeek),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            isClosed ? 'Fermé' : '$openTime - $closeTime',
                            style: TextStyle(
                              color: isClosed
                                  ? Colors.red.shade300
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 24),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final address = widget.gym['address'] as String?;
                    _openNavigation(address ?? '');
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final address = widget.gym['address'] as String?;
                    _openNavigation(address ?? '', useWaze: true);
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Waze'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
