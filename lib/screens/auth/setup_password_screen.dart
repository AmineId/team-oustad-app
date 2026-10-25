import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';
import 'forgot_password_screen.dart';

class SetupPasswordScreen extends StatefulWidget {
  const SetupPasswordScreen({super.key});

  @override
  State<SetupPasswordScreen> createState() => _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends State<SetupPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ApiService _apiService = ApiService.fromEnv();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingPhone = false;
  bool? _phoneExists;

  bool get _isPhoneNumber =>
      !_emailController.text.contains('@') &&
      _emailController.text.trim().isNotEmpty;
  bool get _isEmail => _emailController.text.contains('@');

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkPhoneNumber() async {
    final phoneNumber = _emailController.text.trim();

    if (phoneNumber.isEmpty) {
      _showError('Veuillez entrer un numéro de téléphone');
      return;
    }

    setState(() => _isCheckingPhone = true);

    try {
      final result = await _apiService.checkPhone(phoneNumber);

      if (!mounted) return;

      setState(() => _isCheckingPhone = false);

      if (result['success'] != true) {
        _showError('Une erreur est survenue. Veuillez réessayer.');
        return;
      }

      final exists = result['exists'] as bool? ?? false;
      final hasPassword = result['hasPassword'] as bool? ?? false;

      if (exists && hasPassword) {
        // Cas 1: Le numéro existe et a déjà un mot de passe
        // Rediriger vers l'écran de changement de mot de passe (forgot password)
        setState(() => _phoneExists = true);

        if (!mounted) return;

        // Afficher un message d'information
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Ce numéro a déjà un mot de passe. Redirection vers la réinitialisation...',
            ),
            backgroundColor: context.palette.primaryFill,
            duration: const Duration(seconds: 2),
          ),
        );

        // Attendre un peu puis rediriger
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        // Rediriger vers l'écran de mot de passe oublié
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
        );
      } else if (!exists && !hasPassword) {
        // Cas 2: Le numéro n'existe pas
        // Afficher un message pour passer à la salle
        setState(() => _phoneExists = false);

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store,
                      color: context.palette.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Compte non trouvé',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ce numéro de téléphone n\'est pas encore enregistré dans notre système.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
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
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.palette.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Merci de passer à notre salle pour créer votre compte.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.palette.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Compris',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      } else if (exists && !hasPassword) {
        // Cas 3: Le numéro existe mais n'a pas encore de mot de passe
        // Permettre de continuer avec la configuration
        setState(() => _phoneExists = true);

        final user = result['user'] as Map<String, dynamic>?;
        final userName = user != null ? getUserFullName(user) : 'Utilisateur';

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Compte trouvé: $userName. Vous pouvez configurer votre mot de passe.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingPhone = false);
      _showError('Une erreur est survenue. Veuillez réessayer.');
    }
  }

  Future<void> _setupPassword() async {
    // Validation
    if (_emailController.text.trim().isEmpty) {
      _showError(
        _isPhoneNumber
            ? 'Veuillez entrer votre numéro de téléphone'
            : 'Veuillez entrer votre email',
      );
      return;
    }

    // Si c'est un numéro de téléphone, vérifier qu'il existe et qu'il n'a pas déjà de mot de passe
    if (_isPhoneNumber) {
      if (_phoneExists != true) {
        _showError(
          'Veuillez d\'abord vérifier le numéro en cliquant sur l\'icône de recherche',
        );
        return;
      }
      // Note: Si hasPassword était true, l'utilisateur aurait été redirigé lors de la vérification
    }

    if (_isEmail && _tokenController.text.trim().isEmpty) {
      _showError('Veuillez entrer le code reçu par email');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Veuillez entrer un mot de passe');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.setupPassword(
        _emailController.text.trim(),
        _tokenController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe créé avec succès'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Retour à l'écran de login après 1 seconde
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showError(response['error'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Une erreur est survenue';
      if (e.toString().contains('Token invalide')) {
        errorMessage = 'Code invalide ou expiré';
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'Utilisateur non trouvé';
      } else if (e.toString().contains('Le mot de passe doit')) {
        errorMessage = 'Le mot de passe doit contenir au moins 6 caractères';
      }

      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).cardTheme.color!,
                  ]
                : [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).cardTheme.color!,
                  ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isTablet =
                  constraints.maxWidth > 600 && constraints.maxWidth <= 900;

              Widget content = SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bouton retour
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Logo
                    if (!isDesktop) ...[
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Titre
                    Text(
                      'Première connexion',
                      style: TextStyle(
                        fontSize: isDesktop ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                      ),
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEmail
                          ? 'Créez votre mot de passe avec le code reçu par email'
                          : 'Créez votre mot de passe avec votre numéro de téléphone',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                      ),
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Champ Email/Téléphone
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                        fontSize: 16,
                      ),
                      onChanged: (_) {
                        setState(() {
                          _phoneExists = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Email ou Numéro de téléphone',
                        hintText: _isEmail
                            ? 'votre.email@example.com'
                            : '+33612345678',
                        prefixIcon: Icon(
                          _isEmail ? Icons.email : Icons.phone,
                          color: context.palette.primary,
                        ),
                        suffixIcon: _isPhoneNumber
                            ? IconButton(
                                icon: _phoneExists == true
                                    ? Icon(
                                        Icons.check_circle,
                                        color: context.palette.success,
                                      )
                                    : Icon(
                                        Icons.search,
                                        color: context.palette.primary,
                                      ),
                                onPressed: _isCheckingPhone
                                    ? null
                                    : _checkPhoneNumber,
                              )
                            : null,
                      ),
                    ),
                    if (_isCheckingPhone) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Vérification...',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (_isPhoneNumber && _phoneExists == true) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: context.palette.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Numéro vérifié',
                              style: TextStyle(
                                color: context.palette.success,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Champ Code (uniquement pour email)
                    if (_isEmail) ...[
                      TextField(
                        controller: _tokenController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        maxLength: 6,
                        style: TextStyle(
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Code reçu par email',
                          hintText: '123456',
                          prefixIcon: Icon(
                            Icons.password,
                            color: context.palette.primary,
                          ),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ], // Champ Mot de passe
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        hintText: 'Minimum 6 caractères',
                        prefixIcon: Icon(
                          Icons.lock,
                          color: context.palette.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Confirmation
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: context.palette.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                          ),
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                        ),
                      ),
                      onSubmitted: (_) => _setupPassword(),
                    ),
                    const SizedBox(height: 32),

                    // Bouton valider
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _setupPassword,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Créer mon mot de passe',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info
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
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: context.palette.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isEmail
                                  ? 'Vous avez reçu un code à 6 chiffres par email. Ce code est valide pendant 1 heure.'
                                  : 'Entrez votre numéro de téléphone et cliquez sur "Vérifier" pour confirmer qu\'il existe dans la base de données.',
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (isDesktop || isTablet) {
                content = Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 500 : 600,
                    ),
                    child: content,
                  ),
                );
              }

              return content;
            },
          ),
        ),
      ),
    );
  }
}
