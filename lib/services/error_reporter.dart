import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

/// ErrorReporter tries to send errors to your backend (which can forward to
/// an email). If the backend is unreachable, it falls back to opening the
/// user's mail client with a prefilled mailto: containing the error.
class ErrorReporter {
  final ApiService _apiService;
  final String supportEmail;

  ErrorReporter(this._apiService, {required this.supportEmail});

  /// Try to send error to backend; if it fails, open mail client as fallback.
  Future<void> report(Exception error, StackTrace? stack, {String? context}) async {
    final message = '${error.toString()}${context != null ? '\nContext: $context' : ''}';
    final stackStr = stack?.toString();

    try {
      final sent = await _apiService.reportError(message, stackStr, extra: {'context': context});
      if (sent) return;
    } catch (_) {
      // fall through to mailto fallback
    }

    // Fallback: open mail client with prefilled body so developer can receive the error.
    final subject = Uri.encodeComponent('Crash report: Team Fitness App');
    final body = Uri.encodeComponent('Error:\n$message\n\nStack:\n${stackStr ?? "(no stack)"}');
    final mailto = Uri(scheme: 'mailto', path: supportEmail, query: 'subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(mailto)) await launchUrl(mailto);
    } catch (_) {
      // give up silently
    }
  }
}
