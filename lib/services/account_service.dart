import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import '../models/account.dart';
import '../models/operation.dart';
import 'achievement_service.dart';

class AccountService {
  final String childId;
  final String parentKey;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  late DatabaseReference _accountRef;
  late DatabaseReference _historyRef;
  late DatabaseReference _childRef;

  AccountService({
    required this.childId,
    required this.parentKey,
  }) {
    _accountRef = _db.child('children/$childId/account');
    _historyRef = _db.child('children/$childId/history');
    _childRef = _db.child('parents_children/$parentKey/$childId');
  }

  // Get account stream
  Stream<Account> get accountStream {
    return _accountRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return Account(
          id: childId,
          balance: 0.0,
          dailyRate: 0.0001, // 0.01% annually
          lastCalculatedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      return Account.fromMap(map, id: childId);
    });
  }

  // Get operations stream
  Stream<List<Operation>> get operationsStream {
    return _historyRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return <Operation>[];
      }
      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      return map.entries.map((entry) {
        return Operation.fromMap(
          Map<String, dynamic>.from(entry.value as Map),
          id: entry.key,
        );
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  // Get account with local fallback
  Future<Account> getAccount() async {
    try {
      final snapshot = await _accountRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        final account = Account.fromMap(map, id: childId);
        
        // Save to local cache
        await _saveAccountLocally(account);
        return account;
      }
    } catch (e) {
      debugPrint('Error fetching account from Firebase: $e');
    }

    // Try to get from local cache
    try {
      final localAccount = await _getAccountLocally();
      if (localAccount != null) {
        return localAccount;
      }
    } catch (e) {
      debugPrint('Error fetching account locally: $e');
    }

    // Return default account
    return Account(
      id: childId,
      balance: 0.0,
      dailyRate: 0.0001,
      lastCalculatedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Calculate daily interest for missed days
  Future<List<Operation>> calculateMissedDaysInterest() async {
    final account = await getAccount();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCalculated = account.lastCalculatedAt != null
        ? DateTime(account.lastCalculatedAt!.year, account.lastCalculatedAt!.month, account.lastCalculatedAt!.day)
        : today.subtract(const Duration(days: 1));

    if (lastCalculated.isAfter(today) || lastCalculated.isAtSameMomentAs(today)) {
      return []; // No missed days
    }

    final operations = <Operation>[];
    var currentDate = lastCalculated.add(const Duration(days: 1));
    var currentBalance = account.balance;

    while (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
      final interestAmount = currentBalance * account.dailyRate;
      final newBalance = currentBalance + interestAmount;

      final operation = Operation(
        type: OperationType.dailyInterest,
        amount: interestAmount,
        reason: 'Ежедневный процент за ${_formatDate(currentDate)}',
        timestamp: currentDate,
        balanceBefore: currentBalance,
        balanceAfter: newBalance,
      );

      operations.add(operation);
      currentBalance = newBalance;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return operations;
  }

  // Apply daily interest with transaction
  Future<void> applyDailyInterest() async {
    final operations = await calculateMissedDaysInterest();
    if (operations.isEmpty) return;

    try {
      final account = await getAccount();
      var newBalance = account.balance;
      
      for (final operation in operations) {
        newBalance = operation.balanceAfter;
        
        // Add to history
        await _historyRef.push().set(operation.toMap());
      }

      // Update account
      final updatedAccount = account.copyWith(
        balance: newBalance,
        lastCalculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _accountRef.set(updatedAccount.toMap());
      
      // Update legacy balance
      await _childRef.child('balance').set(newBalance.round());

      // Save operations locally
      await _saveOperationsLocally(operations);
    } catch (e) {
      debugPrint('Error applying daily interest: $e');
    }
  }

  // Update daily rate
  Future<void> updateDailyRate(double newRate) async {
    await _accountRef.update({
      'dailyRate': newRate,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Add operation (for transfers, bonuses, etc.)
  Future<void> addOperation(OperationType type, double amount, String reason) async {
    try {
      final account = await getAccount();
      final newBalance = account.balance + amount;
      final operation = Operation(
        type: type,
        amount: amount,
        reason: reason,
        timestamp: DateTime.now(),
        balanceBefore: account.balance,
        balanceAfter: newBalance,
      );

      // Add to history
      await _historyRef.push().set(operation.toMap());

      // Update account
      final updatedAccount = account.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );

      await _accountRef.set(updatedAccount.toMap());
      
      // Update legacy balance
      await _childRef.child('balance').set(newBalance.round());
      
      // Check for achievements after operation
      try {
        final achievementService = AchievementService();
        await achievementService.checkAndUnlockAchievements(childId);
      } catch (e) {
        debugPrint('Error checking achievements: $e');
      }
    } catch (e) {
      debugPrint('Error adding operation: $e');
    }
  }

  // Local storage methods
  Future<void> _saveAccountLocally(Account account) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/account_$childId.json');
      await file.writeAsString(jsonEncode(account.toMap()));
    } catch (e) {
      debugPrint('Error saving account locally: $e');
    }
  }

  Future<Account?> _getAccountLocally() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/account_$childId.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        return Account.fromMap(map, id: childId);
      }
    } catch (e) {
      debugPrint('Error getting account locally: $e');
    }
    return null;
  }

  Future<void> _saveOperationsLocally(List<Operation> operations) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/operations_$childId.json');
      
      List<Map<String, dynamic>> existingOperations = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        existingOperations = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
      
      final newOperations = operations.map((op) => op.toMap()).toList();
      existingOperations.addAll(newOperations);
      
      await file.writeAsString(jsonEncode(existingOperations));
    } catch (e) {
      debugPrint('Error saving operations locally: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}