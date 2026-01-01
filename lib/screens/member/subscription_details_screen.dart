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

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoadingPayments = true;
    });

    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();
      
      if (token == null || profileData == null) {
        throw Exception('Non authentifié');
      }

      final memberId = profileData['id'] as int;
      
      // Appel API pour récupérer l'historique des paiements
      final uri = _apiService.baseUri.resolve('/api/members/$memberId/payments');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _payments = List<Map<String, dynamic>>.from(data['payments'] ?? []);
          _isLoadingPayments = false;
        });
      } else {
        // Si l'API n'existe pas encore, utiliser des données fictives
        _loadMockPayments();
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading payment history: $e');
      // Charger des données fictives en cas d'erreur
      _loadMockPayments();
    }
  }

  void _loadMockPayments() {
    // Données fictives pour l'instant - exemples de tous les statuts
    setState(() {
      _payments = [
        {
          'id': 1,
          'date': '2025-11-01T13:28:58.110Z',
          'amount': 49.99,
          'status': 'completed',
          'method': 'Carte bancaire',
          'description': 'Abonnement Premium - Novembre 2025',
        },
        {
          'id': 2,
          'date': '2025-10-01T10:15:22.000Z',
          'amount': 49.99,
          'status': 'overdue',
          'method': 'Prélèvement automatique',
          'description': 'Abonnement Premium - Octobre 2025',
        },
        {
          'id': 3,
          'date': '2025-09-15T09:30:45.000Z',
          'amount': 49.99,
          'status': 'failed',
          'method': 'Carte bancaire',
          'description': 'Abonnement Premium - Septembre 2025',
        },
        {
          'id': 4,
          'date': '2025-09-01T09:30:45.000Z',
          'amount': 49.99,
          'status': 'completed',
          'method': 'Carte bancaire',
          'description': 'Abonnement Premium - Septembre 2025',
        },
        {
          'id': 5,
          'date': '2025-08-01T08:20:30.000Z',
          'amount': 49.99,
          'status': 'refunded',
          'method': 'Carte bancaire',
          'description': 'Abonnement Premium - Août 2025',
        },
      ];
      _isLoadingPayments = false;
    });
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
    final subscriptionType = widget.subscriptionData?['type'] ?? 'premium';
    final subscriptionStatus = widget.subscriptionData?['status'] ?? 'unknown';
    final billingPeriod = widget.subscriptionData?['billingPeriod'] ?? 'monthly';
    final price = widget.subscriptionData?['price'] ?? 0;
    final startDate = widget.subscriptionData?['startDate'] ?? 'N/A';
    final expiresAt = widget.subscriptionData?['expiresAt'] ?? 'N/A';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.cardTheme.color!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge!.color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mon Abonnement',
                      style: AppTextStyles.h4.copyWith(
                        color: theme.textTheme.bodyLarge!.color,
                      ),
                    ),
                  ],
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
                                      subscriptionType == 'premium' 
                                          ? 'Abonnement Premium' 
                                          : 'Abonnement Standard',
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
                                'Type',
                                billingPeriod == 'monthly' ? 'Mensuel' : 'Annuel',
                              ),
                              Divider(color: Theme.of(context).dividerColor, height: 24),
                              _buildDetailRow(
                                'Prix',
                                '$price MAD / ${billingPeriod == 'monthly' ? 'mois' : 'an'}',
                              ),
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





