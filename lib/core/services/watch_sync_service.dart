import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class WatchSyncService {
  static const _channel = MethodChannel('team.oustad.watch');

  static Future<void> syncMemberData({
    required String userName,
    required int memberId,
    required Map<String, dynamic>? subscriptionData,
    Map<String, dynamic>? todayPlanning,
    List<int>? qrImageBytes,
  }) async {
    try {
      final sub = subscriptionData?['subscription'] as Map<String, dynamic>?;
      final gym = subscriptionData?['gym'] as Map<String, dynamic>?;
      final endDateStr = subscriptionData?['endDate'] as String?;
      final status = subscriptionData?['status'] as String? ?? 'inactive';

      int daysLeft = 0;
      if (endDateStr != null) {
        try {
          final end = DateTime.parse(endDateStr);
          daysLeft = end.difference(DateTime.now()).inDays.clamp(0, 9999);
        } catch (_) {}
      }

      final qrBase64 = qrImageBytes != null && qrImageBytes.isNotEmpty
          ? base64Encode(qrImageBytes)
          : '';

      await _channel.invokeMethod('syncMemberData', {
        'userName': userName,
        'memberId': memberId,
        'subscriptionStatus': status,
        'subscriptionName': sub?['name'] as String? ?? '',
        'gymName': gym?['name'] as String? ?? '',
        'daysLeft': daysLeft,
        'expiresAt': endDateStr ?? '',
        'todayPlanningTitle': todayPlanning?['title'] as String? ?? '',
        'todayExercisesCount': todayPlanning?['exercisesCount'] as int? ?? 0,
        'qrBase64': qrBase64,
      });
    } catch (e) {
      debugPrint('WatchSyncService: error syncing — $e');
    }
  }

  /// Met à jour uniquement le QR sur la montre sans écraser les autres champs.
  /// Si aucune sync précédente n'existe, ne fait rien.
  static Future<void> updateQr(List<int> qrImageBytes) async {
    try {
      final existing = await getLastSyncData();
      if (existing == null) return;
      await _channel.invokeMethod('syncMemberData', {
        ...existing,
        'qrBase64': base64Encode(qrImageBytes),
      });
    } catch (e) {
      debugPrint('WatchSyncService: error updating QR — $e');
    }
  }

  static Future<Map<String, dynamic>?> getLastSyncData() async {
    try {
      final result = await _channel.invokeMethod<Map>('getLastSyncData');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (_) {
      return null;
    }
  }
}
