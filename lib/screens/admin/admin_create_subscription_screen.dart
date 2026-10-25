import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';

class AdminCreateSubscriptionScreen extends StatefulWidget {
  final int memberId;

  const AdminCreateSubscriptionScreen({
    super.key,
    required this.memberId,
  });

  @override
  State<AdminCreateSubscriptionScreen> createState() => _AdminCreateSubscriptionScreenState();
}

class _AdminCreateSubscriptionScreenState extends State<AdminCreateSubscriptionScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  
  List<Map<String, dynamic>> _subscriptionTypes = [];
  int? _selectedSubscriptionTypeId;
  bool _isLoading = true;
  bool _isCreating = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSubscriptionTypes();
  }

  Future<void> _loadSubscriptionTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final types = await _apiService.getSubscriptionTypes();
      debugPrint('🎯 Types d\'abonnement chargés: $types');
      
      if (types != null) {
        setState(() {
          _subscriptionTypes = types.map((t) => t as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossible de charger les types d\'abonnement';
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

  Future<void> _createSubscription() async {
    if (_selectedSubscriptionTypeId == null) {
      _showErrorDialog('Veuillez sélectionner un type d\'abonnement');
      return;
    }

    // ignore: avoid_print
    debugPrint('🎯 Création abonnement:');
    // ignore: avoid_print
    debugPrint('   - memberId: ${widget.memberId}');
    // ignore: avoid_print
    debugPrint('   - subscriptionTypeId: $_selectedSubscriptionTypeId');

    setState(() {
      _isCreating = true;
    });

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        setState(() {
          _isCreating = false;
        });
        _showErrorDialog('Token non disponible');
        return;
      }

      // ignore: avoid_print
      debugPrint('📤 Envoi de la requête API...');
      final result = await _apiService.createSubscription(
        widget.memberId,
        _selectedSubscriptionTypeId!,
        token,
      );

      // ignore: avoid_print
      debugPrint('📥 Réponse API: $result');

      if (!mounted) return;
      
      setState(() {
        _isCreating = false;
      });

      if (result != null) {
        // ignore: avoid_print
        debugPrint('✅ Abonnement créé avec succès');
        
        // Afficher un message de succès
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: context.palette.success),
                const SizedBox(width: 8),
                const Text(
                  'Succès',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: const Text(
              'L\'abonnement a été créé avec succès',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(color: context.palette.primary),
                ),
              ),
            ],
          ),
        );
        
        // Retourner à l'écran précédent
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        // ignore: avoid_print
        debugPrint('❌ Résultat null');
        _showErrorDialog('Erreur lors de la création de l\'abonnement');
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('❌ Exception: $e');
      setState(() {
        _isCreating = false;
      });
      _showErrorDialog('Erreur: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Row(
          children: [
            Icon(Icons.error, color: context.palette.error),
            const SizedBox(width: 8),
            const Text(
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
            child: Text(
              'OK',
              style: TextStyle(color: context.palette.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nouvel abonnement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: context.palette.primary,
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: context.palette.error,
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
                          onPressed: _loadSubscriptionTypes,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choisir un type d\'abonnement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Liste des types d'abonnement
                        if (_subscriptionTypes.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'Aucun type d\'abonnement disponible',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._subscriptionTypes.map((type) => _buildSubscriptionTypeCard(type)),
                        
                        const SizedBox(height: 24),
                        
                        // Bouton créer
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createSubscription,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.palette.primaryFill,
                              foregroundColor: context.palette.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: _isCreating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Créer l\'abonnement',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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

  Widget _buildSubscriptionTypeCard(Map<String, dynamic> type) {
    final id = type['id'] as int;
    final name = type['name'] as String? ?? 'Sans nom';
    final description = type['description'] as String? ?? '';
    final monthlyPrice = type['monthlyPrice'] as num? ?? 0;
    final features = type['features'] as List<dynamic>? ?? [];
    final isSelected = _selectedSubscriptionTypeId == id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected 
          ? AppColors.primary.withValues(alpha: 0.2)
          : Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected 
              ? context.palette.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSubscriptionTypeId = id;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom et icône de sélection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: context.palette.primary,
                      size: 28,
                    )
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 28,
                    ),
                ],
              ),
              
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Prix
              Text(
                '$monthlyPrice MAD / mois',
                style: TextStyle(
                  color: context.palette.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Caractéristiques
              if (features.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: context.palette.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature.toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


