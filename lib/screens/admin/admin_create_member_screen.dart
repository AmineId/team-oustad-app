import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';

class AdminCreateMemberScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;

  const AdminCreateMemberScreen({super.key, this.onBack, this.onSuccess});

  @override
  State<AdminCreateMemberScreen> createState() =>
      _AdminCreateMemberScreenState();
}

class _AdminCreateMemberScreenState extends State<AdminCreateMemberScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _gymController = TextEditingController(
    text: 'Ma salle',
  );

  bool _isLoading = false;
  bool _isLoadingGym = true;
  bool _sendSetupEmail = true;
  bool _obscurePassword = true;
  int? _gymId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserGymId();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _gymController.dispose();
    super.dispose();
  }

  Future<void> _loadUserGymId() async {
    try {
      final token = await _authService.loadToken();
      if (token == null) {
        debugPrint('❌ Token non disponible');
        return;
      }

      debugPrint('🔍 Chargement de la salle admin...');

      // Récupérer la liste des salles (pour un admin, ce sera sa salle)
      final gyms = await _apiService.getGyms(token);

      debugPrint('📊 Gyms reçus: $gyms');

      if (gyms != null && gyms.isNotEmpty) {
        final gym = gyms.first as Map<String, dynamic>;
        final gymId = gym['id'] as int;
        final gymName = gym['name'] as String? ?? 'Ma salle';

        debugPrint('✅ Gym admin trouvé: $gymName (ID: $gymId)');

        if (mounted) {
          setState(() {
            _gymId = gymId;
            _gymController.text = gymName;
            _isLoadingGym = false;
          });
          debugPrint('✅ Controller mis à jour avec: ${_gymController.text}');
        }
      } else {
        debugPrint('⚠️ Aucune salle trouvée pour cet admin');
        // Fallback: essayer de récupérer depuis le profil
        final profile = await _authService.getCachedUserProfile();
        debugPrint('📊 Profil: $profile');
        if (profile != null) {
          final gymId = profile['gymId'] as int?;
          final gymData = profile['gym'];
          debugPrint('📊 GymId du profil: $gymId, Gym data: $gymData');
          if (mounted) {
            setState(() {
              _gymId = gymId;
              _isLoadingGym = false;
              if (gymData != null && gymData is Map) {
                _gymController.text = gymData['name'] ?? 'Ma salle';
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingGym = false;
            });
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors du chargement du gymId: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingGym = false;
        });
      }
    }
  }

  Future<void> _createMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    debugPrint(
      '🔍 Création membre - _isLoadingGym: $_isLoadingGym, _gymId: $_gymId',
    );

    if (_isLoadingGym) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement de la salle en cours...'),
          backgroundColor: AppColors.info,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_gymId == null) {
      debugPrint('❌ GymId est null!');
      setState(() {
        _errorMessage = 'Impossible de déterminer la salle de sport';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

      // Créer le membre
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final address = _addressController.text.trim();
      final password = _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null;
      // Envoyer l'email seulement si un email est fourni et pas de mot de passe
      final shouldSendEmail = email.isNotEmpty && password == null
          ? _sendSetupEmail
          : false;

      // ignore: avoid_print
      debugPrint('Création du membre: $firstName $lastName ($phone)');

      final result = await _apiService.createMember(
        email.isNotEmpty
            ? email
            : phone, // Utiliser le téléphone si pas d'email
        firstName,
        lastName,
        address,
        _gymId!,
        token,
        password: password,
        phone: phone,
        shouldSendSetupEmail: shouldSendEmail,
      );

      if (result != null) {
        if (!mounted) return;

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _emailController.text.isNotEmpty &&
                      _passwordController.text.isEmpty &&
                      _sendSetupEmail
                  ? 'Membre créé avec succès. Un email d\'activation a été envoyé.'
                  : 'Membre créé avec succès',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        // Retourner à l'écran précédent
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = 'Échec de la création du membre';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajouter un membre',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardTheme.color!,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Message d'erreur
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Icône d'en-tête
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.2),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),

                        Text(
                          'Nouveau membre',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Remplissez les informations du membre',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.color,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Salle (lecture seule)
                        TextFormField(
                          controller: _gymController,
                          enabled: false,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Salle de sport',
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                            ),
                            prefixIcon: const Icon(
                              Icons.fitness_center,
                              color: AppColors.primary,
                            ),
                            suffixIcon: _isLoadingGym
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).cardTheme.color!.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Numéro de téléphone (obligatoire)
                        TextFormField(
                          controller: _phoneController,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Numéro de téléphone *',
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Numéro de téléphone requis';
                            }
                            // Validation basique du format
                            if (!RegExp(
                              r'^\+?[0-9\s\-\(\)]+$',
                            ).hasMatch(value.trim())) {
                              return 'Numéro de téléphone invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email (optionnel)
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email (optionnel)',
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                            ),
                            hintText: 'Pour recevoir l\'email de configuration',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .color!
                                  .withValues(alpha: 0.5),
                            ),
                            prefixIcon: const Icon(
                              Icons.email,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            // Email optionnel, mais s'il est fourni, il doit être valide
                            if (value != null &&
                                value.isNotEmpty &&
                                !value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Prénom
                        TextFormField(
                          controller: _firstNameController,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Prénom *',
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                            ),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Prénom requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Nom de famille
                        TextFormField(
                          controller: _lastNameController,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nom de famille *',
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nom de famille requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Adresse
                        TextFormField(
                          controller: _addressController,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Adresse *',
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                            ),
                            prefixIcon: const Icon(
                              Icons.home,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Adresse requise';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Mot de passe (optionnel)
                        TextFormField(
                          controller: _passwordController,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe (optionnel)',
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.color,
                            ),
                            hintText: 'Laisser vide pour envoyer un email',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .color!
                                  .withValues(alpha: 0.5),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: AppColors.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white60,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Option d'envoi d'email
                        if (_passwordController.text.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _sendSetupEmail,
                                  onChanged: (value) {
                                    setState(() {
                                      _sendSetupEmail = value ?? true;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.all(
                                    AppColors.primary,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Envoyer un email de configuration',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Le membre recevra un email avec un lien pour créer son mot de passe',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Info box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '* Champs requis\n\nLe numéro de téléphone est obligatoire. L\'email est optionnel mais nécessaire pour envoyer l\'email de configuration.\n\nSi vous ne fournissez pas de mot de passe et qu\'un email est fourni, le membre recevra un email pour créer son mot de passe.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Boutons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _createMember,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Créer le membre',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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
                ),
        ),
      ),
    );
  }
}
