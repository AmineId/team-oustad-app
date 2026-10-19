import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_version_service.dart';
import '../../core/theme/theme.dart';

/// Signale qu'une nouvelle version est disponible.
/// Android : bouton vers le Play Store. Autres plateformes : message seul.
/// Une mise à jour obligatoire ne bloque l'app que là où elle est installable
/// (le serveur force toujours sur le canal beta : sans store, l'utilisateur
/// serait bloqué sans issue).
Future<void> showUpdateAvailableDialog(BuildContext context, UpdateInfo info) {
  final blocking = info.forceUpdate && AppVersionService.canOpenStore;
  return showDialog(
    context: context,
    barrierDismissible: !blocking,
    builder: (context) => PopScope(
      canPop: !blocking,
      child: _UpdateAvailableDialog(info: info, blocking: blocking),
    ),
  );
}

class _UpdateAvailableDialog extends StatelessWidget {
  final UpdateInfo info;
  final bool blocking;

  const _UpdateAvailableDialog({required this.info, required this.blocking});

  String get _installHint {
    if (AppVersionService.canOpenStore) {
      return 'Installez-la depuis le Play Store.';
    }
    if (kIsWeb) return 'Rechargez la page pour obtenir la dernière version.';
    return 'Contactez votre salle pour installer la nouvelle version.';
  }

  Future<void> _openStore(BuildContext context) async {
    final opened = await AppVersionService().openStore();
    if (!context.mounted) return;
    if (opened) {
      if (!blocking) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le Play Store'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.system_update,
              color: AppColors.info,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mise à jour disponible',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${info.currentVersion} → ${info.latestVersion}',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.forceUpdate)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette mise à jour est obligatoire',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Nouveautés :',
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.changelog,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              _installHint,
              style: TextStyle(color: textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        if (!blocking)
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              AppVersionService.canOpenStore ? 'Plus tard' : 'OK',
              style: TextStyle(color: textSecondary, fontSize: 16),
            ),
          ),
        if (AppVersionService.canOpenStore)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => _openStore(context),
            child: const Text('Mettre à jour', style: TextStyle(fontSize: 16)),
          ),
      ],
    );
  }
}
