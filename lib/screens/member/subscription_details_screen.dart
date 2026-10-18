import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? subscriptionData;

  const SubscriptionDetailsScreen({
    super.key,
    this.subscriptionData,
  });

  @override
  State<SubscriptionDetailsScreen> createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  final _authService = AuthService(ApiService.fromEnv());
  final _apiService = ApiService.fromEnv();
  
  List<Map<String, dynamic>> _payments = [];
  bool _isLoadingPayments = true;
  Map<String, dynamic>? _quotaData;
  bool _isLoadingQuota = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
    _loadQuotaData();
  }

  Future<void> _loadQuotaData() async {
    setState(() {
      _isLoadingQuota = true;
    });

    try {
      final token = await _authService.loadToken();
      final subscription = widget.subscriptionData?['subscription'] as Map<String, dynamic>?;
      final subscriptionId = subscription?['id'];
      
      debugPrint('🔍 [QUOTA] Chargement quota pour subscriptionId: $subscriptionId');
      debugPrint('🔍 [QUOTA] subscription: $subscription');
      
      if (token == null || subscriptionId == null) {
        debugPrint('❌ [QUOTA] Token ou subscriptionId absent');
        setState(() {
          _isLoadingQuota = false;
        });
        return;
      }
      
      // Appel API pour récupérer le quota
      final uri = _apiService.baseUri.resolve('/check-in/subscription/$subscriptionId/quota');
      debugPrint('🌐 [QUOTA] Requête GET: $uri');
      
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 [QUOTA] Status: ${resp.statusCode}');
      debugPrint('📦 [QUOTA] Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _quotaData = data as Map<String, dynamic>;
          _isLoadingQuota = false;
        });
        debugPrint('✅ [QUOTA] Quota chargé: $_quotaData');
      } else {
        debugPrint('⚠️ [QUOTA] Erreur: ${resp.statusCode}');
        setState(() {
          _isLoadingQuota = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [QUOTA] Exception: $e');
      debugPrint('Error loading quota data: $e');
      setState(() {
        _isLoadingQuota = false;
      });
    }
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoadingPayments = true;
    });

    try {
      final token = await _authService.loadToken();
      final subscription = widget.subscriptionData?['subscription'] as Map<String, dynamic>?;
      final subscriptionId = subscription?['id'];
      
      debugPrint('💰 [PAYMENTS] subscriptionId: $subscriptionId');
      
      if (token == null || subscriptionId == null) {
        debugPrint('❌ [PAYMENTS] Token ou subscriptionId manquant');
        throw Exception('Token ou subscriptionId manquant');
      }
      
      // Appel API pour récupérer l'historique des paiements depuis /subscriptions/{id}
      final uri = _apiService.baseUri.resolve('/subscriptions/$subscriptionId');
      debugPrint('🌐 [PAYMENTS] Requête: $uri');
      
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📡 [PAYMENTS] Status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        debugPrint('📦 [PAYMENTS] Response: $data');
        debugPrint('📦 [PAYMENTS] Payments array: ${data['payments']}');
        
        setState(() {
          _payments = List<Map<String, dynamic>>.from(data['payments'] ?? []);
          _isLoadingPayments = false;
        });
        
        debugPrint('✅ [PAYMENTS] ${_payments.length} paiements chargés');
      } else {
        debugPrint('⚠️ [PAYMENTS] Erreur ${resp.statusCode}: ${resp.body}');
        setState(() {
          _isLoadingPayments = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [PAYMENTS] Exception: $e');
      debugPrint('Error loading payment history: $e');
      setState(() {
        _isLoadingPayments = false;
      });
    }
  }

  Future<void> _renewSubscription(Map<String, dynamic>? subscription) async {
    final subscriptionId = subscription?['id'] as int?;
    if (subscriptionId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Row(
          children: [
            Icon(Icons.autorenew, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Renouveler', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Un nouvel abonnement du même type sera créé à partir d\'aujourd\'hui.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Renouveler'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }
      final result = await _apiService.renewSubscription(subscriptionId, token);
      if (!mounted) return;
      Navigator.pop(context);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement renouvelé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du renouvellement'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Actif';
      case 'overdue':
        return 'En retard';
      case 'failed':
        return 'Échoué';
      case 'refunded':
        return 'Remboursé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extraire subscription puis SubscriptionType (avec majuscule)
    final subscription = widget.subscriptionData?['subscription'] as Map<String, dynamic>?;
    final subscriptionTypeData = subscription?['SubscriptionType'] as Map<String, dynamic>?;
    final subscriptionName = subscriptionTypeData?['name'] ?? 'Abonnement';
    final monthlyPrice = subscriptionTypeData?['monthlyPrice'] ?? 0;
    final durationMonths = subscriptionTypeData?['durationMonths'] ?? 1;
    
    // Logs pour debug
    debugPrint('🔍 [SUBSCRIPTION DETAILS] subscription: $subscription');
    debugPrint('🔍 [SUBSCRIPTION DETAILS] subscriptionTypeData: $subscriptionTypeData');
    debugPrint('🔍 [SUBSCRIPTION DETAILS] subscriptionName: $subscriptionName');
    debugPrint('🔍 [SUBSCRIPTION DETAILS] monthlyPrice: $monthlyPrice');
    
    final subscriptionStatus = subscription?['status'] ?? 'unknown';
    final startDate = subscription?['startDate'] ?? 'N/A';
    final expiresAt = subscription?['endDate'] ?? subscription?['expiresAt'] ?? 'N/A';
    
    // Quota information from API - utiliser subscriptionType.sessionQuota
    final quotaSubscriptionTypeData = _quotaData?['subscriptionType'] as Map<String, dynamic>?;
    final sessionType = quotaSubscriptionTypeData?['sessionType'] as String?;
    final sessionQuota = quotaSubscriptionTypeData?['sessionQuota'] as int?;
    final sessionsUsed = _quotaData?['sessionsUsed'] as int? ?? 0;
    final sessionsRemaining = (sessionQuota != null && sessionQuota > 0) 
        ? sessionQuota - sessionsUsed 
        : null;
    final isUnlimited = sessionType == 'unlimited' || sessionQuota == null || sessionQuota == 0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge!.color),
                ),
                centerTitle: true,
                title: Text(
                  'Mon Abonnement',
                  style: AppTextStyles.h4.copyWith(
                    color: theme.textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subscription details card
                      Card(
                        color: theme.colorScheme.primary,
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
                                      subscriptionName,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: subscriptionStatus == 'active' 
                                          ? AppColors.success 
                                          : AppColors.error,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      subscriptionStatus == 'active' ? 'ACTIVE' : 'INACTIF',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildDetailRow(
                                'Durée',
                                '$durationMonths mois',
                              ),
                              Divider(color: Theme.of(context).dividerColor, height: 24),
                              _buildDetailRow(
                                'Prix',
                                '$monthlyPrice MAD',
                              ),
                              Divider(color: Theme.of(context).dividerColor, height: 24),
                              // Quota de séances
                              if (_isLoadingQuota)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Séances',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary).withValues(alpha: 0.7),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              else if (isUnlimited)
                                _buildDetailRow(
                                  'Séances',
                                  'Illimité ∞',
                                )
                              else _buildDetailRow(
                                'Séances',
                                '$sessionsRemaining restantes sur $sessionQuota',
                              ),
                              if (!_isLoadingQuota && (!isUnlimited || sessionQuota != null))
                                Divider(color: Theme.of(context).dividerColor, height: 24),
                              _buildDetailRow(
                                'Date de début',
                                _formatDate(startDate),
                              ),
                              Divider(color: Theme.of(context).dividerColor, height: 24),
                              _buildDetailRow(
                                'Expire le',
                                expiresAt != 'N/A' ? _formatDate(expiresAt) : 'N/A',
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (subscriptionStatus == 'expired' || subscriptionStatus == 'cancelled') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _renewSubscription(subscription),
                            icon: const Icon(Icons.autorenew, size: 20),
                            label: const Text('Renouveler l\'abonnement'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Payment history section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Historique des Paiements',
                            style: AppTextStyles.h5.copyWith(
                              color: theme.textTheme.bodyLarge!.color,
                            ),
                          ),
                          if (_isLoadingPayments)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment list
                      if (_payments.isEmpty && !_isLoadingPayments)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun paiement enregistré',
                                  style: TextStyle(
                                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._payments.map((payment) => _buildPaymentCard(payment)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final theme = Theme.of(context);
    final status = payment['status'] as String;
    
    // Déterminer la couleur et l'icône selon le statut
    Color statusColor;
    Color backgroundColor;
    IconData statusIcon;
    
    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        backgroundColor = AppColors.success.withValues(alpha: 0.2);
        statusIcon = Icons.check_circle;
        break;
      case 'overdue':
        statusColor = AppColors.warning;
        backgroundColor = AppColors.warning.withValues(alpha: 0.2);
        statusIcon = Icons.schedule;
        break;
      case 'failed':
        statusColor = AppColors.error;
        backgroundColor = AppColors.error.withValues(alpha: 0.2);
        statusIcon = Icons.error;
        break;
      case 'refunded':
        statusColor = AppColors.info;
        backgroundColor = AppColors.info.withValues(alpha: 0.2);
        statusIcon = Icons.refresh;
        break;
      default:
        statusColor = theme.textTheme.bodyMedium!.color!;
        backgroundColor = theme.textTheme.bodyMedium!.color!.withValues(alpha: 0.2);
        statusIcon = Icons.help_outline;
    }
    
    return Card(
      color: theme.cardTheme.color,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment['description'] ?? 'Paiement',
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge!.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(payment['date']),
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium!.color,
                      fontSize: 12,
                    ),
                  ),
                  if (payment['method'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        payment['method'],
                        style: TextStyle(
                          color: theme.textTheme.bodySmall!.color,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${payment['amount']} MAD',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge!.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Builder(
                    builder: (context) => Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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





