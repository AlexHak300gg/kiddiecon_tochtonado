import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';
import '../widgets/photo_upload_dialog.dart';

class ChildTasksScreen extends StatefulWidget {
  final String childName;
  final String childId;

  const ChildTasksScreen({
    super.key, 
    required this.childName,
    required this.childId,
  });

  @override
  State<ChildTasksScreen> createState() => _ChildTasksScreenState();
}

class _ChildTasksScreenState extends State<ChildTasksScreen>
    with SingleTickerProviderStateMixin {
  late TaskService _taskService;
  late TabController _tabController;
  List<Task> _allTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _taskService = TaskService();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    setState(() => _isLoading = true);
    _error = null;

    _taskService.getTasksForChild(widget.childId).listen(
      (tasks) {
        if (mounted) {
          setState(() {
            _allTasks = tasks;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  List<Task> get _activeTasks => _taskService.getActiveTasks(_allTasks);
  List<Task> get _completedTasks => _taskService.getCompletedTasks(_allTasks);

  Future<void> _onTaskComplete(Task task) async {
    final List<XFile> images = [];
    
    // Показываем диалог выбора фото
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PhotoUploadDialog(
        initialImages: images,
        onImagesChanged: (newImages) {
          images.clear();
          images.addAll(newImages);
        },
      ),
    );

    if (result != true || images.isEmpty) return;

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Загрузка фото...'),
          ],
        ),
      ),
    );

    try {
      // Загружаем фото в Firebase Storage
      final photoUrls = await _taskService.uploadImagesToStorage(task.id, images);
      
      if (photoUrls.isEmpty) {
        Navigator.pop(context); // Закрываем загрузку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось загрузить фото'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Отправляем задачу на проверку
      await _taskService.submitTaskForApproval(task.id, photoUrls);
      
      Navigator.pop(context); // Закрываем загрузку
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Задание "${task.title}" отправлено на проверку!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Закрываем загрузку
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTaskTap(Task task) {
    if (task.photoUrls.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoPreviewScreen(
            photoUrls: task.photoUrls,
            taskTitle: task.title,
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<Task> tasks) {
    if (tasks.isEmpty) {
      String message;
      IconData icon;
      
      if (_tabController.index == 0) {
        message = 'У тебя пока нет активных заданий\nЖди новых задач от родителей! 🎯';
        icon = Icons.assignment_outlined;
      } else {
        message = 'Пока нет выполненных заданий\nСделай первые шаги! 🚀';
        icon = Icons.history;
      }
      
      return _buildEmptyState(message, icon);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Перезагрузка данных
        _loadTasks();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onTap: () => _onTaskTap(task),
            onComplete: task.status == TaskStatus.open 
                ? () => _onTaskComplete(task) 
                : null,
            showActions: _tabController.index == 0, // Показываем кнопки только на активной вкладке
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Мои задания",
          style: GoogleFonts.nunito(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade600,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Активные"),
            Tab(text: "История"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Приветствие
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Привет, ${widget.childName}! 👋",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Выполняй задания и получай награды от родителей 💰",
                  style: GoogleFonts.nunito(color: Colors.black54),
                ),
              ],
            ),
          ),
          
          // Контент
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksList(_activeTasks),
                _buildTasksList(_completedTasks),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoPreviewScreen extends StatefulWidget {
  final List<String> photoUrls;
  final String taskTitle;

  const PhotoPreviewScreen({
    super.key,
    required this.photoUrls,
    required this.taskTitle,
  });

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.taskTitle,
          style: GoogleFonts.nunito(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        itemCount: widget.photoUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.network(
                widget.photoUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки фото',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.photoUrls.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_currentIndex + 1} / ${widget.photoUrls.length}',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}