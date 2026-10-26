import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../auth/login_screen.dart';

/// Enveloppe les écrans d'accueil (membre, coach, admin) : la session est
/// surveillée en permanence : à l'ouverture, toutes les 30 s au premier
/// plan, à chaque reprise (l'app reprise depuis l'arrière-plan ne repasse
/// pas par le splash) et à chaque changement de réseau.
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
  static const _pollInterval = Duration(seconds: 30);

  late final AppLifecycleListener _lifecycle;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _poll;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: _startPolling,
      onPause: _stopPolling,
    );
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (_) {},
    );
    _startPolling();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _connectivitySub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  /// Vérification immédiate puis toutes les [_pollInterval] tant que l'app
  /// est au premier plan.
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => _check());
    _check();
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // Plus aucun réseau : bandeau tout de suite, sans attendre le délai
    // d'expiration de la requête.
    if (_noNetwork(results)) {
      AuthService.serverReachable.value = false;
      return;
    }
    _check();
  }

  static bool _noNetwork(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      List<ConnectivityResult>? network;
      try {
        network = await Connectivity().checkConnectivity();
      } catch (_) {
        network = null; // statut inconnu : on interroge le serveur
      }
      if (network != null && _noNetwork(network)) {
        AuthService.serverReachable.value = false;
      } else if (mounted) {
        await SessionGuard.check(context);
      }
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
