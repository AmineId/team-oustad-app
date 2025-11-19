import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class AdminGymOpeningHoursScreen extends StatefulWidget {
  final Map<String, dynamic> gym;

  const AdminGymOpeningHoursScreen({super.key, required this.gym});

  @override
  State<AdminGymOpeningHoursScreen> createState() => _AdminGymOpeningHoursScreenState();
}

class _AdminGymOpeningHoursScreenState extends State<AdminGymOpeningHoursScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  bool _isLoading = false;

  // Données pour les 7 jours (0 = dimanche, 1 = lundi, ..., 6 = samedi)
  final List<Map<String, dynamic>> _hoursData = List.generate(7, (index) {
    return {
      'dayOfWeek': index,
      'isClosed': false,
      'openTime': '09:00',
      'closeTime': '18:00',
    };
  });

  final List<String> _dayNames = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  @override
  void initState() {
    super.initState();
    _loadOpeningHours();
  }

  Future<void> _loadOpeningHours() async {
    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) throw Exception('Token non disponible');

      final hours = await _apiService.getOpeningHours(
        widget.gym['id'] as int,
        token,
      );

      if (hours != null && mounted) {
        // Mettre à jour les données avec les horaires existants
        for (var hour in hours) {
          final dayOfWeek = hour['dayOfWeek'] as int;
          if (dayOfWeek >= 0 && dayOfWeek <= 6) {
            _hoursData[dayOfWeek] = {
              'dayOfWeek': dayOfWeek,
              'isClosed': hour['isClosed'] ?? false,
              'openTime': hour['openTime'] ?? '09:00',
              'closeTime': hour['closeTime'] ?? '18:00',
            };
          }
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveOpeningHours() async {
    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await _apiService.setOpeningHours(
        widget.gym['id'] as int,
        _hoursData,
        token,
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horaires enregistrés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Erreur lors de l\'enregistrement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, String initialTime) async {
    final parts = initialTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    return await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFe89547),
              onSurface: Colors.white,
              surface: Color(0xFF2d3748),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final gymName = widget.gym['name'] as String? ?? 'Sans nom';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1f2e),
              const Color(0xFF2d3748),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Horaires d\'ouverture',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            gymName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFe89547),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final dayData = _hoursData[index];
                          final isClosed = dayData['isClosed'] as bool;

                          return Card(
                            color: const Color(0xFF2d3748),
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _dayNames[index],
                                        style: const TextStyle(
                                          color: Color(0xFFe89547),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Text(
                                        'Fermé',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch(
                                        value: isClosed,
                                        activeTrackColor: Colors.red,
                                        onChanged: (value) {
                                          setState(() {
                                            _hoursData[index]['isClosed'] = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (!isClosed) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTimeButton(
                                            context,
                                            'Ouverture',
                                            dayData['openTime'] as String,
                                            (time) {
                                              setState(() {
                                                _hoursData[index]['openTime'] = time;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildTimeButton(
                                            context,
                                            'Fermeture',
                                            dayData['closeTime'] as String,
                                            (time) {
                                              setState(() {
                                                _hoursData[index]['closeTime'] = time;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bouton sauvegarder
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveOpeningHours,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe89547),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(
    BuildContext context,
    String label,
    String time,
    Function(String) onTimeSelected,
  ) {
    return InkWell(
      onTap: () async {
        final selected = await _selectTime(context, time);
        if (selected != null) {
          onTimeSelected(_timeOfDayToString(selected));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f2e),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFe89547).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFFe89547),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
