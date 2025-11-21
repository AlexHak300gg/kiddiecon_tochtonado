// lib/screens/parent_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'parent_dashboard_screen.dart';
import '../services/achievement_service.dart';

// Predefined task categories
const List<String> taskCategories = [
  'Уборка',
  'Учеба',
  'Спорт',
  'Творчество',
  'Помощь',
  'Покупки',
  'Другое',
];

const Map<String, IconData> categoryIcons = {
  'Уборка': Icons.cleaning_services,
  'Учеба': Icons.school,
  'Спорт': Icons.sports_basketball,
  'Творчество': Icons.palette,
  'Помощь': Icons.favorite,
  'Покупки': Icons.shopping_cart,
  'Другое': Icons.more_horiz,
};

class ParentTasksScreen extends StatefulWidget {
  final String parentName;
  const ParentTasksScreen({super.key, required this.parentName});

  @override
  State<ParentTasksScreen> createState() => _ParentTasksScreenState();
}

class _ParentTasksScreenState extends State<ParentTasksScreen> with TickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  String? _selectedChildId;
  String? _selectedCategory;
  bool _posting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedCategory = taskCategories.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final reward = double.tryParse(_rewardCtrl.text.trim()) ?? 0.0;
    
    if (title.isEmpty || _selectedChildId == null || reward <= 0 || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() => _posting = true);
    final db = FirebaseDatabase.instance.ref();
    final parentKey = widget.parentName.replaceAll('.', '_');

    // check parent balance
    final parentSnap = await db.child('parents/$parentKey/balance').get();
    double parentBalance = 0.0;
    if (parentSnap.exists && parentSnap.value != null) {
      final p = parentSnap.value;
      if (p is num) {
        parentBalance = p.toDouble();
      } else if (p is String) {
        parentBalance = double.tryParse(p) ?? 0.0;
      }
    }
    if (parentBalance < reward) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вознаграждение больше баланса родителя')),
        );
      }
      setState(() => _posting = false);
      return;
    }

    try {
      // create task under tasks/{parentKey}
      final taskRef = db.child('tasks/$parentKey').push();
      await taskRef.set({
        'title': title,
        'description': desc,
        'reward': reward,
        'category': _selectedCategory,
        'childId': _selectedChildId,
        'parentKey': parentKey,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'open',
        'photoUrls': [],
      });

      // log
      final logRef = db.child('logs/$parentKey').push();
      await logRef.set({
        'type': 'task_created',
        'taskId': taskRef.key,
        'title': title,
        'amount': reward,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _posting = false;
          _titleCtrl.clear();
          _descCtrl.clear();
          _rewardCtrl.clear();
          _selectedChildId = null;
          _selectedCategory = taskCategories.first;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача создана')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _approveTask(String taskId) async {
    final db = FirebaseDatabase.instance.ref();
    final parentKey = widget.parentName.replaceAll('.', '_');
    
    try {
      // Получаем информацию о задаче для начисления награды
      final taskSnap = await db.child('tasks/$parentKey/$taskId').get();
      if (!taskSnap.exists) return;
      
      final task = Map<String, dynamic>.from(taskSnap.value as Map);
      final reward = task['reward'] ?? 0;
      final childId = task['childId'] ?? '';
      
      // Обновляем статус задачи
      await db.child('tasks/$parentKey/$taskId').update({
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
      });
      
      // Начисляем награду ребенку
      if (childId.isNotEmpty && reward > 0) {
        final childRef = db.child('parents_children/$parentKey/$childId/balance');
        final childSnap = await childRef.get();
        
        double currentBalance = 0.0;
        if (childSnap.exists && childSnap.value != null) {
          final val = childSnap.value;
          if (val is num) {
            currentBalance = val.toDouble();
          } else if (val is String) {
            currentBalance = double.tryParse(val) ?? 0.0;
          }
        }
        
        await childRef.set(currentBalance + reward);
      }
      
      // Логируем операцию
      final logRef = db.child('logs/$parentKey').push();
      await logRef.set({
        'type': 'task_completed',
        'taskId': taskId,
        'amount': reward,
        'childId': childId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Check for achievements after task approval
      if (childId.isNotEmpty) {
        try {
          final achievementService = AchievementService();
          await achievementService.checkAndUnlockAchievements(childId);
        } catch (e) {
          print('Error checking achievements: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача одобрена и награда начислена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _rejectTask(String taskId) async {
    final TextEditingController reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Причина отклонения'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Укажите причину отклонения...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
    
    if (reason == null || reason.isEmpty) return;
    
    final db = FirebaseDatabase.instance.ref();
    final parentKey = widget.parentName.replaceAll('.', '_');
    
    try {
      await db.child('tasks/$parentKey/$taskId').update({
        'status': 'open',
        'rejectionReason': reason,
        'completedAt': DateTime.now().toIso8601String(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача отклонена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final db = FirebaseDatabase.instance.ref();
    final parentKey = widget.parentName.replaceAll('.', '_');
    
    try {
      await db.child('tasks/$parentKey/$taskId').remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _viewTaskPhotos(List<String> photoUrls, String taskTitle) {
    if (photoUrls.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoPreviewScreen(
          photoUrls: photoUrls,
          taskTitle: taskTitle,
        ),
      ),
    );
  }

  // Build the create task form
  Widget _buildCreateTaskForm() {
    final parentKey = widget.parentName.replaceAll('.', '_');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Название задачи'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Описание'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            items: taskCategories.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
            decoration: const InputDecoration(labelText: 'Категория'),
          ),
          const SizedBox(height: 8),
          FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('parents_children/$parentKey').get(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data?.value == null) {
                return const Text('Нет детей для назначения');
              }
              final raw = snap.data!.value as Map<Object?, Object?>;
              final children = raw.map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));
              return DropdownButtonFormField<String>(
                initialValue: _selectedChildId,
                items: children.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value['childName'] ?? 'Без имени'));
                }).toList(),
                onChanged: (v) => setState(() => _selectedChildId = v),
                decoration: const InputDecoration(labelText: 'Выберите ребёнка'),
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rewardCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Вознаграждение (₽)'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _posting ? null : _createTask,
                child: _posting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Создать задачу'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // Build active tasks tab (open status)
  Widget _buildActiveTasksTab() {
    final parentKey = widget.parentName.replaceAll('.', '_');

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('tasks/$parentKey').onValue,
      builder: (context, snap) {
        if (!snap.hasData || snap.data?.snapshot.value == null) {
          return const Center(child: Text('Нет активных задач'));
        }

        final raw = snap.data!.snapshot.value as Map<Object?, Object?>;
        final allTasks = raw.entries
            .map((e) {
              final id = e.key.toString();
              final task = Map<String, dynamic>.from(e.value as Map);
              return (id, task);
            })
            .where((entry) => entry.$2['status'] == 'open')
            .toList();

        if (allTasks.isEmpty) {
          return const Center(child: Text('Нет активных задач'));
        }

        // Group tasks by child
        final Map<String, List<(String, Map<String, dynamic>)>> tasksByChild = {};
        for (var task in allTasks) {
          final childId = task.$2['childId'] ?? 'unknown';
          if (!tasksByChild.containsKey(childId)) {
            tasksByChild[childId] = [];
          }
          tasksByChild[childId]!.add(task);
        }

        return ListView.builder(
          itemCount: tasksByChild.length,
          itemBuilder: (context, index) {
            final childId = tasksByChild.keys.toList()[index];
            final childTasks = tasksByChild[childId]!;

            return FutureBuilder<DataSnapshot>(
              future: FirebaseDatabase.instance.ref('parents_children/$parentKey/$childId/childName').get(),
              builder: (context, childSnap) {
                final childName = childSnap.hasData && childSnap.data?.value != null
                    ? childSnap.data!.value.toString()
                    : 'Ребёнок';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          childName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...childTasks.map((task) => _buildTaskCard(task.$1, task.$2, 'open')),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Build pending review tasks tab
  Widget _buildPendingTasksTab() {
    final parentKey = widget.parentName.replaceAll('.', '_');

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('tasks/$parentKey').onValue,
      builder: (context, snap) {
        if (!snap.hasData || snap.data?.snapshot.value == null) {
          return const Center(child: Text('Нет задач на проверке'));
        }

        final raw = snap.data!.snapshot.value as Map<Object?, Object?>;
        final pendingTasks = raw.entries
            .map((e) {
              final id = e.key.toString();
              final task = Map<String, dynamic>.from(e.value as Map);
              return (id, task);
            })
            .where((entry) => entry.$2['status'] == 'pending')
            .toList();

        if (pendingTasks.isEmpty) {
          return const Center(child: Text('Нет задач на проверке'));
        }

        return ListView.builder(
          itemCount: pendingTasks.length,
          itemBuilder: (context, index) {
            final (id, task) = pendingTasks[index];
            return _buildPendingTaskCard(id, task);
          },
        );
      },
    );
  }

  // Build history tab (completed and rejected)
  Widget _buildHistoryTab() {
    final parentKey = widget.parentName.replaceAll('.', '_');

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('tasks/$parentKey').onValue,
      builder: (context, snap) {
        if (!snap.hasData || snap.data?.snapshot.value == null) {
          return const Center(child: Text('История задач пуста'));
        }

        final raw = snap.data!.snapshot.value as Map<Object?, Object?>;
        final historyTasks = raw.entries
            .map((e) {
              final id = e.key.toString();
              final task = Map<String, dynamic>.from(e.value as Map);
              return (id, task);
            })
            .where((entry) => entry.$2['status'] == 'completed' || entry.$2['status'] == 'rejected')
            .toList()
            .reversed
            .toList();

        if (historyTasks.isEmpty) {
          return const Center(child: Text('История задач пуста'));
        }

        return ListView.builder(
          itemCount: historyTasks.length,
          itemBuilder: (context, index) {
            final (id, task) = historyTasks[index];
            return _buildHistoryTaskCard(id, task);
          },
        );
      },
    );
  }

  // Build a task card for active tasks
  Widget _buildTaskCard(String taskId, Map<String, dynamic> task, String context) {
    final title = task['title'] ?? '';
    final desc = task['description'] ?? '';
    final reward = task['reward'] ?? 0;
    final category = task['category'] ?? 'Другое';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: Icon(
            categoryIcons[category] ?? Icons.assignment,
            color: Colors.blue,
          ),
        ),
        title: Text(
          '$title — ₽${reward.toString()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desc.isNotEmpty)
              Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
          onSelected: (v) async {
            if (v == 'delete') await _deleteTask(taskId);
          },
        ),
      ),
    );
  }

  // Build a task card for pending review tasks (large photo display)
  Widget _buildPendingTaskCard(String taskId, Map<String, dynamic> task) {
    final title = task['title'] ?? '';
    final desc = task['description'] ?? '';
    final reward = task['reward'] ?? 0;
    final category = task['category'] ?? 'Другое';
    final photoUrls = (task['photoUrls'] as List?)?.cast<String>() ?? [];
    final rejectionReason = task['rejectionReason'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and reward
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: Icon(
                    categoryIcons[category] ?? Icons.assignment,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '₽${reward.toString()}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            if (desc.isNotEmpty)
              Text(desc, style: const TextStyle(color: Colors.grey)),
            if (desc.isNotEmpty) const SizedBox(height: 8),
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Photos
            if (photoUrls.isNotEmpty) ...[
              const Text(
                'Фото подтверждения:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photoUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _viewTaskPhotos(photoUrls, title),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photoUrls[index],
                            fit: BoxFit.cover,
                            width: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Rejection reason if exists
            if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Причина отклонения: $rejectionReason',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveTask(taskId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Принять'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectTask(taskId),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Отклонить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build a task card for history
  Widget _buildHistoryTaskCard(String taskId, Map<String, dynamic> task) {
    final title = task['title'] ?? '';
    final reward = task['reward'] ?? 0;
    final status = task['status'] ?? '';
    final category = task['category'] ?? 'Другое';
    final completedAt = task['completedAt'] as String?;
    final rejectionReason = task['rejectionReason'] as String?;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Выполнено';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Отклонено';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Неизвестно';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            categoryIcons[category] ?? Icons.assignment,
            color: statusColor,
          ),
        ),
        title: Text(
          '$title — ₽${reward.toString()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (completedAt != null)
                  Text(
                    _formatDate(completedAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
            if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Причина: $rejectionReason',
                style: const TextStyle(fontSize: 11, color: Colors.red),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (e) {
      return '';
    }
  }

  // Get count of pending tasks for badge
  Widget _buildPendingTasksBadge() {
    final parentKey = widget.parentName.replaceAll('.', '_');

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('tasks/$parentKey').onValue,
      builder: (context, snap) {
        if (!snap.hasData || snap.data?.snapshot.value == null) {
          return const Text('На проверке');
        }

        final raw = snap.data!.snapshot.value as Map<Object?, Object?>;
        final pendingCount = raw.values
            .whereType<Map>()
            .where((entry) => entry['status'] == 'pending')
            .length;

        if (pendingCount == 0) {
          return const Text('На проверке');
        }

        return Stack(
          children: [
            const Text('На проверке'),
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ParentDashboardScreen(parentName: widget.parentName);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            dashboard.buildHeader(context),
            dashboard.buildNavBar(context, 1),
            // TabBar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  const Tab(text: 'Активные'),
                  Tab(child: _buildPendingTasksBadge()),
                  const Tab(text: 'История'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active tab with create form and active tasks
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildCreateTaskForm(),
                        const SizedBox(height: 12),
                        const Text(
                          'Активные задачи',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 400,
                          child: _buildActiveTasksTab(),
                        ),
                      ],
                    ),
                  ),
                  // Pending review tab
                  _buildPendingTasksTab(),
                  // History tab
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreviewScreen extends StatefulWidget {
  final List<String> photoUrls;
  final String taskTitle;

  const _PhotoPreviewScreen({
    required this.photoUrls,
    required this.taskTitle,
  });

  @override
  State<_PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<_PhotoPreviewScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.taskTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemCount: widget.photoUrls.length,
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
                        const Text(
                          'Ошибка загрузки фото',
                          style: TextStyle(
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
              child: Center(
                child: Text(
                  '${_currentPage + 1} / ${widget.photoUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : null,
    );
  }
}
