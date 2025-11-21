import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _apiService = ApiService.fromEnv();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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
            color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
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

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.forgotPassword(_emailController.text.trim());

      if (!mounted) return;

      if (success) {
        _showSnackBar('Code de réinitialisation envoyé par email');
        
        // Navigate to reset password screen after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        _showSnackBar('Erreur lors de l\'envoi du code', isError: true);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [theme.scaffoldBackgroundColor, theme.cardTheme.color!]
                : [theme.scaffoldBackgroundColor, theme.cardTheme.color!],
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
                      icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge!.color),
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
                            Icons.lock_reset,
                            size: 80,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 32),
                          
                          // Title
                          Text(
                            'Mot de passe oublié',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h2.copyWith(
                              color: theme.textTheme.bodyLarge!.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Subtitle
                          Text(
                            'Entrez votre email pour recevoir un code de réinitialisation',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                              prefixIcon: const Icon(Icons.email, color: AppColors.primary),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary).withValues(alpha: 0.1) : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Submit button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
                                    'Envoyer le code',
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





