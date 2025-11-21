import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_database/firebase_database.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../models/operation.dart';

class AnalyticsService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Get children data for parent dashboard
  Future<List<Map<String, dynamic>>> getChildrenDashboardData(String parentKey) async {
    try {
      final childrenSnapshot = await _db.child('children').get();
      List<Map<String, dynamic>> childrenData = [];

      if (childrenSnapshot.exists && childrenSnapshot.value is Map) {
        final Map<dynamic, dynamic> childrenMap = childrenSnapshot.value as Map;
        
        for (var entry in childrenMap.entries) {
          final childId = entry.key.toString();
          final childData = entry.value as Map;
          
          // Check if this child belongs to the parent
          if (childData['parentKey'] == parentKey) {
            final account = await _getChildAccount(childId);
            final goals = await _getChildGoals(childId);
            final operations = await _getChildOperations(childId);
            final activeGoal = goals.where((g) => g.active).firstOrNull;
            
            childrenData.add({
              'id': childId,
              'name': childData['name'] ?? 'Без имени',
              'balance': account.balance,
              'dailyRate': account.dailyRate,
              'activeGoal': activeGoal,
              'totalGoals': goals.length,
              'completedGoals': goals.where((g) => !g.active).length,
              'operations': operations,
            });
          }
        }
      }
      
      return childrenData;
    } catch (e) {
      developer.log('Error getting children dashboard data: $e');
      return [];
    }
  }

  // Get balance history for charts
  Future<List<Map<String, dynamic>>> getBalanceHistory(String childId, String period) async {
    try {
      final operations = await _getChildOperations(childId);
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case 'День':
          startDate = now.subtract(const Duration(days: 1));
          break;
        case 'Неделя':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Месяц':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'Квартал':
          startDate = now.subtract(const Duration(days: 90));
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }
      
      final filteredOperations = operations
          .where((o) => o.timestamp.isAfter(startDate))
          .toList();
      
      // Group by date and calculate daily balance
      Map<String, double> dailyBalance = {};
      double currentBalance = 0;
      
      // Get initial balance before period
      final beforePeriodOperations = operations
          .where((o) => o.timestamp.isBefore(startDate))
          .toList();
      for (var op in beforePeriodOperations) {
        currentBalance = op.balanceAfter;
      }
      
      // Process operations in chronological order
      final sortedOperations = filteredOperations..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      for (var operation in sortedOperations) {
        final dateKey = _formatDateKey(operation.timestamp);
        currentBalance = operation.balanceAfter;
        dailyBalance[dateKey] = currentBalance;
      }
      
      // Fill missing dates
      final List<Map<String, dynamic>> chartData = [];
      DateTime currentDate = startDate;
      
      while (currentDate.isBefore(now) || currentDate.isAtSameMomentAs(now)) {
        final dateKey = _formatDateKey(currentDate);
        chartData.add({
          'date': dateKey,
          'balance': dailyBalance[dateKey] ?? currentBalance,
        });
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      return chartData;
    } catch (e) {
      print('Error getting balance history: $e');
      return [];
    }
  }

  // Get income data for weekly chart
  Future<List<Map<String, dynamic>>> getWeeklyIncome(String childId, String period) async {
    try {
      final operations = await _getChildOperations(childId);
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case 'День':
          startDate = now.subtract(const Duration(days: 1));
          break;
        case 'Неделя':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Месяц':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'Квартал':
          startDate = now.subtract(const Duration(days: 90));
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }
      
      final incomeOperations = operations
          .where((o) => o.amount > 0 && o.timestamp.isAfter(startDate))
          .toList();
      
      // Group by week
      Map<String, double> weeklyIncome = {};
      
      for (var operation in incomeOperations) {
        final weekKey = _formatWeekKey(operation.timestamp);
        weeklyIncome[weekKey] = (weeklyIncome[weekKey] ?? 0) + operation.amount;
      }
      
      // Generate weekly data
      final List<Map<String, dynamic>> chartData = [];
      final startWeek = _formatWeekKey(startDate);
      final endWeek = _formatWeekKey(now);
      
      // Generate all weeks in range
      DateTime currentWeekStart = _getWeekStart(startDate);
      while (currentWeekStart.isBefore(now) || currentWeekStart.isAtSameMomentAs(now)) {
        final weekKey = _formatWeekKey(currentWeekStart);
        chartData.add({
          'week': weekKey,
          'income': weeklyIncome[weekKey] ?? 0.0,
        });
        currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      }
      
      return chartData;
    } catch (e) {
      print('Error getting weekly income: $e');
      return [];
    }
  }

  // Get goal progress history
  Future<List<Map<String, dynamic>>> getGoalProgressHistory(String childId, String? goalId) async {
    try {
      final goals = await _getChildGoals(childId);
      final operations = await _getChildOperations(childId);
      
      if (goalId != null) {
        // Specific goal progress
        final goal = goals.firstWhere((g) => g.id == goalId);
        return _getGoalProgressData(goal, operations);
      } else {
        // All goals progress
        List<Map<String, dynamic>> allProgressData = [];
        for (var goal in goals) {
          final progressData = await _getGoalProgressData(goal, operations);
          allProgressData.addAll(progressData);
        }
        return allProgressData;
      }
    } catch (e) {
      print('Error getting goal progress history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getGoalProgressData(Goal goal, List<Operation> operations) async {
    List<Map<String, dynamic>> progressData = [];
    
    // Get goal deposit operations
    final goalOperations = operations
        .where((o) => o.type == OperationType.goalDeposit)
        .where((o) => o.timestamp.isAfter(goal.createdAt))
        .toList();
    
    double currentProgress = 0;
    progressData.add({
      'date': _formatDateKey(goal.createdAt),
      'progress': currentProgress,
      'goalName': goal.name,
      'target': goal.target,
    });
    
    for (var operation in goalOperations) {
      currentProgress += operation.amount;
      progressData.add({
        'date': _formatDateKey(operation.timestamp),
        'progress': currentProgress.clamp(0, goal.target),
        'goalName': goal.name,
        'target': goal.target,
      });
    }
    
    if (goal.completedAt != null) {
      progressData.add({
        'date': _formatDateKey(goal.completedAt!),
        'progress': goal.target,
        'goalName': goal.name,
        'target': goal.target,
      });
    }
    
    return progressData;
  }

  // Add bonus to child
  Future<void> addBonus(String childId, double amount, String comment, String parentKey) async {
    try {
      final accountRef = _db.child('children/$childId/account');
      final historyRef = _db.child('children/$childId/history');
      
      final accountSnapshot = await accountRef.get();
      
      if (accountSnapshot.exists) {
        final accountData = accountSnapshot.value as Map<String, dynamic>;
        final currentBalance = _toDouble(accountData['balance']);
        final newBalance = currentBalance + amount;
        
        // Update account
        await accountRef.update({
          'balance': newBalance,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        // Add to history
        final operationId = historyRef.push().key;
        final operation = {
          'type': 'bonus',
          'amount': amount,
          'reason': comment,
          'timestamp': DateTime.now().toIso8601String(),
          'balanceBefore': currentBalance,
          'balanceAfter': newBalance,
          'parentKey': parentKey,
        };
        
        await historyRef.child(operationId!).set(operation);
      }
    } catch (e) {
      print('Error adding bonus: $e');
      rethrow;
    }
  }

  // Update daily rate
  Future<void> updateDailyRate(String childId, double newRate) async {
    try {
      await _db.child('children/$childId/account').update({
        'dailyRate': newRate,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating daily rate: $e');
      rethrow;
    }
  }

  // Helper methods
  Future<Account> _getChildAccount(String childId) async {
    final snapshot = await _db.child('children/$childId/account').get();
    if (snapshot.exists) {
      return Account.fromJson(snapshot.value as Map<String, dynamic>);
    }
    return Account(balance: 0, dailyRate: 0.0001);
  }

  Future<List<Goal>> _getChildGoals(String childId) async {
    List<Goal> goals = [];
    final snapshot = await _db.child('children/$childId/goals').get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final Map<String, dynamic> data = snapshot.value as Map<String, dynamic>;
      for (var entry in data.entries) {
        goals.add(Goal.fromJson(entry.value as Map<String, dynamic>));
      }
    }
    
    return goals;
  }

  Future<List<Operation>> _getChildOperations(String childId) async {
    List<Operation> operations = [];
    final snapshot = await _db.child('children/$childId/history').get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final Map<String, dynamic> data = snapshot.value as Map<String, dynamic>;
      for (var entry in data.entries) {
        operations.add(Operation.fromMap(entry.value as Map<String, dynamic>, id: entry.key));
      }
    }
    
    return operations;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatWeekKey(DateTime date) {
    final weekStart = _getWeekStart(date);
    return '${weekStart.year}-W${weekStart.weekOfYear.toString().padLeft(2, '0')}';
  }

  DateTime _getWeekStart(DateTime date) {
    final daysSinceMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysSinceMonday);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

extension DateTimeExtensions on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysDifference = difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).floor() + 1;
  }
}