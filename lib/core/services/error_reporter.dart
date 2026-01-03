import 'package:url_launcher/url_launcher.dart';

/// ErrorReporter opens the user's mail client with a prefilled mailto
/// containing the error details for developer review.
class ErrorReporter {
  final String supportEmail;

  ErrorReporter({required this.supportEmail});

  /// Open mail client with error details.
  Future<void> report(Exception error, StackTrace? stack, {String? context}) async {
    final message = '${error.toString()}${context != null ? '\nContext: $context' : ''}';
    final stackStr = stack?.toString();

    // Open mail client with prefilled body so developer can receive the error.
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



