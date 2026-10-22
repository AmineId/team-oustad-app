import 'package:flutter/material.dart';
import 'admin_chrome.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/app_snackbar.dart';
import 'admin_subscription_details_screen.dart';
import 'admin_create_subscription_screen.dart';
import 'admin_create_planning_screen.dart';

class AdminMemberDetailsScreen extends StatefulWidget {
  final int memberId;
  final VoidCallback? onBack;

  const AdminMemberDetailsScreen({
    super.key,
    required this.memberId,
    this.onBack,
  });

  @override
  State<AdminMemberDetailsScreen> createState() =>
      _AdminMemberDetailsScreenState();
}

class _AdminMemberDetailsScreenState extends State<AdminMemberDetailsScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());

  Map<String, dynamic>? _member;
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _plannings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMemberDetails();
  }

  Future<void> _loadMemberDetails() async {
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

      // Charger les infos du membre (prioritaire)
      Map<String, dynamic>? member;
      try {
        debugPrint('Chargement du membre avec ID: ${widget.memberId}');
        member = await _apiService.getUserById(widget.memberId, token);
        debugPrint('Réponse API pour le membre: $member');
      } catch (e) {
        debugPrint('Erreur lors du chargement du membre: $e');
        setState(() {
          _errorMessage = 'Erreur de connexion: ${e.toString()}';
          _isLoading = false;
        });
        return;
      }

      // Si le membre n'existe pas, on arrête ici
      if (member == null) {
        debugPrint(
          'Membre null retourné par l\'API pour ID: ${widget.memberId}',
        );
        setState(() {
          _errorMessage = 'Membre introuvable (ID: ${widget.memberId})';
          _isLoading = false;
        });
        return;
      }

      // Charger les abonnements du membre (indépendant)
      List<Map<String, dynamic>> subscriptions = [];
      List<Map<String, dynamic>> allPayments = [];
      try {
        final subsData = await _apiService.getMemberSubscriptions(
          widget.memberId,
          token,
        );
        debugPrint('📋 Member subscriptions raw data: $subsData');
        if (subsData != null) {
          subscriptions = subsData
              .map((s) => s as Map<String, dynamic>)
              .toList();
          debugPrint('📋 Subscriptions count: ${subscriptions.length}');

          // Récupérer tous les paiements de tous les abonnements
          for (var subscription in subscriptions) {
            try {
              final subDetails = await _apiService.getSubscriptionById(
                subscription['id'] as int,
                token,
              );
              if (subDetails != null && subDetails['payments'] != null) {
                final payments = (subDetails['payments'] as List)
                    .map(
                      (p) => {
                        ...p as Map<String, dynamic>,
                        'subscriptionName':
                            subscription['subscriptionType']?['name'] ??
                            'Abonnement',
                        'subscriptionId': subscription['id'],
                      },
                    )
                    .toList();
                allPayments.addAll(payments);
              }
            } catch (e) {
              debugPrint(
                'Erreur lors du chargement des paiements de l\'abonnement ${subscription['id']}: $e',
              );
            }
          }

          // Trier les paiements par date d'échéance (plus récents en premier)
          allPayments.sort((a, b) {
            final dateA = DateTime.tryParse(a['dueDate'] ?? '');
            final dateB = DateTime.tryParse(b['dueDate'] ?? '');
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA);
          });
        }
        debugPrint('Abonnements chargés: ${subscriptions.length}');
        debugPrint('Paiements totaux chargés: ${allPayments.length}');
      } catch (e) {
        debugPrint('Erreur lors du chargement des abonnements: $e');
        // On continue même si les abonnements ne chargent pas
      }

      // Charger les plannings du membre (indépendant)
      List<Map<String, dynamic>> plannings = [];
      try {
        final planningsData = await _apiService.getMemberPlannings(
          widget.memberId,
          token,
        );
        if (planningsData['plannings'] != null) {
          plannings = (planningsData['plannings'] as List)
              .map((p) => p as Map<String, dynamic>)
              .toList();
        }
        debugPrint('Plannings chargés: ${plannings.length}');
      } catch (e) {
        debugPrint('Erreur lors du chargement des plannings: $e');
        // On continue même si les plannings ne chargent pas
      }

      // Mettre à jour l'état avec toutes les données disponibles
      setState(() {
        _member = member;
        _subscriptions = subscriptions;
        _plannings = plannings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur générale: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'paused':
        return 'En pause';
      case 'cancelled':
        return 'Annulé';
      case 'expired':
        return 'Expiré';
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'paused':
        return AppColors.warning;
      case 'cancelled':
      case 'expired':
        return AppColors.error;
      case 'pending':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return adminFrame(
      context,
      embedded: widget.onBack != null,
      padBottom: false,
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Détails du membre',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMemberDetails,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorMessage.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMemberDetails,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadMemberDetails,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carte d'info membre
                      _buildMemberInfoCard(),

                      const SizedBox(height: 24),

                      // Section Abonnements
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Abonnements',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.color,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminCreateSubscriptionScreen(
                                        memberId: widget.memberId,
                                      ),
                                ),
                              );
                              // Recharger après création
                              _loadMemberDetails();
                            },
                            icon: const Icon(Icons.add_circle),
                            color: AppColors.primary,
                            iconSize: 32,
                            tooltip: 'Ajouter un abonnement',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Liste des abonnements
                      if (_subscriptions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.subscriptions_outlined,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun abonnement',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._subscriptions.map(
                          (subscription) =>
                              _buildSubscriptionCard(subscription),
                        ),

                      const SizedBox(height: 32),

                      // Section Plannings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plannings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminCreatePlanningScreen(
                                        preselectedMemberId: widget.memberId,
                                      ),
                                ),
                              );
                              // Recharger après création
                              _loadMemberDetails();
                            },
                            icon: const Icon(Icons.add_circle),
                            color: AppColors.primary,
                            iconSize: 32,
                            tooltip: 'Ajouter un planning',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Liste des plannings
                      if (_plannings.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun planning',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._plannings.map(
                          (planning) => _buildPlanningCard(planning),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    ),
    );
  }

  Widget _buildMemberInfoCard() {
    if (_member == null) return const SizedBox();

    final fullName = getUserFullName(_member);
    final email = _member!['email'] as String? ?? '';
    final uniqueCode = _member!['displayId'] as String? ?? '';
    final phone = _member!['phone'] as String?;

    // Obtenir les initiales pour l'avatar
    final initials = fullName
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nom
          Text(
            fullName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Code unique
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              uniqueCode,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
          const SizedBox(height: 16),

          // Email
          _buildInfoRow(Icons.email, email),

          if (phone != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, phone),
          ],

          if (email.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SendSetupEmailButton(
              email: email,
              apiService: _apiService,
              authService: _authService,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    final subscriptionType =
        subscription['subscriptionType'] as Map<String, dynamic>?;
    final status = subscription['status'] as String? ?? 'unknown';
    final startDate = subscription['startDate'] as String?;
    final endDate = subscription['endDate'] as String?;

    final typeName = subscriptionType?['name'] as String? ?? 'Abonnement';
    final typeDescription = subscriptionType?['description'] as String?;
    final monthlyPrice = subscriptionType?['monthlyPrice'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminSubscriptionDetailsScreen(
                subscriptionId: subscription['id'] as int,
              ),
            ),
          );
          // Recharger après modifications
          _loadMemberDetails();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      typeName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
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

              if (typeDescription != null) ...[
                const SizedBox(height: 8),
                Text(
                  typeDescription,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Prix
              if (monthlyPrice != null)
                Text(
                  '$monthlyPrice MAD / mois',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 12),

              // Dates
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Du ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanningCard(Map<String, dynamic> planning) {
    final title =
        planning['title'] as String? ??
        planning['name'] as String? ??
        'Planning';
    final description = planning['description'] as String?;
    final startDate = planning['startDate'] as String?;
    final endDate = planning['endDate'] as String?;
    final status = planning['status'] as String? ?? 'unknown';
    final coach = planning['coach'] as Map<String, dynamic>?;
    final days = planning['days'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardTheme.color,
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
              // Nom et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
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

              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
              const SizedBox(height: 12),

              // Coach
              if (coach != null)
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coach: ${getUserFullName(coach)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
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
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Du ${_formatDate(startDate)} au ${_formatDate(endDate)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Jours d'entraînement
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${days.length} jour${days.length > 1 ? 's' : ''} d\'entraînement',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 16,
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
    final title =
        planning['title'] as String? ??
        planning['name'] as String? ??
        'Planning';
    final description = planning['description'] as String? ?? '';
    final startDate = planning['startDate'] as String?;
    final endDate = planning['endDate'] as String?;
    final status = planning['status'] as String? ?? 'unknown';
    final member = planning['member'] as Map<String, dynamic>?;
    final coach = planning['coach'] as Map<String, dynamic>?;
    final days = planning['days'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: _getStatusColor(status).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                status,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
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
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (description.isNotEmpty) ...[
                      _buildDetailRow(
                        Icons.description,
                        'Description',
                        description,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (member != null)
                      _buildDetailRow(
                        Icons.person,
                        'Membre',
                        getUserFullName(member),
                      ),

                    const SizedBox(height: 16),

                    if (coach != null)
                      _buildDetailRow(
                        Icons.fitness_center,
                        'Coach',
                        getUserFullName(coach),
                      ),

                    const SizedBox(height: 16),

                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date de début',
                      _formatDate(startDate),
                    ),

                    const SizedBox(height: 16),

                    _buildDetailRow(
                      Icons.event,
                      'Date de fin',
                      _formatDate(endDate),
                    ),

                    const SizedBox(height: 24),
                    Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                    const SizedBox(height: 16),

                    // Jours d'entraînement
                    Text(
                      'Jours d\'entraînement',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (days.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Aucun jour d\'entraînement',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...days.map((day) {
                        final dayOfWeek = day['dayOfWeek'] as int?;
                        final exercises =
                            day['exercises'] as List<dynamic>? ?? [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getDayName(dayOfWeek),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${exercises.length} exercice${exercises.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // Bouton supprimer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeletePlanning(
                            planning['_id'] as String? ?? '',
                            title,
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer le planning'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.2),
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDayName(int? dayOfWeek) {
    if (dayOfWeek == null) return 'Jour inconnu';
    switch (dayOfWeek) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return 'Jour $dayOfWeek';
    }
  }

  void _confirmDeletePlanning(String planningId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Confirmer la suppression',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le planning "$title" ?\n\nCette action est irréversible.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlanning(planningId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlanning(String planningId) async {
    try {
      final token = await _authService.loadToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Token non disponible'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Convertir le planningId en int
      final id = int.tryParse(planningId);
      if (id == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ ID de planning invalide'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Appeler l'API pour supprimer le planning
      final success = await _apiService.deletePlanning(id, token);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Planning supprimé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );

        // Recharger les détails du membre
        _loadMemberDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de la suppression du planning'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppColors.error,
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

class _SendSetupEmailButton extends StatefulWidget {
  final String email;
  final ApiService apiService;
  final AuthService authService;

  const _SendSetupEmailButton({
    required this.email,
    required this.apiService,
    required this.authService,
  });

  @override
  State<_SendSetupEmailButton> createState() => _SendSetupEmailButtonState();
}

class _SendSetupEmailButtonState extends State<_SendSetupEmailButton> {
  bool _isSending = false;
  bool _sent = false;

  Future<void> _send() async {
    setState(() => _isSending = true);
    try {
      final token = await widget.authService.loadToken();
      if (token == null) throw Exception('Non authentifié');
      final ok = await widget.apiService.sendSetupEmail(widget.email, token);
      if (!mounted) return;
      if (ok) {
        setState(() => _sent = true);
        AppSnackBar.success(context, 'Email de configuration envoyé');
      } else {
        AppSnackBar.error(context, 'Échec de l\'envoi');
      }
    } catch (_) {
      if (mounted) AppSnackBar.error(context, 'Erreur lors de l\'envoi');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: (_isSending || _sent) ? null : _send,
      icon: _isSending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_sent ? Icons.check_circle_outline : Icons.mark_email_unread_outlined),
      label: Text(_sent ? 'Email envoyé' : 'Envoyer email de configuration'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
