import 'package:url_launcher/url_launcher.dart';

class AlertService {
  /// Sends a WhatsApp message to [phone] with [message].
  /// [phone] must be in international format without '+', e.g. '27821234567'.
  static Future<bool> sendWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s+\-()]'), '');
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$cleaned?text=$encoded');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens the native SMS app pre-filled with [phone] and [message].
  static Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$encoded');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Sends both WhatsApp and SMS to all [contacts].
  static Future<void> alertAll({
    required List<String> contacts,
    required String message,
  }) async {
    for (final contact in contacts) {
      await sendWhatsApp(phone: contact, message: message);
      await sendSms(phone: contact, message: message);
    }
  }

  // ── Pre-built message templates ──────────────────────────────────────────

  static String trackingStarted({
    required String name,
    required String from,
    required String to,
  }) =>
      '🛡️ GBV Safe Hub Alert\n\n$name has started a journey from $from to $to and has activated Live Safe Tracking.\n\nThey will check in at regular intervals. You will be notified if they miss a check-in.\n\n_This is an automated safety alert._';

  static String checkpointMissed({
    required String name,
    required String checkpoint,
  }) =>
      '⚠️ MISSED CHECK-IN — GBV Safe Hub\n\n$name missed the "$checkpoint" safety checkpoint.\n\nPlease check on them immediately and contact emergency services if needed.\n\n📞 Emergency: 10111\n\n_This is an automated safety alert._';

  static String arrivedSafely({
    required String name,
    required String destination,
  }) =>
      '✅ Safe Arrival — GBV Safe Hub\n\n$name has arrived safely at $destination.\n\nNo further action needed.\n\n_This is an automated safety alert._';

  static String sosAlert({
    required String name,
    required String? location,
  }) =>
      '🚨 SOS EMERGENCY — GBV Safe Hub\n\n$name has triggered an emergency SOS alert!\n\n${location != null ? '📍 Last known location: $location\n\n' : ''}Please contact emergency services immediately.\n\n📞 Emergency: 10111\n📞 GBV Helpline: 0800 428 428\n\n_This is an automated safety alert._';

  static String eHailingTracking({
    required String name,
    required String destination,
  }) =>
      '🚗 E-Hailing Safe Tracker — GBV Safe Hub\n\n$name has activated e-hailing tracking for a ride to $destination.\n\nYou are listed as a Guardian Angel. You will receive updates on booking, arrival, and drop-off.\n\n_This is an automated safety alert._';
}
