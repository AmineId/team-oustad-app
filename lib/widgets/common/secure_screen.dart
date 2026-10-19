import 'package:flutter/widgets.dart';

import '../../core/services/screen_security_service.dart';

/// Empêche les captures d'écran tant que ce widget est monté.
class SecureScreen extends StatefulWidget {
  final Widget child;

  const SecureScreen({super.key, required this.child});

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    ScreenSecurityService.acquire();
  }

  @override
  void dispose() {
    ScreenSecurityService.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
