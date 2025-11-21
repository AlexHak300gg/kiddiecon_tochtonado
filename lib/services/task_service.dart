import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  Stream<List<Task>> getTasksForChild(String childId) {
    final tasksRef = _database.ref('tasks');
    
    return tasksRef.onValue.map((event) {
      final Map<dynamic, dynamic>? tasksData = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (tasksData == null) return <Task>[];
      
      final List<Task> tasks = [];
      
      tasksData.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          final taskData = Map<String, dynamic>.from(value);
          taskData['id'] = key.toString();
          
          // Фильтруем задачи для текущего ребенка
          if (taskData['childId']?.toString() == childId) {
            tasks.add(Task.fromJson(taskData));
          }
        }
      });
      
      // Сортируем по дате создания (новые сначала)
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return tasks;
    });
  }

  Future<List<String>> uploadImagesToStorage(String taskId, List<XFile> images) async {
    if (images.isEmpty) return [];

    final List<String> photoUrls = [];
    
    for (final image in images) {
      try {
        final String fileName = '${taskId}_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final firebase_storage.Reference ref = _storage.ref().child('tasks/$taskId/photos/$fileName');
        
        final firebase_storage.UploadTask uploadTask = ref.putData(
          await image.readAsBytes(),
          firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
        );
        
        final firebase_storage.TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        photoUrls.add(downloadUrl);
      } catch (e) {
        // Продолжаем загрузку остальных фото даже если одно не удалось
      }
    }
    
    return photoUrls;
  }

  Future<void> submitTaskForApproval(String taskId, List<String> photoUrls) async {
    final taskRef = _database.ref('tasks/$taskId');
    
    await taskRef.update({
      'status': 'pending',
      'submittedAt': DateTime.now().toIso8601String(),
      'photoUrls': photoUrls,
    });
  }

  Future<void> completeTask(String taskId) async {
    final taskRef = _database.ref('tasks/$taskId');
    
    await taskRef.update({
      'status': 'completed',
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> rejectTask(String taskId, String reason) async {
    final taskRef = _database.ref('tasks/$taskId');
    
    await taskRef.update({
      'status': 'rejected',
      'rejectionReason': reason,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Task?> getTaskById(String taskId) async {
    final DataSnapshot snapshot = await _database.ref('tasks/$taskId').get();
    
    if (!snapshot.exists) return null;
    
    final taskData = Map<String, dynamic>.from(snapshot.value as Map);
    taskData['id'] = snapshot.key;
    
    return Task.fromJson(taskData);
  }

  Stream<Task?> watchTask(String taskId) {
    return _database.ref('tasks/$taskId').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      
      final taskData = Map<String, dynamic>.from(event.snapshot.value as Map);
      taskData['id'] = event.snapshot.key;
      
      return Task.fromJson(taskData);
    });
  }

  // Метод для получения задач по статусу
  List<Task> filterTasksByStatus(List<Task> tasks, TaskStatus status) {
    return tasks.where((task) => task.status == status).toList();
  }

  // Метод для получения активных задач (open + pending)
  List<Task> getActiveTasks(List<Task> tasks) {
    return tasks.where((task) => task.isActive).toList();
  }

  // Метод для получения завершенных задач (completed + rejected)
  List<Task> getCompletedTasks(List<Task> tasks) {
    return tasks.where((task) => task.isCompleted || task.isRejected).toList();
  }
}