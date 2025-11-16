import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class AdminSubscriptionDetailsScreen extends StatefulWidget {
  final int subscriptionId;

  const AdminSubscriptionDetailsScreen({
    super.key,
    required this.subscriptionId,
  });

  @override
  State<AdminSubscriptionDetailsScreen> createState() => _AdminSubscriptionDetailsScreenState();
}

class _AdminSubscriptionDetailsScreenState extends State<AdminSubscriptionDetailsScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  
  Map<String, dynamic>? _subscriptionDetails;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSubscriptionDetails();
  }

  Future<void> _loadSubscriptionDetails() async {
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

      final details = await _apiService.getSubscriptionById(widget.subscriptionId, token);
      
      if (details != null) {
        setState(() {
          _subscriptionDetails = details;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossible de charger les détails de l\'abonnement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acknowledgePayment(Map<String, dynamic> payment) async {
    final paymentId = payment['id'] as int;
    
    // Dialog pour choisir le mode de paiement
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: const Text(
          'Mode de paiement',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PaymentMethodOption(
              icon: Icons.credit_card,
              label: 'Carte bancaire',
              value: 'credit_card',
            ),
            const SizedBox(height: 8),
            _PaymentMethodOption(
              icon: Icons.account_balance,
              label: 'Virement bancaire',
              value: 'bank_transfer',
            ),
            const SizedBox(height: 8),
            _PaymentMethodOption(
              icon: Icons.money,
              label: 'Espèces',
              value: 'cash',
            ),
            const SizedBox(height: 8),
            _PaymentMethodOption(
              icon: Icons.payment,
              label: 'Autre',
              value: 'other',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );

    if (paymentMethod == null) return;

    // Afficher un loader
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFe89547),
        ),
      ),
    );

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorDialog('Token non disponible');
        return;
      }

      final result = await _apiService.acknowledgePayment(
        paymentId,
        paymentMethod,
        token,
      );

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader

      if (result != null) {
        _showSuccessDialog('Paiement acquitté avec succès');
        _loadSubscriptionDetails(); // Recharger les détails
      } else {
        _showErrorDialog('Erreur lors de l\'acquittement du paiement');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader
      _showErrorDialog('Erreur: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Succès',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFe89547)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Erreur',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFe89547)),
            ),
          ),
        ],
      ),
    );
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
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'cancelled':
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'completed':
        return 'Payé';
      case 'failed':
        return 'Échoué';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
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
          'Détails de l\'abonnement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptionDetails,
          ),
        ],
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
                          onPressed: _loadSubscriptionDetails,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadSubscriptionDetails,
                    color: const Color(0xFFe89547),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Infos abonnement
                          _buildSubscriptionInfoCard(),
                          
                          const SizedBox(height: 24),
                          
                          // Section Paiements
                          const Text(
                            'Paiements',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Liste des paiements
                          _buildPaymentsList(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildSubscriptionInfoCard() {
    if (_subscriptionDetails == null) return const SizedBox();
    
    final subscription = _subscriptionDetails!['subscription'] as Map<String, dynamic>?;
    if (subscription == null) return const SizedBox();
    
    final subscriptionType = subscription['subscriptionType'] as Map<String, dynamic>?;
    final status = subscription['status'] as String? ?? 'unknown';
    final startDate = subscription['startDate'] as String?;
    final endDate = subscription['endDate'] as String?;
    final autoRenew = subscription['autoRenew'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3748),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom et statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subscriptionType?['name'] ?? 'Abonnement',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          if (subscriptionType?['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              subscriptionType!['description'] as String,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          // Prix
          if (subscriptionType?['monthlyPrice'] != null)
            _buildInfoRow(
              Icons.euro,
              'Prix mensuel',
              '${subscriptionType!['monthlyPrice']} €',
            ),
          
          const SizedBox(height: 12),
          
          // Dates
          _buildInfoRow(
            Icons.calendar_today,
            'Début',
            _formatDate(startDate),
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoRow(
            Icons.event,
            'Fin',
            _formatDate(endDate),
          ),
          
          const SizedBox(height: 12),
          
          // Renouvellement automatique
          _buildInfoRow(
            Icons.autorenew,
            'Renouvellement auto',
            autoRenew ? 'Oui' : 'Non',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFe89547), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsList() {
    if (_subscriptionDetails == null) return const SizedBox();
    
    // Les paiements sont dans subscription.payments, pas à la racine
    final subscription = _subscriptionDetails!['subscription'] as Map<String, dynamic>?;
    final payments = subscription?['payments'] as List<dynamic>? ?? [];
    
    print('Nombre de paiements trouvés: ${payments.length}');
    
    if (payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(
                Icons.payment_outlined,
                color: Colors.white60,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun paiement',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: payments.map((payment) {
        final paymentMap = payment as Map<String, dynamic>;
        return _buildPaymentCard(paymentMap);
      }).toList(),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] as String? ?? 'unknown';
    final amount = payment['amount'] as num? ?? 0;
    final dueDate = payment['dueDate'] as String?;
    final paymentDate = payment['paymentDate'] as String?;
    final description = payment['description'] as String? ?? '';
    final subscription = _subscriptionDetails?['subscription'] as Map<String, dynamic>?;
    final subscriptionStatus = subscription?['status'] as String? ?? '';
    
    // On peut acquitter si le paiement est en attente et l'abonnement est actif OU pending
    // (l'API activera automatiquement l'abonnement lors du premier paiement)
    final canAcknowledge = status == 'pending' && 
        (subscriptionStatus == 'active' || subscriptionStatus == 'pending');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2d3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getPaymentStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Montant et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$amount €',
                  style: const TextStyle(
                    color: Color(0xFFe89547),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getPaymentStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getPaymentStatusLabel(status),
                    style: TextStyle(
                      color: _getPaymentStatusColor(status),
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
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Date d'échéance
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white60, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Échéance: ${_formatDate(dueDate)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            
            if (paymentDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Payé le: ${_formatDate(paymentDate)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            // Bouton acquitter pour les paiements en attente
            if (canAcknowledge) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acknowledgePayment(payment),
                  icon: const Icon(Icons.check),
                  label: const Text('Acquitter le paiement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

class _PaymentMethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PaymentMethodOption({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f2e),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFe89547)),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
