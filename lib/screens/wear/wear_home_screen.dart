import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wear/wear.dart';
import '../../core/theme/theme.dart';
import '../../widgets/platform/watch_widgets.dart';
import 'wear_planning_screen.dart';
import 'wear_qr_screen.dart';

class WearHomeScreen extends StatefulWidget {
  final WearShape shape;

  const WearHomeScreen({super.key, required this.shape});

  @override
  State<WearHomeScreen> createState() => _WearHomeScreenState();
}

class _WearHomeScreenState extends State<WearHomeScreen> {
  static const _channel = MethodChannel('team.oustad.watch');

  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'updateData' && call.arguments is Map) {
        setState(() => _data = Map<String, dynamic>.from(call.arguments as Map));
      }
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await _channel.invokeMethod<Map>('getLastSyncData');
      if (result != null && mounted) {
        setState(() => _data = Map<String, dynamic>.from(result));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildStatusPage(),
      WearPlanningScreen(data: _data),
      WearQRScreen(data: _data),
    ];

    return AmbientMode(
      builder: (context, mode, _) => Scaffold(
        backgroundColor: mode == WearMode.active
            ? AppColors.darkBackground
            : Colors.black,
        body: PageView(children: pages),
      ),
    );
  }

  Widget _buildStatusPage() {
    final isRound = widget.shape == WearShape.round;
    final status = _data['subscriptionStatus'] as String? ?? '';
    final gymName = _data['gymName'] as String? ?? 'Team Oustad';
    final userName = _data['userName'] as String? ?? '';
    final daysLeft = _data['daysLeft'] as int? ?? 0;

    if (userName.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.watch, color: context.palette.primary, size: 28),
            const SizedBox(height: 8),
            const Text(
              'Ouvrez Team\nOustad sur\nvotre téléphone',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isRound ? 18 : 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WatchHeader(title: gymName, subtitle: userName),
          const SizedBox(height: 8),
          WatchStatCard(
            icon: status == 'active'
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            title: 'Abonnement',
            value: status == 'active' ? '$daysLeft j' : 'Expiré',
            color:
                status == 'active' ? context.palette.success : context.palette.error,
          ),
        ],
      ),
    );
  }
}
