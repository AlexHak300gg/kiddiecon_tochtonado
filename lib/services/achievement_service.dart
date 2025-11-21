import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../models/operation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _achievementsCacheKey = 'achievements_cache';
  
  // Stream controllers for real-time updates
  final StreamController<List<Achievement>> _achievementsController = 
      StreamController<List<Achievement>>.broadcast();
  
  Stream<List<Achievement>> get achievementsStream => _achievementsController.stream;

  AchievementService() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
  }

  Future<void> _showAchievementNotification(Achievement achievement) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'achievements',
      'Достижения',
      channelDescription: 'Уведомления о разблокировке достижений',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.orange,
      playSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🎉 Новое достижение!',
      achievement.title,
      platformChannelSpecifics,
    );
  }

  // Listen for achievements changes
  Stream<List<Achievement>> listenToAchievements(String childId) {
    _db.child('children/$childId/achievements').onValue.listen((event) async {
      List<Achievement> achievements = [];
      
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        
        for (var entry in data.entries) {
          final achievement = Achievement.fromMap(entry.value, id: entry.key);
          achievements.add(achievement);
        }
      }
      
      // Add locked achievements that aren't in the database yet
      for (var predefined in Achievement.predefinedAchievements) {
        if (!achievements.any((a) => a.id == predefined.id)) {
          achievements.add(predefined);
        }
      }
      
      achievements.sort((a, b) {
        if (a.isUnlocked && !b.isUnlocked) return -1;
        if (!a.isUnlocked && b.isUnlocked) return 1;
        return 0;
      });
      
      _achievementsController.add(achievements);
    });
    
    return _achievementsController.stream;
  }

  Future<List<Achievement>> getAchievements(String childId) async {
    List<Achievement> achievements = [];
    
    try {
      final snapshot = await _db.child('children/$childId/achievements').get();
      
      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;
        
        for (var entry in data.entries) {
          final achievementData = Map<String, dynamic>.from(entry.value as Map);
          final achievement = Achievement.fromMap(achievementData, id: entry.key);
          achievements.add(achievement);
        }
      }
      
      // Add locked achievements that aren't in the database yet
      for (var predefined in Achievement.predefinedAchievements) {
        if (!achievements.any((a) => a.id == predefined.id)) {
          achievements.add(predefined);
        }
      }
      
      achievements.sort((a, b) {
        if (a.isUnlocked && !b.isUnlocked) return -1;
        if (!a.isUnlocked && b.isUnlocked) return 1;
        return 0;
      });
      
      return achievements;
    } catch (e) {
      // Try to load from cache
      return await _loadAchievementsFromCache(childId);
    }
  }

  Future<void> unlockAchievement(String childId, String achievementId) async {
    try {
      final predefined = Achievement.predefinedAchievements
          .firstWhere((a) => a.id == achievementId);
      
      final unlockedAchievement = predefined.copyWith(
        unlockedAt: DateTime.now(),
        isUnlocked: true,
      );
      
      await _db.child('children/$childId/achievements/$achievementId')
          .set(unlockedAchievement.toMap());
      
      await _showAchievementNotification(unlockedAchievement);
      
      // Cache locally
      await _cacheAchievement(childId, unlockedAchievement);
      
    } catch (e) {
      developer.log('Error unlocking achievement: $e');
    }
  }

  Future<void> checkAndUnlockAchievements(String childId) async {
    try {
      // Get current data
      final account = await _getAccount(childId);
      final goals = await _getGoals(childId);
      final operations = await _getOperations(childId);
      final achievements = await getAchievements(childId);
      
      // Check each achievement condition
      for (var achievement in Achievement.predefinedAchievements) {
        if (achievements.any((a) => a.id == achievement.id && a.isUnlocked)) {
          continue; // Already unlocked
        }
        
        bool shouldUnlock = false;
        
        switch (achievement.id) {
          case 'first_task':
            shouldUnlock = operations.where((o) => o.type == OperationType.task).isNotEmpty;
            break;
            
          case 'persistent_saver':
            final activeGoal = goals.where((g) => g.active).firstOrNull;
            if (activeGoal != null) {
              shouldUnlock = (activeGoal.progress / activeGoal.target) >= 0.5;
            }
            break;
            
          case 'goal_achieved':
            shouldUnlock = goals.any((g) => !g.active && g.completedAt != null);
            break;
            
          case 'week_active':
            shouldUnlock = await _checkWeekActivity(childId, operations);
            break;
            
          case 'balance_100':
            shouldUnlock = account.balance >= 100;
            break;
            
          case 'five_tasks':
            final taskOperations = operations.where((o) => o.type == OperationType.task);
            shouldUnlock = taskOperations.length >= 5;
            break;
        }
        
        if (shouldUnlock) {
          await unlockAchievement(childId, achievement.id!);
        }
      }
    } catch (e) {
      developer.log('Error checking achievements: $e');
    }
  }

  Future<bool> _checkWeekActivity(String childId, List<Operation> operations) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final taskOperations = operations
        .where((o) => o.type == OperationType.task)
        .where((o) => o.timestamp.isAfter(weekAgo))
        .toList();
    
    // Check if there are tasks on at least 7 different days
    final Set<DateTime> uniqueDays = {};
    for (var operation in taskOperations) {
      final day = DateTime(
        operation.timestamp.year,
        operation.timestamp.month,
        operation.timestamp.day,
      );
      uniqueDays.add(day);
    }
    
    return uniqueDays.length >= 7;
  }

  Future<Account> _getAccount(String childId) async {
    final snapshot = await _db.child('children/$childId/account').get();
    if (snapshot.exists) {
      final accountData = Map<String, dynamic>.from(snapshot.value as Map);
      return Account.fromMap(accountData);
    }
    return Account(balance: 0, dailyRate: 0.0001);
  }

  Future<List<Goal>> _getGoals(String childId) async {
    List<Goal> goals = [];
    final snapshot = await _db.child('children/$childId/goals').get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map;
      for (var entry in data.entries) {
        final goalData = Map<String, dynamic>.from(entry.value as Map);
        goals.add(Goal.fromJson(goalData..['id'] = entry.key));
      }
    }
    
    return goals;
  }

  Future<List<Task>> _getTasks(String childId) async {
    List<Task> tasks = [];
    final snapshot = await _db.child('tasks').get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map;
      for (var parentEntry in data.entries) {
        if (parentEntry.value is Map) {
          final Map<dynamic, dynamic> parentTasks = parentEntry.value as Map;
          for (var taskEntry in parentTasks.entries) {
            final task = Task.fromJson(taskEntry.value as Map<String, dynamic>, id: taskEntry.key);
            if (task.childId == childId) {
              tasks.add(task);
            }
          }
        }
      }
    }
    
    return tasks;
  }

  Future<List<Operation>> _getOperations(String childId) async {
    List<Operation> operations = [];
    final snapshot = await _db.child('children/$childId/history').get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map;
      for (var entry in data.entries) {
        operations.add(Operation.fromMap(entry.value, id: entry.key));
      }
    }
    
    return operations;
  }

  Future<void> _cacheAchievement(String childId, Achievement achievement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_achievementsCacheKey}_$childId';
      
      String? existingData = prefs.getString(key);
      Map<String, dynamic> cache = {};
      
      if (existingData != null) {
        cache = jsonDecode(existingData);
      }
      
      cache[achievement.id!] = achievement.toMap();
      await prefs.setString(key, jsonEncode(cache));
    } catch (e) {
      developer.log('Error caching achievement: $e');
    }
  }

  Future<List<Achievement>> _loadAchievementsFromCache(String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_achievementsCacheKey}_$childId';
      
      String? cachedData = prefs.getString(key);
      if (cachedData != null) {
        final Map<String, dynamic> cache = jsonDecode(cachedData);
        List<Achievement> achievements = [];
        
        for (var entry in cache.entries) {
          achievements.add(Achievement.fromMap(entry.value, id: entry.key));
        }
        
        return achievements;
      }
    } catch (e) {
      developer.log('Error loading cached achievements: $e');
    }
    
    return Achievement.predefinedAchievements;
  }

  void dispose() {
    _achievementsController.close();
  }
}