import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../auth/login_screen.dart';

/// Enveloppe les écrans d'accueil (membre, coach, admin) : la session est
/// revérifiée auprès du serveur à chaque retour au premier plan (l'app
/// reprise depuis l'arrière-plan ne repasse pas par le splash) et à chaque
/// changement de réseau.
/// - serveur injoignable → bandeau « Hors ligne », données du cache ;
/// - jeton refusé (401/403) → purge de la session et retour au login.
class SessionGuard extends StatefulWidget {
  final Widget child;

  const SessionGuard({super.key, required this.child});

  /// Revérifie la session et applique le résultat (bandeau ou déconnexion).
  static Future<SessionCheck> check(BuildContext context) async {
    final check = await AuthService(ApiService.fromEnv()).validateSession();
    if (check == SessionCheck.invalid && context.mounted) {
      await expire(context);
    }
    return check;
  }

  /// Session refusée par le serveur : même sortie qu'une déconnexion.
  static Future<void> expire(BuildContext context) async {
    final auth = AuthService(ApiService.fromEnv());
    await auth.clearProfileCache();
    await auth.clearAll();
    AuthService.serverReachable.value = true;
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(fromLogout: true)),
      (route) => false,
    );
  }

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  static const _minInterval = Duration(seconds: 15);

  late final AppLifecycleListener _lifecycle;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  DateTime? _lastCheck;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (_) => _check(),
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _onResume() {
    final last = _lastCheck;
    if (last != null && DateTime.now().difference(last) < _minInterval) return;
    _check();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    _lastCheck = DateTime.now();
    try {
      if (mounted) await SessionGuard.check(context);
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.serverReachable,
      builder: (context, reachable, child) {
        if (reachable) return child!;
        return Column(
          children: [
            _OfflineBanner(onRetry: _check),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child!,
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.warning,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.black87, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Hors ligne — données affichées depuis le cache',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: Colors.black87),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
