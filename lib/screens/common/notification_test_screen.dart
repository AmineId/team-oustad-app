import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/common/glass.dart';
import '../../core/theme/theme.dart';

/// Écran de test et démonstration des notifications
class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      extendBodyBehindAppBar: glassExtendsBody,
      appBar: glassAppBar(
        context,
        title: const Text(
          'Test Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: appBackgroundDecoration(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            final isWatch = constraints.maxWidth < 300;
            final padding = isWatch ? 8.0 : (isDesktop ? 24.0 : 16.0);
            
            Widget content = ListView(
              padding: EdgeInsets.fromLTRB(padding, MediaQuery.of(context).padding.top + (glassExtendsBody ? kToolbarHeight : 0) + padding, padding, padding),
          children: [
            // Notification immédiate
            _buildNotificationCard(
              context,
              icon: Icons.notifications,
              title: 'Notification immédiate',
              description: 'Afficher une notification tout de suite',
              onTap: () async {
                await notificationService.showNotification(
                  id: 1,
                  title: 'Test Notification',
                  body: 'Ceci est une notification de test !',
                );
                if (!context.mounted) return;
                _showSnackBar(context, 'Notification envoyée !');
              },
            ),

            const SizedBox(height: 12),

            // Notification planifiée
            _buildNotificationCard(
              context,
              icon: Icons.schedule,
              title: 'Notification dans 10 secondes',
              description: 'Planifier une notification pour dans 10 secondes',
              onTap: () async {
                final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
                await notificationService.scheduleNotification(
                  id: 2,
                  title: 'Notification planifiée',
                  body: 'Cette notification était planifiée il y a 10 secondes',
                  scheduledDate: scheduledTime,
                );
                if (!context.mounted) return;
                _showSnackBar(context, 'Notification planifiée pour dans 10 secondes');
              },
            ),

            const SizedBox(height: 12),

            // Rappel de paiement
            _buildNotificationCard(
              context,
              icon: Icons.payment,
              title: 'Rappel de paiement',
              description: 'Simuler un rappel de paiement',
              onTap: () async {
                await notificationService.schedulePaymentReminder(
                  paymentId: 123,
                  memberName: 'Jean Dupont',
                  amount: 49.99,
                  dueDate: DateTime.now().add(const Duration(days: 3)),
                );
                if (!context.mounted) return;
                _showSnackBar(context, 'Rappel de paiement planifié');
              },
            ),

            const SizedBox(height: 12),

            // Nouveau planning
            _buildNotificationCard(
              context,
              icon: Icons.fitness_center,
              title: 'Nouveau planning',
              description: 'Notification de nouveau planning créé',
              onTap: () async {
                await notificationService.notifyNewPlanning(
                  memberId: 456,
                  memberName: 'Marie Martin',
                  planningTitle: 'Programme Full Body',
                );
                if (!context.mounted) return;
                _showSnackBar(context, 'Notification de planning envoyée');
              },
            ),

            const SizedBox(height: 12),

            // Rappel d'entraînement
            _buildNotificationCard(
              context,
              icon: Icons.alarm,
              title: 'Rappel d\'entraînement',
              description: 'Planifier un rappel pour demain matin',
              onTap: () async {
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                final reminderTime = DateTime(
                  tomorrow.year,
                  tomorrow.month,
                  tomorrow.day,
                  8, // 8h du matin
                  0,
                );
                await notificationService.scheduleWorkoutReminder(
                  memberId: 789,
                  workoutDay: 'Jour de jambes',
                  reminderTime: reminderTime,
                );
                if (!context.mounted) return;
                _showSnackBar(context, 'Rappel d\'entraînement planifié pour demain 8h');
              },
            ),

                const SizedBox(height: 24),

                // Actions
                isWatch
                    ? Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final pending = await notificationService.getPendingNotifications();
                              if (!context.mounted) return;
                              _showDialog(
                                context,
                                'Notifications en attente',
                                'Nombre: ${pending.length}\n\n${pending.map((n) => '- ${n.title}').join('\n')}',
                              );
                            },
                            icon: const Icon(Icons.list, size: 16),
                          label: const Text('Voir en attente', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).cardTheme.color,
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await notificationService.cancelAllNotifications();
                              if (!context.mounted) return;
                              _showSnackBar(context, 'Toutes les notifications annulées');
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Tout annuler', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final pending = await notificationService.getPendingNotifications();
                                if (!context.mounted) return;
                                _showDialog(
                                  context,
                                  'Notifications en attente',
                                  'Nombre: ${pending.length}\n\n${pending.map((n) => '- ${n.title}').join('\n')}',
                                );
                              },
                              icon: const Icon(Icons.list),
                              label: const Text('Voir en attente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).cardTheme.color,
                                foregroundColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await notificationService.cancelAllNotifications();
                                if (!context.mounted) return;
                                _showSnackBar(context, 'Toutes les notifications annulées');
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Tout annuler'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            );
            
            // Desktop: center content with max width
            if (isDesktop) {
              content = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: content,
                ),
              );
            }
            
            return content;
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    String? body,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWatch = constraints.maxWidth < 300;
        final padding = isWatch ? 8.0 : 16.0;
        final iconSize = isWatch ? 20.0 : 28.0;
        final iconPadding = isWatch ? 8.0 : 12.0;
        final titleSize = isWatch ? 12.0 : 16.0;
        final descSize = isWatch ? 10.0 : 14.0;
        
        return Card(
          color: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWatch ? 8 : 12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isWatch ? 8 : 12),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isWatch ? 8 : 12),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: isWatch ? 8 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body ?? description,
                          style: TextStyle(
                            color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            fontSize: descSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: isWatch ? 12 : 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          title,
          style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        ),
        content: Text(
          content,
          style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}





