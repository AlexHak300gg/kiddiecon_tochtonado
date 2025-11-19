import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:untitled12/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> dailyInterestAlarmCallback() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await DailyInterestService.processDailyInterestForAllChildren();
  } catch (e) {
    debugPrint('AlarmManager task error: $e');
  }
}

class DailyInterestService {
  static const Duration _repeatInterval = Duration(minutes: 45);
  static const int _alarmId = 1017;
  static Timer? _fallbackTimer;

  static Future<void> initialize() async {
    if (_supportsAlarmManager) {
      try {
        final initialized = await AndroidAlarmManager.initialize();
        if (initialized) {
          await _registerPeriodicTask();
          return;
        }
        debugPrint('AndroidAlarmManager initialize returned false, enabling fallback timer');
      } catch (e) {
        debugPrint('AndroidAlarmManager init failed: $e');
      }
    }

    _startFallbackTimer();
  }

  static bool get _supportsAlarmManager {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> _registerPeriodicTask() async {
    _stopFallbackTimer();
    await AndroidAlarmManager.cancel(_alarmId);

    final scheduled = await AndroidAlarmManager.periodic(
      _repeatInterval,
      _alarmId,
      dailyInterestAlarmCallback,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
      wakeup: true,
      exact: false,
    );

    if (!scheduled) {
      debugPrint('Unable to schedule alarm manager task, falling back to in-app timer');
      _startFallbackTimer();
    }
  }

  static void _startFallbackTimer() {
    _stopFallbackTimer();
    _fallbackTimer = Timer.periodic(_repeatInterval, (_) async {
      try {
        await processDailyInterestForAllChildren();
      } catch (e) {
        debugPrint('Fallback timer task error: $e');
      }
    });
  }

  static void _stopFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  static Future<void> processDailyInterestForAllChildren() async {
    final db = FirebaseDatabase.instance.ref();

    try {
      // Get all children
      final childrenSnapshot = await db.child('children').get();
      if (!childrenSnapshot.exists || childrenSnapshot.value == null) {
        return;
      }

      final children = Map<String, dynamic>.from(childrenSnapshot.value as Map);

      // Process each child
      for (final entry in children.entries) {
        final childId = entry.key.toString();
        try {
          final childData = Map<String, dynamic>.from(entry.value as Map);

          // Check if child has an account
          if (childData.containsKey('account')) {
            final accountData = Map<String, dynamic>.from(childData['account'] as Map);
            final lastCalculatedAt = _parseDateTime(accountData['lastCalculatedAt']);
            final today = DateTime.now();
            final todayStart = DateTime(today.year, today.month, today.day);

            // Only calculate if last calculated date is before today
            if (lastCalculatedAt == null || lastCalculatedAt.isBefore(todayStart)) {
              await _calculateInterestForChild(childId);
            }
          }
        } catch (e) {
          debugPrint('Error processing child $childId: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in _processDailyInterestForAllChildren: $e');
    }
  }

  static Future<void> _calculateInterestForChild(String childId) async {
    final db = FirebaseDatabase.instance.ref();
    final accountRef = db.child('children/$childId/account');
    final historyRef = db.child('children/$childId/history');

    try {
      final accountSnapshot = await accountRef.get();
      if (!accountSnapshot.exists || accountSnapshot.value == null) {
        return;
      }

      final accountData = Map<String, dynamic>.from(accountSnapshot.value as Map);
      final balance = _toDouble(accountData['balance']);
      double dailyRate = _toDouble(accountData['dailyRate']);
      if (dailyRate == 0.0) {
        dailyRate = 0.0001; // Default rate
      }
      final lastCalculatedAt = _parseDateTime(accountData['lastCalculatedAt']);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCalculatedDay = lastCalculatedAt != null
          ? DateTime(lastCalculatedAt.year, lastCalculatedAt.month, lastCalculatedAt.day)
          : today.subtract(const Duration(days: 1));

      if (lastCalculatedDay.isAfter(today) || lastCalculatedDay.isAtSameMomentAs(today)) {
        return; // Already calculated for today
      }

      // Calculate interest for missed days
      var currentDate = lastCalculatedDay.add(const Duration(days: 1));
      var currentBalance = balance;
      final operations = <Map<String, dynamic>>[];

      while (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
        final interestAmount = currentBalance * dailyRate;
        currentBalance += interestAmount;

        operations.add({
          'type': 'daily_interest',
          'amount': interestAmount,
          'reason': 'Ежедневный процент за ${_formatDate(currentDate)}',
          'timestamp': currentDate.toIso8601String(),
          'balanceBefore': currentBalance - interestAmount,
          'balanceAfter': currentBalance,
        });

        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Add operations to history
      for (final operation in operations) {
        await historyRef.push().set(operation);
      }

      // Update account
      final updatedAccount = {
        ...accountData,
        'balance': currentBalance,
        'lastCalculatedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await accountRef.set(updatedAccount);

      // Update legacy balance in parents_children
      final parentsChildrenSnapshot = await db.child('parents_children').get();
      if (parentsChildrenSnapshot.exists && parentsChildrenSnapshot.value != null) {
        final parentsChildren = Map<String, dynamic>.from(parentsChildrenSnapshot.value as Map);

        for (final parentEntry in parentsChildren.entries) {
          final parentKey = parentEntry.key.toString();
          final parentData = Map<String, dynamic>.from(parentEntry.value as Map);

          if (parentData.containsKey(childId)) {
            final childRef = db.child('parents_children/$parentKey/$childId/balance');
            await childRef.set(currentBalance.round());
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating interest for child $childId: $e');
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Public method to trigger interest calculation manually
  static Future<void> triggerInterestCalculation() async {
    await processDailyInterestForAllChildren();
  }
}
