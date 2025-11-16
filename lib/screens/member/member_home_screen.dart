import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../widgets/common/gym_details_bottom_sheet.dart';
import '../../widgets/responsive/responsive_layout.dart';
import '../auth/login_screen.dart';
import 'subscription_details_screen.dart';
import 'edit_profile_screen.dart';
import '../common/security_settings_screen.dart';
import '../common/about_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MemberDashboardPage(),
    const MemberQrCodePage(),
    const MemberPlanningPage(),
    const MemberProfilePage(),
  ];

  final List<String> _titles = [
    'Accueil',
    'Ma Carte',
    'Mon Planning',
    'Mon Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: _titles[_currentIndex],
      navigationItems: const [
        NavigationItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Accueil',
        ),
        NavigationItem(
          icon: Icons.qr_code_2_outlined,
          activeIcon: Icons.qr_code_2,
          label: 'Ma Carte',
        ),
        NavigationItem(
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center,
          label: 'Mon Planning',
        ),
        NavigationItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Mon Profil',
        ),
      ],
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: _pages[_currentIndex],
    );
  }
}

// ==================== MEMBER DASHBOARD PAGE ====================
class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get token
      final token = await _authService.loadToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Session expirée, veuillez vous reconnecter',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Refresh user profile from API
      await _authService.refreshUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✓ Données mises à jour',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorWithRetry(
          'Une erreur est survenue',
          _refreshDashboard,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: const Color(0xFFe89547),
        notificationPredicate: (notification) => !_isRefreshing,
        child: SingleChildScrollView(
          physics: _isRefreshing 
            ? const NeverScrollableScrollPhysics() 
            : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
            FutureBuilder<Map<String, dynamic>?>(
              future: _authService.getCachedUserProfile(),
              builder: (context, snapshot) {
                final profileData = snapshot.data;
                final fullName = profileData?['fullName'] ?? 'Membre';
                
                // Get subscription info
                Map<String, dynamic>? subscription;
                final subscriptions = profileData?['subscriptions'] as List<dynamic>?;
                if (subscriptions != null && subscriptions.isNotEmpty) {
                  subscription = subscriptions.firstWhere(
                    (sub) => (sub as Map<String, dynamic>)['status'] == 'active',
                    orElse: () => subscriptions.first,
                  ) as Map<String, dynamic>;
                } else {
                  subscription = profileData?['subscription'] as Map<String, dynamic>?;
                }
                
                final status = subscription?['status'] ?? 'unknown';
                final expiresAt = subscription?['expiresAt'] ?? subscription?['endDate'];
                
                String statusText = 'Statut inconnu';
                Color statusColor = Colors.grey;
                
                if (status == 'active') {
                  statusText = 'Votre abonnement est actif';
                  statusColor = Colors.white;
                } else if (status == 'expired') {
                  statusText = 'Votre abonnement a expiré';
                  statusColor = Colors.red.shade200;
                } else if (status == 'cancelled') {
                  statusText = 'Abonnement annulé';
                  statusColor = Colors.orange.shade200;
                }
                
                return Card(
                  color: const Color(0xFFe89547),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue, $fullName !',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            color: statusColor,
                          ),
                        ),
                        if (expiresAt != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Expire le: ${_formatDate(expiresAt)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
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
            const SizedBox(height: 24),

              // Gym information
              const Text(
                'Ma Salle de Sport',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildGymCard(context),
              const SizedBox(height: 24),

              // Next workout section
              const Text(
                'Mon Prochain Entraînement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildNextWorkoutCard(),
              const SizedBox(height: 24),

            // Stats cards
            const Text(
              'Mes Statistiques',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Visites ce mois',
                    '12',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total visites',
                    '148',
                    Icons.fitness_center,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNextWorkoutCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadNextWorkout(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            color: const Color(0xFF2d3748),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFe89547)),
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Card(
            color: const Color(0xFF2d3748),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun entraînement prévu',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Votre coach vous assignera bientôt un programme',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final planning = data['planning'] as Map<String, dynamic>?;
        final day = data['day'] as Map<String, dynamic>?;
        final exercises = day?['exercises'] as List<dynamic>? ?? [];
        final date = day?['date'] as String?;
        final isToday = data['isToday'] as bool? ?? false;

        // Déterminer le statut de l'entraînement
        String workoutStatus;
        Color statusColor;
        IconData statusIcon;
        
        if (isToday) {
          workoutStatus = 'Aujourd\'hui';
          statusColor = Colors.green;
          statusIcon = Icons.play_circle_outline;
        } else {
          // Formater la date pour afficher "Prochain : DD/MM"
          workoutStatus = 'Prochain entraînement';
          statusColor = const Color(0xFFe89547);
          statusIcon = Icons.schedule;
          
          if (date != null) {
            try {
              final parsedDate = DateTime.parse(date);
              final dayName = _getDayName(parsedDate.weekday % 7);
              workoutStatus = '$dayName ${parsedDate.day}/${parsedDate.month}';
            } catch (_) {
              workoutStatus = day?['dayName'] ?? 'Prochain';
            }
          }
        }

        return Card(
          color: const Color(0xFF2d3748),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planning?['title'] ?? 'Mon Entraînement',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    workoutStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (exercises.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    
                    // Exercises preview (show first 3)
                    ...exercises.take(3).map((ex) {
                      final exerciseData = ex as Map<String, dynamic>;
                      final exercise = exerciseData['exercise'] as Map<String, dynamic>?;
                      final sets = exerciseData['sets'] as int?;
                      final reps = exerciseData['reps'] as int?;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFe89547),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                exercise?['name'] ?? 'Exercice',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (sets != null && reps != null)
                              Text(
                                '$sets × $reps',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    
                    if (exercises.length > 3) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${exercises.length - 3} autres exercices',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFe89547),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showNextWorkoutPopup(data),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Voir les détails'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe89547),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _loadNextWorkout() async {
    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();
      
      if (token == null || profileData == null) {
        return null;
      }

      final memberId = profileData['id'] as int;
      final nextDay = await _apiService.getNextPlanningDay(memberId, token);
      
      return nextDay;
    } catch (e) {
      // ignore: avoid_print
      print('Error loading next workout: $e');
      return null;
    }
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    return days[dayOfWeek % 7];
  }

  void _showNextWorkoutPopup(Map<String, dynamic> data) {
    final planning = data['planning'] as Map<String, dynamic>?;
    final day = data['day'] as Map<String, dynamic>?;
    final exercises = day?['exercises'] as List<dynamic>? ?? [];
    final date = day?['date'] as String?;
    final isToday = data['isToday'] as bool? ?? false;

    // Déterminer le statut de l'entraînement
    String workoutStatus;
    if (isToday) {
      workoutStatus = 'Aujourd\'hui';
    } else {
      workoutStatus = 'Prochain entraînement';
      if (date != null) {
        try {
          final parsedDate = DateTime.parse(date);
          final dayName = _getDayName(parsedDate.weekday % 7);
          workoutStatus = '$dayName ${parsedDate.day}/${parsedDate.month}';
        } catch (_) {
          workoutStatus = day?['dayName'] ?? 'Prochain';
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF1a202c),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2d3748),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFe89547).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Color(0xFFe89547),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planning?['title'] ?? 'Mon Entraînement',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exercises.length} exercice${exercises.length > 1 ? 's' : ''} • $workoutStatus',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Exercises list
                Flexible(
                  child: exercises.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'Aucun exercice prévu',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(20),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final exerciseData = exercises[index] as Map<String, dynamic>;
                            final exercise = exerciseData['exercise'] as Map<String, dynamic>?;
                            final sets = exerciseData['sets'] as int?;
                            final reps = exerciseData['reps'] as int?;
                            final weightValue = exerciseData['weight'];
                            final weight = weightValue != null ? (weightValue is int ? weightValue.toDouble() : weightValue as double?) : null;
                            final notes = exerciseData['notes'] as String?;

                            return Card(
                              color: const Color(0xFF2d3748),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFe89547).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Color(0xFFe89547),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            exercise?['name'] ?? 'Exercice',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (sets != null || reps != null || weight != null) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          if (sets != null)
                                            _buildInfoChip('Séries', sets.toString(), Icons.repeat),
                                          if (reps != null)
                                            _buildInfoChip('Reps', reps.toString(), Icons.fitness_center),
                                          if (weight != null)
                                            _buildInfoChip('Poids', '${weight}kg', Icons.monitor_weight),
                                        ],
                                      ),
                                    ],
                                    if (notes != null && notes.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.note,
                                              size: 16,
                                              color: Colors.white.withValues(alpha: 0.7),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                notes,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _requestHelp(exercise?['name'] ?? 'Exercice');
                                        },
                                        icon: const Icon(Icons.help_outline, size: 18),
                                        label: const Text('Demander de l\'aide'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFe89547),
                                          side: const BorderSide(color: Color(0xFFe89547)),
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFe89547)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _requestHelp(String exerciseName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2d3748),
          title: const Text(
            'Demander de l\'aide',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Voulez-vous demander de l\'aide pour l\'exercice "$exerciseName" ?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe89547),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Non authentifié'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final success = await _apiService.requestExerciseHelp(exerciseName, token);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Demande d\'aide envoyée pour $exerciseName'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorWithRetry(
            'Une erreur est survenue',
            () => _requestHelp(exerciseName),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorWithRetry(
          'Une erreur est survenue',
          () => _requestHelp(exerciseName),
        );
      }
    }
  }

  void _showErrorWithRetry(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: const Color(0xFFe89547),
          onPressed: onRetry,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF2d3748),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService(ApiService.fromEnv()).getCachedUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            color: const Color(0xFF2d3748),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFe89547)),
              ),
            ),
          );
        }

        final gym = snapshot.data?['gym'] as Map<String, dynamic>?;
        if (gym == null) {
          return Card(
            color: const Color(0xFF2d3748),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Aucune salle assignée',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          );
        }

        return Card(
          color: const Color(0xFF2d3748),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _showGymDetails(context, gym),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFe89547).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Color(0xFFe89547),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gym['name'] ?? 'Ma Salle',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    gym['address'] ?? 'Adresse non disponible',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white60,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildGymInfoChip(
                          Icons.access_time,
                          'Horaires',
                          Colors.blue,
                          onTap: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGymInfoChip(
                          Icons.navigation,
                          'Navigation',
                          Colors.green,
                          onTap: () => _openInGoogleMaps(
                            gym['address'] ?? '',
                            gym['name'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInGoogleMaps(String address, String? gymName) async {
    if (address.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adresse non disponible'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final encodedAddress = Uri.encodeComponent(address);
    
    // Use geo: URI which allows the user to choose their preferred navigation app
    // This will show a chooser with Google Maps, Waze, and other map apps
    final geoUri = Uri.parse('geo:0,0?q=$encodedAddress');
    
    try {
      final canLaunch = await canLaunchUrl(geoUri);
      if (canLaunch) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web URL if no map app is available
        final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        _showErrorWithRetry(
          'Une erreur est survenue',
          () => _openInGoogleMaps(address, null),
        );
      }
    }
  }

  Widget _buildGymInfoChip(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: chip,
      );
    }

    return chip;
  }

  void _showGymDetails(BuildContext context, Map<String, dynamic> gym) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2d3748),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GymDetailsBottomSheet(gym: gym),
    );
  }
}

// ==================== MEMBER QR CODE PAGE ====================
class MemberQrCodePage extends StatefulWidget {
  const MemberQrCodePage({super.key});

  @override
  State<MemberQrCodePage> createState() => _MemberQrCodePageState();
}

class _MemberQrCodePageState extends State<MemberQrCodePage> {
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final ApiService _apiService = ApiService.fromEnv();

  Future<void> _showQrCode() async {
    // Récupérer l'ID de l'utilisateur depuis le cache
    final profileData = await _authService.getCachedUserProfile();
    if (profileData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Une erreur est survenue'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: const Color(0xFFe89547),
            onPressed: _showQrCode,
          ),
        ),
      );
      return;
    }

    final userId = profileData['id'] as int;
    final token = await _authService.loadToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Une erreur est survenue'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: const Color(0xFFe89547),
            onPressed: _showQrCode,
          ),
        ),
      );
      return;
    }

    // Afficher le dialog avec loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: const Text(
          'Mon QR Code',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFe89547),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chargement du QR code...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Charger le QR code
      final qrImageBytes = await _apiService.getUserQrCode(userId, token);
      
      if (!mounted) return;
      
      // Fermer le dialog de loading
      Navigator.of(context).pop();
      
      if (qrImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: const Color(0xFFe89547),
              onPressed: _showQrCode,
            ),
          ),
        );
        return;
      }

      // Afficher le QR code
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF2d3748),
          title: const Text(
            'Mon QR Code',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.memory(
                  Uint8List.fromList(qrImageBytes),
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                profileData['fullName'] ?? 'Utilisateur',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFe89547).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFe89547).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  profileData['displayId'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFFe89547),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Présentez ce code à l\'entrée',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(color: Color(0xFFe89547), fontSize: 16),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Fermer le dialog de loading s'il est ouvert
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: const Color(0xFFe89547),
            onPressed: _showQrCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ma Carte Membre',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scannez ce code à l\'entrée',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 40),
              
              // Bouton pour afficher le QR Code
              ElevatedButton.icon(
                onPressed: _showQrCode,
                icon: const Icon(Icons.qr_code_2, size: 32),
                label: const Text(
                  'Afficher mon QR Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe89547),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFe89547).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                'Présentez votre QR code au personnel\npour enregistrer votre présence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MEMBER SUBSCRIPTION PAGE ====================
class MemberSubscriptionPage extends StatelessWidget {
  const MemberSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current subscription card
            Card(
              color: const Color(0xFFe89547),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Abonnement Premium',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ACTIF',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSubscriptionDetail('Type', 'Mensuel'),
                    _buildSubscriptionDetail('Prix', '50 € / mois'),
                    _buildSubscriptionDetail('Date de début', '1 Nov 2025'),
                    _buildSubscriptionDetail('Date d\'expiration', '31 Déc 2025'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment history
            const Text(
              'Historique des Paiements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentItem('Nov 2025', '50 €', '1 Nov 2025', true),
            _buildPaymentItem('Oct 2025', '50 €', '1 Oct 2025', true),
            _buildPaymentItem('Sep 2025', '50 €', '1 Sep 2025', true),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(String month, String amount, String date, bool paid) {
    return Card(
      color: const Color(0xFF2d3748),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: paid ? Colors.green.withValues(alpha: 0.7) : Colors.red.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            paid ? Icons.check_circle : Icons.pending,
            color: paid ? Colors.green : Colors.red,
            size: 24,
          ),
        ),
        title: Text(
          month,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          date,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFe89547),
          ),
        ),
      ),
    );
  }
}

// ==================== MEMBER PLANNING PAGE ====================
class MemberPlanningPage extends StatefulWidget {
  const MemberPlanningPage({super.key});

  @override
  State<MemberPlanningPage> createState() => _MemberPlanningPageState();
}

class _MemberPlanningPageState extends State<MemberPlanningPage> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;
  List<dynamic>? _plannings;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  void _showErrorWithRetry(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: const Color(0xFFe89547),
          onPressed: onRetry,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
    _loadPlannings();
  }

  Future<void> _loadPlannings() async {
    if (_isRefreshing) return; // Prevent multiple refreshes
    
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();
      
      if (token == null || profileData == null) {
        setState(() {
          _errorMessage = 'Session expirée';
          _isLoading = false;
          _isRefreshing = false;
        });
        return;
      }

      final memberId = profileData['id'] as int;
      // ignore: avoid_print
      print('🔍 Loading plannings for member ID: $memberId');
      
      final response = await _apiService.getMemberPlannings(memberId, token);
      
      // ignore: avoid_print
      print('📊 Plannings response: $response');
      // ignore: avoid_print
      print('📊 Number of plannings: ${(response['plannings'] as List<dynamic>?)?.length ?? 0}');
      
      setState(() {
        _plannings = response['plannings'] as List<dynamic>?;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading plannings: $e');
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _loadTodayWorkout() async {
    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();
      
      if (token == null || profileData == null) {
        // ignore: avoid_print
        print('❌ Today workout: No token or profile');
        return null;
      }

      final memberId = profileData['id'] as int;
      // ignore: avoid_print
      print('🔍 Loading today workout for member ID: $memberId');
      
      final nextDay = await _apiService.getNextPlanningDay(memberId, token);
      
      // ignore: avoid_print
      print('📊 Today workout response: $nextDay');
      // ignore: avoid_print
      print('📊 Is today: ${nextDay?['isToday']}');
      
      // Only return if it's today
      if (nextDay != null && nextDay['isToday'] == true) {
        return nextDay;
      }
      
      // ignore: avoid_print
      print('ℹ️ No workout for today');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading today workout: $e');
      return null;
    }
  }

  String _formatDateSimple(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr.split('T')[0]; // Fallback to simple split
    }
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    return days[dayOfWeek % 7];
  }

  Widget _buildTodayWorkoutCard(Map<String, dynamic> data) {
    final planning = data['planning'] as Map<String, dynamic>?;
    final day = data['day'] as Map<String, dynamic>?;
    final exercises = day?['exercises'] as List<dynamic>? ?? [];

    return Card(
        color: const Color(0xFF2d3748),
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFe89547), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planning?['title'] ?? 'Mon Entraînement',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Aujourd\'hui',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  '${exercises.length} exercice${exercises.length > 1 ? 's' : ''} prévu${exercises.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTodayWorkoutPopup(data),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Voir les détails'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe89547),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTodayWorkoutPopup(Map<String, dynamic> data) {
    final planning = data['planning'] as Map<String, dynamic>?;
    final day = data['day'] as Map<String, dynamic>?;
    final exercises = day?['exercises'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF1a202c),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2d3748),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planning?['title'] ?? 'Mon Entraînement',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exercises.length} exercice${exercises.length > 1 ? 's' : ''} • Aujourd\'hui',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Exercises list
                Flexible(
                  child: exercises.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'Aucun exercice prévu',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final exerciseData = exercises[index] as Map<String, dynamic>;
                            final exercise = exerciseData['exercise'] as Map<String, dynamic>?;
                            final sets = exerciseData['sets'] as int?;
                            final reps = exerciseData['reps'] as int?;
                            final weight = exerciseData['weight'] as num?;
                            final notes = exerciseData['notes'] as String?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2d3748),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFe89547).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFe89547),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          exercise?['name'] ?? 'Exercice',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      if (sets != null)
                                        _buildExerciseDetail(Icons.repeat, '$sets séries'),
                                      if (reps != null)
                                        _buildExerciseDetail(Icons.fitness_center, '$reps reps'),
                                      if (weight != null && weight > 0)
                                        _buildExerciseDetail(Icons.monitor_weight, '$weight kg'),
                                    ],
                                  ),
                                  if (notes != null && notes.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1a202c),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.blue.shade300,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              notes,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withValues(alpha: 0.7),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _requestHelp(exercise?['name'] ?? 'Exercice');
                                      },
                                      icon: const Icon(Icons.help_outline, size: 18),
                                      label: const Text('Demander aide'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFe89547),
                                        side: const BorderSide(color: Color(0xFFe89547)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isPlanningUpcoming(String startDate) {
    try {
      final start = DateTime.parse(startDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final planningStart = DateTime(start.year, start.month, start.day);
      
      // Planning is upcoming if start date is in the future
      return planningStart.isAfter(today);
    } catch (e) {
      return false;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadPlannings,
        color: const Color(0xFFe89547),
        notificationPredicate: (notification) => !_isRefreshing,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFe89547),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPlannings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFe89547),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _plannings == null || _plannings!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun planning disponible',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Votre coach vous assignera bientôt\nun programme d\'entraînement',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Today's workout section
                          FutureBuilder<Map<String, dynamic>?>(
                            future: _loadTodayWorkout(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }
                              
                              if (snapshot.data != null) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '🔥 Entraînement du jour',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTodayWorkoutCard(snapshot.data!),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Mes Plannings',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              }
                              
                              return const SizedBox.shrink();
                            },
                          ),
                          // All plannings
                          ..._plannings!.map((planning) {
                            final planningData = planning as Map<String, dynamic>;
                            return _buildPlanningCard(planningData);
                          }),
                        ],
                      ),
      ),
    );
  }

  Widget _buildPlanningCard(Map<String, dynamic> planning) {
    final title = planning['title'] as String? ?? 'Planning';
    final description = planning['description'] as String?;
    final status = planning['status'] as String? ?? 'active';
    final startDate = planning['startDate'] as String? ?? '';
    final endDate = planning['endDate'] as String? ?? '';
    final coach = planning['coach'] as Map<String, dynamic>?;
    final days = planning['days'] as List<dynamic>? ?? [];

    // Check if planning is in the future (prévu)
    final bool isUpcoming = _isPlanningUpcoming(startDate);

    return Card(
      color: const Color(0xFF2d3748),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isUpcoming)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Prévu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              
              // Dates
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Du ${_formatDateSimple(startDate)} au ${_formatDateSimple(endDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              
              if (coach != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Coach: ${coach['fullName'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Days summary
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: const Color(0xFFe89547),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${days.length} jour${days.length > 1 ? 's' : ''} d\'entraînement',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFe89547),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white60,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  void _showPlanningDetails(Map<String, dynamic> planning) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2d3748),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final title = planning['title'] as String? ?? 'Planning';
          final description = planning['description'] as String?;
          final days = planning['days'] as List<dynamic>? ?? [];
          
          return Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe89547).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Color(0xFFe89547),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (description != null)
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Days list
                Expanded(
                  child: days.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun exercice programmé',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: days.length,
                          itemBuilder: (context, index) {
                            final day = days[index] as Map<String, dynamic>;
                            return _buildDayCard(day);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day, {bool isToday = false}) {
    final dayOfWeek = day['dayOfWeek'] as int;
    final exercises = day['exercises'] as List<dynamic>? ?? [];
    final date = day['date'] as String?;
    
    // Vérifier si c'est aujourd'hui en comparant les dates
    bool isDayToday = isToday;
    if (!isDayToday && date != null) {
      try {
        final parsedDate = DateTime.parse(date);
        final now = DateTime.now();
        isDayToday = parsedDate.year == now.year &&
                     parsedDate.month == now.month &&
                     parsedDate.day == now.day;
      } catch (_) {
        // Ignore parsing errors
      }
    }
    
    return Card(
      color: const Color(0xFF1a1f2e),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFe89547).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              _getDayName(dayOfWeek).substring(0, 3).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFe89547),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          _getDayName(dayOfWeek),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '${exercises.length} exercice${exercises.length > 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        iconColor: const Color(0xFFe89547),
        collapsedIconColor: Colors.white60,
        children: exercises.map((ex) {
          final exerciseData = ex as Map<String, dynamic>;
          final exercise = exerciseData['exercise'] as Map<String, dynamic>?;
          final sets = exerciseData['sets'] as int?;
          final reps = exerciseData['reps'] as int?;
          final weight = exerciseData['weight'] as num?;
          final notes = exerciseData['notes'] as String?;
          
          return Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2d3748),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFe89547),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise?['name'] ?? 'Exercice',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Exercise details
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (sets != null)
                      _buildExerciseDetail(Icons.repeat, '$sets séries'),
                    if (reps != null)
                      _buildExerciseDetail(Icons.fitness_center, '$reps reps'),
                    if (weight != null && weight > 0)
                      _buildExerciseDetail(Icons.monitor_weight, '$weight kg'),
                  ],
                ),
                
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1f2e),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade300,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Help request button (only show if it's today's workout)
                if (isDayToday) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _requestHelp(exercise?['name'] ?? 'Exercice'),
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('Demander aide'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFe89547),
                        side: const BorderSide(color: Color(0xFFe89547)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFFe89547),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Future<void> _requestHelp(String exerciseName) async {
    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();
      
      if (token == null || profileData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session expirée'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }

      final memberName = profileData['fullName'] as String? ?? 'Un membre';
      
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2d3748),
          title: const Text(
            'Demander de l\'aide',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Voulez-vous notifier les coachs de votre salle pour obtenir de l\'aide avec "$exerciseName" ?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe89547),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Envoi de la demande...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Send help request
      final success = await _apiService.requestExerciseHelp(
        exerciseName,
        token,
        notes: 'Demande d\'aide de $memberName',
      );

      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Les coachs ont été notifiés ! Ils viendront vous aider.'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        _showErrorWithRetry(
          'Une erreur est survenue',
          () => _requestHelp(exerciseName),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error requesting help: $e');
      if (!mounted) return;
      _showErrorWithRetry(
        'Une erreur est survenue',
        () => _requestHelp(exerciseName),
      );
    }
  }
}

// ==================== MEMBER PROFILE PAGE ====================
class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key});

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  final _authService = AuthService(ApiService.fromEnv());
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    // Try to load from cache first
    final cachedData = await _authService.getCachedUserProfile();
    
    if (cachedData != null) {
      setState(() {
        _profileData = cachedData;
        _isLoading = false;
      });
      
      // Check if cache is stale and refresh in background
      final isStale = await _authService.isProfileCacheStale();
      if (isStale) {
        _refreshProfileDataSilently();
      }
    } else {
      // No cache, fetch from API
      await _refreshProfileData();
    }
  }

  Future<void> _refreshProfileData() async {
    if (_isRefreshing) return; // Prevent multiple refreshes
    
    setState(() => _isRefreshing = true);
    
    try {
      final freshData = await _authService.refreshUserProfile();

      if (mounted) {
        setState(() {
          if (freshData != null) {
            _profileData = freshData;
          }
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _refreshProfileDataSilently() async {
    final freshData = await _authService.refreshUserProfile();
    if (mounted && freshData != null) {
      setState(() => _profileData = freshData);
    }
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          profileData: _profileData,
          onProfileUpdated: _refreshProfileDataSilently,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1f2e),
              const Color(0xFF2d3748),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFe89547),
          ),
        ),
      );
    }

    // Extract data from cache
    final fullName = _profileData?['fullName'] ?? 'Utilisateur';
    final email = _profileData?['email'] ?? 'email@exemple.com';
    final joinedAt = _profileData?['joinedAt'] ?? 'N/A';
    
    // Handle both 'subscription' (singular) and 'subscriptions' (plural array)
    Map<String, dynamic>? subscription;
    final subscriptions = _profileData?['subscriptions'] as List<dynamic>?;
    if (subscriptions != null && subscriptions.isNotEmpty) {
      // Get the first active subscription or just the first one
      subscription = subscriptions.firstWhere(
        (sub) => (sub as Map<String, dynamic>)['status'] == 'active',
        orElse: () => subscriptions.first,
      ) as Map<String, dynamic>;
    } else {
      subscription = _profileData?['subscription'] as Map<String, dynamic>?;
    }
    
    final subscriptionType = subscription?['type'] ?? 'premium';
    final subscriptionStatus = subscription?['status'] ?? 'unknown';
    final billingPeriod = subscription?['billingPeriod'] ?? 'monthly';
    final price = subscription?['price'] ?? 0;
    final startDate = subscription?['startDate'] ?? 'N/A';
    final expiresAt = subscription?['expiresAt'] ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshProfileData,
        color: const Color(0xFFe89547),
        notificationPredicate: (notification) => !_isRefreshing,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header - Full width, clickable
              InkWell(
                onTap: () => _navigateToEditProfile(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2d3748),
                        const Color(0xFF2d3748).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFe89547),
                            child: const Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1a1f2e),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFe89547),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Color(0xFFe89547),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Membre depuis: $joinedAt',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFe89547).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFe89547).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: Color(0xFFe89547),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Modifier le profil',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFe89547),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Subscription section
              const Text(
                'Mon Abonnement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionDetailsScreen(
                        subscriptionData: subscription,
                      ),
                    ),
                  );
                },
                child: Card(
                  color: const Color(0xFFe89547),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                subscriptionType == 'premium' ? 'Abonnement Premium' : 'Abonnement Standard',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: subscriptionStatus == 'active' ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                subscriptionStatus.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSubscriptionDetail('Type', billingPeriod == 'monthly' ? 'Mensuel' : 'Annuel'),
                        _buildSubscriptionDetail('Prix', '$price € / ${billingPeriod == 'monthly' ? 'mois' : 'an'}'),
                        _buildSubscriptionDetail('Date de début', startDate),
                        _buildSubscriptionDetail('Expire le', expiresAt),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text(
                              'Voir les détails',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Settings options
              const Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingsItem(
                context,
                'Paramètres',
                Icons.settings,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecuritySettingsPage(),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                'À propos',
                Icons.info_outline,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                'Aide & Support',
                Icons.help_outline,
                () {},
              ),
              const SizedBox(height: 16),
              
              // Logout button
              Card(
                color: Colors.red.shade400,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  onTap: () async {
                    await _authService.clearAll();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: const Color(0xFF2d3748),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFe89547).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFe89547), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
        onTap: onTap,
      ),
    );
  }
}
