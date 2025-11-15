import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SetupPasswordScreen extends StatefulWidget {
  const SetupPasswordScreen({super.key});

  @override
  State<SetupPasswordScreen> createState() => _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends State<SetupPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService.fromEnv();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setupPassword() async {
    // Validation
    if (_emailController.text.trim().isEmpty) {
      _showError('Veuillez entrer votre email');
      return;
    }

    if (_tokenController.text.trim().isEmpty) {
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
            backgroundColor: Colors.green,
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
        backgroundColor: Colors.red,
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
            colors: [
              const Color(0xFF1a1f2e),
              const Color(0xFF2d3748),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
              
              Widget content = SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bouton retour
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                        color: Colors.white,
                      ),
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez votre mot de passe avec le code reçu par email',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        color: Colors.white70,
                      ),
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Champ Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'votre.email@example.com',
                        prefixIcon: Icon(Icons.email, color: Color(0xFFe89547)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ Code
                    TextField(
                      controller: _tokenController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        labelText: 'Code reçu par email',
                        hintText: '123456',
                        prefixIcon: Icon(Icons.password, color: Color(0xFFe89547)),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ Mot de passe
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        hintText: 'Minimum 6 caractères',
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFFe89547)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
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
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFe89547)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                        color: const Color(0xFFe89547).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFe89547).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFe89547),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vous avez reçu un code à 6 chiffres par email. Ce code est valide pendant 1 heure.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
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
