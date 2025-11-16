import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService.fromEnv();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isError ? Colors.white : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: screenHeight - 200,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.resetPassword(
        widget.email,
        _tokenController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar('Mot de passe réinitialisé avec succès');
        
        // Navigate to login screen after a short delay
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        final errorMsg = result['error'] ?? 'Erreur lors de la réinitialisation';
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erreur réseau: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icon
                          Icon(
                            Icons.lock_open,
                            size: 80,
                            color: const Color(0xFFe89547),
                          ),
                          const SizedBox(height: 32),
                          
                          // Title
                          const Text(
                            'Réinitialiser le mot de passe',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Subtitle with email
                          Text(
                            'Code envoyé à ${widget.email}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          // Token field (6 digits)
                          TextFormField(
                            controller: _tokenController,
                            keyboardType: TextInputType.number,
                            enabled: !_isLoading,
                            maxLength: 6,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Code de vérification',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              hintText: '000000',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                letterSpacing: 8,
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFe89547), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le code';
                              }
                              if (value.length != 6) {
                                return 'Le code doit contenir 6 chiffres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // New password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !_isLoading,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Nouveau mot de passe',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFFe89547)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFe89547), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Le mot de passe doit contenir au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            enabled: !_isLoading,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirmer le mot de passe',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFe89547)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFe89547), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez confirmer le mot de passe';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Submit button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitReset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe89547),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Réinitialiser',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
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
}
