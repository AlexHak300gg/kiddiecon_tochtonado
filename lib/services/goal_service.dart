import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/goal.dart';
import 'achievement_service.dart';

/// Сервис управления целями с Firebase синхронизацией
class GoalService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final String parentKey;
  final String childId;
  
  late DatabaseReference _goalsRef;
  StreamSubscription<DatabaseEvent>? _goalsSubscription;
  
  final StreamController<List<Goal>> _goalsController = StreamController<List<Goal>>.broadcast();
  Stream<List<Goal>> get goalsStream => _goalsController.stream;
  
  List<Goal> _cachedGoals = [];
  
  GoalService({required this.parentKey, required this.childId}) {
    _goalsRef = _db.child('parents_children/$parentKey/$childId/goals');
    _subscribeToGoals();
  }
  
  void _subscribeToGoals() {
    _goalsSubscription?.cancel();
    _goalsSubscription = _goalsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      List<Goal> goals = [];
      
      if (data != null && data is Map) {
        for (var entry in data.entries) {
          try {
            final goalData = Map<String, dynamic>.from(entry.value as Map);
            goalData['id'] = entry.key;
            goals.add(Goal.fromJson(goalData));
          } catch (e) {
            debugPrint('Error parsing goal: $e');
          }
        }
      }
      
      // Сортировка: сначала активные, потом по дате создания (новые сверху)
      goals.sort((a, b) {
        if (a.active && !b.active) return -1;
        if (!a.active && b.active) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      _cachedGoals = goals;
      _goalsController.add(goals);
    });
  }
  
  /// Возвращает текущую активную цель или null
  Goal? get activeGoal {
    try {
      return _cachedGoals.firstWhere((g) => g.active);
    } catch (e) {
      return null;
    }
  }
  
  /// Возвращает все цели (кэшированные)
  List<Goal> get allGoals => List.unmodifiable(_cachedGoals);
  
  /// Получить все цели для ребенка (для совместимости)
  Future<List<Goal>> getGoals(String childId) async {
    return _cachedGoals;
  }
  
  /// Слушать изменения целей для ребенка (для совместимости)
  Stream<List<Goal>> listenToGoals(String childId) {
    return _goalsController.stream;
  }
  
  /// Создание новой цели
  /// Возвращает созданную цель или null если есть активная цель
  Future<Goal?> createGoal({
    required String name,
    required int target,
    DateTime? deadline,
  }) async {
    // Валидация
    if (name.trim().isEmpty) {
      throw Exception('Название цели не может быть пустым');
    }
    if (target <= 0) {
      throw Exception('Сумма цели должна быть больше 0');
    }
    if (deadline != null && deadline.isBefore(DateTime.now())) {
      throw Exception('Срок должен быть в будущем');
    }
    
    // Проверяем, нет ли уже активной цели
    if (activeGoal != null) {
      throw Exception('У вас уже есть активная цель. Завершите её или откажитесь от неё.');
    }
    
    // Деактивируем все предыдущие цели (на всякий случай)
    for (var goal in _cachedGoals.where((g) => g.active)) {
      await _goalsRef.child(goal.id).update({'active': false});
    }
    
    final goalId = DateTime.now().millisecondsSinceEpoch.toString();
    final goal = Goal(
      id: goalId,
      name: name.trim(),
      target: target,
      deadline: deadline,
      active: true,
      progress: 0,
    );
    
    await _goalsRef.child(goalId).set(goal.toJson());
    
    // Добавляем запись в историю операций
    await _db.child('parents_children/$parentKey/$childId/history').push().set({
      'action': 'Создание цели',
      'amount': 0,
      'note': name.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return goal;
  }
  
  /// Пополнение цели
  Future<bool> depositToGoal(Goal goal, int amount) async {
    if (amount <= 0) return false;
    if (!goal.active) return false;
    
    final toAdd = amount.clamp(0, goal.remaining);
    final newProgress = goal.progress + toAdd;
    
    await _goalsRef.child(goal.id).update({
      'progress': newProgress,
    });
    
    // Если цель достигнута, отмечаем её как завершённую
    if (newProgress >= goal.target) {
      await completeGoal(goal);
    }
    
    return true;
  }
  
  /// Завершение цели (достижение 100%)
  Future<void> completeGoal(Goal goal) async {
    await _goalsRef.child(goal.id).update({
      'active': false,
      'completedAt': DateTime.now().toIso8601String(),
      'progress': goal.target, // Гарантируем, что progress = target
    });
    
    // Добавляем запись в историю
    await _db.child('parents_children/$parentKey/$childId/history').push().set({
      'action': 'Цель достигнута',
      'amount': goal.target,
      'note': goal.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Check for achievements after goal completion
    try {
      final achievementService = AchievementService();
      await achievementService.checkAndUnlockAchievements(childId);
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }
  
  /// Отказ от цели
  Future<void> abandonGoal(Goal goal) async {
    await _goalsRef.child(goal.id).update({
      'active': false,
    });
    
    // Добавляем запись в историю
    await _db.child('parents_children/$parentKey/$childId/history').push().set({
      'action': 'Отказ от цели',
      'amount': 0,
      'note': goal.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  void dispose() {
    _goalsSubscription?.cancel();
    _goalsController.close();
  }
}
