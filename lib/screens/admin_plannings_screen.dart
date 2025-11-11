import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'admin_create_planning_screen.dart';

class AdminPlanningsScreen extends StatefulWidget {
  const AdminPlanningsScreen({super.key});

  @override
  State<AdminPlanningsScreen> createState() => _AdminPlanningsScreenState();
}

class _AdminPlanningsScreenState extends State<AdminPlanningsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  late TabController _tabController;
  
  List<Map<String, dynamic>> _activePlannings = [];
  List<Map<String, dynamic>> _completedPlannings = [];
  List<Map<String, dynamic>> _cancelledPlannings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlannings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlannings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Token non disponible';
          _isLoading = false;
        });
        return;
      }

      // Charger les plannings actifs
      final activePlannings = await _apiService.getPlannings(token, status: 'active');
      
      // Charger les plannings terminés
      final completedPlannings = await _apiService.getPlannings(token, status: 'completed');
      
      // Charger les plannings annulés
      final cancelledPlannings = await _apiService.getPlannings(token, status: 'cancelled');
      
      setState(() {
        _activePlannings = activePlannings?.map((p) => p as Map<String, dynamic>).toList() ?? [];
        _completedPlannings = completedPlannings?.map((p) => p as Map<String, dynamic>).toList() ?? [];
        _cancelledPlannings = cancelledPlannings?.map((p) => p as Map<String, dynamic>).toList() ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusLabel(String status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plannings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminCreatePlanningScreen(),
                ),
              );
              // Recharger après création
              _loadPlannings();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFe89547),
          labelColor: const Color(0xFFe89547),
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Actifs'),
                  if (_activePlannings.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_activePlannings.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Terminés'),
                  if (_completedPlannings.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_completedPlannings.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Annulés'),
                  if (_cancelledPlannings.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_cancelledPlannings.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFe89547),
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlanningsList(_activePlannings),
                      _buildPlanningsList(_completedPlannings),
                      _buildPlanningsList(_cancelledPlannings),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminCreatePlanningScreen(),
            ),
          );
          // Recharger après création
          _loadPlannings();
        },
        backgroundColor: const Color(0xFFe89547),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau planning'),
      ),
    );
  }

  Widget _buildPlanningsList(List<Map<String, dynamic>> plannings) {
    if (plannings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white60,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun planning',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlannings,
      color: const Color(0xFFe89547),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plannings.length,
        itemBuilder: (context, index) {
          final planning = plannings[index];
          return _buildPlanningCard(planning);
        },
      ),
    );
  }

  Widget _buildPlanningCard(Map<String, dynamic> planning) {
    final title = planning['title'] as String? ?? 'Planning';
    final description = planning['description'] as String? ?? '';
    final status = planning['status'] as String? ?? 'unknown';
    final startDate = planning['startDate'] as String?;
    final endDate = planning['endDate'] as String?;
    final member = planning['member'] as Map<String, dynamic>?;
    final coach = planning['coach'] as Map<String, dynamic>?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2d3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showPlanningDetails(planning),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              
              // Membre
              if (member != null)
                Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFFe89547), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Membre: ${member['fullName'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 8),
              
              // Coach
              if (coach != null)
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Color(0xFFe89547), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coach: ${coach['fullName'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 8),
              
              // Dates
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white60, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Du ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
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
  }

  void _showPlanningDetails(Map<String, dynamic> planning) {
    final title = planning['title'] as String? ?? 'Planning';
    final description = planning['description'] as String?;
    final status = planning['status'] as String? ?? 'unknown';
    final startDate = planning['startDate'] as String?;
    final endDate = planning['endDate'] as String?;
    final member = planning['member'] as Map<String, dynamic>?;
    final coach = planning['coach'] as Map<String, dynamic>?;
    final days = planning['days'] as List<dynamic>? ?? [];
    final planningId = planning['id'] as int?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2d3748),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1f2e),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: _getStatusColor(status),
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
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getStatusColor(status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getStatusLabel(status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.w600,
                                  ),
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
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (description != null && description.isNotEmpty) ...[
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 20),
                        ],
                        // Membre
                        if (member != null)
                          _buildDetailRow(
                            Icons.person,
                            'Membre',
                            member['fullName'] ?? 'N/A',
                          ),
                        const SizedBox(height: 12),
                        // Coach
                        if (coach != null)
                          _buildDetailRow(
                            Icons.fitness_center,
                            'Coach',
                            coach['fullName'] ?? 'N/A',
                          ),
                        const SizedBox(height: 12),
                        // Dates
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Période',
                          'Du ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 20),
                        // Jours d'entraînement
                        Text(
                          '${days.length} jour${days.length > 1 ? 's' : ''} d\'entraînement',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...days.map((day) {
                          final dayData = day as Map<String, dynamic>;
                          final exercises = dayData['exercises'] as List<dynamic>? ?? [];
                          final dayOfWeek = dayData['dayOfWeek'] as int?;
                          return Card(
                            color: const Color(0xFF1a1f2e),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getDayName(dayOfWeek ?? 0),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFe89547),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${exercises.length} exercice${exercises.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  // Bouton de suppression
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1a1f2e),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeletePlanning(planningId, title);
                        },
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text('Supprimer le planning'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFe89547), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    return days[dayOfWeek % 7];
  }

  Future<void> _confirmDeletePlanning(int? planningId, String title) async {
    if (planningId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2d3748),
          title: const Text(
            'Supprimer le planning',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer le planning "$title" ?\n\nCette action est irréversible.',
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
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deletePlanning(planningId);
    }
  }

  Future<void> _deletePlanning(int planningId) async {
    try {
      final token = await _authService.loadToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Token non disponible'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Appeler l'API pour supprimer le planning
      final success = await _apiService.deletePlanning(planningId, token);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Planning supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recharger la liste
        _loadPlannings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la suppression du planning'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
