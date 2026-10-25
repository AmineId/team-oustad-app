import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/l10n/app_localizations.dart';
import '../auth/login_screen.dart';

/// Accueil coach. Provisoire : l'espace coach (membres, séances, check-ins
/// du jour) arrive dans les prochaines tranches Rôles V2 ; en attendant un
/// coach n'atterrit ni dans l'espace gestion ni dans l'espace membre.
class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService(ApiService.fromEnv());
    await authService.clearProfileCache();
    await authService.clearAll();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(fromLogout: true),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coachRole),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.disconnect,
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.coachSpaceSoon,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
