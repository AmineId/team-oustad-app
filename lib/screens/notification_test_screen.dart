import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Écran de test et démonstration des notifications
class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Test Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1f2e),
              Color(0xFF2d3748),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
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
                _showSnackBar(context, 'Rappel d\'entraînement planifié pour demain 8h');
              },
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
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
                      backgroundColor: const Color(0xFF2d3748),
                      foregroundColor: Colors.white,
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
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    return Card(
      color: const Color(0xFF2d3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFe89547).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFe89547),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body ?? description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFe89547),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFe89547),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFe89547)),
            ),
          ),
        ],
      ),
    );
  }
}
